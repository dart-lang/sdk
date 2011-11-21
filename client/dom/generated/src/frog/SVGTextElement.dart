
class SVGTextElement extends SVGTextPositioningElement native "SVGTextElement" {

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}
