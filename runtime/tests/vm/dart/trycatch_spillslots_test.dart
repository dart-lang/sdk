// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that catch and function Parameters don't share spill slots.
//
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
bool bar(String a) {
  if (a.length > 10) {
    throw "baz";
  }
  return false;
}

@pragma('vm:never-inline')
void foo(String a) {
  final b = a;
  bool second_bar_threw = true;
  try {
    bar(a);
    a = "xxx";
    second_bar_threw = bar(b + "-");
  } catch (e, st) {
    if (second_bar_threw) {
      Expect.notEquals(b, "xxx");
    }
    print("a=$a b=$b"); //# 1: ok
  }
  print("a=$a b=$b"); //# 2: ok
}

main() {
  var s = "";
  for (int i = 0; i < 15; i++) {
    foo(s += "-");
  }
}
