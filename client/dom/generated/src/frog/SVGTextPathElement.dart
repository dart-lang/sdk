
class SVGTextPathElementJS extends SVGTextContentElementJS implements SVGTextPathElement native "*SVGTextPathElement" {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  SVGAnimatedEnumerationJS get method() native "return this.method;";

  SVGAnimatedEnumerationJS get spacing() native "return this.spacing;";

  SVGAnimatedLengthJS get startOffset() native "return this.startOffset;";

  // From SVGURIReference

  SVGAnimatedStringJS get href() native "return this.href;";
}
