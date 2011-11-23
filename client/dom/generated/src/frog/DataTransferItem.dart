
class DataTransferItem native "*DataTransferItem" {

  String kind;

  String type;

  Blob getAsFile() native;

  void getAsString(StringCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
