// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WorkerNavigatorWrappingImplementation extends DOMWrapperBase implements WorkerNavigator {
  _WorkerNavigatorWrappingImplementation() : super() {}

  static create__WorkerNavigatorWrappingImplementation() native {
    return new _WorkerNavigatorWrappingImplementation();
  }

  String get appName() { return _get__WorkerNavigator_appName(this); }
  static String _get__WorkerNavigator_appName(var _this) native;

  String get appVersion() { return _get__WorkerNavigator_appVersion(this); }
  static String _get__WorkerNavigator_appVersion(var _this) native;

  bool get onLine() { return _get__WorkerNavigator_onLine(this); }
  static bool _get__WorkerNavigator_onLine(var _this) native;

  String get platform() { return _get__WorkerNavigator_platform(this); }
  static String _get__WorkerNavigator_platform(var _this) native;

  String get userAgent() { return _get__WorkerNavigator_userAgent(this); }
  static String _get__WorkerNavigator_userAgent(var _this) native;

  String get typeName() { return "WorkerNavigator"; }
}
