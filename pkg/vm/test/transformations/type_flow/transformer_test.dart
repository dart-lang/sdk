// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(
    Uri source, List<String> experimentalFlags, bool enableNullSafety) async {
  final target =
      new TestingVmTarget(new TargetFlags(enableNullSafety: enableNullSafety));
  Component component = await compileTestCaseToKernelProgram(source,
      target: target, experimentalFlags: experimentalFlags);

  final coreTypes = new CoreTypes(component);

  component = transformComponent(target, coreTypes, component,
      matcher: new ConstantPragmaAnnotationParser(coreTypes),
      treeShakeProtobufs: true);

  String actual = kernelLibraryToString(component.mainMethod.enclosingLibrary);

  // Tests in /protobuf_handler consist of multiple libraries.
  // Include libraries with protobuf generated messages into the result.
  if (source.toString().contains('/protobuf_handler/')) {
    for (var lib in component.libraries) {
      if (lib.importUri
          .toString()
          .contains('/protobuf_handler/lib/generated/')) {
        lib.name ??= lib.importUri.pathSegments.last;
        actual += kernelLibraryToString(lib);
      }
    }
    // Remove library paths.
    actual = actual.replaceAll(Uri.file(pkgVmDir).toString(), 'file:pkg/vm');
  }

  compareResultWithExpectationsFile(source, actual);

  ensureKernelCanBeSerializedToBinary(component);
}

main() {
  group('transform-component', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/type_flow/transformer');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      final path = entry.path;
      if (path.endsWith('.dart') && !path.endsWith('.pb.dart')) {
        final bool enableNullSafety = path.endsWith('_nnbd_strong.dart');
        final bool enableNNBD = enableNullSafety || path.endsWith('_nnbd.dart');
        final List<String> experimentalFlags = [
          if (enableNNBD) 'non-nullable',
        ];
        test(path,
            () => runTestCase(entry.uri, experimentalFlags, enableNullSafety));
      }
    }
  }, timeout: Timeout.none);
}
