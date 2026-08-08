// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'util.dart';

final String testDir = path.join(
  path.dirname(Platform.script.toFilePath()),
  'mjs_format',
);
final String mainDart = path.join(testDir, 'main.dart');
final String es6GoldenPath = path.join(testDir, 'mjs_es6.mjs.golden');
final String noEs6GoldenPath = path.join(testDir, 'mjs_no_es6.mjs.golden');

Future<void> main(List<String> args) async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  final parser = ArgParser()
    ..addFlag('update-golden', abbr: 'g', negatable: false);
  final argsResult = parser.parse(args);
  final bool updateGolden = argsResult.flag('update-golden');

  await withTempDir((String tempDir) async {
    final es6WasmPath = path.join(tempDir, 'out_es6.wasm');
    final noEs6WasmPath = path.join(tempDir, 'out_no_es6.wasm');
    final es6MjsPath = path.join(tempDir, 'out_es6.mjs');
    final noEs6MjsPath = path.join(tempDir, 'out_no_es6.mjs');

    // Compile with default (ES6 modules enabled)
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '-O0',
      mainDart,
      es6WasmPath,
    ]);

    // Compile with --no-supports-es6-modules
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--no-supports-es6-modules',
      '-O0',
      mainDart,
      noEs6WasmPath,
    ]);

    final es6Mjs = await File(es6MjsPath).readAsString();
    final noEs6Mjs = await File(noEs6MjsPath).readAsString();

    final es6GoldenFile = File(es6GoldenPath);
    final noEs6GoldenFile = File(noEs6GoldenPath);

    if (updateGolden) {
      print('Updating golden files...');
      await es6GoldenFile.writeAsString(es6Mjs);
      await noEs6GoldenFile.writeAsString(noEs6Mjs);
      return;
    }

    Expect.isTrue(
      es6GoldenFile.existsSync(),
      'Expected golden file $es6GoldenPath to exist.',
    );
    Expect.isTrue(
      noEs6GoldenFile.existsSync(),
      'Expected golden file $noEs6GoldenPath to exist.',
    );

    final expectedEs6Mjs = await es6GoldenFile.readAsString();
    final expectedNoEs6Mjs = await noEs6GoldenFile.readAsString();

    Expect.equals(expectedEs6Mjs, es6Mjs);
    Expect.equals(expectedNoEs6Mjs, noEs6Mjs);

    _verifyMjsDifferences(es6Mjs, noEs6Mjs);
  });
}

void _verifyMjsDifferences(String es6Mjs, String noEs6Mjs) {
  Expect.isTrue(
    es6Mjs.contains('export async function compileStreaming('),
    'ES6 mjs should contain export async function compileStreaming',
  );
  Expect.isTrue(
    es6Mjs.contains('export async function compile('),
    'ES6 mjs should contain export async function compile',
  );
  Expect.isFalse(
    es6Mjs.startsWith('(function() {\nconst exportObject = {};'),
    'ES6 mjs should not start with IIFE wrapper',
  );

  Expect.isTrue(
    noEs6Mjs.startsWith('(function() {\nconst exportObject = {};'),
    'Non-ES6 mjs should start with IIFE wrapper',
  );
  Expect.isTrue(
    noEs6Mjs.endsWith('return exportObject;\n})'),
    'Non-ES6 mjs should end with IIFE wrapper closing',
  );
  Expect.isTrue(
    noEs6Mjs.contains(
      'exportObject.compileStreaming = async function compileStreaming(',
    ),
    'Non-ES6 mjs should assign compileStreaming to exportObject',
  );
  Expect.isTrue(
    noEs6Mjs.contains('exportObject.compile = async function compile('),
    'Non-ES6 mjs should assign compile to exportObject',
  );
}
