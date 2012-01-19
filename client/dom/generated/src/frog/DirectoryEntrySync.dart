
class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  DirectoryReaderSync createReader() native;

  DirectoryEntrySync getDirectory(String path, Object flags) native;

  FileEntrySync getFile(String path, Object flags) native;

  void removeRecursively() native;
}
