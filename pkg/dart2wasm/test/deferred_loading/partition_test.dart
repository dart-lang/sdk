// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:compiler/src/deferred_load/program_split_constraints/nodes.dart';
import 'package:compiler/src/deferred_load/program_split_constraints/parser.dart';
import 'package:dart2wasm/deferred_load/partition.dart';
import 'package:dart2wasm/deferred_loading.dart';
import 'package:dart2wasm/modules.dart';
import 'package:dart2wasm/util.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/core_types.dart';

import '../util.dart';

final sdkRootUri = Uri.base;
final sdkRoot = Directory.current.path;
const updateExpectations = bool.fromEnvironment('updateExpectations');

void main() async {
  await runDart2wasmTests();
  await runDart2jsCustomSplitTests();
}

Future runDart2wasmTests() async {
  final outputDataDir = Directory(
      '$sdkRoot/pkg/dart2wasm/test/deferred_loading/partition_tests/');
  final tests = outputDataDir
      .listSync()
      .where((fse) => fse is File && fse.path.endsWith('.dart'))
      .toList();
  for (final mainFile in tests) {
    final mainFilePath = mainFile.path;
    final defaultSplitExpectationFile =
        '${mainFilePath.substring(0, mainFilePath.length - '.dart'.length)}.default.txt';

    // Test without constraints.
    await testPartitionExpectation(
        mainFilePath, null, defaultSplitExpectationFile);
  }
}

Future runDart2jsCustomSplitTests() async {
  final outputDataDir = Directory(
      '$sdkRoot/pkg/dart2wasm/test/deferred_loading/partition_tests_dart2js/custom_split');
  await forEachDart2JsCustomSplitTest(
      (testName, testDir, mainFile, constraintsFile) async {
    // Load constraints data.
    final constraintsJsonString = replaceDart2JsTestUris(
        File('$testDir/constraints.json').readAsStringSync(), testDir);
    final constraints = Parser().read(constraintsJsonString);

    // Test with constraints.
    await testPartitionExpectation(mainFile, constraints,
        '${outputDataDir.path}/$testName.constraints.txt');

    // Test without constraints.
    await testPartitionExpectation(
        mainFile, null, '${outputDataDir.path}/$testName.default.txt');
  });
}

Future testPartitionExpectation(String mainFile, ConstraintData? constraints,
    String expectationFilepath) async {
  print('\nTesting $mainFile against $expectationFilepath');
  await withTempDir((tempDir) async {
    final outDill = '$tempDir/out.dill';

    final result = await Process.run('/usr/bin/env', [
      'bash',
      'pkg/dart2wasm/tool/compile_benchmark',
      '--phases=cfe,tfa',
      '--enable-deferred-loading',
      '-o',
      outDill,
      mainFile,
    ]);

    if (result.exitCode != 0) {
      io.exitCode = 42;
      print('Failed to compile $mainFile:');
      print('stdout:\n${result.stdout}');
      print('stderr:\n${result.stderr}');
      return;
    }

    final (component, coreTypes) = readKernel(outDill);
    final loadingMap = DeferredModuleLoadingMap.fromComponent(component);
    component.accept(DeferredLoadingLowering(coreTypes, loadingMap));

    final partition = partitionAppplication(
        coreTypes, component, loadingMap, findWasmRoots(coreTypes, component),
        constraints: constraints);

    final actual = partition.toText(sdkRootUri, includeRoot: false);
    final expectationFile = File(expectationFilepath);
    if (!expectationFile.existsSync() ||
        actual != expectationFile.readAsStringSync()) {
      if (updateExpectations) {
        print('Updating expectation file: $expectationFilepath');
        expectationFile.parent.createSync(recursive: true);
        expectationFile.writeAsStringSync(actual);
      } else {
        io.exitCode = 42;
        if (!expectationFile.existsSync()) {
          print('Expectation file is missing.');
        } else {
          final expectation = expectationFile.readAsStringSync();
          print('Expectation file mismatch:.');
          print('Expected:\n$expectation');
          print('Actual:\n$actual');
        }
      }
    }
  });
}

Future forEachDart2JsCustomSplitTest(
    Future Function(String testName, String testDir, String mainFile,
            String constraintsFile)
        fun) async {
  final dataDir = Directory('$sdkRoot/pkg/compiler/test/custom_split/data');
  final testCases = dataDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  final outputDataDir = Directory(
      '$sdkRoot/pkg/dart2wasm/test/deferred_loading/partition_test_data');
  if (!outputDataDir.existsSync()) {
    outputDataDir.createSync(recursive: true);
  }

  for (final testName in testCases) {
    final testDir = sdkRootUri
        .resolve('pkg/compiler/test/custom_split/data/$testName')
        .toFilePath();
    final constraintsFile = File('$testDir/constraints.json');
    final mainFile = File('$testDir/main.dart');
    await fun(testName, testDir, mainFile.path, constraintsFile.path);
  }
}

/// The dart2js constraint data has `memory:*` uris in them, replace them with
/// actual file uris.
///
/// The `memory:sdk/tests/web/native/main.dart` is faking the actual main.
String replaceDart2JsTestUris(String constraintsJsonString, String testDir) {
  Object updateJson(Object o) {
    if (o is Map) {
      o.updateAll((key, value) => updateJson(value));
      return o;
    }
    if (o is List) {
      for (int i = 0; i < o.length; ++i) {
        o[i] = updateJson(o[i]);
      }
      return o;
    }
    if (o is String) {
      final needle = 'memory:sdk/tests/web/native/';
      if (o.startsWith(needle)) {
        return sdkRootUri
            .resolve('$testDir/${o.substring(needle.length)}')
            .toString();
      }
      if (o.startsWith('memory:/')) {
        return sdkRootUri.resolve(o.substring('memory:/'.length)).toString();
      }
      return o;
    }
    return o;
  }

  final data = json.decode(constraintsJsonString);
  updateJson(data);
  return json.encode(data);
}

(Component, CoreTypes) readKernel(String dillFilepath) {
  final component = createEmptyComponent();
  BinaryBuilderWithMetadata(File(dillFilepath).readAsBytesSync())
      .readComponent(component);
  return (component, CoreTypes(component));
}
