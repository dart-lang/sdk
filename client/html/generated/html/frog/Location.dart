
class _LocationImpl implements Location native "*Location" {

  String hash;

  String host;

  String hostname;

  String href;

  final String origin;

  String pathname;

  String port;

  String protocol;

  String search;

  void assign(String url) native;

  void reload() native;

  void replace(String url) native;

  String toString() native;
}
