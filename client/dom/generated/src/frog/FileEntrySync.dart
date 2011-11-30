
class FileEntrySync extends EntrySync native "*FileEntrySync" {

  FileWriterSync createWriter() native;

  File file() native;
}
