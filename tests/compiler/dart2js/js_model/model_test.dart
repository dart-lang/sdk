// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:expect/expect.dart';
import '../kernel/compiler_helper.dart';
import '../serialization/helper.dart';

const Map<String, String> SOURCE = const <String, String>{
  'main.dart': r'''
main() {}
'''
};

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

Future mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  enableDebugMode();

  Compiler compiler1 = await compileWithDill(entryPoint, memorySourceFiles, [
    Flags.disableInlining,
    Flags.disableTypeInference
  ], beforeRun: (Compiler compiler) {
    compiler.backendStrategy = new JsBackendStrategy(compiler);
  }, printSteps: true);
  Expect.isFalse(compiler1.compilationFailed);
}
