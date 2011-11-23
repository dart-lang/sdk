
class History native "*History" {

  int length;

  void back() native;

  void forward() native;

  void go(int distance) native;

  void pushState(Object data, String title, [String url = null]) native;

  void replaceState(Object data, String title, [String url = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
