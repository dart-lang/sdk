// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  test(x) => x as B<T>;
}

class B<T> {}

class C<T> {}

main() {
  final a = A<C<int>>();
  a.test(B<C<int>>());
  Expect.throwsTypeError(() => a.test(B<C<num>>()));
}
