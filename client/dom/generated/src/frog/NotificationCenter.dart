
class NotificationCenterJs extends DOMTypeJs implements NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  NotificationJs createHTMLNotification(String url) native;

  NotificationJs createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;
}
