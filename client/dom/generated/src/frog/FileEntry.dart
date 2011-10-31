
class FileEntry extends Entry native "FileEntry" {

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) native;
}
