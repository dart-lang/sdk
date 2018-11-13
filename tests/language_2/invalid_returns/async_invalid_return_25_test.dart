// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*
* `return exp;` where `exp` has static type `S` is an error if `flatten(S)` is
  `void` and `flatten(T)` is not `void`, `dynamic`, or `Null`.
*/
FutureOr<void> v = null;
Object test() async {
  return /*@compile-error=unspecified*/ v;
}

void main() {
  test();
}
