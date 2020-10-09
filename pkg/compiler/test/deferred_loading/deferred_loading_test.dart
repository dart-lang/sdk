// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io' hide Link;
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:expect/expect.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'package:compiler/src/constants/values.dart';

import 'package:kernel/ast.dart' as ir;

///  Add in options to pass to the compiler like
/// `Flags.disableTypeInference` or `Flags.disableInlining`
const List<String> compilerOptions = const [];

/// Compute the [OutputUnit]s for all source files involved in the test, and
/// ensure that the compiler is correctly calculating what is used and what is
/// not. We expect all test entry points to be in the `data` directory and any
/// or all supporting libraries to be in the `libs` folder, starting with the
/// same name as the original file in `data`.
main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const OutputUnitDataComputer(),
        options: compilerOptions, args: args, setUpFunction: () {
      importPrefixes.clear();
    }, testedConfigs: allSpecConfigs);
  });
}

// For ease of testing and making our tests easier to read, we impose an
// artificial constraint of requiring every deferred import use a different
// named prefix per test. We enforce this constraint here by checking that no
// prefix name responds to two different libraries.
Map<String, Uri> importPrefixes = {};

/// Create a consistent string representation of [OutputUnit]s for both
/// KImportEntities and ImportElements.
String outputUnitString(OutputUnit unit) {
  if (unit == null) return 'none';
  StringBuffer sb = StringBuffer();
  bool first = true;
  for (ImportEntity import in unit.importsForTesting) {
    if (!first) sb.write(', ');
    sb.write('${import.name}');
    first = false;
    Expect.isTrue(import.isDeferred);

    if (importPrefixes.containsKey(import.name)) {
      var existing = importPrefixes[import.name];
      var current = import.enclosingLibraryUri;
      Expect.equals(
          existing,
          current,
          '\n    Duplicate prefix \'${import.name}\' used in both:\n'
          '     - $existing and\n'
          '     - $current.\n'
          '    We require using unique prefixes on these tests to make '
          'the expectations more readable.');
    }
    importPrefixes[import.name] = import.enclosingLibraryUri;
  }
  return '${unit.name}{$sb}';
}

class Tags {
  static const String cls = 'class_unit';
  static const String member = 'member_unit';
  static const String closure = 'closure_unit';
  static const String constants = 'constants';
  static const String type = 'type_unit';
}

class OutputUnitDataComputer extends DataComputer<Features> {
  const OutputUnitDataComputer();

  /// OutputData for [member] as a kernel based element.
  ///
  /// At this point the compiler has already been run, so it is holding the
  /// relevant OutputUnits, we just need to extract that information from it. We
  /// fill [actualMap] with the data computed about what the resulting OutputUnit
  /// is.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    OutputUnitIrComputer(compiler.reporter, actualMap, elementMap,
            closedWorld.outputUnitData, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  void computeClassData(Compiler compiler, ClassEntity cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    ClassDefinition definition = elementMap.getClassDefinition(cls);
    OutputUnitIrComputer(compiler.reporter, actualMap, elementMap,
            closedWorld.outputUnitData, closedWorld.closureDataLookup)
        .computeForClass(definition.node);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class OutputUnitIrComputer extends IrDataExtractor<Features> {
  final JsToElementMap _elementMap;
  final OutputUnitData _data;
  final ClosureData _closureDataLookup;

  Set<String> _constants = {};

  OutputUnitIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<Features>> actualMap,
      this._elementMap,
      this._data,
      this._closureDataLookup)
      : super(reporter, actualMap);

  Features getMemberValue(
      String tag, MemberEntity member, Set<String> constants) {
    Features features = Features();
    features.add(tag,
        value: outputUnitString(_data.outputUnitForMemberForTesting(member)));
    for (var constant in constants) {
      features.addElement(Tags.constants, constant);
    }
    return features;
  }

  @override
  Features computeClassValue(Id id, ir.Class node) {
    var cls = _elementMap.getClass(node);
    Features features = Features();
    features.add(Tags.cls,
        value: outputUnitString(_data.outputUnitForClassForTesting(cls)));
    features.add(Tags.type,
        value: outputUnitString(_data.outputUnitForClassTypeForTesting(cls)));
    return features;
  }

  @override
  Features computeMemberValue(Id id, ir.Member node) {
    if (node is ir.Field && node.isConst) {
      ir.Expression initializer = node.initializer;
      ConstantValue constant = _elementMap.getConstantValue(node, initializer);
      if (!constant.isPrimitive) {
        SourceSpan span = computeSourceSpanFromTreeNode(initializer);
        if (initializer is ir.ConstructorInvocation) {
          // Adjust the source-span to match the AST-based location. The kernel FE
          // skips the "const" keyword for the expression offset and any prefix in
          // front of the constructor. The "-6" is an approximation assuming that
          // there is just a single space after "const" and no prefix.
          // TODO(sigmund): offsets should be fixed in the FE instead.
          span = SourceSpan(span.uri, span.begin - 6, span.end - 6);
        }
        _registerValue(
            NodeId(span.begin, IdKind.node),
            Features.fromMap({
              Tags.member: outputUnitString(
                  _data.outputUnitForConstantForTesting(constant))
            }),
            node,
            span,
            actualMap,
            reporter);
      }
    }

    Features features =
        getMemberValue(Tags.member, _elementMap.getMember(node), _constants);
    _constants = {};
    return features;
  }

  @override
  visitConstantExpression(ir.ConstantExpression node) {
    ConstantValue constant = _elementMap.getConstantValue(null, node);
    if (!constant.isPrimitive) {
      _constants.add('${constant.toStructuredText(_elementMap.types)}='
          '${outputUnitString(_data.outputUnitForConstant(constant))}');
    }
    return super.visitConstantExpression(node);
  }

  @override
  Features computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(Tags.closure, info.callMethod, const {});
    }
    return null;
  }
}

/// Set [actualMap] to hold a key of [id] with the computed data [value]
/// corresponding to [object] at location [sourceSpan]. We also perform error
/// checking to ensure that the same [id] isn't added twice.
void _registerValue<T>(Id id, T value, Object object, SourceSpan sourceSpan,
    Map<Id, ActualData<T>> actualMap, CompilerDiagnosticReporter reporter) {
  if (actualMap.containsKey(id)) {
    ActualData<T> existingData = actualMap[id];
    reportHere(reporter, sourceSpan,
        "Duplicate id ${id}, value=$value, object=$object");
    reportHere(
        reporter,
        sourceSpan,
        "Duplicate id ${id}, value=${existingData.value}, "
        "object=${existingData.object}");
    Expect.fail("Duplicate id $id.");
  }
  if (value != null) {
    actualMap[id] =
        ActualData<T>(id, value, sourceSpan.uri, sourceSpan.begin, object);
  }
}
