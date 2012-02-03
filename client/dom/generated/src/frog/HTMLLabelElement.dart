
class _HTMLLabelElementJs extends _HTMLElementJs implements HTMLLabelElement native "*HTMLLabelElement" {

  _HTMLElementJs get control() native "return this.control;";

  _HTMLFormElementJs get form() native "return this.form;";

  String get htmlFor() native "return this.htmlFor;";

  void set htmlFor(String value) native "this.htmlFor = value;";
}
