
class SVGTextElement extends SVGTextPositioningElement native "*SVGTextElement" {

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}
