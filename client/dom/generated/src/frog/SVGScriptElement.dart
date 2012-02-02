
class _SVGScriptElementJs extends _SVGElementJs implements SVGScriptElement native "*SVGScriptElement" {

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  // From SVGURIReference

  _SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
