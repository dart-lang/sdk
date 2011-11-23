
class Entry native "*Entry" {

  DOMFileSystem filesystem;

  String fullPath;

  bool isDirectory;

  bool isFile;

  String name;

  void copyTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getMetadata([MetadataCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void moveTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void remove([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
