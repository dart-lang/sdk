
class HTMLSourceElement extends HTMLElement native "*HTMLSourceElement" {

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}
