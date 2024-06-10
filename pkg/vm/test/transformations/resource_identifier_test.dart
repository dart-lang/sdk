// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';
import 'package:vm/kernel_front_end.dart'
    show runGlobalTransformations, ErrorDetector, KernelCompilationArguments;
import 'package:vm/modular/target/vm.dart' show VmTarget;

import '../common_test_utils.dart';

import 'package:path/path.dart' as path;

final Uri _pkgVmDir = Platform.script.resolve('../..');

void runTestCaseAot(Uri source, bool throws) async {
  final target = VmTarget(TargetFlags(supportMirrors: false));

  Component component;
  try {
    component = await compileTestCaseToKernelProgram(source, target: target);
  } catch (e) {
    if (throws) {
      return;
    } else {
      rethrow;
    }
  }

  final nopErrorDetector = ErrorDetector();

  var tempDir = Directory.systemTemp.createTempSync().path;
  var resourcesFile = Uri(
    scheme: 'file',
    path: path.join(tempDir, 'resources.json'),
  );
  runGlobalTransformations(
      target,
      component,
      nopErrorDetector,
      KernelCompilationArguments(
        useGlobalTypeFlowAnalysis: true,
        enableAsserts: false,
        useProtobufTreeShakerV2: true,
        treeShakeWriteOnlyFields: true,
        resourcesFile: resourcesFile,
      ));

  verifyComponent(
    target,
    VerificationStage.afterGlobalTransformations,
    component,
  );

  final actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary)
      .replaceAll(_pkgVmDir.toString(), 'org-dartlang-test:///');

  compareResultWithExpectationsFile(source, actual, expectFilePostfix: '.aot');
  compareResultWithExpectationsFile(
    source,
    File.fromUri(resourcesFile).readAsStringSync(),
    expectFilePostfix: '.json',
  );
}

void main(List<String> args) {
  assert(args.isEmpty || args.length == 1);
  final filter = args.firstOrNull;
  group('resource-identifier-transformations', () {
    final testCasesDir = Directory.fromUri(
        _pkgVmDir.resolve('testcases/transformations/resource_identifier'));

    for (var file in testCasesDir
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (file.path.endsWith('.dart') &&
          !file.path.contains('helper') &&
          (filter == null || file.path.contains(filter))) {
        test('${file.path} aot',
            () => runTestCaseAot(file.uri, file.path.contains('throws')));
      }
    }
  });
}
