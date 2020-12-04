// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/src/printer.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:vm/kernel_front_end.dart'
    show runGlobalTransformations, ErrorDetector;
import 'package:vm/transformations/protobuf_aware_treeshaker/transformer.dart'
    as treeshaker;

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(Uri source) async {
  await shakeAndRun(source);
  await compileAOT(source);
}

Future<void> shakeAndRun(Uri source) async {
  final target = TestingVmTarget(TargetFlags());
  Component component =
      await compileTestCaseToKernelProgram(source, target: target);

  List<Class> messageClasses = component.libraries
      .expand(
        (lib) => lib.classes.where((klass) =>
            klass.superclass != null &&
            klass.superclass.name == "GeneratedMessage"),
      )
      .toList();

  treeshaker.transformComponent(component, {}, TestingVmTarget(TargetFlags()),
      collectInfo: true);

  for (Class messageClass in messageClasses) {
    expect(messageClass.enclosingLibrary.classes.contains(messageClass),
        messageClass.name.endsWith('Keep'),
        reason: '${messageClass.toText(astTextStrategyForTesting)}');
  }

  final systemTempDir = Directory.systemTemp;
  final file = File('${systemTempDir.path}/${source.pathSegments.last}.dill');
  try {
    final sink = file.openWrite();
    final printer = BinaryPrinter(sink, includeSources: false);

    printer.writeComponentFile(component);
    await sink.close();

    final result = Process.runSync(
        Platform.resolvedExecutable, ['--enable-asserts', file.path]);
    expect(result.exitCode, 0, reason: '${result.stderr}\n${result.stdout}');
  } finally {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

Future<void> compileAOT(Uri source) async {
  final target = TestingVmTarget(TargetFlags());
  Component component =
      await compileTestCaseToKernelProgram(source, target: target);

  // Imitate the global transformations as run by the protobuf-aware tree shaker
  // in AOT mode.
  // Copied verbatim from pkg/vm/bin/protobuf_aware_treeshaker.dart.
  const bool useGlobalTypeFlowAnalysis = true;
  const bool enableAsserts = false;
  const bool useProtobufAwareTreeShaker = true;
  const bool useProtobufAwareTreeShakerV2 = false;
  final nopErrorDetector = ErrorDetector();
  runGlobalTransformations(
    target,
    component,
    useGlobalTypeFlowAnalysis,
    enableAsserts,
    useProtobufAwareTreeShaker,
    useProtobufAwareTreeShakerV2,
    nopErrorDetector,
  );
}

main() async {
  final testCases = Directory(path.join(
    pkgVmDir,
    'testcases',
    'transformations',
    'protobuf_aware_treeshaker',
    'lib',
  )).listSync().where((f) => f.path.endsWith('_test.dart'));
  for (final entry in testCases) {
    test(entry.path, () => runTestCase(entry.uri));
  }
}
