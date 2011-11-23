
class DataTransferItemList native "*DataTransferItemList" {

  int length;

  void add(String data, String type) native;

  void clear() native;

  DataTransferItem item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
