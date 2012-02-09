
class _HTMLFieldSetElementJs extends _HTMLElementJs implements HTMLFieldSetElement native "*HTMLFieldSetElement" {

  final _HTMLFormElementJs form;

  final String validationMessage;

  final _ValidityStateJs validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
