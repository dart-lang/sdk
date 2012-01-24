
class HTMLObjectElementJS extends HTMLElementJS implements HTMLObjectElement native "*HTMLObjectElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get archive() native "return this.archive;";

  void set archive(String value) native "this.archive = value;";

  String get border() native "return this.border;";

  void set border(String value) native "this.border = value;";

  String get code() native "return this.code;";

  void set code(String value) native "this.code = value;";

  String get codeBase() native "return this.codeBase;";

  void set codeBase(String value) native "this.codeBase = value;";

  String get codeType() native "return this.codeType;";

  void set codeType(String value) native "this.codeType = value;";

  DocumentJS get contentDocument() native "return this.contentDocument;";

  String get data() native "return this.data;";

  void set data(String value) native "this.data = value;";

  bool get declare() native "return this.declare;";

  void set declare(bool value) native "this.declare = value;";

  HTMLFormElementJS get form() native "return this.form;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  int get hspace() native "return this.hspace;";

  void set hspace(int value) native "this.hspace = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get standby() native "return this.standby;";

  void set standby(String value) native "this.standby = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get useMap() native "return this.useMap;";

  void set useMap(String value) native "this.useMap = value;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJS get validity() native "return this.validity;";

  int get vspace() native "return this.vspace;";

  void set vspace(int value) native "this.vspace = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  SVGDocumentJS getSVGDocument() native;

  void setCustomValidity(String error) native;
}
