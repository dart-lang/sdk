
class _NavigatorImpl implements Navigator native "*Navigator" {

  final String appCodeName;

  final String appName;

  final String appVersion;

  final bool cookieEnabled;

  final _GeolocationImpl geolocation;

  final String language;

  final _DOMMimeTypeArrayImpl mimeTypes;

  final bool onLine;

  final String platform;

  final _DOMPluginArrayImpl plugins;

  final String product;

  final String productSub;

  final String userAgent;

  final String vendor;

  final String vendorSub;

  void getStorageUpdates() native;

  bool javaEnabled() native;

  void registerProtocolHandler(String scheme, String url, String title) native;

  void webkitGetUserMedia(String options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback = null]) native;
}
