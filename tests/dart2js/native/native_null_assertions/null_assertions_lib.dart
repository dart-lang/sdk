// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../native_testing.dart';

abstract class NativeInterface {
  int get size;
  String get name;
  String? get optName;
  int method1();
  String method2();
  String? optMethod();
}

@Native("AAA")
class AAA implements NativeInterface {
  int get size native;
  String get name native;
  String? get optName native;
  int method1() native;
  String method2() native;
  String? optMethod() native;
}

abstract class JSInterface {
  String get name;
  String? get optName;
}

class BBB implements NativeInterface {
  int get size => 300;
  String get name => 'Brenda';
  String? get optName => name;
  int method1() => 400;
  String method2() => 'brilliant!';
  String? optMethod() => method2();
}
