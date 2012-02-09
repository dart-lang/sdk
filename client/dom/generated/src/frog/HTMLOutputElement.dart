
class _HTMLOutputElementJs extends _HTMLElementJs implements HTMLOutputElement native "*HTMLOutputElement" {

  String defaultValue;

  final _HTMLFormElementJs form;

  _DOMSettableTokenListJs htmlFor;

  final _NodeListJs labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
