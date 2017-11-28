// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_resolved_ast_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/filenames.dart';
import '../equivalence/check_functions.dart';
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_data.dart';

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
      // TODO(johnniwinther): Change to test all serialized resolved ast instead
      // only those used in the test.
      Test test = TESTS.first;
      await check(serializedData, entryPoint, test.sourceFiles);
    }
  });
}

Future check(SerializedData serializedData, Uri entryPoint,
    [Map<String, String> sourceFiles = const <String, String>{}]) async {
  Compiler compilerNormal =
      compilerFor(memorySourceFiles: sourceFiles, options: [Flags.analyzeAll]);
  compilerNormal.impactCacheDeleter.retainCachesForTesting = true;
  await compilerNormal.run(entryPoint);

  Compiler compilerDeserialized = compilerFor(
      memorySourceFiles: serializedData.toMemorySourceFiles(sourceFiles),
      resolutionInputs: serializedData.toUris(),
      options: [Flags.analyzeAll]);
  compilerDeserialized.impactCacheDeleter.retainCachesForTesting = true;
  await compilerDeserialized.run(entryPoint);

  checkAllResolvedAsts(compilerNormal, compilerDeserialized, verbose: true);
}
