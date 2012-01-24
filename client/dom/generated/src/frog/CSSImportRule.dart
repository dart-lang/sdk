
class CSSImportRuleJs extends CSSRuleJs implements CSSImportRule native "*CSSImportRule" {

  String get href() native "return this.href;";

  MediaListJs get media() native "return this.media;";

  CSSStyleSheetJs get styleSheet() native "return this.styleSheet;";
}
