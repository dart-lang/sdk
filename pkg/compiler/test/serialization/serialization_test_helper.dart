// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/codegen.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dump_info.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/inferrer/types.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/strategies.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:compiler/src/util/memory_compiler.dart';
import '../helpers/text_helpers.dart';

/// Entries in dump info that naturally differ between compilations.
const List<String> dumpInfoExceptions = [
  '"compilationMoment":',
  '"compilationDuration":',
  '"toJsonDuration":',
  '"ramUsage":'
];

Future<void> generateJavaScriptCode(Compiler compiler,
    GlobalTypeInferenceResults globalTypeInferenceResults) async {
  final codegenInputs = compiler.initializeCodegen(globalTypeInferenceResults);
  final codegenResults = OnDemandCodegenResults(
      codegenInputs, compiler.backendStrategy.functionCompiler);
  final programSize = compiler.runCodegenEnqueuer(
      codegenResults,
      globalTypeInferenceResults.inferredData,
      SourceLookup(compiler.componentForTesting),
      globalTypeInferenceResults.closedWorld);
  if (compiler.options.dumpInfo) {
    await compiler.runDumpInfo(
        codegenResults,
        globalTypeInferenceResults,
        DumpInfoProgramData.fromEmitterResults(
            compiler.backendStrategy, compiler.dumpInfoRegistry, programSize));
  }
}

Future<void> finishCompileAndCompare(
    Map<api.OutputType, Map<String, String>> expectedOutput,
    OutputCollector actualOutputCollector,
    Compiler compiler,
    SerializationStrategy strategy,
    {bool stoppedAfterClosedWorld = false,
    bool stoppedAfterTypeInference = false}) async {
  if (stoppedAfterClosedWorld) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    var newClosedWorld = cloneClosedWorld(compiler, closedWorld, strategy);
    compiler.performGlobalTypeInference(newClosedWorld);
  }

  if (stoppedAfterClosedWorld || stoppedAfterTypeInference) {
    GlobalTypeInferenceResults globalInferenceResults =
        compiler.globalInference.resultsForTesting!;
    GlobalTypeInferenceResults newGlobalInferenceResults =
        cloneInferenceResults(compiler, globalInferenceResults, strategy);
    await generateJavaScriptCode(compiler, newGlobalInferenceResults);
  }
  var actualOutput = actualOutputCollector.clear();
  Expect.setEquals(
      expectedOutput.keys, actualOutput.keys, "Output type mismatch.");

  void check(api.OutputType outputType, Map<String, String> fileMap) {
    Map<String, String> newFileMap = actualOutput[outputType]!;
    Expect.setEquals(fileMap.keys, newFileMap.keys,
        "File mismatch for output type $outputType.");
    fileMap.forEach((String fileName, String code) {
      String newCode = newFileMap[fileName]!;
      bool Function(int, List<String>, List<String>)? filter;
      if (outputType == api.OutputType.dumpInfo) {
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
      int? failureLine =
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
    {Uri? entryPoint,
    Map<String, String> memorySourceFiles = const <String, String>{},
    Uri? packageConfig,
    Uri? librariesSpecificationUri,
    required List<String> options,
    SerializationStrategy strategy = const BytesInMemorySerializationStrategy(),
    bool useDataKinds = false}) async {
  var commonOptions = options + ['--out=out.js'];
  OutputCollector collector = OutputCollector();
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: commonOptions,
      outputProvider: collector,
      beforeRun: (Compiler compiler) {
        compiler.forceSerializationForTesting = true;
      });
  Expect.isTrue(result.isSuccess);
  Map<api.OutputType, Map<String, String>> expectedOutput = collector.clear();

  OutputCollector collector2 = OutputCollector();
  CompilationResult result2 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: commonOptions,
      outputProvider: collector2,
      beforeRun: (Compiler compiler) {
        compiler.forceSerializationForTesting = true;
        compiler.stopAfterClosedWorldForTesting = true;
      });
  Expect.isTrue(result2.isSuccess);

  Directory dir =
      await Directory.systemTemp.createTemp('serialization_test_helper');
  final cfeDillFileUri = dir.uri.resolve('cfe.dill');

  OutputCollector cfeDillCollector = OutputCollector();
  CompilationResult resultCfeDill = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      outputProvider: cfeDillCollector,
      options: options + ['--out=$cfeDillFileUri', Flags.cfeOnly]);
  Expect.isTrue(resultCfeDill.isSuccess);
  Expect.isTrue(cfeDillCollector.binaryOutputMap.containsKey(cfeDillFileUri));

  File(cfeDillFileUri.path)
      .writeAsBytesSync(cfeDillCollector.binaryOutputMap[cfeDillFileUri]!.list);

  var dillUri = dir.uri.resolve('out.dill');
  var closedWorldUri = Uri.parse('world.data');
  OutputCollector collector3a = OutputCollector();
  CompilationResult result3a = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: options +
          [
            '--out=$dillUri',
            '${Flags.inputDill}=$cfeDillFileUri',
            '${Flags.writeClosedWorld}=$closedWorldUri'
          ],
      outputProvider: collector3a,
      beforeRun: (Compiler compiler) {
        compiler.forceSerializationForTesting = true;
      });
  Expect.isTrue(result3a.isSuccess);
  Expect.isTrue(collector3a.binaryOutputMap.containsKey(dillUri));
  Expect.isTrue(collector3a.binaryOutputMap.containsKey(closedWorldUri));

  final dillFileUri = dir.uri.resolve('out.dill');
  final closedWorldFileUri = dir.uri.resolve('world.data');
  final globalDataUri = Uri.parse('global.data');
  final dillBytes = collector3a.binaryOutputMap[dillUri]!.list;
  final closedWorldBytes = collector3a.binaryOutputMap[closedWorldUri]!.list;
  File(dillFileUri.path).writeAsBytesSync(dillBytes);
  File(closedWorldFileUri.path).writeAsBytesSync(closedWorldBytes);
  OutputCollector collector3b = OutputCollector();
  CompilationResult result3b = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: commonOptions +
          [
            '${Flags.inputDill}=$dillFileUri',
            '${Flags.readClosedWorld}=$closedWorldFileUri',
            '${Flags.writeData}=$globalDataUri'
          ],
      outputProvider: collector3b,
      beforeRun: (Compiler compiler) {
        compiler.forceSerializationForTesting = true;
        compiler.stopAfterGlobalTypeInferenceForTesting = true;
      });
  Expect.isTrue(result3b.isSuccess);
  Expect.isTrue(collector3b.binaryOutputMap.containsKey(globalDataUri));

  final globalDataFileUri = dir.uri.resolve('global.data');

  // We must write the global data bytes before calling
  // `finishCompileAndCompare` below as that clears the collector.

  final globalDataBytes = collector3b.binaryOutputMap[globalDataUri]!.list;
  File(globalDataFileUri.path).writeAsBytesSync(globalDataBytes);

  await finishCompileAndCompare(
      expectedOutput, collector2, result2.compiler, strategy,
      stoppedAfterClosedWorld: true);
  await finishCompileAndCompare(
      expectedOutput, collector3b, result3b.compiler, strategy,
      stoppedAfterTypeInference: true);

  final jsOutUri = Uri.parse('out.js');
  OutputCollector collector4 = OutputCollector();
  CompilationResult result4 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      librariesSpecificationUri: librariesSpecificationUri,
      options: commonOptions +
          [
            '${Flags.inputDill}=$dillFileUri',
            '${Flags.readClosedWorld}=$closedWorldFileUri',
            '${Flags.readData}=$globalDataFileUri',
            '--out=$jsOutUri'
          ],
      outputProvider: collector4,
      beforeRun: (Compiler compiler) {
        compiler.forceSerializationForTesting = true;
      });
  Expect.isTrue(result4.isSuccess);

  await dir.delete(recursive: true);
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

JClosedWorld cloneClosedWorld(Compiler compiler, JClosedWorld closedWorld,
    SerializationStrategy strategy) {
  SerializationIndices indices = SerializationIndices();
  ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
  List<int> irData = strategy.serializeComponent(component);
  final closedWorldData = strategy.serializeClosedWorld(
      closedWorld, compiler.options, indices) as List<int>;
  print('data size: ${closedWorldData.length}');

  ir.Component newComponent = strategy.deserializeComponent(irData);
  var newClosedWorld = strategy.deserializeClosedWorld(
      compiler.options,
      compiler.reporter,
      compiler.environment,
      compiler.abstractValueStrategy,
      newComponent,
      closedWorldData,
      indices);
  indices = SerializationIndices();
  final newClosedWorldData = strategy.serializeClosedWorld(
      newClosedWorld, compiler.options, indices) as List<int>;
  checkData(closedWorldData, newClosedWorldData);
  return newClosedWorld;
}

/// Tests that cloned inference results serialize to the same data.
///
/// Does 3 round trips to serialize/deserialize the provided data. The first
/// round normalizes the data as some information might be dropped in the
/// serialization/deserialization process. The second and third rounds are
/// compared for consistency.
GlobalTypeInferenceResults cloneInferenceResults(Compiler compiler,
    GlobalTypeInferenceResults results, SerializationStrategy strategy) {
  SerializationIndices indices = SerializationIndices(testMode: true);
  List<int> irData = strategy.unpackAndSerializeComponent(results);
  final closedWorldData = strategy.serializeClosedWorld(
      results.closedWorld, compiler.options, indices) as List<int>;
  ir.Component newComponent = strategy.deserializeComponent(irData);
  var newClosedWorld = strategy.deserializeClosedWorld(
      compiler.options,
      compiler.reporter,
      compiler.environment,
      compiler.abstractValueStrategy,
      newComponent,
      closedWorldData,
      indices);
  indices = SerializationIndices(testMode: true);
  final worldData = strategy.serializeGlobalTypeInferenceResults(
      results, compiler.options, indices) as List<int>;
  print('data size: ${worldData.length}');
  GlobalTypeInferenceResults initialResults =
      strategy.deserializeGlobalTypeInferenceResults(
          compiler.options,
          compiler.reporter,
          compiler.environment,
          compiler.abstractValueStrategy,
          newComponent,
          newClosedWorld,
          worldData,
          indices);
  indices = SerializationIndices(testMode: true);
  final initialWorldData = strategy.serializeGlobalTypeInferenceResults(
      initialResults, compiler.options, indices) as List<int>;
  GlobalTypeInferenceResults finalResults =
      strategy.deserializeGlobalTypeInferenceResults(
          compiler.options,
          compiler.reporter,
          compiler.environment,
          compiler.abstractValueStrategy,
          newComponent,
          newClosedWorld,
          worldData,
          indices);
  indices = SerializationIndices(testMode: true);
  final finalWorldData = strategy.serializeGlobalTypeInferenceResults(
      finalResults, compiler.options, indices) as List<int>;
  checkData(initialWorldData, finalWorldData);
  return finalResults;
}
