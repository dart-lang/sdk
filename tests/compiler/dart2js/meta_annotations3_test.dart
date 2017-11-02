// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Functional test of 'tryInline' annotation from package:meta/dart2js.dart.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/compiler_new.dart';
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': r'''
        import 'package:meta/dart2js.dart';

        monster1(u) {
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
        }

        @tryInline
        monster2(u) {
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
          print(u + 1000);
        }

        main() {
          // large function used twice should not normally be inlined.
          monster1(38000992);
          monster1(38000993);
          monster2(48000992);
          monster2(48000993);
        }'''
};

void main() {
  asyncTest(() async {
    OutputCollector collector = new OutputCollector();
    await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    String jsOutput = collector.getOutput('', OutputType.js);

    void has(String text) {
      Expect.isTrue(jsOutput.contains(text), "output should contain '$text'");
    }

    void hasNot(String text) {
      print(jsOutput);
      Expect.isFalse(
          jsOutput.contains(text), "output must not contain '$text'");
    }

    // Check that (u + 1000) from monster1 is not inlined and constant folded.
    has('38000992');
    has('38000993');
    hasNot('38001992');
    hasNot('38001993');

    // Check that (u + 1000) from monster2 is inlined and constant folded.
    hasNot('48000992');
    hasNot('48000993');
    has('48001992');
    has('48001993');
  });
}
