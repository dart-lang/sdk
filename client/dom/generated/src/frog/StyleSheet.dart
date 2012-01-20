
class StyleSheet native "*StyleSheet" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get href() native "return this.href;";

  MediaList get media() native "return this.media;";

  Node get ownerNode() native "return this.ownerNode;";

  StyleSheet get parentStyleSheet() native "return this.parentStyleSheet;";

  String get title() native "return this.title;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
