
class DirectoryEntrySyncJS extends EntrySyncJS implements DirectoryEntrySync native "*DirectoryEntrySync" {

  DirectoryReaderSyncJS createReader() native;

  DirectoryEntrySyncJS getDirectory(String path, Object flags) native;

  FileEntrySyncJS getFile(String path, Object flags) native;

  void removeRecursively() native;
}
