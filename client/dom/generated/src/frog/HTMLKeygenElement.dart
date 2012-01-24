
class HTMLKeygenElementJS extends HTMLElementJS implements HTMLKeygenElement native "*HTMLKeygenElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  String get challenge() native "return this.challenge;";

  void set challenge(String value) native "this.challenge = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElementJS get form() native "return this.form;";

  String get keytype() native "return this.keytype;";

  void set keytype(String value) native "this.keytype = value;";

  NodeListJS get labels() native "return this.labels;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJS get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
