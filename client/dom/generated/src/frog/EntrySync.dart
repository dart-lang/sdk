
class EntrySyncJS implements EntrySync native "*EntrySync" {

  DOMFileSystemSyncJS get filesystem() native "return this.filesystem;";

  String get fullPath() native "return this.fullPath;";

  bool get isDirectory() native "return this.isDirectory;";

  bool get isFile() native "return this.isFile;";

  String get name() native "return this.name;";

  EntrySyncJS copyTo(DirectoryEntrySyncJS parent, String name) native;

  MetadataJS getMetadata() native;

  DirectoryEntrySyncJS getParent() native;

  EntrySyncJS moveTo(DirectoryEntrySyncJS parent, String name) native;

  void remove() native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
