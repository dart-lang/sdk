
class _DirectoryEntrySyncImpl extends _EntrySyncImpl implements DirectoryEntrySync native "*DirectoryEntrySync" {

  _DirectoryReaderSyncImpl createReader() native;

  _DirectoryEntrySyncImpl getDirectory(String path, Object flags) native;

  _FileEntrySyncImpl getFile(String path, Object flags) native;

  void removeRecursively() native;
}
