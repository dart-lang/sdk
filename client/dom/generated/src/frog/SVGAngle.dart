
class SVGAngle native "SVGAngle" {

  int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
