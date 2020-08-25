// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';

import '../common_test_utils.dart';
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;
import 'package:vm/transformations/mixin_deduplication.dart' as deduplication;

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source) async {
  final target = new TestingVmTarget(new TargetFlags());
  Component component =
      await compileTestCaseToKernelProgram(source, target: target);

  final coreTypes = new CoreTypes(component);
  deduplication.transformComponent(component);
  component = transformComponent(target, coreTypes, component,
      matcher: new ConstantPragmaAnnotationParser(coreTypes),
      treeShakeProtobufs: true);

  // Remove core libraries so the expected output isn't enormous and broken by
  // core libraries changes.
  component.libraries.removeWhere(
    (lib) =>
        lib.importUri.scheme == "dart" &&
        lib.importUri.toString() != 'dart:_internal',
  );

  final indexer = LibraryIndex.all(component);
  final internal = indexer.getLibrary('dart:_internal');
  internal.classes.removeWhere(
    (clazz) => !clazz.isAnonymousMixin || !clazz.isEliminatedMixin,
  );
  [
    internal.fields,
    internal.procedures,
    internal.parts,
    internal.additionalExports,
    internal.dependencies,
    internal.typedefs,
  ].forEach((i) => i.clear());
  String actual = kernelComponentToString(component);

  // Remove absolute library URIs.
  actual = actual.replaceAll(new Uri.file(pkgVmDir).toString(), '#pkg/vm');

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('deferred-loading', () {
    final testCasesDir =
        new Directory(pkgVmDir + '/testcases/transformations/move_mixin');

    for (var entry in testCasesDir
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (entry.path.endsWith("main.dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
