
class DirectoryEntry extends Entry native "*DirectoryEntry" {

  DirectoryReader createReader() native;

  void getDirectory(String path, [WebKitFlags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getFile(String path, [WebKitFlags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void removeRecursively([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}
