
class _DataTransferItemListImpl implements DataTransferItemList native "*DataTransferItemList" {

  final int length;

  void add(var data_OR_file, [String type = null]) native;

  void clear() native;

  _DataTransferItemImpl item(int index) native;
}
