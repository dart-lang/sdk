
class DataTransferItemListJS implements DataTransferItemList native "*DataTransferItemList" {

  int get length() native "return this.length;";

  void add(String data, String type) native;

  void clear() native;

  DataTransferItemJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
