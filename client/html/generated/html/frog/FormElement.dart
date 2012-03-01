
class _FormElementImpl extends _ElementImpl implements FormElement native "*HTMLFormElement" {

  String acceptCharset;

  String action;

  String autocomplete;

  String encoding;

  String enctype;

  final int length;

  String method;

  String name;

  bool noValidate;

  String target;

  bool checkValidity() native;

  void reset() native;

  void submit() native;
}
