// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:dart2wasm/cfg/ir_log.dart';
import 'package:path/path.dart' as path;

import 'package:wasm_builder/source_map.dart'
    show DebugInfoDeserializer, SourceMapDecoder;
import 'package:wasm_builder/src/ir/ir.dart';
import 'package:wasm_builder/src/serialize/deserializer.dart';
import 'package:wasm_builder/src/serialize/printer.dart';

import 'util.dart';

void main(List<String> args) async {
  await runIrTestSuite(
    args,
    testDirectory: 'pkg/dart2wasm/test/ir_tests',
    watExtension: '.wat',
  );
}

Future<void> runIrTestSuite(
  List<String> args, {
  required String testDirectory,
  required String watExtension,
  bool isCfgTest = false,
}) async {
  final result = argParser.parse(args);
  final help = result.flag('help');
  final write = result.flag('write');
  final runFromSource = result.flag('src');
  final filter = result.option('filter');

  if (help) {
    print('Usage:\n${argParser.usage}');
    io.exit(0);
  }
  if (result.rest.isNotEmpty) {
    print('Unknown arguments: ${result.rest.join(' ')}');
    print('Usage:\n${argParser.usage}');
    io.exit(1);
  }

  final filterRegExp = filter != null ? RegExp(filter) : null;

  await withTempDir((String tempDir) async {
    for (final dartFilename in listTests(testDirectory)) {
      // Ignore helper files (e.g. tests may use deferred modules which requires
      // multiple dart files to test).
      if (dartFilename.contains('.h.')) {
        continue;
      }

      if (filterRegExp != null && !filterRegExp.hasMatch(dartFilename)) {
        continue;
      }

      void failTest() {
        print('-> test "$dartFilename" failed\n');
        io.exitCode = 254;
      }

      final dartCode = File(dartFilename).readAsStringSync();
      final baseName = path.basenameWithoutExtension(dartFilename);
      final wasmFile = File(path.join(tempDir, '$baseName.wasm'));
      final cfgTxtTempFile = File(path.join(tempDir, '$baseName.cfg.txt'));

      List<String>? cfgLines;
      final (settings, compilerOptions) = parseSettings(
        dartCode,
        isCfgTest: isCfgTest,
        cfgLinesProvider: () => cfgLines,
      );
      final hasOptLevel = compilerOptions.any(
        (opt) => opt.startsWith('-O') || opt.startsWith('--optimization-level'),
      );

      print('\nTesting $dartFilename');

      final result = await Process.run('/usr/bin/env', [
        'bash',
        'pkg/dart2wasm/tool/compile_benchmark',
        if (isCfgTest) ...[
          '--extra-compiler-option=--cfg',
          '--extra-compiler-option=--dump-cfg=${cfgTxtTempFile.path}',
          if (!hasOptLevel) '--extra-compiler-option=-O0',
        ],
        '--extra-compiler-option=--unique-types',
        '--no-strip-toolchain-annotations',
        '--extra-compiler-option=--no-unique-constant-names',
        '--extra-compiler-option=--enable-experimental-wasm-interop',
        // Minify interop names so that the names of these entities are more
        // stable against SDK and compiler changes.
        '--extra-compiler-option=--minify-interop-names',
        '--no-strip-wasm',
        for (final option in compilerOptions)
          if (option == '--standalone')
            '--standalone'
          else
            '--extra-compiler-option=$option',
        if (runFromSource) '--src',
        '-o',
        wasmFile.path,
        dartFilename,
      ]);
      if (result.exitCode != 0) {
        print('Compilation failed:');
        print('stdout:\n${result.stdout}');
        print('stderr:\n${result.stderr}\n');
        failTest();
        continue;
      }

      if (isCfgTest) {
        final actualCfgTxt = cfgTxtTempFile.readAsStringSync();
        cfgLines = actualCfgTxt.split('\n');
        final cfgTxtFile = File(
          path.join(path.dirname(dartFilename), '$baseName.cfg.txt'),
        );
        if (!checkExpectationFile(
          file: cfgTxtFile,
          actual: actualCfgTxt,
          write: write,
          failTest: failTest,
        )) {
          continue;
        }
      }

      final deferredModulePrefix =
          '${path.withoutExtension(wasmFile.path)}_mod';
      final deferredModuleWasmFiles = wasmFile.parent
          .listSync()
          .whereType<File>()
          .where(
            (fse) =>
                fse.path.endsWith('.wasm') &&
                fse.path.startsWith(deferredModulePrefix),
          )
          .toList();

      for (final file in [wasmFile, ...deferredModuleWasmFiles]) {
        DebugInfoDeserializer? debugInfoDeserializer;
        if (settings.printSourcePositions) {
          final mapFile = File('${file.path}.map');
          if (mapFile.existsSync()) {
            final mapJson = jsonDecode(mapFile.readAsStringSync());
            debugInfoDeserializer = SourceMapDecoder.fromJson(mapJson);
          }
        }
        final module = parseModule(
          file.readAsBytesSync(),
          debugInfoDeserializer,
        );
        final wat = module.printAsWat(settings: settings);
        final watFile = File(
          path.join(
            path.dirname(dartFilename),
            path.setExtension(path.basename(file.path), watExtension),
          ),
        );

        checkExpectationFile(
          file: watFile,
          actual: wat,
          write: write,
          failTest: failTest,
        );
      }
    }
  });
}

final argParser = ArgParser()
  ..addFlag(
    'help',
    abbr: 'h',
    defaultsTo: false,
    help: 'Prints available options.',
  )
  ..addFlag('src', defaultsTo: false, help: 'Runs the compiler from source.')
  ..addOption(
    'filter',
    abbr: 'f',
    help: 'Runs only tests that match the filter.',
  )
  ..addFlag(
    'write',
    abbr: 'w',
    defaultsTo: false,
    help: 'Writes new expectation files.',
  );

Iterable<String> listTests(String testDirectory) {
  final dir = Directory(testDirectory);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => path.endsWith('.dart'));
}

Module parseModule(
  Uint8List wasmBytes, [
  DebugInfoDeserializer? debugInfoDeserializer,
]) {
  final deserializer = Deserializer(wasmBytes);
  return Module.deserialize(
    deserializer,
    debugInfoDeserializer: debugInfoDeserializer,
  );
}

(ModulePrintSettings, List<String>) parseSettings(
  String dartCode, {
  required bool isCfgTest,
  List<String>? Function()? cfgLinesProvider,
}) {
  const functionFilter = '// functionFilter=';
  const tableFilter = '// tableFilter=';
  const globalFilter = '// globalFilter=';
  const typeFilter = '// typeFilter=';
  const compilerOption = '// compilerOption=';
  const printSourcePositionsPrefix = '// printSourcePositions';
  const noPrintSourcePositionsPrefix = '// noPrintSourcePositions';

  final functionFilters = <RegExp>[];
  final tableFilters = <RegExp>[];
  final globalFilters = <RegExp>[];
  final typeFilters = <RegExp>[];
  final compilerOptions = <String>[];
  bool printSourcePositions = isCfgTest;

  for (final line in dartCode.split('\n')) {
    if (line.startsWith(printSourcePositionsPrefix)) {
      printSourcePositions = true;
    } else if (line.startsWith(noPrintSourcePositionsPrefix)) {
      printSourcePositions = false;
    }
    for (final (prefix, regexpList) in [
      (functionFilter, functionFilters),
      (tableFilter, tableFilters),
      (globalFilter, globalFilters),
      (typeFilter, typeFilters),
    ]) {
      if (line.startsWith(prefix)) {
        final value = line.substring(prefix.length).trim();
        if (value.isNotEmpty) {
          regexpList.add(RegExp(value));
        }
      }
    }
    for (final (prefix, list) in [(compilerOption, compilerOptions)]) {
      if (line.startsWith(prefix)) {
        final value = line.substring(prefix.length).trim();
        if (value.isNotEmpty) {
          list.add(value);
        }
      }
    }
  }
  return (
    ModulePrintSettings(
      functionFilters: functionFilters,
      tableFilters: tableFilters,
      globalFilters: globalFilters,
      typeFilters: typeFilters,
      preferMultiline: true,
      scrubAbsoluteUris: true,
      printInSortedOrder: true,
      printSourcePositions: printSourcePositions,
      printUrl: !isCfgTest,
      sourceFileProvider: (uri) {
        if (uri == CfgLog.defaultUri) return cfgLinesProvider?.call();
        if (!uri.isScheme('file')) return null;
        final file = File(uri.toFilePath());
        return file.existsSync() ? file.readAsLinesSync() : null;
      },
    ),
    compilerOptions,
  );
}

bool checkExpectationFile({
  required File file,
  required String actual,
  required bool write,
  required void Function() failTest,
}) {
  if (write) {
    print('-> Updated expectation file: ${file.path}');
    file.writeAsStringSync(actual);
    return true;
  }
  if (!file.existsSync()) {
    print('Expected "${file.path}" to exist.');
    failTest();
    return false;
  }

  final expected = file.readAsStringSync();
  if (expected != actual) {
    print('-> Expectation of ${path.basename(file.path)} mismatch: ');
    print('Expected:\n  ${expected.split('\n').join('\n  ')}');
    print('Actual:\n  ${actual.split('\n').join('\n  ')}');
    print('-> Run with `-w` to update expectation file.');
    failTest();
    return false;
  }
  return true;
}
