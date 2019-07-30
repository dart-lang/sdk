// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test programing for testing that optimizations do wrongly assume loads
// from and stores to C memory are not aliased.
//
// SharedObjects=ffi_test_functions
// VMOptions=--deterministic --optimization-counter-threshold=50

library FfiTest;

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

void main() {
  for (int i = 0; i < 100; ++i) {
    testNonAlias();
    testAliasCast();
    testAliasCast2();
    testAliasOffsetBy();
    testAliasOffsetBy2();
    testAliasElementAt();
    testAliasElementAt2();
    testAliasFromAddress();
    testAliasFromAddress2();
    testAliasFromAddressViaMemory();
    testAliasFromAddressViaMemory2();
    testAliasFromAddressViaNativeFunction();
    testAliasFromAddressViaNativeFunction2();
    testPartialOverlap();
  }
}

void testNonAlias() {
  final source = Pointer<Int64>.allocate();
  source.store(42);
  final int a = source.load();
  source.store(1984);
  // alias.load() should be re-executed, as we wrote to alias.
  Expect.notEquals(a, source.load<int>());
  source.free();
}

void testAliasCast() {
  final source = Pointer<Int64>.allocate();
  final alias = source.cast<Int8>().cast<Int64>();
  source.store(42);
  final int a = source.load();
  alias.store(1984);
  // source.load() should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.load<int>());
  source.free();
}

void testAliasCast2() {
  final source = Pointer<Int64>.allocate();
  final alias = source.cast<Int16>().cast<Int64>();
  final alias2 = source.cast<Int8>().cast<Int64>();
  alias.store(42);
  final int a = alias.load();
  alias2.store(1984);
  // alias.load() should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.load<int>());
  source.free();
}

void testAliasOffsetBy() {
  final source = Pointer<Int64>.allocate(count: 2);
  final alias = source.offsetBy(8).offsetBy(-8);
  source.store(42);
  final int a = source.load();
  alias.store(1984);
  // source.load() should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.load<int>());
  source.free();
}

void testAliasOffsetBy2() {
  final source = Pointer<Int64>.allocate(count: 3);
  final alias = source.offsetBy(16).offsetBy(-16);
  final alias2 = source.offsetBy(8).offsetBy(-8);
  alias.store(42);
  final int a = alias.load();
  alias2.store(1984);
  // alias.load() should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.load<int>());
  source.free();
}

void testAliasElementAt() {
  final source = Pointer<Int64>.allocate(count: 2);
  final alias = source.elementAt(1).elementAt(-1);
  source.store(42);
  final int a = source.load();
  alias.store(1984);
  // source.load() should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.load<int>());
  source.free();
}

void testAliasElementAt2() {
  final source = Pointer<Int64>.allocate(count: 3);
  final alias = source.elementAt(2).elementAt(-2);
  final alias2 = source.elementAt(1).elementAt(-1);
  alias.store(42);
  final int a = alias.load();
  alias2.store(1984);
  // alias.load() should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.load<int>());
  source.free();
}

void testAliasFromAddress() {
  final source = Pointer<Int64>.allocate();
  final alias = Pointer<Int64>.fromAddress(source.address);
  source.store(42);
  final int a = source.load();
  alias.store(1984);
  // source.load() should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.load<int>());
  source.free();
}

void testAliasFromAddress2() {
  final source = Pointer<Int64>.allocate();
  final alias = Pointer<Int64>.fromAddress(source.address);
  final alias2 = Pointer<Int64>.fromAddress(source.address);
  alias.store(42);
  final int a = alias.load();
  alias2.store(1984);
  // alias.load() should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.load<int>());
  source.free();
}

void testAliasFromAddressViaMemory() {
  final helper = Pointer<IntPtr>.allocate();
  final source = Pointer<Int64>.allocate();
  helper.store(source.address);
  final alias = Pointer<Int64>.fromAddress(helper.load());
  source.store(42);
  final int a = source.load();
  alias.store(1984);
  // source.load() should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.load<int>());
  helper.free();
  source.free();
}

void testAliasFromAddressViaMemory2() {
  final helper = Pointer<IntPtr>.allocate();
  final source = Pointer<Int64>.allocate();
  helper.store(source.address);
  final alias = Pointer<Int64>.fromAddress(helper.load());
  final alias2 = Pointer<Int64>.fromAddress(helper.load());
  alias.store(42);
  final int a = alias.load();
  alias2.store(1984);
  // alias.load() should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.load<int>());
  helper.free();
  source.free();
}

typedef NativeQuadOpSigned = Int64 Function(Int8, Int16, Int32, Int64);
typedef QuadOp = int Function(int, int, int, int);

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

QuadOp intComputation = ffiTestFunctions
    .lookupFunction<NativeQuadOpSigned, QuadOp>("IntComputation");

void testAliasFromAddressViaNativeFunction() {
  final source = Pointer<Int64>.allocate();
  final alias =
      Pointer<Int64>.fromAddress(intComputation(0, 0, 0, source.address));
  source.store(42);
  final int a = source.load();
  alias.store(1984);
  // source.load() should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.load<int>());
  source.free();
}

void testAliasFromAddressViaNativeFunction2() {
  final source = Pointer<Int64>.allocate();
  final alias =
      Pointer<Int64>.fromAddress(intComputation(0, 0, 0, source.address));
  final alias2 =
      Pointer<Int64>.fromAddress(intComputation(0, 0, 0, source.address));
  alias.store(42);
  final int a = alias.load();
  alias2.store(1984);
  // alias.load() should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.load<int>());
  source.free();
}

@pragma('vm:never-inline')
Pointer<Int8> makeDerived(Pointer<Int64> source) =>
    source.offsetBy(7).cast<Int8>();

testPartialOverlap() {
  final source = Pointer<Int64>.allocate(count: 2);
  final derived = makeDerived(source);
  source.store(0x1122334455667788);
  final int value = source.load();
  derived.store(0xaa);
  Expect.notEquals(value, source.load<int>());
  source.free();
}
