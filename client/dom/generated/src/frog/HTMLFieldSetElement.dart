
class HTMLFieldSetElement extends HTMLElement native "*HTMLFieldSetElement" {

  HTMLFormElement form;

  String validationMessage;

  ValidityState validity;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
