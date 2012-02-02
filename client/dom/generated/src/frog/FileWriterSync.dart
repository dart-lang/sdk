
class _FileWriterSyncJs extends _DOMTypeJs implements FileWriterSync native "*FileWriterSync" {

  int get length() native "return this.length;";

  int get position() native "return this.position;";

  void seek(int position) native;

  void truncate(int size) native;

  void write(_BlobJs data) native;
}
