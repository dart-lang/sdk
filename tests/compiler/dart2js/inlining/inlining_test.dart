// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:compiler/src/js_backend/backend.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  JavaScriptBackend.cacheCodegenImpactForTesting = true;
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(
        dataDir, computeMemberAstInlinings, computeMemberIrInlinings,
        args: args,
        skipForKernel: [
          // TODO(sra,johnniwinther): Handle this for kernel.
          'constructor.dart',
          'dynamic.dart',
        ]);
  });
}

/// Compute type inference data for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data.
void computeMemberAstInlinings(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new InliningAstComputer(
            compiler.reporter, actualMap, resolvedAst, compiler.backend)
        .run();
  });
}

abstract class ComputeValueMixin<T> {
  JavaScriptBackend get backend;

  String getMemberValue(MemberEntity member) {
    StaticUse use = new StaticUse.inlining(member);
    List<String> inlinedIn = <String>[];
    backend.codegenImpactsForTesting
        .forEach((MemberEntity member, WorldImpact impact) {
      if (impact.staticUses.contains(use)) {
        inlinedIn.add(member.name);
      }
    });
    inlinedIn.sort();
    return '[${inlinedIn.join(',')}]';
  }
}

/// AST visitor for computing inlining data for a member.
class InliningAstComputer extends AstDataExtractor
    with ComputeValueMixin<ast.Node> {
  final JavaScriptBackend backend;

  InliningAstComputer(DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap, ResolvedAst resolvedAst, this.backend)
      : super(reporter, actualMap, resolvedAst);

  @override
  String computeElementValue(Id id, AstElement element) {
    if (element.isParameter) {
      return null;
    } else if (element.isLocal && element.isFunction) {
      LocalFunctionElement localFunction = element;
      return getMemberValue(localFunction.callMethod);
    } else {
      MemberElement member = element.declaration;
      return getMemberValue(member);
    }
  }

  @override
  String computeNodeValue(Id id, ast.Node node, [AstElement element]) {
    if (element != null && element.isLocal && element.isFunction) {
      return computeElementValue(id, element);
    }
    return null;
  }
}

/// Compute type inference data for [member] from kernel based inference.
///
/// Fills [actualMap] with the data.
void computeMemberIrInlinings(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  new InliningIrComputer(
          compiler.reporter,
          actualMap,
          elementMap,
          member,
          compiler.backend,
          backendStrategy.closureDataLookup as ClosureDataLookup<ir.Node>)
      .run(definition.node);
}

/// AST visitor for computing inference data for a member.
class InliningIrComputer extends IrDataExtractor
    with ComputeValueMixin<ir.Node> {
  final JavaScriptBackend backend;
  final KernelToElementMapForBuilding _elementMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;

  InliningIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap,
      this._elementMap,
      MemberEntity member,
      this.backend,
      this._closureDataLookup)
      : super(reporter, actualMap);

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
