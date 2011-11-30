
class HTMLKeygenElement extends HTMLElement native "*HTMLKeygenElement" {

  bool autofocus;

  String challenge;

  bool disabled;

  HTMLFormElement form;

  String keytype;

  NodeList labels;

  String name;

  String type;

  String validationMessage;

  ValidityState validity;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
