// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Functional test of 'noInline' annotation from package:meta/dart2js.dart.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/compiler_new.dart';
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': r'''
        import 'package:meta/dart2js.dart';

        @noInline
        foo(y) => 49912344 + y;

        class A {
          var field;

          @noInline
          A([this.field = 4711]);

          @noInline
          static bar(x) => x + 123455;

          @noInline
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
  asyncTest(() async {
    OutputCollector collector = new OutputCollector();
    await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    // Simply check that the constants of the small functions are still in the
    // output, and that we don't see the result of constant folding.
    String jsOutput = collector.getOutput('', OutputType.js);

    void has(String text) {
      Expect.isTrue(jsOutput.contains(text), "output should contain '$text'");
    }

    void hasNot(String text) {
      Expect.isFalse(
          jsOutput.contains(text), "output must not contain '$text'");
    }

    has('49912344');
    has('123455');
    has('81234512');
    hasNot('49935756');
    hasNot('211109');
    hasNot('82155031');
    hasNot('4712');
  });
}
