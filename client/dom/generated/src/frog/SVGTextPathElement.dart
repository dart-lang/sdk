
class SVGTextPathElementJs extends SVGTextContentElementJs implements SVGTextPathElement native "*SVGTextPathElement" {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  SVGAnimatedEnumerationJs get method() native "return this.method;";

  SVGAnimatedEnumerationJs get spacing() native "return this.spacing;";

  SVGAnimatedLengthJs get startOffset() native "return this.startOffset;";

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";
}
