
class HTMLButtonElement extends HTMLElement native "HTMLButtonElement" {

  String accessKey;

  bool autofocus;

  bool disabled;

  HTMLFormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  NodeList labels;

  String name;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  bool checkValidity() native;

  void click() native;

  void setCustomValidity(String error) native;
}
