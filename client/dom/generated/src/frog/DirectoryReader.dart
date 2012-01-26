
class DirectoryReaderJs extends DOMTypeJs implements DirectoryReader native "*DirectoryReader" {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) native;
}
