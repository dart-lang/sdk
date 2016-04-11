// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart overriden_field`

class Base {
  Object field = 'lorem';

  Object something = 'change';
}

class Bad1 extends Base {
  @override
  final x = 1, field = 'ipsum'; // LINT
}

class Bad2 extends Base {
  @override
  Object something = 'done'; // LINT
}

class Ok extends Base {
  Object newField; // OK

  final Object newFinal = 'ignore'; // OK
}

class Super1 {}

class Sub1 extends Super1 {
  @override
  int y;
}

class Super2 {
  int x, y;
}

class Sub2 extends Super2 {
  @override
  int y; // LINT
}

class Super3 {
  int x;
}

class Sub3 extends Super3 {
  int x; // LINT
}