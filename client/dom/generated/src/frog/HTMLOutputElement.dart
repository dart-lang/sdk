
class _HTMLOutputElementJs extends _HTMLElementJs implements HTMLOutputElement native "*HTMLOutputElement" {

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  _HTMLFormElementJs get form() native "return this.form;";

  _DOMSettableTokenListJs get htmlFor() native "return this.htmlFor;";

  void set htmlFor(_DOMSettableTokenListJs value) native "this.htmlFor = value;";

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

  void setCustomValidity(String error) native;
}
