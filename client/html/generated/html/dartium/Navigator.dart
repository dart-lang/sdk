
class _NavigatorImpl extends _DOMTypeBase implements Navigator {
  _NavigatorImpl._wrap(ptr) : super._wrap(ptr);

  String get appCodeName() => _wrap(_ptr.appCodeName);

  String get appName() => _wrap(_ptr.appName);

  String get appVersion() => _wrap(_ptr.appVersion);

  bool get cookieEnabled() => _wrap(_ptr.cookieEnabled);

  Geolocation get geolocation() => _wrap(_ptr.geolocation);

  String get language() => _wrap(_ptr.language);

  DOMMimeTypeArray get mimeTypes() => _wrap(_ptr.mimeTypes);

  bool get onLine() => _wrap(_ptr.onLine);

  String get platform() => _wrap(_ptr.platform);

  DOMPluginArray get plugins() => _wrap(_ptr.plugins);

  String get product() => _wrap(_ptr.product);

  String get productSub() => _wrap(_ptr.productSub);

  String get userAgent() => _wrap(_ptr.userAgent);

  String get vendor() => _wrap(_ptr.vendor);

  String get vendorSub() => _wrap(_ptr.vendorSub);

  void getStorageUpdates() {
    _ptr.getStorageUpdates();
    return;
  }

  bool javaEnabled() {
    return _wrap(_ptr.javaEnabled());
  }

  void registerProtocolHandler(String scheme, String url, String title) {
    _ptr.registerProtocolHandler(_unwrap(scheme), _unwrap(url), _unwrap(title));
    return;
  }

  void webkitGetUserMedia(String options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.webkitGetUserMedia(_unwrap(options), _unwrap(successCallback));
      return;
    } else {
      _ptr.webkitGetUserMedia(_unwrap(options), _unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }
}
