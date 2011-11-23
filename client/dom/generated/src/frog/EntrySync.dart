
class EntrySync native "*EntrySync" {

  DOMFileSystemSync filesystem;

  String fullPath;

  bool isDirectory;

  bool isFile;

  String name;

  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  Metadata getMetadata() native;

  DirectoryEntrySync getParent() native;

  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  void remove() native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
