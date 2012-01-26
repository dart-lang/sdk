
class DataTransferItemListJs extends DOMTypeJs implements DataTransferItemList native "*DataTransferItemList" {

  int get length() native "return this.length;";

  void add(String data, String type) native;

  void clear() native;

  DataTransferItemJs item(int index) native;
}
