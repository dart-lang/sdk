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
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/ssa/builder_kernel.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const InliningDataComputer(), args: args);
  });
}

class InliningDataComputer extends DataComputer<String> {
  const InliningDataComputer();

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new InliningIrComputer(compiler.reporter, actualMap, elementMap, member,
            compiler.backendStrategy, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// AST visitor for computing inference data for a member.
class InliningIrComputer extends IrDataExtractor<String> {
  final JsBackendStrategy _backendStrategy;
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;
  final InlineDataCache _inlineDataCache;

  InliningIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      MemberEntity member,
      this._backendStrategy,
      this._closureDataLookup)
      : this._inlineDataCache = new InlineDataCache(enableUserAssertions: true),
        super(reporter, actualMap);

  String getMemberValue(MemberEntity member) {
    if (member is FunctionEntity) {
      ConstructorBodyEntity constructorBody;
      if (member is ConstructorEntity && member.isGenerativeConstructor) {
        constructorBody = getConstructorBody(member);
      }
      List<String> inlinedIn = <String>[];
      _backendStrategy.codegenImpactsForTesting
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
      String tooDifficultReason1 = getTooDifficultReasonForbidLoops(member);
      String tooDifficultReason2 = getTooDifficultReasonAllowLoops(member);
      inlinedIn.sort();
      String sep = '';
      if (tooDifficultReason1 != null) {
        sb.write(sep);
        sb.write(tooDifficultReason1);
        sep = ',';
      }
      if (tooDifficultReason2 != null &&
          tooDifficultReason2 != tooDifficultReason1) {
        sb.write(sep);
        sb.write('(allowLoops)');
        sb.write(tooDifficultReason2);
        sep = ',';
      }
      if (inlinedIn.isNotEmpty || sep == '') {
        sb.write(sep);
        sb.write('[');
        sb.write(inlinedIn.join(','));
        sb.write(']');
      }
      return sb.toString();
    }
    return null;
  }

  ConstructorBodyEntity getConstructorBody(ConstructorEntity constructor) {
    return _elementMap
        .getConstructorBody(_elementMap.getMemberDefinition(constructor).node);
  }

  String getTooDifficultReasonForbidLoops(MemberEntity member) {
    if (member is! FunctionEntity) return null;
    return _inlineDataCache
        .getInlineData(_elementMap, member)
        .cannotBeInlinedReason();
  }

  String getTooDifficultReasonAllowLoops(MemberEntity member) {
    if (member is! FunctionEntity) return null;
    return _inlineDataCache
        .getInlineData(_elementMap, member)
        .cannotBeInlinedReason(allowLoops: true);
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
