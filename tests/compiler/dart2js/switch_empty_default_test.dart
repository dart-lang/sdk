// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding on numbers.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String SIMPLY_EMPTY = """
int foo(x) => x;
void main() {
  var a = foo(4);
  var b = 1;
  switch (a) {
    case 1:
      b += 2;
      a = 0;
  }
  print(a);
}
""";

const String TOTAL = """
void main() {
  for (int a = 0; a < 3; a++) {
    switch (a) {
      case 0:
        a = 99;
        break;
      case 1:
        a = 2;
        break;
      case 2:
        a = 1;
        break;
      default:
        a = 33;
    }
  }
  print(a);
}
""";

const String OPTIMIZED = """
void main() {
  var b;
  for (int a = 0; a < 3; a++) {
    switch (a) {
      case 1:
      case 2:
        b = 0;
        ++a;
        break;
      default:
        b = 0;
    }
  }
  print(a+b);
}
""";

const String LABEL = """
void main() {
  var b;
  for (int a = 0; a < 3; a++) {
    switch (a) {
      case 1:
        break;
      case 2:
        b = 0;
        continue K;
      K: case 3:
        b = 19;
      default:
        b = 5;
    }
  }
  print(a+b);
}
""";

const String DEFLABEL = """
void main() {
  var b;
  for (int a = 0; a < 3; a++) {
    switch (a) {
      case 1:
        continue L;
      case 2:
        b = 0;
        break;
      L: default:
        b = 5;
    }
  }
  print(a+b);
}
""";

const String EMPTYDEFLABEL = """
void main() {
  var b;
  for (int a = 0; a < 3; a++) {
    switch (a) {
      case 1:
        continue L;
      case 2:
        b = 0;
        break;
      L: default:
    }
  }
  print(a+b);
}
""";

main() {
  var def = new RegExp(r"default:");
  var defOrCase3 = new RegExp(r"(default:|case 3):");
  var case3 = new RegExp(r"case 3:");

  asyncTest(() => Future.wait([
    compileAndDoNotMatch(SIMPLY_EMPTY, 'main', def),
    compileAndDoNotMatch(TOTAL, 'main', defOrCase3),
    compileAndDoNotMatch(OPTIMIZED, 'main', def),
    compileAndMatch(LABEL, 'main', case3),
    compileAndMatch(DEFLABEL, 'main', def),
    compileAndMatch(EMPTYDEFLABEL, 'main', def),
  ]));
}
