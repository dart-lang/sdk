
class CSSRule native "*CSSRule" {

  static final int CHARSET_RULE = 2;

  static final int FONT_FACE_RULE = 5;

  static final int IMPORT_RULE = 3;

  static final int MEDIA_RULE = 4;

  static final int PAGE_RULE = 6;

  static final int STYLE_RULE = 1;

  static final int UNKNOWN_RULE = 0;

  static final int WEBKIT_KEYFRAMES_RULE = 8;

  static final int WEBKIT_KEYFRAME_RULE = 9;

  static final int WEBKIT_REGION_RULE = 10;

  String get cssText() native "return this.cssText;";

  void set cssText(String value) native "this.cssText = value;";

  CSSRule get parentRule() native "return this.parentRule;";

  CSSStyleSheet get parentStyleSheet() native "return this.parentStyleSheet;";

  int get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
