
class XMLHttpRequestUploadJS implements XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJS evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
