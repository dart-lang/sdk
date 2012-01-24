
class SVGMPathElementJS extends SVGElementJS implements SVGMPathElement native "*SVGMPathElement" {

  // From SVGURIReference

  SVGAnimatedStringJS get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
