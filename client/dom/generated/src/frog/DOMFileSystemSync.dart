
class DOMFileSystemSyncJs extends DOMTypeJs implements DOMFileSystemSync native "*DOMFileSystemSync" {

  String get name() native "return this.name;";

  DirectoryEntrySyncJs get root() native "return this.root;";
}
