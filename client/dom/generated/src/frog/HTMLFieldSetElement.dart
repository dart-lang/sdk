
class HTMLFieldSetElementJS extends HTMLElementJS implements HTMLFieldSetElement native "*HTMLFieldSetElement" {

  HTMLFormElementJS get form() native "return this.form;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJS get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
