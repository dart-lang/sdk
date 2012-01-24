
class HTMLHtmlElementJS extends HTMLElementJS implements HTMLHtmlElement native "*HTMLHtmlElement" {

  String get manifest() native "return this.manifest;";

  void set manifest(String value) native "this.manifest = value;";

  String get version() native "return this.version;";

  void set version(String value) native "this.version = value;";
}
