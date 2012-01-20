
class Location native "*Location" {

  String get hash() native "return this.hash;";

  void set hash(String value) native "this.hash = value;";

  String get host() native "return this.host;";

  void set host(String value) native "this.host = value;";

  String get hostname() native "return this.hostname;";

  void set hostname(String value) native "this.hostname = value;";

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get origin() native "return this.origin;";

  String get pathname() native "return this.pathname;";

  void set pathname(String value) native "this.pathname = value;";

  String get port() native "return this.port;";

  void set port(String value) native "this.port = value;";

  String get protocol() native "return this.protocol;";

  void set protocol(String value) native "this.protocol = value;";

  String get search() native "return this.search;";

  void set search(String value) native "this.search = value;";

  void assign(String url) native;

  void reload() native;

  void replace(String url) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
