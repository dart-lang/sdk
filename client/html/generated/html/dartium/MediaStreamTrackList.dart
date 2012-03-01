
class _MediaStreamTrackListImpl extends _DOMTypeBase implements MediaStreamTrackList {
  _MediaStreamTrackListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  MediaStreamTrack item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
