
class _VideoElementImpl extends _MediaElementImpl implements VideoElement {
  _VideoElementImpl._wrap(ptr) : super._wrap(ptr);

  int get height() => _wrap(_ptr.height);

  void set height(int value) { _ptr.height = _unwrap(value); }

  String get poster() => _wrap(_ptr.poster);

  void set poster(String value) { _ptr.poster = _unwrap(value); }

  int get videoHeight() => _wrap(_ptr.videoHeight);

  int get videoWidth() => _wrap(_ptr.videoWidth);

  int get webkitDecodedFrameCount() => _wrap(_ptr.webkitDecodedFrameCount);

  bool get webkitDisplayingFullscreen() => _wrap(_ptr.webkitDisplayingFullscreen);

  int get webkitDroppedFrameCount() => _wrap(_ptr.webkitDroppedFrameCount);

  bool get webkitSupportsFullscreen() => _wrap(_ptr.webkitSupportsFullscreen);

  int get width() => _wrap(_ptr.width);

  void set width(int value) { _ptr.width = _unwrap(value); }

  void webkitEnterFullScreen() {
    _ptr.webkitEnterFullScreen();
    return;
  }

  void webkitEnterFullscreen() {
    _ptr.webkitEnterFullscreen();
    return;
  }

  void webkitExitFullScreen() {
    _ptr.webkitExitFullScreen();
    return;
  }

  void webkitExitFullscreen() {
    _ptr.webkitExitFullscreen();
    return;
  }
}
