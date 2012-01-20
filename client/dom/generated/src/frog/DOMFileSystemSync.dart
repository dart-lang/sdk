
class DOMFileSystemSync native "*DOMFileSystemSync" {

  String get name() native "return this.name;";

  DirectoryEntrySync get root() native "return this.root;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
