// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST = r"""
foo(param0, param1, param2) {
  if (param0)
    do {
      param1();
    } while(param2());
  else {
    param2();
  }
}
""";

main() {
  print("foo");
  asyncTest(() => compile(TEST, entry: 'foo', check: (String generated) {
    // Check that the do-while in the 'then' is enclosed in braces.
    // Otherwise Android 4.0 stock browser has a syntax error. See issue 10923.
    Expect.isTrue(
        new RegExp(r'if[ ]*\([^)]+\)[ ]*\{[\n ]*do').hasMatch(generated));
  }));
}
