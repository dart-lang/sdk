
class _DOMFileSystemSyncJs extends _DOMTypeJs implements DOMFileSystemSync native "*DOMFileSystemSync" {

  String get name() native "return this.name;";

  _DirectoryEntrySyncJs get root() native "return this.root;";
}
