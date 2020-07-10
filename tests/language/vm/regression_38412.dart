// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=1

// Found by DartFuzzing: would sometimes fail:
// https://github.com/dart-lang/sdk/issues/38412

import "package:expect/expect.dart";

import 'dart:async';
import 'dart:convert';

int fuzzvar1 = -9223372028264841217;
Map<int, String> fuzzvar8 = {1: "a"};

class X1 {
  List<int> foo1_0(List<int> par1, String par3) {
    Expect.equals("not", par3);
    Expect.equals(10, par1.length);
    return [1];
  }
}

String bar(Map<int, String> o1, int o2) {
  Expect.equals(1, o1.length);
  Expect.equals(-9223372028264841218, o2);
  return "not";
}

main() {
  for (int loc0 = 0; loc0 < 7500; loc0++) {
    "a" == Uri.parse("\u2665");
  }
  print('fuzzvar8 runtime type: ${fuzzvar8.runtimeType}');
  var x =
      X1().foo1_0([for (int i = 0; i < 10; ++i) 0], bar(fuzzvar8, --fuzzvar1));
  Expect.equals(1, x[0]);
}
