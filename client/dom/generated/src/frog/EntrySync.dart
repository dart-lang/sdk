
class _EntrySyncJs extends _DOMTypeJs implements EntrySync native "*EntrySync" {

  _DOMFileSystemSyncJs get filesystem() native "return this.filesystem;";

  String get fullPath() native "return this.fullPath;";

  bool get isDirectory() native "return this.isDirectory;";

  bool get isFile() native "return this.isFile;";

  String get name() native "return this.name;";

  _EntrySyncJs copyTo(_DirectoryEntrySyncJs parent, String name) native;

  _MetadataJs getMetadata() native;

  _DirectoryEntrySyncJs getParent() native;

  _EntrySyncJs moveTo(_DirectoryEntrySyncJs parent, String name) native;

  void remove() native;

  String toURL() native;
}
