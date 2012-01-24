
class SVGScriptElementJs extends SVGElementJs implements SVGScriptElement native "*SVGScriptElement" {

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
