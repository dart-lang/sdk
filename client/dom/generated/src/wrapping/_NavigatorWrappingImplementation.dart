// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NavigatorWrappingImplementation extends DOMWrapperBase implements Navigator {
  _NavigatorWrappingImplementation() : super() {}

  static create__NavigatorWrappingImplementation() native {
    return new _NavigatorWrappingImplementation();
  }

  String get appCodeName() { return _get__Navigator_appCodeName(this); }
  static String _get__Navigator_appCodeName(var _this) native;

  String get appName() { return _get__Navigator_appName(this); }
  static String _get__Navigator_appName(var _this) native;

  String get appVersion() { return _get__Navigator_appVersion(this); }
  static String _get__Navigator_appVersion(var _this) native;

  bool get cookieEnabled() { return _get__Navigator_cookieEnabled(this); }
  static bool _get__Navigator_cookieEnabled(var _this) native;

  String get language() { return _get__Navigator_language(this); }
  static String _get__Navigator_language(var _this) native;

  DOMMimeTypeArray get mimeTypes() { return _get__Navigator_mimeTypes(this); }
  static DOMMimeTypeArray _get__Navigator_mimeTypes(var _this) native;

  bool get onLine() { return _get__Navigator_onLine(this); }
  static bool _get__Navigator_onLine(var _this) native;

  String get platform() { return _get__Navigator_platform(this); }
  static String _get__Navigator_platform(var _this) native;

  DOMPluginArray get plugins() { return _get__Navigator_plugins(this); }
  static DOMPluginArray _get__Navigator_plugins(var _this) native;

  String get product() { return _get__Navigator_product(this); }
  static String _get__Navigator_product(var _this) native;

  String get productSub() { return _get__Navigator_productSub(this); }
  static String _get__Navigator_productSub(var _this) native;

  String get userAgent() { return _get__Navigator_userAgent(this); }
  static String _get__Navigator_userAgent(var _this) native;

  String get vendor() { return _get__Navigator_vendor(this); }
  static String _get__Navigator_vendor(var _this) native;

  String get vendorSub() { return _get__Navigator_vendorSub(this); }
  static String _get__Navigator_vendorSub(var _this) native;

  void getStorageUpdates() {
    _getStorageUpdates(this);
    return;
  }
  static void _getStorageUpdates(receiver) native;

  bool javaEnabled() {
    return _javaEnabled(this);
  }
  static bool _javaEnabled(receiver) native;

  String get typeName() { return "Navigator"; }
}
