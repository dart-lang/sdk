// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/compiler_new.dart';
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
        import 'package:expect/expect.dart';

        @NoInline()
        foo(y) => 49912344 + y;

        class A {
          var field;

          @NoInline()
          A([this.field = 4711]);

          @NoInline()
          static bar(x) => x + 123455;

          @NoInline()
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

    Expect.isTrue(jsOutput.contains('49912344'));
    Expect.isTrue(jsOutput.contains('123455'));
    Expect.isTrue(jsOutput.contains('81234512'));
    Expect.isFalse(jsOutput.contains('49935756'));
    Expect.isFalse(jsOutput.contains('211109'));
    Expect.isFalse(jsOutput.contains('82155031'));
    Expect.isFalse(jsOutput.contains('4712'));
  });
}
