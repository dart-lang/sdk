
class _QuoteElementImpl extends _ElementImpl implements QuoteElement {
  _QuoteElementImpl._wrap(ptr) : super._wrap(ptr);

  String get cite() => _wrap(_ptr.cite);

  void set cite(String value) { _ptr.cite = _unwrap(value); }
}
