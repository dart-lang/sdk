// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import '../util.dart';

const String helperJsLoadIdLookupToken = 'LOAD_ID_LOOKUP';
const String helperJsModuleDirToken = 'MODULE_DIR';

final String goldenPath =
    '${path.dirname(Platform.script.path)}/data/deferred_load_ids.golden.json';
final String mainDart = '${path.dirname(Platform.script.path)}/data/main.dart';
final String helperJs = '${path.dirname(Platform.script.path)}/helper.js';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('update-golden', abbr: 'g', negatable: false);

  final argsResult = parser.parse(args);

  await withTempDir((tmpDirPath) async {
    final tmpDir = File(tmpDirPath);
    final loadIdsUri = tmpDir.uri.resolve('deferred_load_ids.json');
    final outFilename = '${tmpDir.path}/out.wasm';
    // Compile the test
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      mainDart,
      '--platform=$platformDill',
      '--enable-deferred-loading',
      '--load-ids=$loadIdsUri',
      outFilename,
    ]);

    final loadIdsContent = await File.fromUri(loadIdsUri).readAsString();
    final goldenFile = File(goldenPath);

    if (argsResult.flag('update-golden')) {
      print('Updating golden:\n$loadIdsContent');
      await goldenFile.writeAsString(loadIdsContent);
      return;
    }

    // Ensure the load IDs JSON matches the golden.
    Expect.equals(await goldenFile.readAsString(), loadIdsContent);

    // Extract a map from each load ID to its corresponding module.
    final loadIdToModules = <String, List<String>>{};
    final json = const JsonDecoder().convert(loadIdsContent);
    (json as Map).forEach((_, info) {
      ((info as Map)['imports'] as Map).forEach((loadId, modules) {
        loadIdToModules[loadId] = (modules as List).cast<String>();
      });
    });

    // Fill in the helper JS file with the module mapping.
    final loadIdLookup = const JsonEncoder().convert(loadIdToModules);
    final helpersTemplate = await File(helperJs).readAsString();
    final populatedHelperJs = helpersTemplate
        .replaceAll(helperJsLoadIdLookupToken, loadIdLookup)
        .replaceAll(helperJsModuleDirToken, tmpDir.path);

    final helperFile = File.fromUri(tmpDir.uri.resolve('helper.js'));
    await helperFile.writeAsString(populatedHelperJs);

    // Load the helper JS and run the compiled code
    await run(
        ['pkg/dart2wasm/tool/run_benchmark', helperFile.path, outFilename]);
  });
}
