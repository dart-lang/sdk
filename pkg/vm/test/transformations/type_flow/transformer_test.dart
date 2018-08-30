// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;
import 'package:vm/transformations/type_flow/utils.dart';

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

// Since we don't run the constants transformation in this test, we can't
// recognize all pragma annotations precisely. Instead, we pattern match on
// annotations which look like a pragma and assume that their options field
// evaluates to true.
class ExpressionEntryPointsAnnotationMatcher
    extends EntryPointsAnnotationMatcher {
  final CoreTypes coreTypes;

  ExpressionEntryPointsAnnotationMatcher(this.coreTypes);

  bool _looksLikePragma(ConstructorInvocation annotation) {
    if (annotation.constructedType.classNode != coreTypes.pragmaClass) {
      return false;
    }

    if (annotation.arguments.types.length != 0 ||
        annotation.arguments.positional.length < 1 ||
        annotation.arguments.named.length != 0) {
      throw "Cannot evaluate pragma annotation $annotation";
    }

    var argument = annotation.arguments.positional[0];
    return argument is StringLiteral && argument.value == kEntryPointPragmaName;
  }

  @override
  PragmaEntryPointType annotationsDefineRoot(List<Expression> annotations) {
    for (var annotation in annotations) {
      assertx(annotation is! ConstantExpression);
      if (annotation is ConstructorInvocation && _looksLikePragma(annotation)) {
        return PragmaEntryPointType.Always;
      }
    }
    return null;
  }
}

runTestCase(Uri source) async {
  Component component = await compileTestCaseToKernelProgram(source);

  final coreTypes = new CoreTypes(component);

  final entryPoints = [
    pkgVmDir + '/lib/transformations/type_flow/entry_points.json',
    pkgVmDir + '/lib/transformations/type_flow/entry_points_extra.json',
  ];

  component = transformComponent(coreTypes, component, entryPoints,
      new ExpressionEntryPointsAnnotationMatcher(coreTypes));

  final actual = kernelLibraryToString(component.mainMethod.enclosingLibrary);

  compareResultWithExpectationsFile(source, actual);

  ensureKernelCanBeSerializedToBinary(component);
}

main() {
  group('transform-component', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/type_flow/transformer');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
