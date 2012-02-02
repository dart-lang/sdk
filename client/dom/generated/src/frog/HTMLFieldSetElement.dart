
class _HTMLFieldSetElementJs extends _HTMLElementJs implements HTMLFieldSetElement native "*HTMLFieldSetElement" {

  _HTMLFormElementJs get form() native "return this.form;";

  String get validationMessage() native "return this.validationMessage;";

  _ValidityStateJs get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
