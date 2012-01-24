
class SVGAnimatedBooleanJS implements SVGAnimatedBoolean native "*SVGAnimatedBoolean" {

  bool get animVal() native "return this.animVal;";

  bool get baseVal() native "return this.baseVal;";

  void set baseVal(bool value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
