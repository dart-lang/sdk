
class HTMLVideoElementJS extends HTMLMediaElementJS implements HTMLVideoElement native "*HTMLVideoElement" {

  int get height() native "return this.height;";

  void set height(int value) native "this.height = value;";

  String get poster() native "return this.poster;";

  void set poster(String value) native "this.poster = value;";

  int get videoHeight() native "return this.videoHeight;";

  int get videoWidth() native "return this.videoWidth;";

  int get webkitDecodedFrameCount() native "return this.webkitDecodedFrameCount;";

  bool get webkitDisplayingFullscreen() native "return this.webkitDisplayingFullscreen;";

  int get webkitDroppedFrameCount() native "return this.webkitDroppedFrameCount;";

  bool get webkitSupportsFullscreen() native "return this.webkitSupportsFullscreen;";

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  void webkitEnterFullScreen() native;

  void webkitEnterFullscreen() native;

  void webkitExitFullScreen() native;

  void webkitExitFullscreen() native;
}
