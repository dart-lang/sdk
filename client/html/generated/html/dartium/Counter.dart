
class _CounterImpl extends _DOMTypeBase implements Counter {
  _CounterImpl._wrap(ptr) : super._wrap(ptr);

  String get identifier() => _wrap(_ptr.identifier);

  String get listStyle() => _wrap(_ptr.listStyle);

  String get separator() => _wrap(_ptr.separator);
}
