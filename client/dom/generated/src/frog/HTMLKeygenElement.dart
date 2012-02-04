
class _HTMLKeygenElementJs extends _HTMLElementJs implements HTMLKeygenElement native "*HTMLKeygenElement" {

  bool autofocus;

  String challenge;

  bool disabled;

  final _HTMLFormElementJs form;

  String keytype;

  final _NodeListJs labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
