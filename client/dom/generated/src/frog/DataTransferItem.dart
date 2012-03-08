
class _DataTransferItemJs extends _DOMTypeJs implements DataTransferItem native "*DataTransferItem" {

  final String kind;

  final String type;

  _BlobJs getAsFile() native;

  void getAsString([StringCallback callback = null]) native;
}
