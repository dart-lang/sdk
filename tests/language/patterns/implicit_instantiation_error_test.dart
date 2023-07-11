// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that implicit generic function instantiations are inserted based on
/// the pattern's context type, but not when destructuring.

import "package:expect/expect.dart";

main() {
  // Does not instantiate during destructuring. Therefore, these are errors
  // because the type of the value isn't assignable to the pattern's type.
  (TFn,) record = (id,);
  var (IntFn b,) = record;
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
  //         ^
  // [cfe] The matched value of type 'T Function<T>(T)' isn't assignable to the required type 'int Function(int)'.

  List<TFn> list = [id];
  var [IntFn c] = list;
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
  //         ^
  // [cfe] The matched value of type 'T Function<T>(T)' isn't assignable to the required type 'int Function(int)'.

  Map<String, TFn> map = {'x': id};
  var {'x': IntFn d} = map;
  //        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
  //              ^
  // [cfe] The matched value of type 'T Function<T>(T)' isn't assignable to the required type 'int Function(int)'.

  Box<TFn> box = Box(id);
  var Box<TFn>(value: IntFn e) = box;
  //                  ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
  //                        ^
  // [cfe] The matched value of type 'T Function<T>(T)' isn't assignable to the required type 'int Function(int)'.
}

T id<T>(T t) => t;

class Box<T> {
  final T value;
  Box(this.value);
}

typedef IntFn = int Function(int);
typedef TFn = T Function<T>(T);
