
class _DOMFileSystemJs extends _DOMTypeJs implements DOMFileSystem native "*DOMFileSystem" {

  String get name() native "return this.name;";

  _DirectoryEntryJs get root() native "return this.root;";
}
