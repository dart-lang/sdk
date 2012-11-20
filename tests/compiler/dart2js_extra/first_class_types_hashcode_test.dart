// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that Type instances work with maps. This behavior is not required by
// the specification.

class A {}

class B<T> {}

main() {
  Map<Type, String> map = new Map<Type, String>();
  A a = new A().runtimeType;
  B b1 = new B<int>().runtimeType;
  B b2 = new B<String>().runtimeType;
  map[a] = 'A';
  map[b1] = 'B<int>';
  map[b2] = 'B<String>';
  Expect.equals('A', map[new A().runtimeType]);
  Expect.equals('B<int>', map[new B<int>().runtimeType]);
  Expect.equals('B<String>', map[new B<String>().runtimeType]);
}
