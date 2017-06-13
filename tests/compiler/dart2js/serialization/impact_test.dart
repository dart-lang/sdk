// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_impact_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/filenames.dart';
import '../memory_compiler.dart';
import '../equivalence/check_functions.dart';
import 'helper.dart';

main(List<String> args) {
  Arguments arguments = new Arguments.from(args);
  asyncTest(() async {
    SerializedData serializedData =
        await serializeDartCore(arguments: arguments);
    if (arguments.filename != null) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.filename));
      await check(serializedData, entryPoint);
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      await check(serializedData, entryPoint,
          sourceFiles: {'main.dart': 'main() {}'}, verbose: arguments.verbose);
    }
  });
}

Future check(SerializedData serializedData, Uri entryPoint,
    {Map<String, String> sourceFiles: const <String, String>{},
    bool verbose: false}) async {
  Compiler compilerNormal =
      compilerFor(memorySourceFiles: sourceFiles, options: [Flags.analyzeAll]);
  compilerNormal.resolution.retainCachesForTesting = true;
  await compilerNormal.run(entryPoint);

  Compiler compilerDeserialized = compilerFor(
      memorySourceFiles: serializedData.toMemorySourceFiles(sourceFiles),
      resolutionInputs: serializedData.toUris(),
      options: [Flags.analyzeAll]);
  compilerDeserialized.resolution.retainCachesForTesting = true;
  await compilerDeserialized.run(entryPoint);

  checkAllImpacts(compilerNormal, compilerDeserialized, verbose: verbose);
}
