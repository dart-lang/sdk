// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide Link;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:expect/expect.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'package:compiler/src/constants/values.dart';

import 'package:kernel/ast.dart' as ir;

const List<String> skipForKernel = const <String>[];

///  Add in options to pass to the compiler like
/// `Flags.disableTypeInference` or `Flags.disableInlining`
const List<String> compilerOptions = const <String>[];

/// Compute the [OutputUnit]s for all source files involved in the test, and
/// ensure that the compiler is correctly calculating what is used and what is
/// not. We expect all test entry points to be in the `data` directory and any
/// or all supporting libraries to be in the `libs` folder, starting with the
/// same name as the original file in `data`.
main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(
        dataDir, computeAstOutputUnitData, computeKernelOutputUnitData,
        libDirectory: new Directory.fromUri(Platform.script.resolve('libs')),
        skipForKernel: skipForKernel,
        options: compilerOptions,
        args: args, setUpFunction: () {
      importPrefixes.clear();
    });
  });
}

// For ease of testing and making our tests easier to read, we impose an
// artificial constraint of requiring every deferred import use a different
// named prefix per test. We enforce this constraint here by checking that no
// prefix name responds to two different libraries.
Map<String, Uri> importPrefixes = <String, Uri>{};

/// Create a consistent string representation of [OutputUnit]s for both
/// KImportEntities and ImportElements.
String outputUnitString(OutputUnit unit) {
  if (unit == null) return 'null';
  StringBuffer sb = new StringBuffer();
  bool first = true;
  for (ImportEntity import in unit.importsForTesting) {
    if (!first) sb.write(', ');
    sb.write('${import.name}');
    first = false;
    Expect.isTrue(import.isDeferred);

    if (importPrefixes.containsKey(import.name)) {
      var existing = importPrefixes[import.name];
      var current = import.enclosingLibrary.canonicalUri;
      Expect.equals(
          existing,
          current,
          '\n    Duplicate prefix \'${import.name}\' used in both:\n'
          '     - $existing and\n'
          '     - $current.\n'
          '    We require using unique prefixes on these tests to make '
          'the expectations more readable.');
    }
    importPrefixes[import.name] = import.enclosingLibrary.canonicalUri;
  }
  return 'OutputUnit(${unit.name}, {$sb})';
}

/// Compute closure data mapping for [member] as a [MemberElement].
///
/// Fills [actualMap] with the data computed about what the resulting OutputUnit
/// is.
void computeAstOutputUnitData(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  OutputUnitData data = compiler.backend.outputUnitData;
  String value = outputUnitString(data.outputUnitForEntity(member));

  _registerValue(computeElementId(member), value, member, member.sourcePosition,
      actualMap, compiler.reporter);

  if (member is FieldElement && member.isConst) {
    var node = member.initializer;
    var constant = compiler.constants.getConstantValue(member.constant);
    if (constant.isPrimitive) return;
    _registerValue(
        new NodeId(node.getBeginToken().charOffset, IdKind.node),
        outputUnitString(data.outputUnitForConstant(constant)),
        member,
        new SourceSpan(member.resolvedAst.sourceUri,
            node.getBeginToken().charOffset, node.getEndToken().charEnd),
        actualMap,
        compiler.reporter);
  }
}

/// OutputData for [member] as a kernel based element.
///
/// At this point the compiler has already been run, so it is holding the
/// relevant OutputUnits, we just need to extract that information from it. We
/// fill [actualMap] with the data computed about what the resulting OutputUnit
/// is.
void computeKernelOutputUnitData(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  OutputUnitData data = compiler.backend.outputUnitData;
  String value = outputUnitString(data.outputUnitForEntity(member));

  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  MemberDefinition definition = elementMap.getMemberDefinition(member);

  _registerValue(
      computeEntityId(definition.node),
      value,
      member,
      computeSourceSpanFromTreeNode(definition.node),
      actualMap,
      compiler.reporter);

  ir.Member memberNode = definition.node;
  if (memberNode is ir.Field && memberNode.isConst) {
    ir.Expression node = memberNode.initializer;
    ConstantValue constant = elementMap.getConstantValue(node);
    if (constant.isPrimitive) return;
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    if (node is ir.ConstructorInvocation ||
        node is ir.ListLiteral ||
        (node is ir.MapLiteral && node.keyType == null)) {
      // Adjust the source-span to match the AST-based location. The kernel FE
      // skips the "const" keyword for the expression offset and any prefix in
      // front of the constructor. The "-6" is an approximation assuming that
      // there is just a single space after "const" and no prefix.
      // TODO(sigmund): offsets should be fixed in the FE instead.
      span = new SourceSpan(span.uri, span.begin - 6, span.end - 6);
    }
    _registerValue(
        new NodeId(span.begin, IdKind.node),
        outputUnitString(data.outputUnitForConstant(constant)),
        member,
        span,
        actualMap,
        compiler.reporter);
  }
}

/// Set [actualMap] to hold a key of [id] with the computed data [value]
/// corresponding to [object] at location [sourceSpan]. We also perform error
/// checking to ensure that the same [id] isn't added twice.
void _registerValue(Id id, String value, Object object, SourceSpan sourceSpan,
    Map<Id, ActualData> actualMap, CompilerDiagnosticReporter reporter) {
  if (actualMap.containsKey(id)) {
    ActualData existingData = actualMap[id];
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
    actualMap[id] = new ActualData(new IdValue(id, value), sourceSpan, object);
  }
}
