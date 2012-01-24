
class HTMLFormElementJs extends HTMLElementJs implements HTMLFormElement native "*HTMLFormElement" {

  String get acceptCharset() native "return this.acceptCharset;";

  void set acceptCharset(String value) native "this.acceptCharset = value;";

  String get action() native "return this.action;";

  void set action(String value) native "this.action = value;";

  String get autocomplete() native "return this.autocomplete;";

  void set autocomplete(String value) native "this.autocomplete = value;";

  HTMLCollectionJs get elements() native "return this.elements;";

  String get encoding() native "return this.encoding;";

  void set encoding(String value) native "this.encoding = value;";

  String get enctype() native "return this.enctype;";

  void set enctype(String value) native "this.enctype = value;";

  int get length() native "return this.length;";

  String get method() native "return this.method;";

  void set method(String value) native "this.method = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  bool get noValidate() native "return this.noValidate;";

  void set noValidate(bool value) native "this.noValidate = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";

  bool checkValidity() native;

  void reset() native;

  void submit() native;
}
