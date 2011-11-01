
class HTMLObjectElement extends HTMLElement native "HTMLObjectElement" {

  String align;

  String archive;

  String border;

  String code;

  String codeBase;

  String codeType;

  Document contentDocument;

  String data;

  bool declare;

  HTMLFormElement form;

  String height;

  int hspace;

  String name;

  String standby;

  String type;

  String useMap;

  String validationMessage;

  ValidityState validity;

  int vspace;

  String width;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
