
class _SVGPatternElementJs extends _SVGElementJs implements SVGPatternElement native "*SVGPatternElement" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedEnumerationJs patternContentUnits;

  final _SVGAnimatedTransformListJs patternTransform;

  final _SVGAnimatedEnumerationJs patternUnits;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}
