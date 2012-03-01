
class _OutputElementImpl extends _ElementImpl implements OutputElement native "*HTMLOutputElement" {

  String defaultValue;

  final _FormElementImpl form;

  _DOMSettableTokenListImpl htmlFor;

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
