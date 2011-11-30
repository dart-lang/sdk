
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

  static final int WEBKIT_REGION_STYLE_RULE = 10;

  String cssText;

  CSSRule parentRule;

  CSSStyleSheet parentStyleSheet;

  int type;

  var dartObjectLocalStorage;

  String get typeName() native;
}
