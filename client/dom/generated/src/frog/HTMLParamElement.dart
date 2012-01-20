
class HTMLParamElement extends HTMLElement native "*HTMLParamElement" {

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  String get valueType() native "return this.valueType;";

  void set valueType(String value) native "this.valueType = value;";
}
