
class _DataTransferItemListJs extends _DOMTypeJs implements DataTransferItemList native "*DataTransferItemList" {

  int get length() native "return this.length;";

  void add(var data_OR_file, [String type = null]) native;

  void clear() native;

  _DataTransferItemJs item(int index) native;
}
