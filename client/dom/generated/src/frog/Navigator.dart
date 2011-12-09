
class Navigator native "*Navigator" {

  String appCodeName;

  String appName;

  String appVersion;

  bool cookieEnabled;

  Geolocation geolocation;

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

  void registerProtocolHandler(String scheme, String url, String title) native;

  void webkitGetUserMedia(String options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
