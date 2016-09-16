// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
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
  RegExp directivePattern = new RegExp(
      //      \1                    \2        \3
      r'''// *(present|absent): (?:"([^"]*)"|'([^'']*)')''',
      multiLine: true);

  Future check(String test) {
    Uri uri = new Uri(scheme: 'dart', path: 'test');
    var compiler = compilerFor(test, uri, expectedErrors: 0);
    return compiler.run(uri).then((_) {
      var element = findElement(compiler, 'main');
      var backend = compiler.backend;
      String generated = backend.getGeneratedCode(element);

      for (Match match in directivePattern.allMatches(test)) {
        String directive = match.group(1);
        String pattern = match.groups([2, 3]).where((s) => s != null).single;
        if (directive == 'present') {
          Expect.isTrue(generated.contains(pattern),
              "Cannot find '$pattern' in:\n$generated");
        } else {
          assert(directive == 'absent');
          Expect.isFalse(generated.contains(pattern),
              "Must not find '$pattern' in:\n$generated");
        }
      }
    });
  }

  asyncTest(() => Future.wait([
        check(TEST_1),
      ]));
}
