// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart';
import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';
import 'package:vm/kernel_front_end.dart'
    show runGlobalTransformations, ErrorDetector, KernelCompilationArguments;
import 'package:vm/modular/target/vm.dart' show VmTarget;

import '../common_test_utils.dart';

import 'package:path/path.dart' as path;

final Uri _pkgVmDir = Platform.script.resolve('../..');

void runTestCaseAot(
  Uri sourceFileUri,
  Uri sourcePackageUri,
  Uri packagesFileUri,
  bool throws,
) async {
  final target = VmTarget(TargetFlags(supportMirrors: false));

  Component component;
  try {
    component = await compileTestCaseToKernelProgram(
      sourcePackageUri,
      target: target,
      packagesFileUri: packagesFileUri,
    );
  } catch (e) {
    if (throws) {
      return;
    } else {
      rethrow;
    }
  }

  final nopErrorDetector = ErrorDetector();

  var tempDir = Directory.systemTemp.createTempSync().path;
  var recordedUsagesFile = Uri(
    scheme: 'file',
    path: path.join(tempDir, 'recorded_usages.json'),
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
      recordedUsages: recordedUsagesFile,
      source: sourcePackageUri,
    ),
  );

  verifyComponent(
    target,
    VerificationStage.afterGlobalTransformations,
    component,
  );

  final actual = kernelLibraryToString(
    component.mainMethod!.enclosingLibrary,
  ).replaceAll(_pkgVmDir.toString(), 'org-dartlang-test:///');

  compareResultWithExpectationsFile(
    sourceFileUri,
    actual,
    expectFilePostfix: '.aot',
  );

  final actualSemantic = Recordings.fromJson(
    jsonDecode(File.fromUri(recordedUsagesFile).readAsStringSync()),
  );
  final goldenFile = File('${sourceFileUri.toFilePath()}.json.expect');
  final update = bool.fromEnvironment('updateExpectations');

  bool semanticEquals = false;
  if (goldenFile.existsSync()) {
    try {
      final goldenContents = await goldenFile.readAsString();
      final golden = Recordings.fromJson(jsonDecode(goldenContents));
      semanticEquals = actualSemantic.semanticEquals(golden);
    } on FormatException {
      if (!update) {
        rethrow;
      }
    }
  }

  if (!semanticEquals || update) {
    compareResultWithExpectationsFile(
      sourceFileUri,
      File.fromUri(recordedUsagesFile).readAsStringSync(),
      expectFilePostfix: '.json',
    );
  }
}

void main(List<String> args) {
  assert(args.isEmpty || args.length == 1);
  final filter = args.firstOrNull;
  group('record-use-transformations', () {
    final recordUseTestDir = _pkgVmDir.resolve(
      'testcases/transformations/record_use/',
    );
    final testCasesDir = Directory.fromUri(recordUseTestDir.resolve('lib/'));
    final packagesFileUri = _pkgVmDir.resolve(
      '../../.dart_tool/package_config.json',
    );

    for (var file
        in testCasesDir
            .listSync(recursive: true, followLinks: false)
            .reversed) {
      if (file.path.endsWith('.dart') &&
          !file.path.contains('helper') &&
          (filter == null || file.path.contains(filter))) {
        final relativePath = path.relative(file.path, from: testCasesDir.path);
        final packageUri = Uri.parse('package:record_use_test/$relativePath');
        test(
          '${file.path} aot',
          () => runTestCaseAot(
            file.uri,
            packageUri,
            packagesFileUri,
            file.path.contains('throws'),
          ),
        );
      }
    }

    test('outside_package_throws', () async {
      final sourceFileUri = recordUseTestDir.resolve(
        'outside_package_throws.dart',
      );
      final target = VmTarget(TargetFlags(supportMirrors: false));

      bool failed = false;
      try {
        await compileTestCaseToKernelProgram(
          sourceFileUri,
          target: target,
          packagesFileUri: packagesFileUri,
        );
      } catch (e) {
        failed = true;
        final message = e.toString();
        expect(message, contains('RecordUse'));
        expect(message, contains('package:'));
      }
      if (!failed) {
        fail('Should have failed with a diagnostic error');
      }
    });
  });
}
