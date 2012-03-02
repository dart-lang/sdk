
class _MediaStreamTrackImpl extends _DOMTypeBase implements MediaStreamTrack {
  _MediaStreamTrackImpl._wrap(ptr) : super._wrap(ptr);

  bool get enabled() => _wrap(_ptr.enabled);

  void set enabled(bool value) { _ptr.enabled = _unwrap(value); }

  String get kind() => _wrap(_ptr.kind);

  String get label() => _wrap(_ptr.label);
}
