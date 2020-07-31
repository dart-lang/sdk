// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

// Use strict does not allow parameters or locals named "arguments" or "eval".

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
      class A {
        final arguments;
        final eval;
        A(this.arguments, this.eval);

        foo(x, y) => this.arguments + this.eval;
      }

      class B {
        foo(arguments, eval) => arguments + eval;
      }

      class C {
        foo(var x, var y) {
          var arguments, eval;
          arguments = x + y;
          eval = x - y;
          if (arguments < eval) return arguments;
          return eval;
        }
      }

      main() {
        var list = [];
        for (int i = 0; i < 1000; i++) {
          list.add(new A(i, i + 1));
          list.add(new B());
          list.add(new C());
        }
        for (int i = 0; i < list.length; i++) {
          print(list[i].foo(i, i + 1));
        }
      }'''
};

main() {
  runTest() async {
    OutputCollector collector = new OutputCollector();
    await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    String jsOutput = collector.getOutput('', OutputType.js);

    // Skip comments.
    List<String> lines = jsOutput.split("\n");

    // Filter out any lines unrelated to the code above where dart2js today
    // produces the text "eval" or "arguments"
    // Currently this includes comments, and a few lines in the body of
    // Closure.cspForwardCall and Closure.cspForwardInterceptedCall.
    List<RegExp> filters = [
      RegExp(r' *//'), // skip comments
      RegExp(r'"Intercepted function with no arguments."'),
      RegExp(r'f.apply\(s\(this\), arguments\)'),
      RegExp(r'Array.prototype.push.apply\(a, arguments\)'),
    ];
    String filtered = lines
        .where((String line) => !filters.any((regexp) => regexp.hasMatch(line)))
        .join("\n");

    RegExp re = new RegExp(r'[^\w$](arguments|eval)[^\w$]');
    Expect.isFalse(re.hasMatch(filtered));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
