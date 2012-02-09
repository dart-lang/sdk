
class _FileWriterJs extends _DOMTypeJs implements FileWriter native "*FileWriter" {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  final _FileErrorJs error;

  final int length;

  EventListener onabort;

  EventListener onerror;

  EventListener onprogress;

  EventListener onwrite;

  EventListener onwriteend;

  EventListener onwritestart;

  final int position;

  final int readyState;

  void abort() native;

  void seek(int position) native;

  void truncate(int size) native;

  void write(_BlobJs data) native;
}
