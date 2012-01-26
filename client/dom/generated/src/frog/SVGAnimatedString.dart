
class SVGAnimatedStringJs extends DOMTypeJs implements SVGAnimatedString native "*SVGAnimatedString" {

  String get animVal() native "return this.animVal;";

  String get baseVal() native "return this.baseVal;";

  void set baseVal(String value) native "this.baseVal = value;";
}
