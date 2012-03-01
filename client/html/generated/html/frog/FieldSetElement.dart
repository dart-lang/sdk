
class _FieldSetElementImpl extends _ElementImpl implements FieldSetElement native "*HTMLFieldSetElement" {

  final _FormElementImpl form;

  final String validationMessage;

  final _ValidityStateImpl validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
