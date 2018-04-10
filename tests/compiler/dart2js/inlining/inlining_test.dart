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
import 'package:compiler/src/ssa/builder.dart' as ast;
import 'package:compiler/src/ssa/builder_kernel.dart' as kernel;
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
        skipForAst: ['external.dart'],
        // TODO(johnniwinther): Run tests with strong mode.
        testStrongMode: false);
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

  ConstructorBodyEntity getConstructorBody(ConstructorEntity constructor);

  String getTooDifficultReason(MemberEntity member);

  String getMemberValue(MemberEntity member) {
    if (member is FunctionEntity) {
      ConstructorBodyEntity constructorBody;
      if (member is ConstructorEntity && member.isGenerativeConstructor) {
        constructorBody = getConstructorBody(member);
      }
      List<String> inlinedIn = <String>[];
      backend.codegenImpactsForTesting
          .forEach((MemberEntity user, WorldImpact impact) {
        for (StaticUse use in impact.staticUses) {
          if (use.kind == StaticUseKind.INLINING) {
            if (use.element == member) {
              if (use.type != null) {
                inlinedIn.add('${user.name}:${use.type}');
              } else {
                inlinedIn.add(user.name);
              }
            } else if (use.element == constructorBody) {
              if (use.type != null) {
                inlinedIn.add('${user.name}+:${use.type}');
              } else {
                inlinedIn.add('${user.name}+');
              }
            }
          }
        }
      });
      StringBuffer sb = new StringBuffer();
      String tooDifficultReason = getTooDifficultReason(member);
      inlinedIn.sort();
      if (tooDifficultReason != null) {
        sb.write(tooDifficultReason);
        if (inlinedIn.isNotEmpty) {
          sb.write(',[${inlinedIn.join(',')}]');
        }
      } else {
        sb.write('[${inlinedIn.join(',')}]');
      }
      return sb.toString();
    }
    return null;
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
  ConstructorBodyEntity getConstructorBody(
      covariant ConstructorElement constructor) {
    return constructor.enclosingClass.lookupConstructorBody(constructor.name);
  }

  @override
  String getTooDifficultReason(MemberEntity member) {
    if (member is MethodElement) {
      if (member is ConstructorElement && member.isDefaultConstructor) {
        return null;
      }
      return ast.InlineWeeder.cannotBeInlinedReason(member.resolvedAst, null,
          enableUserAssertions: true);
    }
    return null;
  }

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

  ConstructorBodyEntity getConstructorBody(ConstructorEntity constructor) {
    return _elementMap
        .getConstructorBody(_elementMap.getMemberDefinition(constructor).node);
  }

  @override
  String getTooDifficultReason(MemberEntity member) {
    if (member is! FunctionEntity) return null;
    return kernel.InlineWeeder.cannotBeInlinedReason(_elementMap, member, null,
        enableUserAssertions: true);
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
