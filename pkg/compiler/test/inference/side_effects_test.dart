// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/inferred_data.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('side_effects'));
    await checkTests(dataDir, const SideEffectsDataComputer(),
        args: args,
        options: [stopAfterTypeInference],
        testedConfigs: allInternalConfigs);
  });
}

class SideEffectsDataComputer extends DataComputer<String> {
  const SideEffectsDataComputer();

  /// Compute side effects data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new SideEffectsIrComputer(compiler.reporter, actualMap, closedWorld,
            compiler.globalInference.resultsForTesting.inferredData)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// AST visitor for computing side effects data for a member.
class SideEffectsIrComputer extends IrDataExtractor<String> {
  final JsClosedWorld closedWorld;
  final InferredData inferredData;

  SideEffectsIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this.closedWorld,
      this.inferredData)
      : super(reporter, actualMap);

  JsToElementMap get _elementMap => closedWorld.elementMap;
  ClosureData get _closureDataLookup => closedWorld.closureDataLookup;

  String getMemberValue(MemberEntity member) {
    if (member is FunctionEntity) {
      return inferredData.getSideEffectsOfElement(member).toString();
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
