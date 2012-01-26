
class DataTransferItemJs extends DOMTypeJs implements DataTransferItem native "*DataTransferItem" {

  String get kind() native "return this.kind;";

  String get type() native "return this.type;";

  BlobJs getAsFile() native;

  void getAsString(StringCallback callback) native;
}
