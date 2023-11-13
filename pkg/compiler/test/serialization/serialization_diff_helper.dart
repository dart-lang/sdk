// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/expect.dart';

const int numShards = 4;
const List<String> dataDirs = ['data', '../inference/data'];
const Set<String> needsLibs = {'deferred.dart'};

const jsOutFilename = 'out.js';
const sourceMapFilename = '${jsOutFilename}.map';
const dumpInfoFilename = 'out.info.json';

typedef CompiledOutput = Map<api.OutputType, Map<String, String>>;

Future<CompiledOutput> compileWithSerialization(
    {Uri? entryPoint,
    required Map<String, dynamic> memorySourceFiles,
    required List<String> options}) async {
  final cfeDillUri = 'memory:cfe.dill';
  final worldDillUri = 'memory:out.dill';
  final closedWorldUri = 'memory:world.data';
  final globalDataUri = 'memory:global.data';
  final codegenUri = 'memory:codegen';
  final jsOutUri = 'memory:$jsOutFilename';
  Future<CompiledOutput> compile(List<String> options) async {
    final outputProvider = OutputCollector();
    CompilationResult result = await runCompiler(
        entryPoint: entryPoint,
        memorySourceFiles: memorySourceFiles,
        outputProvider: outputProvider,
        unsafeToTouchSourceFiles: true,
        options: options);
    Expect.isTrue(result.isSuccess);
    outputProvider.binaryOutputMap.forEach((fileName, binarySink) {
      memorySourceFiles[fileName.path] = binarySink.list;
    });
    return outputProvider.clear();
  }

  await compile([...options, '--out=$cfeDillUri', Flags.cfeOnly]);
  await compile([
    ...options,
    '--out=$worldDillUri',
    '${Flags.inputDill}=$cfeDillUri',
    '${Flags.writeClosedWorld}=$closedWorldUri'
  ]);
  await compile([
    ...options,
    '${Flags.inputDill}=$worldDillUri',
    '${Flags.readClosedWorld}=$closedWorldUri',
    '${Flags.writeData}=$globalDataUri'
  ]);
  await compile([
    ...options,
    '${Flags.inputDill}=$worldDillUri',
    '${Flags.readClosedWorld}=$closedWorldUri',
    '${Flags.readData}=$globalDataUri',
    '${Flags.writeCodegen}=$codegenUri',
    '${Flags.codegenShards}=2',
    '${Flags.codegenShard}=0',
  ]);
  await compile([
    ...options,
    '${Flags.inputDill}=$worldDillUri',
    '${Flags.readClosedWorld}=$closedWorldUri',
    '${Flags.readData}=$globalDataUri',
    '${Flags.writeCodegen}=$codegenUri',
    '${Flags.codegenShards}=2',
    '${Flags.codegenShard}=1',
  ]);
  final output = await compile([
    ...options,
    '${Flags.inputDill}=$worldDillUri',
    '${Flags.readClosedWorld}=$closedWorldUri',
    '${Flags.readData}=$globalDataUri',
    '${Flags.readCodegen}=$codegenUri',
    '${Flags.codegenShards}=2',
    '--out=$jsOutUri'
  ]);
  return output;
}

Future<CompiledOutput> compileWithoutSerialization(
    {Uri? entryPoint,
    required Map<String, dynamic> memorySourceFiles,
    required List<String> options}) async {
  final jsOutUri = 'memory:$jsOutFilename';
  final outputProvider = OutputCollector();

  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      unsafeToTouchSourceFiles: true,
      outputProvider: outputProvider,
      options: [...options, '--out=$jsOutUri']);
  Expect.isTrue(result.isSuccess);

  return outputProvider.clear();
}

// TODO(natebiggs): Check dump info diff when the results are aligned with and
//   without serialization.
Set<api.OutputType> _outputTypesToIgnore = {api.OutputType.dumpInfo};

Future<void> compareResults(CompiledOutput serializationResult,
    CompiledOutput noSerializationResult) async {
  serializationResult.forEach((outputType, outputs) {
    if (_outputTypesToIgnore.contains(outputType)) return;
    Expect.isTrue(noSerializationResult.containsKey(outputType));
    final otherOutputs = noSerializationResult[outputType]!;
    Expect.mapEquals(outputs, otherOutputs);
  });
}

Future runTests(List<String> args, int shard) async {
  assert(shard >= 0 && shard < numShards,
      'Shard must be between 0 and ${numShards - 1} (inclusive)');

  final libDirectory = Directory.fromUri(Platform.script.resolve('libs'));

  final testFiles = dataDirs
      .map((e) => Directory.fromUri(Platform.script.resolve('data')))
      .expand((dataDir) => dataDir.listSync());
  int i = 0;
  for (final testFile in testFiles) {
    if (!testFile.uri.pathSegments.last.endsWith('.dart')) continue;
    if (i++ % numShards != shard) continue;

    String name = testFile.uri.pathSegments.last;
    List<String> testOptions = [Flags.dumpInfo];
    print('----------------------------------------------------------------');
    print('Test file: ${testFile.uri}');
    String mainCode = await File.fromUri(testFile.uri).readAsString();
    final mainUri = _createUri('src/main.dart');
    Map<String, dynamic> memorySourceFiles = {mainUri.path: mainCode};

    if (needsLibs.contains(name)) {
      print('Supporting libraries:');
      String filePrefix = name.substring(0, name.lastIndexOf('.'));
      await for (final libFile in libDirectory.list()) {
        String libFileName = libFile.uri.pathSegments.last;
        if (libFileName.startsWith(filePrefix)) {
          print('    - libs/$libFileName');
          Uri libFileUri = _createUri('libs/$libFileName');
          String libCode = await File.fromUri(libFile.uri).readAsString();
          memorySourceFiles[libFileUri.path] = libCode;
        }
      }
    }

    final serializationResult = await compileWithSerialization(
        entryPoint: mainUri,
        memorySourceFiles: memorySourceFiles,
        options: testOptions);
    final noSerializationResult = await compileWithoutSerialization(
        entryPoint: mainUri,
        memorySourceFiles: memorySourceFiles,
        options: testOptions);

    await compareResults(serializationResult, noSerializationResult);
  }
}

// Pretend this is a dart2js_native test to allow use of 'native' keyword
// and import of private libraries.
Uri _createUri(String fileName) {
  return Uri.parse('memory:sdk/tests/web/native/$fileName');
}
