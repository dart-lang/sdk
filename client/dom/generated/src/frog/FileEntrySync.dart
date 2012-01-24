
class FileEntrySyncJs extends EntrySyncJs implements FileEntrySync native "*FileEntrySync" {

  FileWriterSyncJs createWriter() native;

  FileJs file() native;
}
