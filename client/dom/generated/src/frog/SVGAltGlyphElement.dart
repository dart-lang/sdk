
class SVGAltGlyphElementJS extends SVGTextPositioningElementJS implements SVGAltGlyphElement native "*SVGAltGlyphElement" {

  String get format() native "return this.format;";

  void set format(String value) native "this.format = value;";

  String get glyphRef() native "return this.glyphRef;";

  void set glyphRef(String value) native "this.glyphRef = value;";

  // From SVGURIReference

  SVGAnimatedStringJS get href() native "return this.href;";
}
