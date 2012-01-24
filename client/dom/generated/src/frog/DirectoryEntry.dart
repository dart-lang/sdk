
class DirectoryEntryJs extends EntryJs implements DirectoryEntry native "*DirectoryEntry" {

  DirectoryReaderJs createReader() native;

  void getDirectory(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getFile(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;
}
