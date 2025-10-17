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
      if (filterRegExp != null && !filterRegExp.hasMatch(dartFilename)) {
        continue;
      }

      void failTest() {
        print('-> test "$dartFilename" failed\n');
        io.exitCode = 254;
      }

      final dartCode = File(dartFilename).readAsStringSync();
      final watFile = File(path.setExtension(dartFilename, '.wat'));
      final wasmFile = File(path.join(
          tempDir, path.setExtension(path.basename(dartFilename), '.wasm')));

      print('\nTesting $dartFilename');

      final result = await Process.run('/usr/bin/env', [
        'bash',
        'pkg/dart2wasm/tool/compile_benchmark',
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

      final wasmBytes = wasmFile.readAsBytesSync();
      final wat =
          moduleToString(parseModule(wasmBytes), parseNameFilters(dartCode));
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
        print(
            '-> Expectation mismatch. Run with `-w` to update expectation file.');
        failTest();
        continue;
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

String moduleToString(Module module, List<RegExp> functionNameFilters) {
  bool printFunctionBody(BaseFunction function) {
    final name = function.functionName;
    if (name == null) return false;
    return functionNameFilters.any((pattern) => name.contains(pattern));
  }

  final mp = ModulePrinter(module, printFunctionBody: printFunctionBody);
  for (final function in module.functions.defined) {
    if (printFunctionBody(function)) {
      mp.enqueueFunction(function);
    }
  }
  return mp.print();
}

List<RegExp> parseNameFilters(String dartCode) {
  const functionFilter = '// functionFilter=';
  final filters = <RegExp>[];
  for (final line in dartCode.split('\n')) {
    if (line.startsWith(functionFilter)) {
      final filter = line.substring(functionFilter.length).trim();
      if (filter.isNotEmpty) {
        filters.add(RegExp(filter));
      }
    }
  }
  return filters;
}
