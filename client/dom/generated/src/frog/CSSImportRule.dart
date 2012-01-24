
class CSSImportRuleJS extends CSSRuleJS implements CSSImportRule native "*CSSImportRule" {

  String get href() native "return this.href;";

  MediaListJS get media() native "return this.media;";

  CSSStyleSheetJS get styleSheet() native "return this.styleSheet;";
}
