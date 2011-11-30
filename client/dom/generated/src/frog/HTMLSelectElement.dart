
class HTMLSelectElement extends HTMLElement native "*HTMLSelectElement" {

  bool autofocus;

  bool disabled;

  HTMLFormElement form;

  NodeList labels;

  int length;

  bool multiple;

  String name;

  HTMLOptionsCollection options;

  bool required;

  int selectedIndex;

  int size;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  void add(HTMLElement element, HTMLElement before) native;

  bool checkValidity() native;

  Node item(int index) native;

  Node namedItem(String name) native;

  void remove(var index_OR_option) native;

  void setCustomValidity(String error) native;
}
