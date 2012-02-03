
class _FileJs extends _BlobJs implements File native "*File" {

  String get fileName() native "return this.fileName;";

  int get fileSize() native "return this.fileSize;";

  Date get lastModifiedDate() native "return this.lastModifiedDate;";

  String get name() native "return this.name;";

  String get webkitRelativePath() native "return this.webkitRelativePath;";
}
