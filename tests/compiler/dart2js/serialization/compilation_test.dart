// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_compilation_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/filenames.dart';
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_data.dart';
import '../output_collector.dart';

main(List<String> args) {
  asyncTest(() async {
    Arguments arguments = new Arguments.from(args);
    SerializedData serializedData =
        await serializeDartCore(arguments: arguments);
    if (arguments.filename != null) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.filename));
      await compile(
          entryPoint,
          resolutionInputs: serializedData.toUris(),
          sourceFiles: serializedData.toMemorySourceFiles());
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      await arguments.forEachTest(serializedData, TESTS, compile);
    }
  });
}

Future compile(
    Uri entryPoint,
    {Map<String, String> sourceFiles: const <String, String>{},
     List<Uri> resolutionInputs,
     int index,
     Test test,
     bool verbose: false}) async {
  if (test != null && test.name == 'Disable tree shaking through reflection') {
    // TODO(johnniwinther): Support serialization of native element data.
    return;
  }
  String testDescription = test != null ? test.name : '${entryPoint}';
  String id = index != null ? '$index: ' : '';
  print('------------------------------------------------------------------');
  print('compile ${id}${testDescription}');
  print('------------------------------------------------------------------');
  OutputCollector outputCollector = new OutputCollector();
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: sourceFiles,
      resolutionInputs: resolutionInputs,
      options: [],
      outputProvider: outputCollector);
  if (verbose) {
    print(outputCollector.getOutput('', 'js'));
  }
}

