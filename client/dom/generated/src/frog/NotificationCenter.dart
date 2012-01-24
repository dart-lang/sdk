
class NotificationCenterJS implements NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  NotificationJS createHTMLNotification(String url) native;

  NotificationJS createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
