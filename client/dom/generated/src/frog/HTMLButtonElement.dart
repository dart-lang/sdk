
class _HTMLButtonElementJs extends _HTMLElementJs implements HTMLButtonElement native "*HTMLButtonElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

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

  _NodeListJs get labels() native "return this.labels;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  _ValidityStateJs get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void click() native;

  void setCustomValidity(String error) native;
}
