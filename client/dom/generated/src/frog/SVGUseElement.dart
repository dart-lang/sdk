
class SVGUseElement extends SVGElement native "SVGUseElement" {

  SVGElementInstance animatedInstanceRoot;

  SVGAnimatedLength height;

  SVGElementInstance instanceRoot;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

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
