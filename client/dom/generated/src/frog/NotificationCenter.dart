
class _NotificationCenterJs extends _DOMTypeJs implements NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  _NotificationJs createHTMLNotification(String url) native;

  _NotificationJs createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;
}
