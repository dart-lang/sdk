// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';
import '../helpers/memory_compiler.dart';

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

    JS('', 'Array'); //   absent: "Array"
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

const String TEST_4 = r"""
  import 'dart:_foreign_helper';
  main() {
    var s = JS('String|Null', '"Hello"');
    var s1 = JS('returns:String;depends:none;effects:none;throws:null(1)',
        '#.toLowerCase()', s);
    var s2 = JS('returns:String;depends:none;effects:none;throws:null(1)',
        '#.toUpperCase()', s);

    // present: 'erCase' - retained at least one call to guarantee exception.
  }
""";

const String TEST_5 = r"""
  import 'dart:_foreign_helper';
  main() {
    var s = JS('String', '"Hello"');
    var s1 = JS('returns:String;depends:none;effects:none;throws:null(1)',
        '#.toLowerCase()', s);
    var s2 = JS('returns:String;depends:none;effects:none;throws:null(1)',
        '#.toUpperCase()', s);

    // absent: 'erCase' - neither call needs to be retained since there is no
    // exception.
  }
""";

main() {
  runTests() async {
    check(String test) async {
      var checker = checkerForAbsentPresent(test);
      String main = 'sdk/tests/dart2js_2/native/main.dart';
      Uri entryPoint = Uri.parse('memory:$main');
      var result = await runCompiler(
          entryPoint: entryPoint, memorySourceFiles: {main: test});
      Expect.isTrue(result.isSuccess);
      var compiler = result.compiler;
      var closedWorld = compiler.backendClosedWorldForTesting;
      var elementEnvironment = closedWorld.elementEnvironment;

      MemberEntity element = elementEnvironment.mainFunction;
      String generated =
          compiler.backendStrategy.getGeneratedCodeForTesting(element);
      checker(generated);
    }

    await check(TEST_1);
    await check(TEST_2);
    await check(TEST_3);
    await check(TEST_4);
    await check(TEST_5);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
