#ifndef RMLUIRENDERER_H
#define RMLUIRENDERER_H

#include <RmlUi/Core/RenderInterface.h>
#include <RmlUi/Core/Types.h>
#include <framework/graphics/declarations.h>
#include <framework/graphics/texture.h>
#include <framework/graphics/framebuffer.h>
#include <memory>
#include <vector>
#include <unordered_map>
#include <string>

class RmlUiRenderInterface : public Rml::RenderInterface {
public:
    RmlUiRenderInterface();
    ~RmlUiRenderInterface();

    Rml::CompiledGeometryHandle CompileGeometry(Rml::Span<const Rml::Vertex> vertices,
        Rml::Span<const int> indices) override;

    void RenderGeometry(Rml::CompiledGeometryHandle geometry, Rml::Vector2f translation,
        Rml::TextureHandle texture) override;

    void ReleaseGeometry(Rml::CompiledGeometryHandle geometry) override;

    void EnableScissorRegion(bool enable) override;
    void SetScissorRegion(Rml::Rectanglei region) override;

    Rml::TextureHandle LoadTexture(Rml::Vector2i& texture_dimensions,
        const Rml::String& source) override;
    Rml::TextureHandle GenerateTexture(Rml::Span<const Rml::byte> source,
        Rml::Vector2i source_dimensions) override;
    void ReleaseTexture(Rml::TextureHandle texture) override;

    void SetTransform(const Rml::Matrix4f* transform) override;

    Rml::LayerHandle PushLayer() override;
    void CompositeLayers(Rml::LayerHandle source, Rml::LayerHandle destination,
        Rml::BlendMode blend_mode, Rml::Span<const Rml::CompiledFilterHandle> filters) override;
    void PopLayer() override;

    Rml::CompiledFilterHandle CompileFilter(const Rml::String& name,
        const Rml::Dictionary& parameters) override;
    void ReleaseFilter(Rml::CompiledFilterHandle filter) override;

private:
    struct CompiledGeometry {
        std::vector<float> vertices;
        std::vector<int> indices;
    };
    struct LayerEntry {
        FrameBufferPtr framebuffer;
        Rml::TextureHandle textureHandle;
    };
    struct FilterEntry {
        Rml::String name;
        Rml::Dictionary parameters;
    };

    std::vector<CompiledGeometry*> m_geometries;
    std::vector<LayerEntry> m_layers;
    std::vector<FilterEntry> m_filters;
    bool m_scissorEnabled = false;
    Rml::Rectanglei m_scissorRegion;
    std::unordered_map<Rml::TextureHandle, TexturePtr> m_textureCache;
};

#endif
