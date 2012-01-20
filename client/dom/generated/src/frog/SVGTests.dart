
class SVGTests native "*SVGTests" {

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
