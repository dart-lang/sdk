// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show defaultExperimentalFlags, ExperimentalFlag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/summary_collector.dart';
import 'package:vm/transformations/type_flow/analysis.dart';
import 'annotation_matcher.dart' show ExpressionPragmaAnnotationParser;
import 'package:kernel/target/targets.dart';

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

class PrintSummaries extends RecursiveVisitor<Null> {
  final SummaryCollector _summaryCollector;
  final StringBuffer _buf = new StringBuffer();

  PrintSummaries(Target target, TypeEnvironment environment,
      CoreTypes coreTypes, ClassHierarchy hierarchy)
      : _summaryCollector = new SummaryCollector(
            target,
            environment,
            hierarchy,
            new EmptyEntryPointsListener(),
            new NativeCodeOracle(
                null,
                defaultExperimentalFlags[ExperimentalFlag.constantUpdate2018]
                    ? new ConstantPragmaAnnotationParser(coreTypes)
                    : new ExpressionPragmaAnnotationParser(coreTypes)),
            new GenericInterfacesInfoImpl(hierarchy));

  String print(TreeNode node) {
    visitLibrary(node);
    return _buf.toString();
  }

  @override
  defaultMember(Member member) {
    if (!member.isAbstract &&
        !((member is Field) && (member.initializer == null))) {
      _buf.writeln("------------ $member ------------");
      _buf.writeln(_summaryCollector.createSummary(member));
    }
  }
}

runTestCase(Uri source) async {
  final Target target = new TestingVmTarget(new TargetFlags());
  final Component component = await compileTestCaseToKernelProgram(source);
  final Library library = component.mainMethod.enclosingLibrary;
  final CoreTypes coreTypes = new CoreTypes(component);

  final ClassHierarchy hierarchy = new ClassHierarchy(component);
  final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);

  final actual =
      new PrintSummaries(target, typeEnvironment, coreTypes, hierarchy)
          .print(library);

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('collect-summary', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/type_flow/summary_collector');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
