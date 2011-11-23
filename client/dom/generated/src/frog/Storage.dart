
class Storage native "*Storage" {

  int length;

  void clear() native;

  String getItem(String key) native;

  String key(int index) native;

  void removeItem(String key) native;

  void setItem(String key, String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
