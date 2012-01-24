
class FileReaderSyncJS implements FileReaderSync native "*FileReaderSync" {

  ArrayBufferJS readAsArrayBuffer(BlobJS blob) native;

  String readAsBinaryString(BlobJS blob) native;

  String readAsDataURL(BlobJS blob) native;

  String readAsText(BlobJS blob, [String encoding = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
