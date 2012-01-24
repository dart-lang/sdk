
class HTMLSelectElementJS extends HTMLElementJS implements HTMLSelectElement native "*HTMLSelectElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElementJS get form() native "return this.form;";

  NodeListJS get labels() native "return this.labels;";

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  bool get multiple() native "return this.multiple;";

  void set multiple(bool value) native "this.multiple = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  HTMLOptionsCollectionJS get options() native "return this.options;";

  bool get required() native "return this.required;";

  void set required(bool value) native "this.required = value;";

  int get selectedIndex() native "return this.selectedIndex;";

  void set selectedIndex(int value) native "this.selectedIndex = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityStateJS get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  void add(HTMLElementJS element, HTMLElementJS before) native;

  bool checkValidity() native;

  NodeJS item(int index) native;

  NodeJS namedItem(String name) native;

  void remove(var index_OR_option) native;

  void setCustomValidity(String error) native;
}
