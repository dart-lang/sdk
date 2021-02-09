// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/src/text_util.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/analysis.dart';
import 'package:vm/transformations/type_flow/calls.dart';
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/summary_collector.dart';
import 'package:vm/transformations/type_flow/types.dart';

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

class FakeTypesBuilder extends TypesBuilder {
  final Map<Class, TFClass> _classes = <Class, TFClass>{};
  int _classIdCounter = 0;

  FakeTypesBuilder(CoreTypes coreTypes)
      : super(coreTypes, /*nullSafety=*/ false);

  @override
  TFClass getTFClass(Class c) =>
      _classes[c] ??= new TFClass(++_classIdCounter, c);
}

class FakeEntryPointsListener implements EntryPointsListener {
  final FakeTypesBuilder _typesBuilder;

  FakeEntryPointsListener(this._typesBuilder);

  @override
  void addRawCall(Selector selector) {}

  @override
  void addDirectFieldAccess(Field field, Type value) {}

  @override
  ConcreteType addAllocatedClass(Class c) {
    return new ConcreteType(_typesBuilder.getTFClass(c), null);
  }

  @override
  void recordMemberCalledViaInterfaceSelector(Member target) {}

  @override
  void recordMemberCalledViaThis(Member target) {}

  @override
  void recordTearOff(Procedure target) {}
}

class PrintSummaries extends RecursiveVisitor<Null> {
  SummaryCollector _summaryCollector;
  final StringBuffer _buf = new StringBuffer();

  PrintSummaries(Target target, TypeEnvironment environment,
      CoreTypes coreTypes, ClosedWorldClassHierarchy hierarchy) {
    final typesBuilder = new FakeTypesBuilder(coreTypes);
    _summaryCollector = new SummaryCollector(
        target,
        environment,
        hierarchy,
        new FakeEntryPointsListener(typesBuilder),
        typesBuilder,
        new NativeCodeOracle(
            null, new ConstantPragmaAnnotationParser(coreTypes)),
        new GenericInterfacesInfoImpl(hierarchy),
        /*_protobufHandler=*/ null);
  }

  String print(TreeNode node) {
    visitLibrary(node);
    return _buf.toString();
  }

  @override
  defaultMember(Member member) {
    if (!member.isAbstract &&
        !((member is Field) && (member.initializer == null))) {
      _buf.writeln(
          "------------ ${qualifiedMemberNameToString(member)} ------------");
      _buf.writeln(_summaryCollector.createSummary(member));
    }
  }
}

runTestCase(Uri source) async {
  final Target target = new TestingVmTarget(new TargetFlags());
  final Component component = await compileTestCaseToKernelProgram(source);
  final Library library = component.mainMethod.enclosingLibrary;
  final CoreTypes coreTypes = new CoreTypes(component);

  final ClassHierarchy hierarchy = new ClassHierarchy(component, coreTypes);
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
