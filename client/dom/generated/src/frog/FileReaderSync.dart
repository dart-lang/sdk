
class FileReaderSync native "FileReaderSync" {

  ArrayBuffer readAsArrayBuffer(Blob blob) native;

  String readAsBinaryString(Blob blob) native;

  String readAsDataURL(Blob blob) native;

  String readAsText(Blob blob, [String encoding = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
