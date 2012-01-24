
class HTMLLinkElementJS extends HTMLElementJS implements HTMLLinkElement native "*HTMLLinkElement" {

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get hreflang() native "return this.hreflang;";

  void set hreflang(String value) native "this.hreflang = value;";

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  String get rel() native "return this.rel;";

  void set rel(String value) native "this.rel = value;";

  String get rev() native "return this.rev;";

  void set rev(String value) native "this.rev = value;";

  StyleSheetJS get sheet() native "return this.sheet;";

  DOMSettableTokenListJS get sizes() native "return this.sizes;";

  void set sizes(DOMSettableTokenListJS value) native "this.sizes = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}
