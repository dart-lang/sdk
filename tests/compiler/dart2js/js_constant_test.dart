// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_1 = r"""
  import 'dart:_foreign_helper';
  main() {
    JS('', '#.toString()', -5);
    // absent: "5.toString"
    // present: "(-5).toString"
  }
""";

main() {
  Future check(String test) {
    Uri uri = new Uri(scheme: 'dart', path: 'test');
    var compiler = compilerFor(test, uri, expectedErrors: 0);
    return compiler.run(uri).then((_) {
      MemberElement element = findElement(compiler, 'main');
      var backend = compiler.backend;
      String generated = backend.getGeneratedCode(element);
      checkerForAbsentPresent(test)(generated);
    });
  }

  asyncTest(() => Future.wait([
        check(TEST_1),
      ]));
}
