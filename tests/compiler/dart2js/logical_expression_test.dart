// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that logical or-expressions don't introduce unnecessary nots.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo(bar, gee) {
  bool cond1 = bar();
  if (cond1 || gee()) gee();
  if (cond1 || gee()) gee();
}
""";

const String TEST_TWO = r"""
void foo(list, bar) {
  if (list == null) bar();
  if (list == null || bar()) bar();
  if (list == null || bar()) bar();
}
""";

main() {
  asyncTest(() => Future.wait([
    // We want something like:
    //     var t1 = bar.call$0() === true;
    //     if (t1 || gee.call$0() === true) gee.call$0();
    //     if (t1 || gee.call$0() === true) gee.call$0();
    compileAndDoNotMatchFuzzy(TEST_ONE, 'foo',
        r"""var x = [a-zA-Z0-9$.]+\(\) == true;
            if \(x \|\| [a-zA-Z0-9$.]+\(\) === true\) [^;]+;
            if \(x \|\| [a-zA-Z0-9$.]+\(\) === true\) [^;]+;"""),


    // We want something like:
    //     var t1 = list == null;
    //     if (t1) bar.call$0();
    //     if (t1 || bar.call$0() === true) bar.call$0();
    //     if (t1 || bar.call$0() === true) bar.call$0();
    compileAndMatchFuzzy(TEST_TWO, 'foo',
        r"""var x = x == null;
            if \(x\) [^;]+;
            if \(x \|\| [a-zA-Z0-9$.]+\(\) === true\) [^;]+;
            if \(x \|\| [a-zA-Z0-9$.]+\(\) === true\) [^;]+;"""),
  ]));
}
