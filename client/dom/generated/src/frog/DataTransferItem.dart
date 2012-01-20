
class DataTransferItem native "*DataTransferItem" {

  String get kind() native "return this.kind;";

  String get type() native "return this.type;";

  Blob getAsFile() native;

  void getAsString(StringCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
