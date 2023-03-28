// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/types.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

const List<String> skip = const <String>[];

main(List<String> args) {
  runTests(args);
}

runTests(List<String> args, [int? shardIndex]) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const TypeMaskDataComputer(),
        forUserLibrariesOnly: true,
        args: args,
        options: [stopAfterTypeInference],
        testedConfigs: allInternalConfigs,
        perTestOptions: {
          "issue48304.dart": [Flags.soundNullSafety],
        },
        skip: skip,
        shardIndex: shardIndex ?? 0,
        shards: shardIndex != null ? 4 : 1);
  });
}

class TypeMaskDataComputer extends DataComputer<String> {
  const TypeMaskDataComputer();

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose = false}) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    JsToElementMap elementMap = closedWorld.elementMap;
    GlobalTypeInferenceResults results =
        compiler.globalInference.resultsForTesting!;
    GlobalLocalsMap localsMap = results.globalLocalsMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    TypeMaskIrComputer(
            compiler.reporter,
            actualMap,
            elementMap,
            member,
            localsMap.getLocalsMap(member),
            results,
            closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// IR visitor for computing inference data for a member.
class TypeMaskIrComputer extends IrDataExtractor<String> {
  final GlobalTypeInferenceResults results;
  GlobalTypeInferenceMemberResult result;
  final JsToElementMap _elementMap;
  final KernelToLocalsMap _localsMap;
  final ClosureData _closureDataLookup;

  TypeMaskIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      MemberEntity member,
      this._localsMap,
      this.results,
      this._closureDataLookup)
      : result = results.resultOfMember(member),
        super(reporter, actualMap);

  String? getMemberValue(MemberEntity member) {
    GlobalTypeInferenceMemberResult memberResult =
        results.resultOfMember(member);
    if (member.isFunction || member is ConstructorEntity || member.isGetter) {
      return getTypeMaskValue(memberResult.returnType);
    } else if (member is FieldEntity) {
      return getTypeMaskValue(memberResult.type);
    } else {
      assert(member.isSetter);
      // Setters have no type mask of interest; the return type is always void
      // and shouldn't be used, and their type is a closure which cannot be
      // created.
      return null;
    }
  }

  String? getParameterValue(Local parameter) {
    return getTypeMaskValue(results.resultOfParameter(parameter));
  }

  String? getTypeMaskValue(AbstractValue? typeMask) {
    return typeMask != null ? '$typeMask' : null;
  }

  @override
  visitFunctionExpression(ir.FunctionExpression node) {
    GlobalTypeInferenceMemberResult oldResult = result;
    ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
    result = results.resultOfMember(info.callMethod!);
    super.visitFunctionExpression(node);
    result = oldResult;
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    GlobalTypeInferenceMemberResult oldResult = result;
    ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
    result = results.resultOfMember(info.callMethod!);
    super.visitFunctionDeclaration(node);
    result = oldResult;
  }

  @override
  String? computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String? computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.VariableDeclaration && node.parent is ir.FunctionNode) {
      Local parameter = _localsMap.getLocalVariable(node);
      return getParameterValue(parameter);
    } else if (node is ir.FunctionExpression ||
        node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info =
          _closureDataLookup.getClosureInfo(node as ir.LocalFunction);
      return getMemberValue(info.callMethod!);
    } else if (node is ir.InstanceInvocation ||
        node is ir.InstanceGetterInvocation ||
        node is ir.DynamicInvocation ||
        node is ir.FunctionInvocation ||
        node is ir.EqualsNull ||
        node is ir.EqualsCall) {
      return getTypeMaskValue(result.typeOfReceiver(node));
    } else if (node is ir.InstanceGet ||
        node is ir.DynamicGet ||
        node is ir.InstanceTearOff ||
        node is ir.FunctionTearOff) {
      return getTypeMaskValue(result.typeOfReceiver(node));
    } else if (node is ir.InstanceSet || node is ir.DynamicSet) {
      return getTypeMaskValue(result.typeOfReceiver(node));
    } else if (node is ir.ForInStatement) {
      if (id.kind == IdKind.iterator) {
        return getTypeMaskValue(result.typeOfIterator(node));
      } else if (id.kind == IdKind.current) {
        return getTypeMaskValue(result.typeOfIteratorCurrent(node));
      } else if (id.kind == IdKind.moveNext) {
        return getTypeMaskValue(result.typeOfIteratorMoveNext(node));
      }
    } else if (node is ir.RecordIndexGet || node is ir.RecordNameGet) {
      return getTypeMaskValue(result.typeOfReceiver(node));
    }
    return null;
  }
}
