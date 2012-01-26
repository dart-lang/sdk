
class WebGLLoseContextJs extends DOMTypeJs implements WebGLLoseContext native "*WebGLLoseContext" {

  void loseContext() native;

  void restoreContext() native;
}
