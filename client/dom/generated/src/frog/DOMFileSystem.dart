
class DOMFileSystemJs extends DOMTypeJs implements DOMFileSystem native "*DOMFileSystem" {

  String get name() native "return this.name;";

  DirectoryEntryJs get root() native "return this.root;";
}
