
class DOMFileSystemJS implements DOMFileSystem native "*DOMFileSystem" {

  String get name() native "return this.name;";

  DirectoryEntryJS get root() native "return this.root;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
