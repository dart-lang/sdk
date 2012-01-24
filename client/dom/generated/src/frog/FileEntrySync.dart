
class FileEntrySyncJS extends EntrySyncJS implements FileEntrySync native "*FileEntrySync" {

  FileWriterSyncJS createWriter() native;

  FileJS file() native;
}
