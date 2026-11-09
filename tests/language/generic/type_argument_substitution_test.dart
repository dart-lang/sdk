// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that substitutions are emitted for classes that are only used as
// type arguments.

import 'package:expect/expect.dart';

class K {}

class A<T> {}

class B extends A<K> {}

class X<T> {}

class FunctionArgument<T> implements A<Function> {}

class NullableFunctionArgument<T> implements A<Function?> {}

class RecordArgument<T> implements A<Record> {}

class NullableRecordArgument<T> implements A<Record?> {}

bool isA<T>(Object o) => o is A<T>;

T generic<T>(T x, Function a, Function? b, Record c, Record? d) => x;

Object instantiate<T>() {
  T Function(T, Function, Function?, Record, Record?) f = generic;
  return f;
}

main() {
  var v = new DateTime.now().millisecondsSinceEpoch != 42
      ? new X<B>()
      : new X<A<String>>();
  Expect.isFalse(v is X<A<String>>);

  Expect.isTrue(isA<Function>(FunctionArgument<int>()));
  Expect.isTrue(isA<Function?>(FunctionArgument<int>()));
  Expect.isFalse(isA<Record>(FunctionArgument<int>()));

  Expect.isFalse(isA<Function>(NullableFunctionArgument<int>()));
  Expect.isTrue(isA<Function?>(NullableFunctionArgument<int>()));

  Expect.isTrue(isA<Record>(RecordArgument<int>()));
  Expect.isTrue(isA<Record?>(RecordArgument<int>()));
  Expect.isFalse(isA<Function>(RecordArgument<int>()));

  Expect.isFalse(isA<Record>(NullableRecordArgument<int>()));
  Expect.isTrue(isA<Record?>(NullableRecordArgument<int>()));

  Expect.isTrue(
    instantiate<int>()
        is int Function(int, Function, Function?, Record, Record?),
  );
  Expect.isFalse(
    instantiate<int>()
        is String Function(String, Function, Function?, Record, Record?),
  );

  dynamic functionBound = <T extends Function>() => T;
  Expect.equals(Function, functionBound<Function>());
  dynamic recordBound = <T extends Record>() => T;
  Expect.equals(Record, recordBound<Record>());
}
