// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=entrypoints_verification_test

import 'dart:ffi';
import './dylib_utils.dart';

main(List<String> args) {
  final helper = dlopenPlatformSpecific('entrypoints_verification_test');
  final runTest = helper.lookupFunction<Void Function(), void Function()>(
    'RunTests',
  );
  runTest();
}

final void Function() noop = () {};

@pragma("vm:entry-point", "get")
final void Function() testValue = noop;

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

  void Function()? fld0 = noop;

  @pragma("vm:entry-point")
  void Function()? fld1 = noop;

  @pragma("vm:entry-point", "get")
  void Function()? fld2 = noop;

  @pragma("vm:entry-point", "set")
  void Function()? fld3 = noop;

  void Function() _instanceFieldForGetterSetterTests = noop;

  void Function() get get1 => _instanceFieldForGetterSetterTests;

  @pragma("vm:entry-point")
  void Function() get get2 => _instanceFieldForGetterSetterTests;

  @pragma("vm:entry-point", "get")
  void Function() get get3 => _instanceFieldForGetterSetterTests;

  set set1(void Function() value) => _instanceFieldForGetterSetterTests = value;

  @pragma("vm:entry-point")
  set set2(void Function() value) => _instanceFieldForGetterSetterTests = value;

  @pragma("vm:entry-point", "set")
  set set3(void Function() value) => _instanceFieldForGetterSetterTests = value;
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
  static void Function()? fld0 = noop;

  @pragma("vm:entry-point")
  static void Function()? fld1 = noop;

  @pragma("vm:entry-point", "get")
  static void Function()? fld2 = noop;

  @pragma("vm:entry-point", "set")
  static void Function()? fld3 = noop;

  static void Function() _classFieldForGetterSetterTests = noop;

  static void Function() get get1 => _classFieldForGetterSetterTests;

  @pragma("vm:entry-point")
  static void Function() get get2 => _classFieldForGetterSetterTests;

  @pragma("vm:entry-point", "get")
  static void Function() get get3 => _classFieldForGetterSetterTests;

  static set set1(void Function() value) =>
      _classFieldForGetterSetterTests = value;

  @pragma("vm:entry-point")
  static set set2(void Function() value) =>
      _classFieldForGetterSetterTests = value;

  @pragma("vm:entry-point", "set")
  static set set3(void Function() value) =>
      _classFieldForGetterSetterTests = value;
}

void Function()? fld0 = noop;

@pragma("vm:entry-point")
void Function()? fld1 = noop;

@pragma("vm:entry-point", "get")
void Function()? fld2 = noop;

@pragma("vm:entry-point", "set")
void Function()? fld3 = noop;

void Function() _libFieldForGetterSetterTests = noop;

void Function() get get1 => _libFieldForGetterSetterTests;

@pragma("vm:entry-point")
void Function() get get2 => _libFieldForGetterSetterTests;

@pragma("vm:entry-point", "get")
void Function() get get3 => _libFieldForGetterSetterTests;

set set1(void Function() value) => _libFieldForGetterSetterTests = value;

@pragma("vm:entry-point")
set set2(void Function() value) => _libFieldForGetterSetterTests = value;

@pragma("vm:entry-point", "set")
set set3(void Function() value) => _libFieldForGetterSetterTests = value;
