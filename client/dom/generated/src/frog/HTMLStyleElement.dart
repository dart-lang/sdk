
class _HTMLStyleElementJs extends _HTMLElementJs implements HTMLStyleElement native "*HTMLStyleElement" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  bool get scoped() native "return this.scoped;";

  void set scoped(bool value) native "this.scoped = value;";

  _StyleSheetJs get sheet() native "return this.sheet;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}
