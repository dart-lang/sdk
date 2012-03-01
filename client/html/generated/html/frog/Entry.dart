
class _EntryImpl implements Entry native "*Entry" {

  final _DOMFileSystemImpl filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  void copyTo(_DirectoryEntryImpl parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void moveTo(_DirectoryEntryImpl parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;

  String toURL() native;
}
