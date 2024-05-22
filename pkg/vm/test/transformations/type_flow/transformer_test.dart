// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2wasm/record_class_generator.dart'
    show generateRecordClasses;
import 'package:dart2wasm/target.dart' show WasmTarget;
import 'package:front_end/src/api_unstable/vm.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';
import 'package:vm/modular/target/install.dart' show installAdditionalTargets;
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/config.dart';
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;

import '../../common_test_utils.dart';

final Uri pkgVmDir = Platform.script.resolve('../../..');

void runTestCase(
    Uri source,
    List<Uri>? linkedDependencies,
    List<String>? experimentalFlags,
    String? targetName,
    TFAConfiguration tfaConfig) async {
  targetName ??= "vm";
  // Install all VM targets and dart2wasm.
  installAdditionalTargets();
  targets["dart2wasm"] = (TargetFlags flags) => WasmTarget();
  final target = getTarget(targetName, TargetFlags())!;
  Component component = await compileTestCaseToKernelProgram(source,
      target: target,
      linkedDependencies: linkedDependencies,
      experimentalFlags: experimentalFlags);

  final coreTypes = new CoreTypes(component);

  bool useRapidTypeAnalysis = true;
  if (target is WasmTarget) {
    // Keep these flags in-sync with pkg/dart2wasm/lib/compile.dart
    useRapidTypeAnalysis = false;
    target.recordClasses = generateRecordClasses(component, coreTypes);
  }

  component = transformComponent(target, coreTypes, component,
      matcher: new ConstantPragmaAnnotationParser(coreTypes, target),
      config: tfaConfig,
      treeShakeProtobufs: true,
      useRapidTypeAnalysis: useRapidTypeAnalysis);

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
      actual += kernelLibraryToString(lib, removeSelectorIds: true);
    }
    // Remove library paths.
    actual = actual.replaceAll(pkgVmDir.toString(), 'file:pkg/vm/');
  }

  compareResultWithExpectationsFile(source, actual);

  ensureKernelCanBeSerializedToBinary(component);
}

String? argsTestName(List<String> args) {
  if (args.isNotEmpty) {
    return args.last;
  }
  return null;
}

class TestOptions {
  /// List of libraries the should be precompiled to .dill before compiling the
  /// main library from source.
  static const Option<List<String>?> linked =
      Option('--linked', StringListValue());

  static const Option<List<String>?> enableExperiment =
      Option('--enable-experiment', StringListValue());

  static const Option<String?> target = Option('--target', StringValue());

  static const Option<int?> maxAllocatedTypesInSetSpecialization =
      Option('--tfa.maxAllocatedTypesInSetSpecialization', IntValue());

  static const Option<int?> maxInterfaceInvocationsPerSelector =
      Option('--tfa.maxInterfaceInvocationsPerSelector', IntValue());

  static const List<Option> options = [
    linked,
    enableExperiment,
    target,
    maxAllocatedTypesInSetSpecialization,
    maxInterfaceInvocationsPerSelector
  ];
}

void main(List<String> args) {
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
        List<String>? experimentalFlags;
        String? targetName;
        TFAConfiguration tfaConfig = defaultTFAConfiguration;

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
          experimentalFlags = TestOptions.enableExperiment.read(parsedOptions);
          targetName = TestOptions.target.read(parsedOptions);
          tfaConfig = TFAConfiguration(
            maxInterfaceInvocationsPerSelector: TestOptions
                    .maxInterfaceInvocationsPerSelector
                    .read(parsedOptions) ??
                defaultTFAConfiguration.maxInterfaceInvocationsPerSelector,
            maxAllocatedTypesInSetSpecialization: TestOptions
                    .maxAllocatedTypesInSetSpecialization
                    .read(parsedOptions) ??
                defaultTFAConfiguration.maxAllocatedTypesInSetSpecialization,
          );
        }

        test(
            path,
            () => runTestCase(entry.uri, linkDependencies, experimentalFlags,
                targetName, tfaConfig));
      }
    }
  }, timeout: Timeout.none);
}
