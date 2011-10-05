// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PerformanceNavigationWrappingImplementation extends DOMWrapperBase implements PerformanceNavigation {
  _PerformanceNavigationWrappingImplementation() : super() {}

  static create__PerformanceNavigationWrappingImplementation() native {
    return new _PerformanceNavigationWrappingImplementation();
  }

  int get redirectCount() { return _get__PerformanceNavigation_redirectCount(this); }
  static int _get__PerformanceNavigation_redirectCount(var _this) native;

  int get type() { return _get__PerformanceNavigation_type(this); }
  static int _get__PerformanceNavigation_type(var _this) native;

  String get typeName() { return "PerformanceNavigation"; }
}
