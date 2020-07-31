// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:async_helper/async_helper.dart';
import '../helpers/memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
        main() {
          print(12300000);
          // TODO(efortuna): Uncomment below when issue 33160 is fixed.
          // print(0xffffffff00000000);
          print(double.maxFinite);
          print(-22230000);
        }'''
};

Future test({bool minify}) async {
  OutputCollector collector = new OutputCollector();
  List<String> options = <String>[];
  if (minify) {
    options.add(Flags.minify);
  }
  await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      outputProvider: collector,
      options: options);

  // Check that we use the shorter exponential representations.
  String jsOutput = collector.getOutput('', OutputType.js);
  print(jsOutput);

  if (minify) {
    Expect.isTrue(jsOutput.contains('123e5')); // Shorter than 12300000.
    Expect.isFalse(jsOutput.contains('12300000'));
    Expect.isTrue(jsOutput.contains('-2223e4')); // Shorter than -22230000.
    Expect.isFalse(jsOutput.contains('-22230000'));
  } else {
    Expect.isTrue(jsOutput.contains('12300000'));
    Expect.isTrue(jsOutput.contains('-22230000'));
  }
  // TODO(efortuna): Uncomment when issue 33160 is fixed.
  //Expect.isTrue(jsOutput.contains('18446744069414584e3'));
  //Expect.isFalse(jsOutput.contains('-4294967296'));
  Expect.isTrue(jsOutput.contains('17976931348623157e292'));
  Expect.isFalse(jsOutput.contains('1234567890123456789012345'));
  // The decimal expansion of double.maxFinite has 308 digits. We only check
  // for its prefix.
  Expect.isFalse(jsOutput.contains('179769313486231570814527423731'));
}

main() {
  runTest() async {
    await test(minify: true);
    await test(minify: false);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
