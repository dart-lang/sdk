
class HTMLTrackElement extends HTMLElement native "*HTMLTrackElement" {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool get isDefault() native "return this.isDefault;";

  void set isDefault(bool value) native "this.isDefault = value;";

  String get kind() native "return this.kind;";

  void set kind(String value) native "this.kind = value;";

  String get label() native "return this.label;";

  void set label(String value) native "this.label = value;";

  int get readyState() native "return this.readyState;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get srclang() native "return this.srclang;";

  void set srclang(String value) native "this.srclang = value;";

  TextTrack get track() native "return this.track;";
}
