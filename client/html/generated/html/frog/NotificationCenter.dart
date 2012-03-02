
class _NotificationCenterImpl implements NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  _NotificationImpl createHTMLNotification(String url) native;

  _NotificationImpl createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;
}
