
class Navigator native "*Navigator" {

  String get appCodeName() native "return this.appCodeName;";

  String get appName() native "return this.appName;";

  String get appVersion() native "return this.appVersion;";

  bool get cookieEnabled() native "return this.cookieEnabled;";

  Geolocation get geolocation() native "return this.geolocation;";

  String get language() native "return this.language;";

  DOMMimeTypeArray get mimeTypes() native "return this.mimeTypes;";

  bool get onLine() native "return this.onLine;";

  String get platform() native "return this.platform;";

  DOMPluginArray get plugins() native "return this.plugins;";

  String get product() native "return this.product;";

  String get productSub() native "return this.productSub;";

  String get userAgent() native "return this.userAgent;";

  String get vendor() native "return this.vendor;";

  String get vendorSub() native "return this.vendorSub;";

  void getStorageUpdates() native;

  bool javaEnabled() native;

  void registerProtocolHandler(String scheme, String url, String title) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
