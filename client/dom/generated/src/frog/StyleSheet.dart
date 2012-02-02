
class _StyleSheetJs extends _DOMTypeJs implements StyleSheet native "*StyleSheet" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get href() native "return this.href;";

  _MediaListJs get media() native "return this.media;";

  _NodeJs get ownerNode() native "return this.ownerNode;";

  _StyleSheetJs get parentStyleSheet() native "return this.parentStyleSheet;";

  String get title() native "return this.title;";

  String get type() native "return this.type;";
}
