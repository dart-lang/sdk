
class SVGAnimatedInteger native "*SVGAnimatedInteger" {

  int get animVal() native "return this.animVal;";

  int get baseVal() native "return this.baseVal;";

  void set baseVal(int value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
