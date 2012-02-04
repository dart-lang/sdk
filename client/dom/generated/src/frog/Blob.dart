
class _BlobJs extends _DOMTypeJs implements Blob native "*Blob" {

  final int size;

  final String type;

  _BlobJs webkitSlice([int start = null, int end = null, String contentType = null]) native;
}
