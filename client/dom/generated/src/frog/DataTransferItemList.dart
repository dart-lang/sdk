
class DataTransferItemListJs extends DOMTypeJs implements DataTransferItemList native "*DataTransferItemList" {

  int get length() native "return this.length;";

  void add(var data_OR_file, [String type = null]) native;

  void clear() native;

  DataTransferItemJs item(int index) native;
}
