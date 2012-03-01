
class _TrackElementImpl extends _ElementImpl implements TrackElement {
  _TrackElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get isDefault() => _wrap(_ptr.isDefault);

  void set isDefault(bool value) { _ptr.isDefault = _unwrap(value); }

  String get kind() => _wrap(_ptr.kind);

  void set kind(String value) { _ptr.kind = _unwrap(value); }

  String get label() => _wrap(_ptr.label);

  void set label(String value) { _ptr.label = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  String get srclang() => _wrap(_ptr.srclang);

  void set srclang(String value) { _ptr.srclang = _unwrap(value); }

  TextTrack get track() => _wrap(_ptr.track);
}
