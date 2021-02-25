// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_model/js_world.dart';
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

void finishCompileAndCompare(
    Map<OutputType, Map<String, String>> expectedOutput,
    OutputCollector actualOutputCollector,
    Compiler compiler,
    SerializationStrategy strategy,
    {bool stoppedAfterClosedWorld = false,
    bool stoppedAfterTypeInference = false}) {
  if (stoppedAfterClosedWorld) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsClosedWorld newClosedWorld =
        cloneClosedWorld(compiler, closedWorld, strategy);
    compiler.performGlobalTypeInference(newClosedWorld);
  }

  if (stoppedAfterClosedWorld || stoppedAfterTypeInference) {
    GlobalTypeInferenceResults globalInferenceResults =
        compiler.globalInference.resultsForTesting;
    GlobalTypeInferenceResults newGlobalInferenceResults =
        cloneInferenceResults(compiler, globalInferenceResults, strategy);
    compiler.generateJavaScriptCode(newGlobalInferenceResults);
  }
  var actualOutput = actualOutputCollector.clear();
  Expect.setEquals(
      expectedOutput.keys, actualOutput.keys, "Output type mismatch.");

  void check(OutputType outputType, Map<String, String> fileMap) {
    Map<String, String> newFileMap = actualOutput[outputType];
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
  }

  expectedOutput.forEach(check);
}

runTest(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    Uri packageConfig,
    Uri librariesSpecificationUri,
    List<String> options,
    SerializationStrategy strategy: const BytesInMemorySerializationStrategy(),
    bool useDataKinds: false}) async {
  OutputCollector collector = new OutputCollector();
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: options,
      outputProvider: collector,
      beforeRun: (Compiler compiler) {
        compiler.kernelLoader.forceSerialization = true;
      });
  Expect.isTrue(result.isSuccess);
  Map<OutputType, Map<String, String>> expectedOutput = collector.clear();

  OutputCollector collector2 = new OutputCollector();
  CompilationResult result2 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: options,
      outputProvider: collector2,
      beforeRun: (Compiler compiler) {
        compiler.kernelLoader.forceSerialization = true;
        compiler.stopAfterClosedWorld = true;
      });
  Expect.isTrue(result2.isSuccess);

  OutputCollector collector3 = new OutputCollector();
  CompilationResult result3 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: options,
      outputProvider: collector3,
      beforeRun: (Compiler compiler) {
        compiler.kernelLoader.forceSerialization = true;
        compiler.stopAfterTypeInference = true;
      });
  Expect.isTrue(result3.isSuccess);

  finishCompileAndCompare(
      expectedOutput, collector2, result2.compiler, strategy,
      stoppedAfterClosedWorld: true);
  finishCompileAndCompare(
      expectedOutput, collector3, result3.compiler, strategy,
      stoppedAfterTypeInference: true);
}

void checkData(List<int> data, List<int> newData) {
  Expect.equals(
      data.length, newData.length, "Reserialization data length mismatch.");
  for (int i = 0; i < data.length; i++) {
    if (data[i] != newData[i]) {
      print('Reserialization data mismatch at offset $i:');
      for (int j = i - 50; j < i + 50; j++) {
        if (0 <= j && j <= data.length) {
          String text;
          if (data[j] == newData[j]) {
            text = '${data[j]}';
          } else {
            text = '${data[j]} <> ${newData[j]}';
          }
          print('${j == i ? '> ' : '  '}$j: $text');
        }
      }
      break;
    }
  }
  Expect.listEquals(data, newData);
}

JsClosedWorld cloneClosedWorld(Compiler compiler, JsClosedWorld closedWorld,
    SerializationStrategy strategy) {
  ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
  List<int> irData = strategy.serializeComponent(component);
  List<int> closedWorldData = strategy.serializeClosedWorld(closedWorld);
  print('data size: ${closedWorldData.length}');

  ir.Component newComponent = strategy.deserializeComponent(irData);
  JsClosedWorld newClosedWorld = strategy.deserializeClosedWorld(
      compiler.options,
      compiler.reporter,
      compiler.environment,
      compiler.abstractValueStrategy,
      newComponent,
      closedWorldData);
  List<int> newClosedWorldData = strategy.serializeClosedWorld(newClosedWorld);
  checkData(closedWorldData, newClosedWorldData);
  return newClosedWorld;
}

GlobalTypeInferenceResults cloneInferenceResults(Compiler compiler,
    GlobalTypeInferenceResults results, SerializationStrategy strategy) {
  List<int> irData = strategy.unpackAndSerializeComponent(results);

  List<int> worldData = strategy.serializeGlobalTypeInferenceResults(results);
  print('data size: ${worldData.length}');

  ir.Component newComponent = strategy.deserializeComponent(irData);
  GlobalTypeInferenceResults newResults =
      strategy.deserializeGlobalTypeInferenceResults(
          compiler.options,
          compiler.reporter,
          compiler.environment,
          compiler.abstractValueStrategy,
          newComponent,
          worldData);
  List<int> newWorldData =
      strategy.serializeGlobalTypeInferenceResults(newResults);
  checkData(worldData, newWorldData);
  return newResults;
}
