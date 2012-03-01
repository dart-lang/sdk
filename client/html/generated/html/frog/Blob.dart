
class _BlobImpl implements Blob native "*Blob" {

  final int size;

  final String type;

  _BlobImpl webkitSlice([int start = null, int end = null, String contentType = null]) native;
}
