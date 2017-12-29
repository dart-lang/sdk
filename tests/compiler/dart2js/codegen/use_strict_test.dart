// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';

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
  runTest({bool useKernel}) async {
    OutputCollector collector = new OutputCollector();
    await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        outputProvider: collector,
        options: useKernel ? [Flags.useKernel] : []);
    String jsOutput = collector.getOutput('', OutputType.js);

    // Skip comments.
    List<String> lines = jsOutput.split("\n");
    RegExp commentLine = new RegExp(r' *//');
    String filtered =
        lines.where((String line) => !commentLine.hasMatch(line)).join("\n");

    // TODO(floitsch): we will need to adjust this filter if we start using
    // 'eval' or 'arguments' ourselves. Currently we disallow any 'eval' or
    // 'arguments'.
    RegExp re = new RegExp(r'[^\w$](arguments|eval)[^\w$]');
    Expect.isFalse(re.hasMatch(filtered));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
