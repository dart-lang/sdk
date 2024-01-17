// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/src/text_util.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:vm/target/vm.dart' show VmTarget;
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/analysis.dart';
import 'package:vm/transformations/type_flow/calls.dart';
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/summary.dart';
import 'package:vm/transformations/type_flow/summary_collector.dart';
import 'package:vm/transformations/type_flow/types.dart';

import '../../common_test_utils.dart';

final Uri pkgVmDir = Platform.script.resolve('../../..');

class FakeTypesBuilder extends TypesBuilder {
  final Map<Class, TFClass> _classes = <Class, TFClass>{};
  int _classIdCounter = 0;

  FakeTypesBuilder(CoreTypes coreTypes)
      : super(coreTypes, /*soundNullSafety=*/ true);

  @override
  TFClass getTFClass(Class c) =>
      _classes[c] ??= new TFClass(++_classIdCounter, c, {}, null);
}

class FakeEntryPointsListener implements EntryPointsListener {
  final FakeTypesBuilder _typesBuilder;

  FakeEntryPointsListener(this._typesBuilder);

  @override
  void addRawCall(Selector selector) {}

  @override
  void addFieldUsedInConstant(Field field, Type instance, Type value) {}

  @override
  ConcreteType addAllocatedClass(Class c) {
    return _typesBuilder.getTFClass(c).concreteType;
  }

  @override
  Field getRecordPositionalField(RecordShape shape, int pos) =>
      getRecordNamedField(shape, shape.fieldName(pos));

  @override
  Field getRecordNamedField(RecordShape shape, String name) =>
      Field.immutable(Name(name), fileUri: dummyUri);

  @override
  void recordMemberCalledViaInterfaceSelector(Member target) {}

  @override
  void recordMemberCalledViaThis(Member target) {}

  @override
  void recordTearOff(Member target) {}
}

class FakeSharedVariable implements SharedVariable {
  final VariableDeclaration decl;
  FakeSharedVariable(this.decl);

  @override
  Type getValue(TypeHierarchy typeHierarchy, CallHandler callHandler) =>
      throw 'Not implemented';

  @override
  void setValue(Type newValue, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      throw 'Not implemented';

  @override
  String toString() => decl.name ?? '__tmp';
}

class FakeSharedVariableBuilder implements SharedVariableBuilder {
  final Map<VariableDeclaration, SharedVariable> _sharedVariables = {};

  @override
  SharedVariable getSharedVariable(VariableDeclaration variable) =>
      _sharedVariables[variable] ??= FakeSharedVariable(variable);
}

class PrintSummaries extends RecursiveVisitor {
  late SummaryCollector _summaryCollector;
  final StringBuffer _buf = new StringBuffer();

  PrintSummaries(Target target, TypeEnvironment environment,
      CoreTypes coreTypes, ClosedWorldClassHierarchy hierarchy) {
    final typesBuilder = FakeTypesBuilder(coreTypes);
    final annotationParser = ConstantPragmaAnnotationParser(coreTypes, target);
    _summaryCollector = SummaryCollector(
        target,
        environment,
        hierarchy,
        FakeEntryPointsListener(typesBuilder),
        typesBuilder,
        NativeCodeOracle(coreTypes.index, annotationParser),
        GenericInterfacesInfoImpl(coreTypes, hierarchy),
        FakeSharedVariableBuilder(),
        /*_protobufHandler=*/ null);
  }

  String print(Library node) {
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

class TestOptions {
  static const Option<List<String>?> enableExperiment =
      Option('--enable-experiment', StringListValue());

  static const List<Option> options = [enableExperiment];
}

runTestCase(Uri source, List<String>? experimentalFlags) async {
  final Target target = new VmTarget(new TargetFlags());
  final Component component = await compileTestCaseToKernelProgram(source,
      target: target, experimentalFlags: experimentalFlags);
  final Library library = component.mainMethod!.enclosingLibrary;
  final CoreTypes coreTypes = new CoreTypes(component);

  final ClosedWorldClassHierarchy hierarchy =
      new ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy;
  final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);

  final actual =
      new PrintSummaries(target, typeEnvironment, coreTypes, hierarchy)
          .print(library);

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('collect-summary', () {
    final testCasesDir = Directory.fromUri(pkgVmDir
        .resolve('testcases/transformations/type_flow/summary_collector'));

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      final path = entry.path;
      if (path.endsWith(".dart")) {
        List<String>? experimentalFlags;
        final File optionsFile = new File('${path}.options');
        if (optionsFile.existsSync()) {
          ParsedOptions parsedOptions = ParsedOptions.parse(
              ParsedOptions.readOptionsFile(optionsFile.readAsStringSync()),
              TestOptions.options);
          experimentalFlags = TestOptions.enableExperiment.read(parsedOptions);
        }
        test(path, () => runTestCase(entry.uri, experimentalFlags));
      }
    }
  });
}
