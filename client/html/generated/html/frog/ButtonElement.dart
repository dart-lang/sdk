
class _ButtonElementImpl extends _ElementImpl implements ButtonElement native "*HTMLButtonElement" {

  bool autofocus;

  bool disabled;

  final _FormElementImpl form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  final _NodeListImpl labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
