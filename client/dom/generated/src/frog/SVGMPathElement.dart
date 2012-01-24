
class SVGMPathElementJs extends SVGElementJs implements SVGMPathElement native "*SVGMPathElement" {

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
