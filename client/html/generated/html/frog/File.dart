
class _FileImpl extends _BlobImpl implements File native "*File" {

  final String fileName;

  final int fileSize;

  final Date lastModifiedDate;

  final String name;

  final String webkitRelativePath;
}
