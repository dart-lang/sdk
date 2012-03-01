
class _JavaScriptCallFrameImpl extends _DOMTypeBase implements JavaScriptCallFrame {
  _JavaScriptCallFrameImpl._wrap(ptr) : super._wrap(ptr);

  JavaScriptCallFrame get caller() => _wrap(_ptr.caller);

  int get column() => _wrap(_ptr.column);

  String get functionName() => _wrap(_ptr.functionName);

  int get line() => _wrap(_ptr.line);

  List get scopeChain() => _wrap(_ptr.scopeChain);

  int get sourceID() => _wrap(_ptr.sourceID);

  Object get thisObject() => _wrap(_ptr.thisObject);

  String get type() => _wrap(_ptr.type);

  void evaluate(String script) {
    _ptr.evaluate(_unwrap(script));
    return;
  }

  int scopeType(int scopeIndex) {
    return _wrap(_ptr.scopeType(_unwrap(scopeIndex)));
  }
}
