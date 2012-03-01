
class _StyleMediaImpl extends _DOMTypeBase implements StyleMedia {
  _StyleMediaImpl._wrap(ptr) : super._wrap(ptr);

  String get type() => _wrap(_ptr.type);

  bool matchMedium(String mediaquery) {
    return _wrap(_ptr.matchMedium(_unwrap(mediaquery)));
  }
}
