
class XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  EventListener onabort;

  EventListener onerror;

  EventListener onload;

  EventListener onloadstart;

  EventListener onprogress;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
