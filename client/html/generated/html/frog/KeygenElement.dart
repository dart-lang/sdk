
class _KeygenElementImpl extends _ElementImpl implements KeygenElement native "*HTMLKeygenElement" {

  bool autofocus;

  String challenge;

  bool disabled;

  final _FormElementImpl form;

  String keytype;

  final _NodeListImpl labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
