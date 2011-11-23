
class HTMLTextAreaElement extends HTMLElement native "*HTMLTextAreaElement" {

  String accessKey;

  bool autofocus;

  int cols;

  String defaultValue;

  bool disabled;

  HTMLFormElement form;

  NodeList labels;

  int maxLength;

  String name;

  String placeholder;

  bool readOnly;

  bool required;

  int rows;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int textLength;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  String wrap;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}
