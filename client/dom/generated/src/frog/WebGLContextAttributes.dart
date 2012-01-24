
class WebGLContextAttributesJs extends DOMTypeJs implements WebGLContextAttributes native "*WebGLContextAttributes" {

  bool get alpha() native "return this.alpha;";

  void set alpha(bool value) native "this.alpha = value;";

  bool get antialias() native "return this.antialias;";

  void set antialias(bool value) native "this.antialias = value;";

  bool get depth() native "return this.depth;";

  void set depth(bool value) native "this.depth = value;";

  bool get premultipliedAlpha() native "return this.premultipliedAlpha;";

  void set premultipliedAlpha(bool value) native "this.premultipliedAlpha = value;";

  bool get preserveDrawingBuffer() native "return this.preserveDrawingBuffer;";

  void set preserveDrawingBuffer(bool value) native "this.preserveDrawingBuffer = value;";

  bool get stencil() native "return this.stencil;";

  void set stencil(bool value) native "this.stencil = value;";
}
