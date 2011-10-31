
class NotificationCenter native "NotificationCenter" {

  int checkPermission() native;

  Notification createHTMLNotification(String url) native;

  Notification createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
