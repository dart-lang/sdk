
class DOMFileSystem native "*DOMFileSystem" {

  String get name() native "return this.name;";

  DirectoryEntry get root() native "return this.root;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
