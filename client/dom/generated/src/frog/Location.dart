
class Location native "Location" {

  String hash;

  String host;

  String hostname;

  String href;

  String origin;

  String pathname;

  String port;

  String protocol;

  String search;

  void assign(String url) native;

  String getParameter(String name) native;

  void reload() native;

  void replace(String url) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
