// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

class InjectedClass {} // Error

injectedMethod() {} // Error

@patch
class Class {
  injectedMethod() {} // Error
  static staticInjectedMethod() {} // Error
}

@patch
extension Extension on int {
  injectedMethod() {} // Error
  static staticInjectedMethod() {} // Error
}

class _PrivateInjectedClass /* Ok */ {
  publicMethod() {} // Ok
}

extension _PrivateInjectedExtension on int /* Ok */ {
  publicMethod() {} // Ok
}

@patch
class _PrivateClass {
  injectedMethod() {} // Error
  static staticInjectedMethod() {} // Ok
}

@patch
extension _PrivateExtension on int {
  injectedMethod() {} // Error
  static staticInjectedMethod() {} // Ok
}
