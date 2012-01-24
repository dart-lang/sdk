
class SVGAnimatedNumberJS implements SVGAnimatedNumber native "*SVGAnimatedNumber" {

  num get animVal() native "return this.animVal;";

  num get baseVal() native "return this.baseVal;";

  void set baseVal(num value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
