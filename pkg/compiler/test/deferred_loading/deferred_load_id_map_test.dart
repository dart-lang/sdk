// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide Link;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_api.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/expect.dart';

const resultFilename = 'deferred.data';
const cfeFilename = 'cfe.dill';

Future<void> runTest(String testGroup, List<String> options,
    {required bool generateGoldens}) async {
  Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
  Directory goldensDir = Directory.fromUri(
      Platform.script.resolve('load_id_map_goldens/').resolve(testGroup));
  final goldenFiles = goldensDir.listSync();
  for (final testDir in dataDir.listSync()) {
    if (testDir is! Directory) continue;
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
          '--stage=cfe',
          '--out=$cfeFilename',
          '${Flags.noSoundNullSafety}',
          ...options,
        ],
        outputProvider: cfeCollector,
        beforeRun: (c) => compiler = c,
        unsafeToTouchSourceFiles: true);
    final cfeDill = cfeCollector.binaryOutputMap.values.first.list;
    final dillInputFiles = {cfeFilename: cfeDill};
    final resultCollector = OutputCollector();
    final compilerResult = await runCompiler(
        memorySourceFiles: dillInputFiles,
        outputProvider: resultCollector,
        options: [
          '${Flags.deferredLoadIdMapUri}=$resultFilename',
          '--input-dill=memory:$cfeFilename',
          '${Flags.noSoundNullSafety}',
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

main(List<String> args) {
  final generateGoldens = args.contains('-g');
  asyncTest(() async {
    await runTest('simple_ids', [Flags.useSimpleLoadIds],
        generateGoldens: generateGoldens);
  });
  asyncTest(() async {
    await runTest('base', const [], generateGoldens: generateGoldens);
  });
}
