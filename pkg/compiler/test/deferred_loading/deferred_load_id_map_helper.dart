// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide Link;
import 'dart:typed_data';

import 'package:compiler/compiler_api.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

const resultFilename = 'deferred.data';
const cfeFilename = 'cfe.dill';

const shardCount = 3;

void mainHelper(
    String testGroup, int shard, List<String> flags, List<String> args) {
  if (shard < 0 || shard > shardCount) throw 'Invalid shard $shard.';
  final generateGoldens = args.contains('-g');
  asyncTest(() async {
    await runTest(testGroup, shard, flags, generateGoldens: generateGoldens);
  });
}

Future<void> runTest(String testGroup, int shard, List<String> options,
    {required bool generateGoldens}) async {
  Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
  Directory goldensDir = Directory.fromUri(
      Platform.script.resolve('load_id_map_goldens/').resolve(testGroup));
  final goldenFiles = goldensDir.listSync();
  int counter = 0;
  for (final testDir in dataDir.listSync()) {
    if (testDir is! Directory) continue;
    if (counter++ % shardCount != shard) continue;
    final testName = testDir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    print('-- Testing deferred load id map for: $testName ($testGroup) --');
    late Compiler compiler;
    final testFiles = testDir.listSync();
    final sourceFiles = <String, String>{};
    for (final testFile in testFiles) {
      sourceFiles[testFile.uri.pathSegments.last] =
          await (testFile as File).readAsString();
    }
    final cfeCollector = OutputCollector();
    await runCompiler(
        memorySourceFiles: sourceFiles,
        options: [
          '${Flags.stage}=cfe',
          '--out=$cfeFilename',
          ...options,
        ],
        outputProvider: cfeCollector,
        beforeRun: (c) => compiler = c);
    final cfeDill =
        Uint8List.fromList(cfeCollector.binaryOutputMap.values.first.list);
    final dillInputFiles = {cfeFilename: cfeDill};
    final resultCollector = OutputCollector();
    final compilerResult = await runCompiler(
        memorySourceFiles: dillInputFiles,
        outputProvider: resultCollector,
        options: [
          '${Flags.stage}=deferred-load-ids',
          '${Flags.deferredLoadIdMapUri}=$resultFilename',
          '${Flags.stage}=deferred-load-ids',
          '--input-dill=memory:$cfeFilename',
          ...options,
        ],
        beforeRun: (c) => compiler = c);
    Expect.isTrue(compilerResult.isSuccess);
    Expect.isNull(compiler.globalInference.resultsForTesting);
    final result =
        resultCollector.getOutput(resultFilename, OutputType.deferredLoadIds);
    Expect.isNotNull(result);

    final goldenUri = goldensDir.uri.resolve('$testName.golden');
    if (generateGoldens) {
      File.fromUri(goldenUri).writeAsString(result.toString());
      print('-- Updated golden for: $testName ($testGroup) --');
    } else {
      final expectedOutput = await (goldenFiles
              .firstWhere((e) => e.path == goldenUri.path) as File)
          .readAsString();
      Expect.equals(expectedOutput, result.toString());
    }
  }
}
