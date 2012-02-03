
class _FileReaderSyncJs extends _DOMTypeJs implements FileReaderSync native "*FileReaderSync" {

  _ArrayBufferJs readAsArrayBuffer(_BlobJs blob) native;

  String readAsBinaryString(_BlobJs blob) native;

  String readAsDataURL(_BlobJs blob) native;

  String readAsText(_BlobJs blob, [String encoding = null]) native;
}
