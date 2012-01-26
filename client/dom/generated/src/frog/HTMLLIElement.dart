
class HTMLLIElementJs extends HTMLElementJs implements HTMLLIElement native "*HTMLLIElement" {

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  int get value() native "return this.value;";

  void set value(int value) native "this.value = value;";
}
