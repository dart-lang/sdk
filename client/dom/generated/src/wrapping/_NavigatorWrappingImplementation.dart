// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NavigatorWrappingImplementation extends DOMWrapperBase implements Navigator {
  _NavigatorWrappingImplementation() : super() {}

  static create__NavigatorWrappingImplementation() native {
    return new _NavigatorWrappingImplementation();
  }

  String get appCodeName() { return _get_appCodeName(this); }
  static String _get_appCodeName(var _this) native;

  String get appName() { return _get_appName(this); }
  static String _get_appName(var _this) native;

  String get appVersion() { return _get_appVersion(this); }
  static String _get_appVersion(var _this) native;

  bool get cookieEnabled() { return _get_cookieEnabled(this); }
  static bool _get_cookieEnabled(var _this) native;

  String get language() { return _get_language(this); }
  static String _get_language(var _this) native;

  DOMMimeTypeArray get mimeTypes() { return _get_mimeTypes(this); }
  static DOMMimeTypeArray _get_mimeTypes(var _this) native;

  bool get onLine() { return _get_onLine(this); }
  static bool _get_onLine(var _this) native;

  String get platform() { return _get_platform(this); }
  static String _get_platform(var _this) native;

  DOMPluginArray get plugins() { return _get_plugins(this); }
  static DOMPluginArray _get_plugins(var _this) native;

  String get product() { return _get_product(this); }
  static String _get_product(var _this) native;

  String get productSub() { return _get_productSub(this); }
  static String _get_productSub(var _this) native;

  String get userAgent() { return _get_userAgent(this); }
  static String _get_userAgent(var _this) native;

  String get vendor() { return _get_vendor(this); }
  static String _get_vendor(var _this) native;

  String get vendorSub() { return _get_vendorSub(this); }
  static String _get_vendorSub(var _this) native;

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
