
class _TextAreaElementImpl extends _ElementImpl implements TextAreaElement native "*HTMLTextAreaElement" {

  bool autofocus;

  int cols;

  String defaultValue;

  bool disabled;

  final _FormElementImpl form;

  final _NodeListImpl labels;

  int maxLength;

  String name;

  String placeholder;

  bool readOnly;

  bool required;

  int rows;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  final int textLength;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  String wrap;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}
