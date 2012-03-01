
class _FileImpl extends _BlobImpl implements File {
  _FileImpl._wrap(ptr) : super._wrap(ptr);

  String get fileName() => _wrap(_ptr.fileName);

  int get fileSize() => _wrap(_ptr.fileSize);

  Date get lastModifiedDate() => _wrap(_ptr.lastModifiedDate);

  String get name() => _wrap(_ptr.name);

  String get webkitRelativePath() => _wrap(_ptr.webkitRelativePath);
}
