// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:wasm_builder/src/ir/ir.dart';
import 'package:wasm_builder/src/serialize/deserializer.dart';
import 'package:wasm_builder/src/serialize/printer.dart';

import 'util.dart';

void main(List<String> args) async {
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
    for (final dartFilename in listIrTests()) {
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
      final wasmFile = File(path.join(
          tempDir, path.setExtension(path.basename(dartFilename), '.wasm')));

      final (settings, compilerOptions) = parseSettings(dartCode);

      print('\nTesting $dartFilename');

      final result = await Process.run('/usr/bin/env', [
        'bash',
        'pkg/dart2wasm/tool/compile_benchmark',
        for (final option in compilerOptions) '--extra-compiler-option=$option',
        if (runFromSource) '--src',
        '--no-strip-wasm',
        '-o',
        wasmFile.path,
        dartFilename
      ]);
      if (result.exitCode != 0) {
        print('Compilation failed:');
        print('stdout:\n${result.stdout}');
        print('stderr:\n${result.stderr}\n');
        failTest();
        continue;
      }

      final deferredModulePrefix =
          '${path.withoutExtension(wasmFile.path)}_mod';
      final deferredModuleWasmFiles = wasmFile.parent
          .listSync()
          .whereType<File>()
          .where((fse) =>
              fse.path.endsWith('.wasm') &&
              fse.path.startsWith(deferredModulePrefix))
          .toList();

      for (final file in [wasmFile, ...deferredModuleWasmFiles]) {
        final module = parseModule(file.readAsBytesSync());
        final wat = module.printAsWat(settings: settings);
        final watFile = File(path.join(path.dirname(dartFilename),
            path.setExtension(path.basename(file.path), '.wat')));

        if (write) {
          print('-> Updated expectation file: ${watFile.path}');
          watFile.writeAsStringSync(wat);
          continue;
        }
        if (!watFile.existsSync()) {
          print('Expected "${watFile.path}" to exist.');
          failTest();
          continue;
        }

        final oldWat = watFile.readAsStringSync();
        if (oldWat != wat) {
          print('-> Expectation of ${path.basename(watFile.path)} mismatch: ');
          print('Expected:\n  ${oldWat.split('\n').join('\n  ')}');
          print('Actual:\n  ${wat.split('\n').join('\n  ')}');
          print('-> Run with `-w` to update expectation file.');
          failTest();
          continue;
        }
      }
    }
  });
}

final argParser = ArgParser()
  ..addFlag('help',
      abbr: 'h', defaultsTo: false, help: 'Prints available options.')
  ..addFlag('src', defaultsTo: false, help: 'Runs the compiler from source.')
  ..addOption('filter',
      abbr: 'f', help: 'Runs only tests that match the filter.')
  ..addFlag('write',
      abbr: 'w', defaultsTo: false, help: 'Writes new expectation files.');

Iterable<String> listIrTests() {
  return Directory('pkg/dart2wasm/test/ir_tests')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => path.endsWith('.dart'));
}

Module parseModule(Uint8List wasmBytes) {
  final deserializer = Deserializer(wasmBytes);
  return Module.deserialize(deserializer);
}

(ModulePrintSettings, List<String>) parseSettings(String dartCode) {
  const functionFilter = '// functionFilter=';
  const tableFilter = '// tableFilter=';
  const globalFilter = '// globalFilter=';
  const typeFilter = '// typeFilter=';
  const compilerOption = '// compilerOption=';

  final functionFilters = <RegExp>[];
  final tableFilters = <RegExp>[];
  final globalFilters = <RegExp>[];
  final typeFilters = <RegExp>[];
  final compilerOptions = <String>[];

  for (final line in dartCode.split('\n')) {
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
    for (final (prefix, list) in [
      (compilerOption, compilerOptions),
    ]) {
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
        scrubAbsoluteUris: true),
    compilerOptions
  );
}
