
class _XMLHttpRequestUploadJs extends _EventTargetJs implements XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
