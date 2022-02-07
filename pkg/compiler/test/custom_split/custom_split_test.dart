// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io' hide Link;
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;

import '../equivalence/id_equivalence_helper.dart';
import '../deferred_loading/deferred_loading_test_helper.dart';

///  Add in options to pass to the compiler like
/// `Flags.disableTypeInference` or `Flags.disableInlining`
const List<String> compilerOptions = const [];

const List<String> tests = [
  'diamond',
  'diamond_and',
  'diamond_fuse',
  'diamond_or',
  'fuse_with_and',
  'fuse_with_or',
  'two_step',
  'two_branch',
];

Map<String, List<String>> createPerTestOptions() {
  Map<String, List<String>> perTestOptions = {};
  for (var test in tests) {
    Uri constraints = Platform.script.resolve('data/$test/constraints.json');
    perTestOptions['$test'] = ['--read-program-split=$constraints'];
  }
  return perTestOptions;
}

/// Returns a list of the deferred imports in a component where each import
/// becomes a string of 'uri#prefix'.
List<String> getDeferredImports(ir.Component component) {
  List<String> imports = [];
  for (var library in component.libraries) {
    for (var import in library.dependencies) {
      if (import.isDeferred) {
        imports.add('${library.importUri}#${import.name}');
      }
    }
  }
  imports.sort();
  return imports;
}

/// A helper function which performs the following steps:
/// 1) Get deferred imports from a given [component]
/// 2) Spawns the supplied [constraintsUri] in its own isolate
/// 3) Passes deferred imports via a port to the spawned isolate
/// 4) Listens for a json string from the spawned isolated and returns the
///    results as a a [Future<String>].
Future<String> constraintsToJson(
    ir.Component component, Uri constraintsUri) async {
  var imports = getDeferredImports(component);
  SendPort sendPort;
  var receivePort = ReceivePort();
  var isolate = await Isolate.spawnUri(constraintsUri, [], receivePort.sendPort,
      paused: true);
  isolate.addOnExitListener(receivePort.sendPort);
  isolate.resume(isolate.pauseCapability);
  String json;
  await for (var msg in receivePort) {
    if (msg == null) {
      receivePort.close();
    } else if (sendPort == null) {
      sendPort = msg;
      sendPort.send(imports);
    } else if (json == null) {
      json = msg;
    } else {
      throw 'Unexpected message $msg';
    }
  }
  return json;
}

Uri getFileInTestFolder(String test, String file) =>
    Platform.script.resolve('data/$test/$file');

Future<String> compileConstraintsToJson(String test, Compiler compiler) async {
  var constraints = getFileInTestFolder(test, 'constraints.dart');
  var component = compiler.componentForTesting;
  return constraintsToJson(component, constraints);
}

File getConstraintsJsonFile(String test) {
  var constraintsJsonUri = getFileInTestFolder(test, 'constraints.json');
  return File(constraintsJsonUri.toFilePath());
}

/// Verifies the programmatic API produces the expected JSON.
Future<void> verifyCompiler(String test, Compiler compiler) async {
  var json = await compileConstraintsToJson(test, compiler);
  Expect.equals(getConstraintsJsonFile(test).readAsStringSync(), json);
}

/// Generates constraint JSON.
Future<void> generateJSON(String test, Compiler compiler) async {
  var json = await compileConstraintsToJson(test, compiler);
  getConstraintsJsonFile(test).writeAsStringSync(json);
}

/// Compute the [OutputUnit]s for all source files involved in the test, and
/// ensure that the compiler is correctly calculating what is used and what is
/// not. We expect all test entry points to be in the `data` directory and any
/// or all supporting libraries to be in the `libs` folder, starting with the
/// same name as the original file in `data`.
main(List<String> args) {
  bool generateGoldens = args.contains('-g');
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const OutputUnitDataComputer(),
        options: compilerOptions,
        perTestOptions: createPerTestOptions(),
        args: args, setUpFunction: () {
      importPrefixes.clear();
    },
        testedConfigs: allSpecConfigs,
        verifyCompiler: generateGoldens ? generateJSON : verifyCompiler);
  });
}
