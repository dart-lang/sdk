
class SVGAngleJS implements SVGAngle native "*SVGAngle" {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  int get unitType() native "return this.unitType;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";

  String get valueAsString() native "return this.valueAsString;";

  void set valueAsString(String value) native "this.valueAsString = value;";

  num get valueInSpecifiedUnits() native "return this.valueInSpecifiedUnits;";

  void set valueInSpecifiedUnits(num value) native "this.valueInSpecifiedUnits = value;";

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
