
class _NavigatorJs extends _DOMTypeJs implements Navigator native "*Navigator" {

  final String appCodeName;

  final String appName;

  final String appVersion;

  final bool cookieEnabled;

  final _GeolocationJs geolocation;

  final String language;

  final _DOMMimeTypeArrayJs mimeTypes;

  final bool onLine;

  final String platform;

  final _DOMPluginArrayJs plugins;

  final String product;

  final String productSub;

  final String userAgent;

  final String vendor;

  final String vendorSub;

  void getStorageUpdates() native;

  bool javaEnabled() native;

  void registerProtocolHandler(String scheme, String url, String title) native;
}
