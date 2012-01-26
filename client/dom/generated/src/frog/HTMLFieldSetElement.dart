
class HTMLFieldSetElementJs extends HTMLElementJs implements HTMLFieldSetElement native "*HTMLFieldSetElement" {

  HTMLFormElementJs get form() native "return this.form;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJs get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
