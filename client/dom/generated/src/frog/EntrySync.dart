
class EntrySync native "*EntrySync" {

  DOMFileSystemSync get filesystem() native "return this.filesystem;";

  String get fullPath() native "return this.fullPath;";

  bool get isDirectory() native "return this.isDirectory;";

  bool get isFile() native "return this.isFile;";

  String get name() native "return this.name;";

  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  Metadata getMetadata() native;

  DirectoryEntrySync getParent() native;

  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  void remove() native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
