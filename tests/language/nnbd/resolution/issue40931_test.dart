// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

main() {}

extension E<T> on T? {
  T foo() => throw 0;
}

void f(int? a) {
  a.foo();
}
