
class _DataTransferItemJs extends _DOMTypeJs implements DataTransferItem native "*DataTransferItem" {

  String get kind() native "return this.kind;";

  String get type() native "return this.type;";

  _BlobJs getAsFile() native;

  void getAsString(StringCallback callback) native;
}
