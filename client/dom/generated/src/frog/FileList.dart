
class FileListJs extends DOMTypeJs implements FileList native "*FileList" {

  int get length() native "return this.length;";

  FileJs item(int index) native;
}
