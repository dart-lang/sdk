// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 42088.

class Foo<T> {}

void main() {
  var f = <T>() => Foo<T>().runtimeType;

  print(f<int>());
  print(f<String>());
}
