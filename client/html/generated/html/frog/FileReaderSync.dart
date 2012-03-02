
class _FileReaderSyncImpl implements FileReaderSync native "*FileReaderSync" {

  _ArrayBufferImpl readAsArrayBuffer(_BlobImpl blob) native;

  String readAsBinaryString(_BlobImpl blob) native;

  String readAsDataURL(_BlobImpl blob) native;

  String readAsText(_BlobImpl blob, [String encoding = null]) native;
}
