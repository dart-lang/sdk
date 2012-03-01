
class _DataTransferItemImpl implements DataTransferItem native "*DataTransferItem" {

  final String kind;

  final String type;

  _BlobImpl getAsFile() native;

  void getAsString(StringCallback callback) native;
}
