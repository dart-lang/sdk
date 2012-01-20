
class CSSImportRule extends CSSRule native "*CSSImportRule" {

  String get href() native "return this.href;";

  MediaList get media() native "return this.media;";

  CSSStyleSheet get styleSheet() native "return this.styleSheet;";
}
