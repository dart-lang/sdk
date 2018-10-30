// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/serialization/strategies.dart';
import 'package:compiler/src/types/types.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../helpers/memory_compiler.dart';

runTest(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    Uri packageConfig,
    Uri libraryRoot,
    List<String> options,
    SerializationStrategy strategy: const BytesInMemorySerializationStrategy(),
    bool useDataKinds: false}) async {
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      libraryRoot: libraryRoot,
      options: options,
      beforeRun: (Compiler compiler) {
        compiler.stopAfterTypeInference = true;
      });
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  GlobalTypeInferenceResults globalInferenceResults = cloneInferenceResults(
      compiler, compiler.globalInference.resultsForTesting, strategy);
  compiler.generateJavaScriptCode(globalInferenceResults);
}

GlobalTypeInferenceResults cloneInferenceResults(Compiler compiler,
    GlobalTypeInferenceResults results, SerializationStrategy strategy) {
  List<int> irData = strategy.serializeComponent(results);

  List worldData = strategy.serializeData(results);
  print('data size: ${worldData.length}');

  ir.Component newComponent = strategy.deserializeComponent(irData);
  GlobalTypeInferenceResults newResults = strategy.deserializeData(
      compiler.options,
      compiler.reporter,
      compiler.environment,
      compiler.abstractValueStrategy,
      newComponent,
      worldData);
  List newWorldData = strategy.serializeData(newResults);
  Expect.equals(worldData.length, newWorldData.length,
      "Reserialization data length mismatch.");
  for (int i = 0; i < worldData.length; i++) {
    if (worldData[i] != newWorldData[i]) {
      print('Reserialization data mismatch at offset $i:');
      for (int j = i - 50; j < i + 50; j++) {
        if (0 <= j && j <= worldData.length) {
          String text;
          if (worldData[j] == newWorldData[j]) {
            text = '${worldData[j]}';
          } else {
            text = '${worldData[j]} <> ${newWorldData[j]}';
          }
          print('${j == i ? '> ' : '  '}$j: $text');
        }
      }
      break;
    }
  }
  Expect.listEquals(worldData, newWorldData);

  return newResults;
}
