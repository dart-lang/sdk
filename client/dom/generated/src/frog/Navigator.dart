
class Navigator native "Navigator" {

  String appCodeName;

  String appName;

  String appVersion;

  bool cookieEnabled;

  String language;

  DOMMimeTypeArray mimeTypes;

  bool onLine;

  String platform;

  DOMPluginArray plugins;

  String product;

  String productSub;

  String userAgent;

  String vendor;

  String vendorSub;

  void getStorageUpdates() native;

  bool javaEnabled() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
