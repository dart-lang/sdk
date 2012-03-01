
class _WorkerNavigatorImpl extends _DOMTypeBase implements WorkerNavigator {
  _WorkerNavigatorImpl._wrap(ptr) : super._wrap(ptr);

  String get appName() => _wrap(_ptr.appName);

  String get appVersion() => _wrap(_ptr.appVersion);

  bool get onLine() => _wrap(_ptr.onLine);

  String get platform() => _wrap(_ptr.platform);

  String get userAgent() => _wrap(_ptr.userAgent);
}
