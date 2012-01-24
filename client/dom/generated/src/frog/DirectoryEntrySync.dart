
class DirectoryEntrySyncJs extends EntrySyncJs implements DirectoryEntrySync native "*DirectoryEntrySync" {

  DirectoryReaderSyncJs createReader() native;

  DirectoryEntrySyncJs getDirectory(String path, Object flags) native;

  FileEntrySyncJs getFile(String path, Object flags) native;

  void removeRecursively() native;
}
