
class SVGTestsJS implements SVGTests native "*SVGTests" {

  SVGStringListJS get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringListJS get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringListJS get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
