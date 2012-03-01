
class _HistoryImpl implements History native "*History" {

  final int length;

  final Dynamic state;

  void back() native;

  void forward() native;

  void go(int distance) native;

  void pushState(Object data, String title, [String url = null]) native;

  void replaceState(Object data, String title, [String url = null]) native;
}
