// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  foo(/*bc:1*/ bar(), baz: /*bc:2*/ baz());
  /*nbb:0:4*/
}

void foo(int bar, {int /*bc:3*/ baz}) {
  /*bc:4*/ print('foo!');
}

int bar() {
  return 42;
}

int baz() {
  return 42;
}
