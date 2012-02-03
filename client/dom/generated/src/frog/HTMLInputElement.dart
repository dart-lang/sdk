
class _HTMLInputElementJs extends _HTMLElementJs implements HTMLInputElement native "*HTMLInputElement" {

  String get accept() native "return this.accept;";

  void set accept(String value) native "this.accept = value;";

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get alt() native "return this.alt;";

  void set alt(String value) native "this.alt = value;";

  String get autocomplete() native "return this.autocomplete;";

  void set autocomplete(String value) native "this.autocomplete = value;";

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  bool get checked() native "return this.checked;";

  void set checked(bool value) native "this.checked = value;";

  bool get defaultChecked() native "return this.defaultChecked;";

  void set defaultChecked(bool value) native "this.defaultChecked = value;";

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  String get dirName() native "return this.dirName;";

  void set dirName(String value) native "this.dirName = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  _FileListJs get files() native "return this.files;";

  _HTMLFormElementJs get form() native "return this.form;";

  String get formAction() native "return this.formAction;";

  void set formAction(String value) native "this.formAction = value;";

  String get formEnctype() native "return this.formEnctype;";

  void set formEnctype(String value) native "this.formEnctype = value;";

  String get formMethod() native "return this.formMethod;";

  void set formMethod(String value) native "this.formMethod = value;";

  bool get formNoValidate() native "return this.formNoValidate;";

  void set formNoValidate(bool value) native "this.formNoValidate = value;";

  String get formTarget() native "return this.formTarget;";

  void set formTarget(String value) native "this.formTarget = value;";

  bool get incremental() native "return this.incremental;";

  void set incremental(bool value) native "this.incremental = value;";

  bool get indeterminate() native "return this.indeterminate;";

  void set indeterminate(bool value) native "this.indeterminate = value;";

  _NodeListJs get labels() native "return this.labels;";

  _HTMLElementJs get list() native "return this.list;";

  String get max() native "return this.max;";

  void set max(String value) native "this.max = value;";

  int get maxLength() native "return this.maxLength;";

  void set maxLength(int value) native "this.maxLength = value;";

  String get min() native "return this.min;";

  void set min(String value) native "this.min = value;";

  bool get multiple() native "return this.multiple;";

  void set multiple(bool value) native "this.multiple = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get pattern() native "return this.pattern;";

  void set pattern(String value) native "this.pattern = value;";

  String get placeholder() native "return this.placeholder;";

  void set placeholder(String value) native "this.placeholder = value;";

  bool get readOnly() native "return this.readOnly;";

  void set readOnly(bool value) native "this.readOnly = value;";

  bool get required() native "return this.required;";

  void set required(bool value) native "this.required = value;";

  _HTMLOptionElementJs get selectedOption() native "return this.selectedOption;";

  String get selectionDirection() native "return this.selectionDirection;";

  void set selectionDirection(String value) native "this.selectionDirection = value;";

  int get selectionEnd() native "return this.selectionEnd;";

  void set selectionEnd(int value) native "this.selectionEnd = value;";

  int get selectionStart() native "return this.selectionStart;";

  void set selectionStart(int value) native "this.selectionStart = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get step() native "return this.step;";

  void set step(String value) native "this.step = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get useMap() native "return this.useMap;";

  void set useMap(String value) native "this.useMap = value;";

  String get validationMessage() native "return this.validationMessage;";

  _ValidityStateJs get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  Date get valueAsDate() native "return this.valueAsDate;";

  void set valueAsDate(Date value) native "this.valueAsDate = value;";

  num get valueAsNumber() native "return this.valueAsNumber;";

  void set valueAsNumber(num value) native "this.valueAsNumber = value;";

  bool get webkitGrammar() native "return this.webkitGrammar;";

  void set webkitGrammar(bool value) native "this.webkitGrammar = value;";

  bool get webkitSpeech() native "return this.webkitSpeech;";

  void set webkitSpeech(bool value) native "this.webkitSpeech = value;";

  bool get webkitdirectory() native "return this.webkitdirectory;";

  void set webkitdirectory(bool value) native "this.webkitdirectory = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void click() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}
