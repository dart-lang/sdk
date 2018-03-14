// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

main() {
  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await test([Flags.useOldFrontend]);
    print('--test from kernel------------------------------------------------');
    await test([]);
  });
}

test(List<String> options) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: {
        'main.dart': '''
        import 'dart:html';
        main() => document;
        '''
      },
      diagnosticHandler: collector,
      options: [Flags.analyzeAll, Flags.verbose]..addAll(options));
  int allNativeUsedCount =
      collector.verboseInfos.where((CollectedMessage message) {
    return message.text.startsWith('All native types marked as used due to ');
  }).length;
  Expect.equals(
      1, allNativeUsedCount, "Unexpected message count: $allNativeUsedCount");
}
