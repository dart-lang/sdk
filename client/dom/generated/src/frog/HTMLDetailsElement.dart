
class HTMLDetailsElementJs extends HTMLElementJs implements HTMLDetailsElement native "*HTMLDetailsElement" {

  bool get open() native "return this.open;";

  void set open(bool value) native "this.open = value;";
}
