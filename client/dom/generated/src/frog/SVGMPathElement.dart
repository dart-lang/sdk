
class SVGMPathElement extends SVGElement native "*SVGMPathElement" {

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
