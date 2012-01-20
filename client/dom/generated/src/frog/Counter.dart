
class Counter native "*Counter" {

  String get identifier() native "return this.identifier;";

  String get listStyle() native "return this.listStyle;";

  String get separator() native "return this.separator;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
