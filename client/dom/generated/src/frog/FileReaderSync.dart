
class FileReaderSyncJs extends DOMTypeJs implements FileReaderSync native "*FileReaderSync" {

  ArrayBufferJs readAsArrayBuffer(BlobJs blob) native;

  String readAsBinaryString(BlobJs blob) native;

  String readAsDataURL(BlobJs blob) native;

  String readAsText(BlobJs blob, [String encoding = null]) native;
}
