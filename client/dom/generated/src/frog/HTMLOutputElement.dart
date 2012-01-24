
class HTMLOutputElementJS extends HTMLElementJS implements HTMLOutputElement native "*HTMLOutputElement" {

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  HTMLFormElementJS get form() native "return this.form;";

  DOMSettableTokenListJS get htmlFor() native "return this.htmlFor;";

  void set htmlFor(DOMSettableTokenListJS value) native "this.htmlFor = value;";

  NodeListJS get labels() native "return this.labels;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJS get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
