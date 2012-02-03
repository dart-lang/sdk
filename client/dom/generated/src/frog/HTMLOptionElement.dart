
class _HTMLOptionElementJs extends _HTMLElementJs implements HTMLOptionElement native "*HTMLOptionElement" {

  bool get defaultSelected() native "return this.defaultSelected;";

  void set defaultSelected(bool value) native "this.defaultSelected = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  _HTMLFormElementJs get form() native "return this.form;";

  int get index() native "return this.index;";

  String get label() native "return this.label;";

  void set label(String value) native "this.label = value;";

  bool get selected() native "return this.selected;";

  void set selected(bool value) native "this.selected = value;";

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";
}
