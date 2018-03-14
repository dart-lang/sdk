// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';

main() {
  asyncTest(() async {
    String oldMap = (await compile([Flags.useOldFrontend]))
        .getOutput('', OutputType.sourceMap);
    String newMap =
        (await compile([Flags.useOldFrontend, Flags.useNewSourceInfo]))
            .getOutput('', OutputType.sourceMap);
    OutputCollector multiCollector1 =
        await compile([Flags.useOldFrontend, Flags.useMultiSourceInfo]);
    String multiMap1a = multiCollector1.getOutput('', OutputType.sourceMap);
    String multiMap1b =
        multiCollector1.getOutput('out.js', OutputType.sourceMap);
    Expect.equals(oldMap, multiMap1a);
    Expect.equals(newMap, multiMap1b);
    OutputCollector multiCollector2 = await compile([
      Flags.useOldFrontend,
      Flags.useMultiSourceInfo,
      Flags.useNewSourceInfo
    ]);
    String multiMap2a = multiCollector2.getOutput('', OutputType.sourceMap);
    String multiMap2b =
        multiCollector2.getOutput('out.js', OutputType.sourceMap);
    Expect.equals(newMap, multiMap2a);
    Expect.equals(oldMap, multiMap2b);
  });
}

Future<OutputCollector> compile(List<String> options) async {
  OutputCollector collector = new OutputCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:main.dart'),
      memorySourceFiles: const {'main.dart': 'main() {}'},
      outputProvider: collector,
      options: options);
  return collector;
}
