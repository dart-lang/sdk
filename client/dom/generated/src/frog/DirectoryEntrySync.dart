
class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  DirectoryReaderSync createReader() native;

  DirectoryEntrySync getDirectory(String path, WebKitFlags flags) native;

  FileEntrySync getFile(String path, WebKitFlags flags) native;

  void removeRecursively() native;
}
