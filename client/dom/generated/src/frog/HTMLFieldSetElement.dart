
class HTMLFieldSetElement extends HTMLElement native "*HTMLFieldSetElement" {

  HTMLFormElement get form() native "return this.form;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
