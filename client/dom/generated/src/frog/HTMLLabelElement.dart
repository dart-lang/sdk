
class HTMLLabelElement extends HTMLElement native "*HTMLLabelElement" {

  HTMLElement get control() native "return this.control;";

  HTMLFormElement get form() native "return this.form;";

  String get htmlFor() native "return this.htmlFor;";

  void set htmlFor(String value) native "this.htmlFor = value;";
}
