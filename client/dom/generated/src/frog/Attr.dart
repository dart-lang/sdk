
class Attr extends Node native "*Attr" {

  bool get isId() native "return this.isId;";

  String get name() native "return this.name;";

  Element get ownerElement() native "return this.ownerElement;";

  bool get specified() native "return this.specified;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";
}
