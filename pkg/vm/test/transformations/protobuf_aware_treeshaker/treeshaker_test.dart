// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/printer.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:vm/kernel_front_end.dart'
    show runGlobalTransformations, ErrorDetector, KernelCompilationArguments;
import 'package:vm/modular/target/vm.dart' show VmTarget;
import 'package:vm/transformations/type_flow/transformer.dart'
    as globalTypeFlow
    show transformComponent;

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(Uri source) async {
  await shakeAndRun(source);
  await compileAOT(source);
}

Future<void> shakeAndRun(Uri source) async {
  final target = VmTarget(TargetFlags());
  Component component = await compileTestCaseToKernelProgram(
    source,
    target: target,
  );

  List<Class> messageClasses =
      component.libraries
          .expand(
            (lib) => lib.classes.where(
              (klass) =>
                  klass.superclass != null &&
                  klass.superclass!.name == "GeneratedMessage",
            ),
          )
          .toList();

  globalTypeFlow.transformComponent(
    VmTarget(TargetFlags()),
    CoreTypes(component),
    component,
    treeShakeProtobufs: true,
    treeShakeSignatures: false,
  );

  for (Class messageClass in messageClasses) {
    expect(
      messageClass.enclosingLibrary.classes.contains(messageClass),
      messageClass.name.endsWith('Keep'),
      reason: '${messageClass.toText(astTextStrategyForTesting)}',
    );
  }

  final systemTempDir = Directory.systemTemp;
  final file = File('${systemTempDir.path}/${source.pathSegments.last}.dill');
  try {
    final sink = file.openWrite();
    final printer = BinaryPrinter(sink, includeSources: false);

    component.metadata.clear();
    printer.writeComponentFile(component);
    await sink.close();

    final result = Process.runSync(Platform.resolvedExecutable, [
      '--enable-asserts',
      file.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}\n${result.stdout}');
  } finally {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

Future<void> compileAOT(Uri source) async {
  final target = VmTarget(TargetFlags(supportMirrors: false));
  Component component = await compileTestCaseToKernelProgram(
    source,
    target: target,
  );

  // Imitate the global transformations as run by the protobuf-aware tree shaker
  // in AOT mode.
  // Copied verbatim from pkg/vm/bin/protobuf_aware_treeshaker.dart.
  final nopErrorDetector = ErrorDetector();
  runGlobalTransformations(
    target,
    component,
    nopErrorDetector,
    KernelCompilationArguments(
      useGlobalTypeFlowAnalysis: true,
      enableAsserts: false,
      useProtobufTreeShakerV2: true,
    ),
  );
}

main() {
  group('protobuf-aware-treeshaker', () {
    final testCases = Directory(
      path.join(
        pkgVmDir,
        'testcases',
        'transformations',
        'type_flow',
        'transformer',
        'protobuf_handler',
        'lib',
      ),
    ).listSync().where((f) => f.path.endsWith('_test.dart'));
    for (final entry in testCases) {
      test(entry.path, () => runTestCase(entry.uri));
    }
  }, timeout: Timeout.none);
}
