
class HTMLFormElement extends HTMLElement native "*HTMLFormElement" {

  String acceptCharset;

  String action;

  String autocomplete;

  HTMLCollection elements;

  String encoding;

  String enctype;

  int length;

  String method;

  String name;

  bool noValidate;

  String target;

  bool checkValidity() native;

  void reset() native;

  void submit() native;
}
