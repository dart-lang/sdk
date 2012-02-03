
class _FileEntrySyncJs extends _EntrySyncJs implements FileEntrySync native "*FileEntrySync" {

  _FileWriterSyncJs createWriter() native;

  _FileJs file() native;
}
