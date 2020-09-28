// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` and the future value type of
 * the function is `Tv` is an error if `S` is not assignable to `Tv` and
 * `flatten(S)` is not a subtype of `Tv`.
 */

Future<Future<String>> v = Future.value(Future<String>.value(''));

Future<String> test1() async {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'Future<Future<String>>' can't be returned from an async function with return type 'Future<String>'.
}

Future<String> Function() test2 = () async {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'Future<Future<String>>' can't be returned from an async function with return type 'Future<String>'.
};

void main() {
  test1();
  test2();
}
