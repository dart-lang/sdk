
class WebGLActiveInfoJS implements WebGLActiveInfo native "*WebGLActiveInfo" {

  String get name() native "return this.name;";

  int get size() native "return this.size;";

  int get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
