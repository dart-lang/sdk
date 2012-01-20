
class HTMLUListElement extends HTMLElement native "*HTMLUListElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}
