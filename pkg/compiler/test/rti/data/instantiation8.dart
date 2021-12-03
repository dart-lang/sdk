// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(47054): Take closure signature into account to handle equality of
// instantiated closures.
/*class: Class:deps=[create]*/
class Class<T> {}

/*member: create:deps=[test]*/
Class<T> create<T>() => new Class<T>();

equals(a, b) {
  if (a != b) throw '$a != $b';
}

/*member: test:needsArgs*/
test<T>(f) {
  Class<T> Function() g = create;
  equals(f, g);
}

main() {
  Class<int> Function() f = create;
  test<int>(f);
}
