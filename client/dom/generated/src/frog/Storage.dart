
class Storage native "*Storage" {

  int length;

  void clear() native;

  String getItem(String key) native;

  String key(int index) native;

  void removeItem(String key) native;

  void setItem(String key, String data) native;

  var get dartObjectLocalStorage() native """

    if (this === window.localStorage)
      return window._dartLocalStorageLocalStorage;
    else if (this === window.sessionStorage)
      return window._dartSessionStorageLocalStorage;
    else
      throw new UnsupportedOperationException('Cannot dartObjectLocalStorage for unknown Storage object.');

""" {
    throw new UnsupportedOperationException('');
  }

  void set dartObjectLocalStorage(var value) native """

    if (this === window.localStorage)
      window._dartLocalStorageLocalStorage = value;
    else if (this === window.sessionStorage)
      window._dartSessionStorageLocalStorage = value;
    else
      throw new UnsupportedOperationException('Cannot dartObjectLocalStorage for unknown Storage object.');

""" {
    throw new UnsupportedOperationException('');
  }

  String get typeName() native;
}
