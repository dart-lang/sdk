
class EntrySyncJs extends DOMTypeJs implements EntrySync native "*EntrySync" {

  DOMFileSystemSyncJs get filesystem() native "return this.filesystem;";

  String get fullPath() native "return this.fullPath;";

  bool get isDirectory() native "return this.isDirectory;";

  bool get isFile() native "return this.isFile;";

  String get name() native "return this.name;";

  EntrySyncJs copyTo(DirectoryEntrySyncJs parent, String name) native;

  MetadataJs getMetadata() native;

  DirectoryEntrySyncJs getParent() native;

  EntrySyncJs moveTo(DirectoryEntrySyncJs parent, String name) native;

  void remove() native;

  String toURL() native;
}
