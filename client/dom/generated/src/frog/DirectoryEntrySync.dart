
class _DirectoryEntrySyncJs extends _EntrySyncJs implements DirectoryEntrySync native "*DirectoryEntrySync" {

  _DirectoryReaderSyncJs createReader() native;

  _DirectoryEntrySyncJs getDirectory(String path, Object flags) native;

  _FileEntrySyncJs getFile(String path, Object flags) native;

  void removeRecursively() native;
}
