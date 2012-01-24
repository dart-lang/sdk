
class NotificationJS implements Notification native "*Notification" {

  String get dir() native "return this.dir;";

  void set dir(String value) native "this.dir = value;";

  String get replaceId() native "return this.replaceId;";

  void set replaceId(String value) native "this.replaceId = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void cancel() native;

  bool dispatchEvent(EventJS evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void show() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
