// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import '../helpers/memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
        import 'package:expect/expect.dart';

        @pragma('dart2js:noInline')
        foo(y) => 49912344 + y;

        class A {
          @pragma('dart2js:noElision')
          var field;

          @pragma('dart2js:noInline')
          A([this.field = 4711]);

          @pragma('dart2js:noInline')
          static bar(x) => x + 123455;

          @pragma('dart2js:noInline')
          gee(x, y) => x + y + 81234512;
        }

        main() {
          print(foo(23412));
          print(A.bar(87654));
          print(new A().gee(1337, 919182));
          print(new A().field + 1);
        }'''
};

void main() {
  runTest() async {
    OutputCollector collector = new OutputCollector();
    await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        outputProvider: collector,
        options: [Flags.testMode]);
    // Simply check that the constants of the small functions are still in the
    // output, and that we don't see the result of constant folding.
    String jsOutput = collector.getOutput('', OutputType.js);

    Expect.isTrue(jsOutput.contains('49912344'));
    Expect.isTrue(jsOutput.contains('123455'));
    Expect.isTrue(jsOutput.contains('81234512'));
    Expect.isFalse(jsOutput.contains('49935756'));
    Expect.isFalse(jsOutput.contains('211109'));
    Expect.isFalse(jsOutput.contains('82155031'));
    Expect.isFalse(jsOutput.contains('4712'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
