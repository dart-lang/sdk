
class HTMLMapElement extends HTMLElement native "*HTMLMapElement" {

  HTMLCollection get areas() native "return this.areas;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";
}
