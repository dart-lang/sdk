// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorWrappingImplementation extends DOMWrapperBase implements Navigator {
  NavigatorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get appCodeName() { return _ptr.appCodeName; }

  String get appName() { return _ptr.appName; }

  String get appVersion() { return _ptr.appVersion; }

  bool get cookieEnabled() { return _ptr.cookieEnabled; }

  String get language() { return _ptr.language; }

  DOMMimeTypeArray get mimeTypes() { return LevelDom.wrapDOMMimeTypeArray(_ptr.mimeTypes); }

  bool get onLine() { return _ptr.onLine; }

  String get platform() { return _ptr.platform; }

  DOMPluginArray get plugins() { return LevelDom.wrapDOMPluginArray(_ptr.plugins); }

  String get product() { return _ptr.product; }

  String get productSub() { return _ptr.productSub; }

  String get userAgent() { return _ptr.userAgent; }

  String get vendor() { return _ptr.vendor; }

  String get vendorSub() { return _ptr.vendorSub; }

  void getStorageUpdates() {
    _ptr.getStorageUpdates();
    return;
  }

  bool javaEnabled() {
    return _ptr.javaEnabled();
  }
}
