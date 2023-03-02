// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  final T t;
  const C(this.t);
}

Map<C<String>, int> foo() => throw 0;

test() {
  var {const C(:var t): a1} = foo();
}
