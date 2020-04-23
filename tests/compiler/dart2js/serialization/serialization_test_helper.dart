// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/types.dart';
import 'package:compiler/src/serialization/strategies.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../helpers/memory_compiler.dart';
import '../helpers/text_helpers.dart';

/// Entries in dump info that naturally differ between compilations.
const List<String> dumpInfoExceptions = [
  '"compilationMoment":',
  '"compilationDuration":',
  '"toJsonDuration":'
];

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
        compiler.kernelLoader.forceSerialization = true;
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
        compiler.kernelLoader.forceSerialization = true;
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
      bool Function(int, List<String>, List<String>) filter;
      if (outputType == OutputType.dumpInfo) {
        filter = (int index, List<String> lines1, List<String> lines2) {
          if (index <= lines1.length && index <= lines2.length) {
            String line1 = lines1[index];
            String line2 = lines2[index];
            for (String exception in dumpInfoExceptions) {
              if (line1.trim().startsWith(exception) &&
                  line2.trim().startsWith(exception)) {
                return true;
              }
            }
          }
          return false;
        };
      }
      int failureLine =
          checkEqualContentAndShowDiff(code, newCode, filter: filter);
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
