
class _ScriptProfileNodeImpl extends _DOMTypeBase implements ScriptProfileNode {
  _ScriptProfileNodeImpl._wrap(ptr) : super._wrap(ptr);

  int get callUID() => _wrap(_ptr.callUID);

  List get children() => _wrap(_ptr.children);

  String get functionName() => _wrap(_ptr.functionName);

  int get lineNumber() => _wrap(_ptr.lineNumber);

  int get numberOfCalls() => _wrap(_ptr.numberOfCalls);

  num get selfTime() => _wrap(_ptr.selfTime);

  num get totalTime() => _wrap(_ptr.totalTime);

  String get url() => _wrap(_ptr.url);

  bool get visible() => _wrap(_ptr.visible);
}
