// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*
* `return exp;` where `exp` has static type `S` is an error if
  `Future<flatten(S)>` is not assignable to `T`.
*/
Future<Future<String>> v = null;
Future<String> test() async {
  return /*@compile-error=unspecified*/ v;
}

void main() {
  test();
}
