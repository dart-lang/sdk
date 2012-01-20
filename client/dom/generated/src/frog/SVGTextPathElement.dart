
class SVGTextPathElement extends SVGTextContentElement native "*SVGTextPathElement" {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  SVGAnimatedEnumeration get method() native "return this.method;";

  SVGAnimatedEnumeration get spacing() native "return this.spacing;";

  SVGAnimatedLength get startOffset() native "return this.startOffset;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";
}
