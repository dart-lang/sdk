// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that implicit call tear-offs are inserted based on the pattern's
/// context type, but not when destructuring.

import "package:expect/expect.dart";

main() {
  // Does not tear-off during destructuring. Therefore, these are errors because
  // the type of the value isn't assignable to the pattern's type.
  (C,) record = (C(),);
  var (IntFn b,) = record;
  //         ^
  // [analyzer] unspecified
  // [cfe] The matched value of type 'C' isn't assignable to the required type 'int Function(int)'.

  List<C> list = [C()];
  var [IntFn c] = list;
  //         ^
  // [analyzer] unspecified
  // [cfe] The matched value of type 'C' isn't assignable to the required type 'int Function(int)'.

  Map<String, C> map = {'x': C()};
  var {'x': IntFn d} = map;
  //              ^
  // [analyzer] unspecified
  // [cfe] The matched value of type 'C' isn't assignable to the required type 'int Function(int)'.

  Box<C> box = Box(C());
  var Box<C>(value: IntFn e) = box;
  //                      ^
  // [analyzer] unspecified
  // [cfe] The matched value of type 'C' isn't assignable to the required type 'int Function(int)'.
}

class C {
  const C();
  int call(int x) => x;
}

class Box<T> {
  final T value;
  Box(this.value);
}

typedef IntFn = int Function(int);
