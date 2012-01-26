
class XMLHttpRequestUploadJs extends DOMTypeJs implements XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
