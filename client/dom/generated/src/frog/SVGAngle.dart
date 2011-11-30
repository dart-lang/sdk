
class SVGAngle native "*SVGAngle" {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
