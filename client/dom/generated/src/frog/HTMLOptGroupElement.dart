
class HTMLOptGroupElement extends HTMLElement native "*HTMLOptGroupElement" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get label() native "return this.label;";

  void set label(String value) native "this.label = value;";
}
