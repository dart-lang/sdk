// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  foo(/*bc:1*/ bar());
  /*nbb:0:3*/
}

void foo(int bar, {int /*bc:2*/ baz}) {
  /*bc:3*/ print('foo!');
}

int bar() {
  return 42;
}
