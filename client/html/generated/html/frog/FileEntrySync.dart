
class _FileEntrySyncImpl extends _EntrySyncImpl implements FileEntrySync native "*FileEntrySync" {

  _FileWriterSyncImpl createWriter() native;

  _FileImpl file() native;
}
