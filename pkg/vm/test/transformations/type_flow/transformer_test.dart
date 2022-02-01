// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:front_end/src/api_unstable/vm.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;

import '../../common_test_utils.dart';

final Uri pkgVmDir = Platform.script.resolve('../../..');

runTestCase(
    Uri source, bool enableNullSafety, List<Uri>? linkedDependencies) async {
  final target =
      new TestingVmTarget(new TargetFlags(enableNullSafety: enableNullSafety));
  Component component = await compileTestCaseToKernelProgram(source,
      target: target, linkedDependencies: linkedDependencies);

  final coreTypes = new CoreTypes(component);

  component = transformComponent(target, coreTypes, component,
      matcher: new ConstantPragmaAnnotationParser(coreTypes, target),
      treeShakeProtobufs: true);

  String actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);

  Set<Library> dependencies = {};

  // Tests in /protobuf_handler consist of multiple libraries.
  // Include libraries with protobuf generated messages into the result.
  if (source.toString().contains('/protobuf_handler/')) {
    for (var lib in component.libraries) {
      if (lib.importUri
          .toString()
          .contains('/protobuf_handler/lib/generated/')) {
        dependencies.add(lib);
      }
    }
  }
  for (var lib in component.libraries) {
    if (lib.fileUri.path.endsWith('.lib.dart')) {
      dependencies.add(lib);
    }
  }

  if (dependencies.isNotEmpty) {
    for (var lib in dependencies) {
      lib.name ??= lib.importUri.pathSegments.last;
      actual += kernelLibraryToString(lib);
    }
    // Remove library paths.
    actual = actual.replaceAll(pkgVmDir.toString(), 'file:pkg/vm/');
  }

  compareResultWithExpectationsFile(source, actual);

  ensureKernelCanBeSerializedToBinary(component);
}

String? argsTestName(List<String> args) {
  if (args.length > 0) {
    return args.last;
  }
  return null;
}

class TestOptions {
  /// List of libraries the should be precompiled to .dill before compiling the
  /// main library from source.
  static const Option<List<String>?> linked =
      Option('--linked', StringListValue());

  /// If set, the test should be compiled with sound null safety.
  static const Option<bool> nnbdStrong =
      Option('--nnbd-strong', BoolValue(false));

  static const List<Option> options = [linked, nnbdStrong];
}

main(List<String> args) {
  final testNameFilter = argsTestName(args);

  group('transform-component', () {
    final testCasesDir = new Directory.fromUri(
        pkgVmDir.resolve('testcases/transformations/type_flow/transformer/'));

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      final path = entry.path;
      if (path.endsWith('.dart') &&
          !path.endsWith('.pb.dart') &&
          !path.endsWith('.lib.dart')) {
        String name = entry.uri.pathSegments.last;
        if (testNameFilter != null && !path.contains(testNameFilter)) {
          print('Skipping ${name}');
          continue;
        }
        List<Uri>? linkDependencies;
        bool enableNullSafety = path.endsWith('_nnbd_strong.dart');

        File optionsFile = new File('${path}.options');
        if (optionsFile.existsSync()) {
          ParsedOptions parsedOptions = ParsedOptions.parse(
              ParsedOptions.readOptionsFile(optionsFile.readAsStringSync()),
              TestOptions.options);
          List<String>? linked = TestOptions.linked.read(parsedOptions);
          if (linked != null) {
            linkDependencies =
                linked.map((String name) => entry.uri.resolve(name)).toList();
          }
          if (TestOptions.nnbdStrong.read(parsedOptions)) {
            enableNullSafety = true;
          }
        }

        test(path,
            () => runTestCase(entry.uri, enableNullSafety, linkDependencies));
      }
    }
  }, timeout: Timeout.none);
}
