// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

// Test that certain interfaces/classes are blacklisted from being
// implemented or extended (VM corelib only).

#library("BlackListedTest.dart");
#import("dart:coreimpl");

class MyBool extends Bool {}  /// 01: compile-time error

class MyDouble extends Double {}  /// 02: compile-time error

class MyObjectArray extends ObjectArray {}  /// 03: compile-time error

class MyImmutableArray extends ImmutableArray {}  /// 04: compile-time error

class MyGrowableObjectArray extends GrowableObjectArray {}  /// 05: compile-time error

class MyIntegerImplementation extends IntegerImplementation {}  /// 06: compile-time error

class MySmi extends Smi {}  /// 07: compile-time error

class MyMint extends Mint {}  /// 08: compile-time error

class MyBigint extends Bigint {}  /// 09: compile-time error

class MyOneByteString extends OneByteString {}  /// 10: compile-time error

class MyTwoByteString extends TwoByteString {}  /// 11: compile-time error

class MyFourByteString extends FourByteString {}  /// 12: compile-time error

main() {

}