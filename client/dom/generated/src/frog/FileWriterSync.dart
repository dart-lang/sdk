
class _FileWriterSyncJs extends _DOMTypeJs implements FileWriterSync native "*FileWriterSync" {

  final int length;

  final int position;

  void seek(int position) native;

  void truncate(int size) native;

  void write(_BlobJs data) native;
}
