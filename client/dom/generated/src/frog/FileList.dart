
class _FileListJs extends _DOMTypeJs implements FileList native "*FileList" {

  int get length() native "return this.length;";

  _FileJs item(int index) native;
}
