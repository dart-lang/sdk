// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

class A {
  bool operator ==(covariant A other) => true;
}

class B extends A {
  bool operator ==(other) => true;
}

class C<T> {
  bool operator ==(covariant C<T> other) => true;
}

class D extends C<int> {}

main() {}
