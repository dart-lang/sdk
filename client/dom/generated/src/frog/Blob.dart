
class BlobJs extends DOMTypeJs implements Blob native "*Blob" {

  int get size() native "return this.size;";

  String get type() native "return this.type;";

  BlobJs webkitSlice([int start = null, int end = null, String contentType = null]) native;
}
