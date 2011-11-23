
class DirectoryReader native "*DirectoryReader" {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
