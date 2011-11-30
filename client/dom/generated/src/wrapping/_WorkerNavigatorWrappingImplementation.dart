// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WorkerNavigatorWrappingImplementation extends DOMWrapperBase implements WorkerNavigator {
  _WorkerNavigatorWrappingImplementation() : super() {}

  static create__WorkerNavigatorWrappingImplementation() native {
    return new _WorkerNavigatorWrappingImplementation();
  }

  String get appName() { return _get_appName(this); }
  static String _get_appName(var _this) native;

  String get appVersion() { return _get_appVersion(this); }
  static String _get_appVersion(var _this) native;

  bool get onLine() { return _get_onLine(this); }
  static bool _get_onLine(var _this) native;

  String get platform() { return _get_platform(this); }
  static String _get_platform(var _this) native;

  String get userAgent() { return _get_userAgent(this); }
  static String _get_userAgent(var _this) native;

  String get typeName() { return "WorkerNavigator"; }
}
