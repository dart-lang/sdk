
class SVGElementInstanceListJS implements SVGElementInstanceList native "*SVGElementInstanceList" {

  int get length() native "return this.length;";

  SVGElementInstanceJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
