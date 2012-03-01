
class _TextTrackCueListImpl extends _DOMTypeBase implements TextTrackCueList {
  _TextTrackCueListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  TextTrackCue getCueById(String id) {
    return _wrap(_ptr.getCueById(_unwrap(id)));
  }

  TextTrackCue item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
