
class SVGElementInstanceList native "*SVGElementInstanceList" {

  int get length() native "return this.length;";

  SVGElementInstance item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
