// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/serialization/strategies.dart';
import 'package:compiler/src/types/types.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../helpers/memory_compiler.dart';
import '../helpers/text_helpers.dart';

runTest(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    Uri packageConfig,
    Uri librariesSpecificationUri,
    List<String> options,
    SerializationStrategy strategy: const BytesInMemorySerializationStrategy(),
    bool useDataKinds: false}) async {
  OutputCollector collector1 = new OutputCollector();
  CompilationResult result1 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: options,
      outputProvider: collector1,
      beforeRun: (Compiler compiler) {
        compiler.libraryLoader.forceSerialization = true;
      });
  Expect.isTrue(result1.isSuccess);

  OutputCollector collector2 = new OutputCollector();
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: options,
      outputProvider: collector2,
      beforeRun: (Compiler compiler) {
        compiler.libraryLoader.forceSerialization = true;
        compiler.stopAfterTypeInference = true;
      });
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  GlobalTypeInferenceResults globalInferenceResults =
      compiler.globalInference.resultsForTesting;
  GlobalTypeInferenceResults newGlobalInferenceResults =
      cloneInferenceResults(compiler, globalInferenceResults, strategy);

  Map<OutputType, Map<String, String>> output = collector1.clear();

  compiler.generateJavaScriptCode(newGlobalInferenceResults);
  Map<OutputType, Map<String, String>> newOutput = collector2.clear();

  Expect.setEquals(output.keys, newOutput.keys, "Output type mismatch.");

  output.forEach((OutputType outputType, Map<String, String> fileMap) {
    Map<String, String> newFileMap = newOutput[outputType];
    Expect.setEquals(fileMap.keys, newFileMap.keys,
        "File mismatch for output type $outputType.");

    fileMap.forEach((String fileName, String code) {
      String newCode = newFileMap[fileName];
      int failureLine = checkEqualContentAndShowDiff(code, newCode);
      Expect.isNull(
          failureLine,
          "Output mismatch at line $failureLine in "
          "file '${fileName}' of type ${outputType}.");
    });
  });
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
