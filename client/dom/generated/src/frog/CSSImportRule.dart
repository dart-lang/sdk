
class _CSSImportRuleJs extends _CSSRuleJs implements CSSImportRule native "*CSSImportRule" {

  String get href() native "return this.href;";

  _MediaListJs get media() native "return this.media;";

  _CSSStyleSheetJs get styleSheet() native "return this.styleSheet;";
}
