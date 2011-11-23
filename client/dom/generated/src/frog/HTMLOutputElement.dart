
class HTMLOutputElement extends HTMLElement native "*HTMLOutputElement" {

  String defaultValue;

  HTMLFormElement form;

  DOMSettableTokenList htmlFor;

  NodeList labels;

  String name;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
