
class _ScriptProfileImpl extends _DOMTypeBase implements ScriptProfile {
  _ScriptProfileImpl._wrap(ptr) : super._wrap(ptr);

  ScriptProfileNode get head() => _wrap(_ptr.head);

  String get title() => _wrap(_ptr.title);

  int get uid() => _wrap(_ptr.uid);
}
