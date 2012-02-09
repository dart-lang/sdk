
class _HTMLButtonElementJs extends _HTMLElementJs implements HTMLButtonElement native "*HTMLButtonElement" {

  bool autofocus;

  bool disabled;

  final _HTMLFormElementJs form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  final _NodeListJs labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void click() native;

  void setCustomValidity(String error) native;
}
