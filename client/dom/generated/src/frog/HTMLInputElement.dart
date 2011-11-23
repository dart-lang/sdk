
class HTMLInputElement extends HTMLElement native "*HTMLInputElement" {

  String accept;

  String accessKey;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  bool disabled;

  FileList files;

  HTMLFormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  NodeList labels;

  HTMLElement list;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  EventListener onwebkitspeechchange;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  HTMLOptionElement selectedOption;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  String validationMessage;

  ValidityState validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  bool willValidate;

  bool checkValidity() native;

  void click() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}
