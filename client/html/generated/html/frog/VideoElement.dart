
class _VideoElementImpl extends _MediaElementImpl implements VideoElement native "*HTMLVideoElement" {

  int height;

  String poster;

  final int videoHeight;

  final int videoWidth;

  final int webkitDecodedFrameCount;

  final bool webkitDisplayingFullscreen;

  final int webkitDroppedFrameCount;

  final bool webkitSupportsFullscreen;

  int width;

  void webkitEnterFullScreen() native;

  void webkitEnterFullscreen() native;

  void webkitExitFullScreen() native;

  void webkitExitFullscreen() native;
}
