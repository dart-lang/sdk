// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verify-entry-points=true
// SharedObjects=entrypoints_verification_test

import 'dart:ffi';
import './dylib_utils.dart';

main() {
  final helper = dlopenPlatformSpecific('entrypoints_verification_test');
  final runTest =
      helper.lookupFunction<Void Function(), void Function()>('RunTests');
  runTest();

  new C();
  new D();
}

class C {}

@pragma("vm:entry-point")
class D {
  D();

  @pragma("vm:entry-point")
  D.defined();

  @pragma("vm:entry-point")
  factory D.fact() => E.ctor();

  void fn0() {}

  @pragma("vm:entry-point")
  void fn1() {}

  @pragma("vm:entry-point", "get")
  void fn1_get() {}

  @pragma("vm:entry-point", "call")
  void fn1_call() {}

  static void fn2() {}

  @pragma("vm:entry-point")
  static void fn3() {}

  @pragma("vm:entry-point", "call")
  static void fn3_call() {}

  @pragma("vm:entry-point", "get")
  static void fn3_get() {}

  void Function()? fld0;

  @pragma("vm:entry-point")
  void Function()? fld1;

  @pragma("vm:entry-point", "get")
  void Function()? fld2;

  @pragma("vm:entry-point", "set")
  void Function()? fld3;
}

void fn0() {}

@pragma("vm:entry-point")
void fn1() {}

@pragma("vm:entry-point", "get")
void fn1_get() {}

@pragma("vm:entry-point", "call")
void fn1_call() {}

class E extends D {
  E.ctor();
}

@pragma("vm:entry-point")
class F {
  static void Function()? fld0;

  @pragma("vm:entry-point")
  static void Function()? fld1;

  @pragma("vm:entry-point", "get")
  static void Function()? fld2;

  @pragma("vm:entry-point", "set")
  static void Function()? fld3;
}

void Function()? fld0;

@pragma("vm:entry-point")
void Function()? fld1;

@pragma("vm:entry-point", "get")
void Function()? fld2;

@pragma("vm:entry-point", "set")
void Function()? fld3;
