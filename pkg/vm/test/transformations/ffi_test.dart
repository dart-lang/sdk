// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart';

import 'package:test/test.dart';

import 'package:vm/transformations/ffi/native.dart' show transformLibraries;

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

class TestDiagnosticReporter extends DiagnosticReporter<Object, Object> {
  @override
  void report(Object message, int charOffset, int length, Uri? fileUri,
      {List<Object>? context}) {/* nop */}
}

runTestCase(Uri source) async {
  final target = TestingVmTarget(TargetFlags());

  Component component = await compileTestCaseToKernelProgram(source,
      target: target, experimentalFlags: ['generic-metadata']);

  final coreTypes = CoreTypes(component);

  transformLibraries(
      component,
      coreTypes,
      ClassHierarchy(component, coreTypes),
      component.libraries,
      TestDiagnosticReporter(),
      /*referenceFromIndex=*/ null);

  verifyComponent(component);

  final actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);

  compareResultWithExpectationsFile(source, actual);
}

void main(List<String> args) {
  assert(args.length == 0 || args.length == 1);
  String? filter;
  if (args.length > 0) {
    filter = args.first;
  }

  group('ffi-transformations', () {
    final testCasesDir = Directory(pkgVmDir + '/testcases/transformations/ffi');

    for (var entry in testCasesDir
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (entry.path.endsWith(".dart") &&
          (filter == null || entry.path.contains(filter))) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
