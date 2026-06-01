#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import mimetypes
import posixpath
import re
import shutil
import struct
import subprocess
import sys
import threading
import time
import zlib
import zipfile
from dataclasses import dataclass
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[2]
TOOLS_DIR = Path(__file__).resolve().parent
DIST_DIR = ROOT / "updater_dist"
PATCHED_DIR = DIST_DIR / "patched"
FILES_DIR = DIST_DIR / "files"
RELEASE_DIR = ROOT / "release_client"
CONFIG_PATH = TOOLS_DIR / "updater_config.json"
CHANGELOG_PATH = TOOLS_DIR / "changelog.txt"
MANIFEST_PATH = DIST_DIR / "manifest.json"
EMBEDDED_DATA_MAGIC = b"OTCV8_EMBEDDED_DATA_V1"
XXTEA_DELTA = 0x9E3779B9
UINT32_MASK = 0xFFFFFFFF


DEFAULT_CONFIG = {
    "host": "127.0.0.1",
    "port": 8080,
    "api_path": "/updater",
    "files_path": "/files/",
    "public_files_url": "",
    "title": "Tibia Otcv8 Classic",
    "include": ["init.lua", "data", "modules"],
    "executables": ["otclient_gl_x64.exe", "otclient_dx_x64.exe"],
    "launcher_executable": "otclient_gl_x64.exe",
    "copy_dlls": True,
    "compression_level": 1,
    "keep_files": False,
    "protect_files": True,
    "protect_extensions": [".lua", ".otui", ".otmod", ".otml", ".json", ".css"],
    "protection_seed": "tibiaotcv8-local-protection",
    "embed_data_zip": True,
    "protect_embedded_zip": False,
    "keep_release_data_zip": False,
}


@dataclass(frozen=True)
class Entry:
    rel: str
    path: Path
    checksum: str
    size: int


def fail(message: str) -> None:
    print(f"[erro] {message}", file=sys.stderr)
    raise SystemExit(1)


def safe_rmtree(path: Path) -> None:
    resolved = path.resolve()
    root = ROOT.resolve()
    if resolved == root or root not in resolved.parents:
        fail(f"recusando apagar fora da pasta do client: {resolved}")
    if path.exists():
        try:
            shutil.rmtree(path)
        except PermissionError as exc:
            fail(f"nao consegui limpar {path}; feche o client aberto e tente de novo ({exc})")


def merge_config() -> dict:
    config = dict(DEFAULT_CONFIG)
    if CONFIG_PATH.exists():
        try:
            user_config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            fail(f"JSON invalido em {CONFIG_PATH}: {exc}")
        config.update(user_config)

    config["api_path"] = normalize_url_path(config["api_path"], trailing_slash=False)
    config["files_path"] = normalize_url_path(config["files_path"], trailing_slash=True)
    return config


def normalize_url_path(path: str, trailing_slash: bool) -> str:
    if not path.startswith("/"):
        path = "/" + path
    if trailing_slash and not path.endswith("/"):
        path += "/"
    if not trailing_slash and len(path) > 1 and path.endswith("/"):
        path = path[:-1]
    return path


def updater_api_url(config: dict) -> str:
    return f"http://{config['host']}:{config['port']}{config['api_path']}"


def read_changelog() -> list[str]:
    if not CHANGELOG_PATH.exists():
        return [
            "Pacote local preparado para o auto updater.",
            "Edite tools/updater/changelog.txt para mostrar suas notas aqui.",
        ]

    lines = []
    for line in CHANGELOG_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            if line.startswith("- "):
                line = line[2:].strip()
            lines.append(line)
    return lines or ["Pacote local sem notas de changelog."]


def parse_app_version() -> int | None:
    init_path = ROOT / "init.lua"
    if not init_path.exists():
        return None
    text = init_path.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"APP_VERSION\s*=\s*(\d+)", text)
    return int(match.group(1)) if match else None


def should_include_file(path: Path) -> bool:
    name = path.name.lower()
    if name.endswith((".tmp", ".bak", ".log", ".pdb", ".ilk")):
        return False
    if "__pycache__" in path.parts:
        return False
    return path.is_file()


def iter_package_paths(config: dict) -> list[Path]:
    paths: list[Path] = []
    for item in config["include"]:
        base = (ROOT / item).resolve()
        if not base.exists():
            continue
        if base.is_file():
            if should_include_file(base):
                paths.append(base)
            continue
        for path in base.rglob("*"):
            if should_include_file(path):
                paths.append(path)
    paths.sort(key=lambda p: p.relative_to(ROOT).as_posix().lower())
    return paths


def patch_init_lua(data: bytes, api_url: str) -> bytes:
    text = data.decode("utf-8", errors="replace")
    pattern = r"(?m)^(\s*updater\s*=\s*)[\"'][^\"']*[\"']"
    text = re.sub(pattern, lambda match: f'{match.group(1)}"{api_url}"', text, count=1)
    return text.encode("utf-8")


def packaged_bytes(path: Path, rel: str, config: dict) -> bytes:
    data = path.read_bytes()
    if rel == "init.lua":
        data = patch_init_lua(data, updater_api_url(config))
    if should_protect(rel, config):
        data = protect_buffer(data, str(config.get("protection_seed", "")))
    return data


def crc32_hex(data: bytes) -> str:
    return f"{zlib.crc32(data) & 0xFFFFFFFF:08x}"


def adler32(data: bytes) -> int:
    return zlib.adler32(data) & UINT32_MASK


def xxtea_mx(z: int, y: int, total: int, key: tuple[int, int, int, int], p: int, e: int) -> int:
    left = (((z >> 5) ^ ((y << 2) & UINT32_MASK)) + ((y >> 3) ^ ((z << 4) & UINT32_MASK))) & UINT32_MASK
    right = ((total ^ y) + (key[(p & 3) ^ e] ^ z)) & UINT32_MASK
    return (left ^ right) & UINT32_MASK


def xxtea_encrypt(data: bytes, key64: int) -> bytes:
    usable = len(data) - (len(data) % 4)
    words_count = usable // 4
    if words_count < 2:
        return data

    words = list(struct.unpack("<" + "I" * words_count, data[:usable]))
    key = (
        (key64 >> 32) & UINT32_MASK,
        key64 & UINT32_MASK,
        0xDEADDEAD,
        0xB00BEEEF,
    )

    rounds = 6 + 52 // words_count
    total = 0
    z = words[words_count - 1]

    for _ in range(rounds):
        total = (total + XXTEA_DELTA) & UINT32_MASK
        e = (total >> 2) & 3
        for p in range(words_count - 1):
            y = words[p + 1]
            words[p] = (words[p] + xxtea_mx(z, y, total, key, p, e)) & UINT32_MASK
            z = words[p]

        y = words[0]
        p = words_count - 1
        words[p] = (words[p] + xxtea_mx(z, y, total, key, p, e)) & UINT32_MASK
        z = words[p]

    return struct.pack("<" + "I" * words_count, *words) + data[usable:]


def protect_buffer(data: bytes, seed: str) -> bytes:
    if data.startswith(b"ENC3"):
        return data

    key64 = ((adler32(data) << 32) | adler32(data[: len(data) // 2])) & 0xFFFFFFFFFFFFFFFF
    compressed = zlib.compress(data)
    encrypted = xxtea_encrypt(compressed, key64)
    seed_value = adler32(seed.encode("utf-8")) if seed else 0
    checksum = adler32(data) ^ seed_value
    return b"ENC3" + struct.pack("<QIII", key64, len(encrypted), len(data), checksum) + encrypted


def should_protect(rel: str, config: dict) -> bool:
    if not config.get("protect_files", True):
        return False
    extensions = {str(ext).lower() for ext in config.get("protect_extensions", [])}
    return Path(rel).suffix.lower() in extensions


def collect_entries(config: dict) -> list[Entry]:
    entries: list[Entry] = []
    seen: set[str] = set()

    for path in iter_package_paths(config):
        rel = path.relative_to(ROOT).as_posix()
        if rel in seen:
            continue
        seen.add(rel)
        data = packaged_bytes(path, rel, config)
        entries.append(Entry(rel=rel, path=path, checksum=crc32_hex(data), size=len(data)))

    if not any(entry.rel == "init.lua" for entry in entries):
        fail("init.lua nao foi encontrado no pacote")

    return entries


def write_manifest(entries: list[Entry], config: dict) -> dict:
    PATCHED_DIR.mkdir(parents=True, exist_ok=True)
    patched_init = packaged_bytes(ROOT / "init.lua", "init.lua", config)
    (PATCHED_DIR / "init.lua").write_bytes(patched_init)

    version = config.get("version") or parse_app_version()
    manifest = {
        "title": config["title"],
        "version": version,
        "date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "url": config.get("public_files_url") or "",
        "keepFiles": bool(config.get("keep_files", False)),
        "changelog": read_changelog(),
        "files": {entry.rel: entry.checksum for entry in entries},
    }

    DIST_DIR.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    return manifest


def copy_web_files(entries: list[Entry], config: dict) -> None:
    safe_rmtree(FILES_DIR)
    FILES_DIR.mkdir(parents=True, exist_ok=True)

    for entry in entries:
        target = FILES_DIR / Path(entry.rel)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(packaged_bytes(entry.path, entry.rel, config))


def copy_runtime_files(config: dict, overwrite_executables: bool = True) -> None:
    RELEASE_DIR.mkdir(parents=True, exist_ok=True)

    copied = 0
    for exe in config["executables"]:
        source = ROOT / exe
        target = RELEASE_DIR / exe
        if target.exists() and not overwrite_executables:
            copied += 1
            continue
        if source.exists():
            try:
                shutil.copy2(source, target)
                copied += 1
            except PermissionError:
                print(f"[aviso] nao consegui copiar {exe}; arquivo em uso, mantendo copia atual")

    if copied == 0:
        existing = [name for name in config["executables"] if (RELEASE_DIR / name).exists()]
        if not existing:
            fail("nenhum executavel otclient foi encontrado para copiar")

    if config.get("copy_dlls", True):
        for dll in ROOT.glob("*.dll"):
            shutil.copy2(dll, RELEASE_DIR / dll.name)


def write_data_zip(entries: list[Entry], config: dict) -> None:
    RELEASE_DIR.mkdir(parents=True, exist_ok=True)
    zip_path = RELEASE_DIR / "data.zip"
    level = int(config.get("compression_level", 1))

    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=level) as archive:
        for entry in entries:
            archive.writestr(entry.rel, packaged_bytes(entry.path, entry.rel, config))


def embedded_footer_info(data: bytes) -> tuple[int, int, int] | None:
    footer_size = len(EMBEDDED_DATA_MAGIC) + 8 + 4
    if len(data) <= footer_size:
        return None

    footer_start = len(data) - footer_size
    if data[footer_start : footer_start + len(EMBEDDED_DATA_MAGIC)] != EMBEDDED_DATA_MAGIC:
        return None

    packed_size, checksum = struct.unpack_from("<QI", data, footer_start + len(EMBEDDED_DATA_MAGIC))
    packed_start = footer_start - packed_size
    if packed_size <= 0 or packed_start < 0:
        return None

    return packed_start, footer_start, checksum


def has_embedded_package(path: Path) -> bool:
    if not path.exists() or not path.is_file():
        return False
    return embedded_footer_info(path.read_bytes()) is not None


def strip_embedded_package(data: bytes) -> bytes:
    info = embedded_footer_info(data)
    if not info:
        return data
    packed_start, _, _ = info
    return data[:packed_start]


def embed_data_zip(config: dict) -> int:
    zip_path = RELEASE_DIR / "data.zip"
    if not zip_path.exists():
        fail("data.zip nao existe para embutir no executavel")

    raw_zip = zip_path.read_bytes()
    seed = str(config.get("protection_seed", ""))
    payload = protect_buffer(raw_zip, seed) if config.get("protect_embedded_zip", True) else raw_zip
    checksum = zlib.crc32(payload) & UINT32_MASK
    footer = EMBEDDED_DATA_MAGIC + struct.pack("<QI", len(payload), checksum)

    embedded = 0
    for exe in config["executables"]:
        exe_path = RELEASE_DIR / exe
        if not exe_path.exists():
            continue
        base = strip_embedded_package(exe_path.read_bytes())
        exe_path.write_bytes(base + payload + footer)
        embedded += 1

    if embedded == 0:
        fail("nenhum executavel encontrado para embutir data.zip")

    if not config.get("keep_release_data_zip", False):
        zip_path.unlink(missing_ok=True)

    return embedded


def release_package_ready(config: dict) -> bool:
    launcher = RELEASE_DIR / config["launcher_executable"]
    data_zip = RELEASE_DIR / "data.zip"

    if config.get("embed_data_zip", True):
        if has_embedded_package(launcher):
            return True
        return data_zip.exists()

    return data_zip.exists()


def build_package(args: argparse.Namespace, config: dict) -> dict:
    entries = collect_entries(config)
    manifest = write_manifest(entries, config)
    rebuild_release = bool(getattr(args, "rebuild_release", False))
    if rebuild_release:
        safe_rmtree(RELEASE_DIR)
    package_ready = release_package_ready(config)
    copy_runtime_files(config, overwrite_executables=rebuild_release or not package_ready)

    data_zip = RELEASE_DIR / "data.zip"
    embedded_count = 0
    if rebuild_release or not package_ready:
        write_data_zip(entries, config)
        if config.get("embed_data_zip", True):
            embedded_count = embed_data_zip(config)
            zip_status = f"data.zip embutido em {embedded_count} exe(s)"
        else:
            zip_status = "data.zip recriado"
    else:
        zip_status = "pacote do release mantido"

    if getattr(args, "copy_files", False):
        copy_web_files(entries, config)

    total_size = sum(entry.size for entry in entries)
    print(f"[ok] manifest: {MANIFEST_PATH}")
    print(f"[ok] release: {RELEASE_DIR} ({zip_status})")
    print(f"[ok] arquivos no pacote: {len(entries)} ({total_size / 1024 / 1024:.1f} MB)")
    if config.get("protect_files", True):
        print("[ok] protecao: lua/otui/otmod sensiveis criptografados no pacote")
    print(f"[ok] updater api: {updater_api_url(config)}")
    return manifest


def load_manifest() -> dict:
    if not MANIFEST_PATH.exists():
        fail("manifest nao existe; rode o build primeiro")
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def make_handler(config: dict):
    class UpdaterHandler(BaseHTTPRequestHandler):
        server_version = "OTCv8Updater/1.0"

        def log_message(self, fmt: str, *args) -> None:
            print("[http] " + fmt % args)

        def send_json(self, payload: dict) -> None:
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self) -> None:
            path = urlparse(self.path).path
            if path != config["api_path"]:
                self.send_error(404, "Updater endpoint not found")
                return

            length = int(self.headers.get("Content-Length", "0") or "0")
            request_body = self.rfile.read(length) if length else b""
            if request_body:
                try:
                    request_json = json.loads(request_body.decode("utf-8"))
                    print(
                        "[updater] check "
                        f"version={request_json.get('version')} build={request_json.get('build')}"
                    )
                except Exception:
                    pass

            manifest = load_manifest()
            host = self.headers.get("Host", f"{config['host']}:{config['port']}")
            manifest["url"] = config.get("public_files_url") or f"http://{host}{config['files_path']}"
            self.send_json(manifest)

        def do_GET(self) -> None:
            request_path = urlparse(self.path).path

            if request_path == "/manifest.json":
                self.send_json(load_manifest())
                return

            if not request_path.startswith(config["files_path"]):
                self.send_error(404, "File endpoint not found")
                return

            rel = unquote(request_path[len(config["files_path"]):])
            rel = posixpath.normpath(rel).lstrip("/")
            if rel == "." or rel.startswith("../") or "/../" in rel:
                self.send_error(400, "Invalid path")
                return

            manifest = load_manifest()
            if rel not in manifest.get("files", {}):
                self.send_error(404, "File is not in manifest")
                return

            source = ROOT / Path(rel)
            if not source.exists() or not source.is_file():
                self.send_error(404, "Source file not found")
                return

            data = packaged_bytes(source, rel, config)
            content_type = mimetypes.guess_type(source.name)[0] or "application/octet-stream"
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

    return UpdaterHandler


def serve(config: dict) -> ThreadingHTTPServer:
    address = (config["host"], int(config["port"]))
    server = ThreadingHTTPServer(address, make_handler(config))
    print(f"[ok] servidor updater ligado em {updater_api_url(config)}")
    print("[info] deixe esta janela aberta enquanto o client atualiza")
    return server


def launch_client(config: dict) -> subprocess.Popen:
    preferred = RELEASE_DIR / config["launcher_executable"]
    exe = preferred if preferred.exists() else None
    if exe is None:
        for name in config["executables"]:
            candidate = RELEASE_DIR / name
            if candidate.exists():
                exe = candidate
                break
    if exe is None:
        fail("nenhum executavel encontrado em release_client")

    print(f"[ok] abrindo client: {exe}")
    return subprocess.Popen([str(exe)], cwd=str(RELEASE_DIR))


def command_build(args: argparse.Namespace) -> None:
    config = merge_config()
    build_package(args, config)


def command_serve(args: argparse.Namespace) -> None:
    config = merge_config()
    load_manifest()
    server = serve(config)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[ok] servidor finalizado")
    finally:
        server.server_close()


def command_run(args: argparse.Namespace) -> None:
    config = merge_config()
    build_package(args, config)
    server = serve(config)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()
    client = launch_client(config)

    try:
        while True:
            time.sleep(1)
            if client.poll() is not None:
                print("[info] client fechou; Ctrl+C encerra o servidor")
                client = launch_client(config) if getattr(args, "restart_when_closed", False) else client
                if not getattr(args, "restart_when_closed", False):
                    while True:
                        time.sleep(1)
    except KeyboardInterrupt:
        print("\n[ok] encerrando servidor updater")
    finally:
        server.server_close()


def main() -> None:
    parser = argparse.ArgumentParser(description="OTCv8 local auto updater toolkit")
    subparsers = parser.add_subparsers(dest="command", required=True)

    build_parser = subparsers.add_parser("build", help="gera manifest e release_client")
    build_parser.add_argument("--rebuild-release", action="store_true", help="recria release_client/data.zip")
    build_parser.add_argument("--copy-files", action="store_true", help="copia todos os arquivos para updater_dist/files")
    build_parser.set_defaults(func=command_build)

    serve_parser = subparsers.add_parser("serve", help="liga apenas o servidor local")
    serve_parser.set_defaults(func=command_serve)

    run_parser = subparsers.add_parser("run", help="gera manifest, liga servidor e abre o client")
    run_parser.add_argument("--rebuild-release", action="store_true", help="recria release_client/data.zip antes de abrir")
    run_parser.add_argument("--copy-files", action="store_true", help="copia todos os arquivos para updater_dist/files")
    run_parser.add_argument("--restart-when-closed", action="store_true", help="reabre o client quando ele fechar")
    run_parser.set_defaults(func=command_run)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
