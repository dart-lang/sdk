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
    // present: 'Moose'
    JS('', 'Moose');

    // absent: 'Phantom' - pure.
    JS('returns: bool;effects:none;depends:none;throws:never', 'Phantom');

    // present: 'Spider' - unused after constant folding 'is', but unpure.
    print(JS('returns:bool;effects:none;depends:all', 'Spider') is bool);

    // absent: 'Wasp' - unused after constant folding 'is', and unpure.
    print(JS('returns:bool;effects:none;depends:all;throws:never', 'Wasp')
          is bool);

    JS('', 'Array');   // absent: "Array"
  }
""";

const String TEST_2 = r"""
  import 'dart:_foreign_helper';
  main() {
    var w1 = JS('returns:int;depends:none;effects:none;throws:never',
        'foo(#)', 1);
    var w2 = JS('returns:int;depends:none;effects:none;throws:never',
        'foo(#)', 2);

    print([w2, w1]);

    // present: '[foo(2), foo(1)]' - since 'foo' is pure, we expect to generate
    // code out-of-order.
  }
""";

const String TEST_3 = r"""
  import 'dart:_foreign_helper';
  main() {
    var s = JS('String|Null', '"Hello"');
    var s1 = JS('returns:String;depends:none;effects:none;throws:null(1)',
        '#.toLowerCase()', s);
    var s2 = JS('returns:String;depends:none;effects:none;throws:null(1)',
        '#.toUpperCase()', s);
    print(s2);

    // absent: 'toLowerCase' - removed since s.toUpperCase() generates the same
    // noSuchMethod.
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
    check(TEST_2),
    check(TEST_3),
  ]));
}
