
class DOMFileSystemSyncJS implements DOMFileSystemSync native "*DOMFileSystemSync" {

  String get name() native "return this.name;";

  DirectoryEntrySyncJS get root() native "return this.root;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
