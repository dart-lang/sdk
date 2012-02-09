
class _HistoryJs extends _DOMTypeJs implements History native "*History" {

  final int length;

  void back() native;

  void forward() native;

  void go(int distance) native;

  void pushState(Object data, String title, [String url = null]) native;

  void replaceState(Object data, String title, [String url = null]) native;
}
