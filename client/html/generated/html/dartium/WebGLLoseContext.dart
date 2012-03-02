
class _WebGLLoseContextImpl extends _DOMTypeBase implements WebGLLoseContext {
  _WebGLLoseContextImpl._wrap(ptr) : super._wrap(ptr);

  void loseContext() {
    _ptr.loseContext();
    return;
  }

  void restoreContext() {
    _ptr.restoreContext();
    return;
  }
}
