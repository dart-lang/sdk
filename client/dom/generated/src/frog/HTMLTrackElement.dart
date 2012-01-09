
class HTMLTrackElement extends HTMLElement native "*HTMLTrackElement" {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool isDefault;

  String kind;

  String label;

  int readyState;

  String src;

  String srclang;

  TextTrack track;
}
