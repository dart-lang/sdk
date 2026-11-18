// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Base class for all integer-like handles in the debug_info package.
extension type const DebugItem._(int _value) {
  static const DebugItem none = DebugItem._(0);

  bool get isNone => _value == 0;
  bool get isValid => _value != 0;
}

/// An opaque handle representing the debug information at a specific position
/// or instruction in a module.
extension type const DebugInfo._(int _value) implements DebugItem {
  static const DebugInfo none = DebugInfo._(0);
}

/// An opaque handle representing a scope in an original source file.
extension type const Scope._(int _value) implements DebugItem {
  static const Scope none = Scope._(0);
}

/// An opaque handle representing a variable in an original source file. Two
/// variables with the same name in different scopes are different [Variable]s.
extension type const Variable._(int _value) implements DebugItem {
  static const Variable none = Variable._(0);
}

/// Internal handle construction and deconstruction helpers.
///
/// A handle is its index plus one, so that index 0 is not `none`.
extension DebugItemInternalMethods on DebugItem {
  int get rawValue => _value;
  int get index => _value - 1;

  @pragma('dart2js:prefer-inline')
  @pragma('vm:prefer-inline')
  static int _compose(int index) {
    assert(index >= 0);
    return index + 1;
  }

  static DebugInfo makeDebugInfoHandle(int index) =>
      DebugInfo._(_compose(index));

  static Scope makeScopeHandle(int index) => Scope._(_compose(index));

  static Variable makeVariableHandle(int index) => Variable._(_compose(index));
}
