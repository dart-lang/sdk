
class WorkerLocationJS implements WorkerLocation native "*WorkerLocation" {

  String get hash() native "return this.hash;";

  String get host() native "return this.host;";

  String get hostname() native "return this.hostname;";

  String get href() native "return this.href;";

  String get pathname() native "return this.pathname;";

  String get port() native "return this.port;";

  String get protocol() native "return this.protocol;";

  String get search() native "return this.search;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
