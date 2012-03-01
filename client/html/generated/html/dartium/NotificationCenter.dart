
class _NotificationCenterImpl extends _DOMTypeBase implements NotificationCenter {
  _NotificationCenterImpl._wrap(ptr) : super._wrap(ptr);

  int checkPermission() {
    return _wrap(_ptr.checkPermission());
  }

  Notification createHTMLNotification(String url) {
    return _wrap(_ptr.createHTMLNotification(_unwrap(url)));
  }

  Notification createNotification(String iconUrl, String title, String body) {
    return _wrap(_ptr.createNotification(_unwrap(iconUrl), _unwrap(title), _unwrap(body)));
  }

  void requestPermission(VoidCallback callback) {
    _ptr.requestPermission(_unwrap(callback));
    return;
  }
}
