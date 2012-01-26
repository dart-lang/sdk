
class HTMLTextAreaElementJs extends HTMLElementJs implements HTMLTextAreaElement native "*HTMLTextAreaElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  int get cols() native "return this.cols;";

  void set cols(int value) native "this.cols = value;";

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  String get dirName() native "return this.dirName;";

  void set dirName(String value) native "this.dirName = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElementJs get form() native "return this.form;";

  NodeListJs get labels() native "return this.labels;";

  int get maxLength() native "return this.maxLength;";

  void set maxLength(int value) native "this.maxLength = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get placeholder() native "return this.placeholder;";

  void set placeholder(String value) native "this.placeholder = value;";

  bool get readOnly() native "return this.readOnly;";

  void set readOnly(bool value) native "this.readOnly = value;";

  bool get required() native "return this.required;";

  void set required(bool value) native "this.required = value;";

  int get rows() native "return this.rows;";

  void set rows(int value) native "this.rows = value;";

  String get selectionDirection() native "return this.selectionDirection;";

  void set selectionDirection(String value) native "this.selectionDirection = value;";

  int get selectionEnd() native "return this.selectionEnd;";

  void set selectionEnd(int value) native "this.selectionEnd = value;";

  int get selectionStart() native "return this.selectionStart;";

  void set selectionStart(int value) native "this.selectionStart = value;";

  int get textLength() native "return this.textLength;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJs get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  String get wrap() native "return this.wrap;";

  void set wrap(String value) native "this.wrap = value;";

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}
