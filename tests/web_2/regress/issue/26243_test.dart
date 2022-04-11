// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

var trace = [];
void write(String s, int a, int b) {
  trace.add("$s $a $b");
}

void foo() {
  var i = 0;
  write("foo", i, i += 1);
}

void bar() {
  var i = 0;
  try {
    write("bar", i, i += 1);
  } catch (_) {}
}

void baz() {
  var i = 0;
  write("baz-notry", i, i += 1);

  i = 0;
  try {
    write("baz-try", i, i += 1);
  } catch (_) {}
}

void main() {
  foo();
  bar();
  baz();
  Expect.listEquals(
      ['foo 0 1', 'bar 0 1', 'baz-notry 0 1', 'baz-try 0 1'], trace);
}
