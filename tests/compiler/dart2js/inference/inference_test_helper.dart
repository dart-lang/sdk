// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/types/masks.dart';
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

const List<String> skipForKernel = const <String>[
  // TODO(johnniwinther): Remove this when issue 31767 is fixed.
  'mixin_constructor_default_parameter_values.dart',
];

const List<String> skipForStrong = const <String>[
  // TODO(johnniwinther): Remove this when issue 31767 is fixed.
  'mixin_constructor_default_parameter_values.dart',
  // These contain compile-time errors:
  'erroneous_super_get.dart',
  'erroneous_super_invoke.dart',
  'erroneous_super_set.dart',
  'switch3.dart',
  'switch4.dart',
  // TODO(johnniwinther): Make a strong mode clean version of this?
  'call_in_loop.dart',
];

main(List<String> args) {
  runTests(args);
}

runTests(List<String> args, [int shardIndex]) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, computeMemberIrTypeMasks,
        libDirectory: new Directory.fromUri(Platform.script.resolve('libs')),
        forUserLibrariesOnly: true,
        args: args,
        options: [stopAfterTypeInference],
        skipForKernel: skipForKernel,
        skipForStrong: skipForStrong,
        shardIndex: shardIndex ?? 0,
        shards: shardIndex != null ? 2 : 1);
  });
}

abstract class ComputeValueMixin<T> {
  GlobalTypeInferenceResults<T> get results;

  String getMemberValue(MemberEntity member) {
    GlobalTypeInferenceMemberResult<T> memberResult =
        results.resultOfMember(member);
    if (member.isFunction || member.isConstructor || member.isGetter) {
      return getTypeMaskValue(memberResult.returnType);
    } else if (member.isField) {
      return getTypeMaskValue(memberResult.type);
    } else {
      assert(member.isSetter);
      // Setters have no type mask of interest; the return type is always void
      // and shouldn't be used, and their type is a closure which cannot be
      // created.
      return null;
    }
  }

  String getParameterValue(Local parameter) {
    GlobalTypeInferenceParameterResult<T> elementResult =
        results.resultOfParameter(parameter);
    return getTypeMaskValue(elementResult.type);
  }

  String getTypeMaskValue(TypeMask typeMask) {
    return typeMask != null ? '$typeMask' : null;
  }
}

/// Compute type inference data for [member] from kernel based inference.
///
/// Fills [actualMap] with the data.
void computeMemberIrTypeMasks(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  GlobalLocalsMap localsMap = backendStrategy.globalLocalsMapForTesting;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  new TypeMaskIrComputer(
          compiler.reporter,
          actualMap,
          elementMap,
          member,
          localsMap.getLocalsMap(member),
          compiler.globalInference.results,
          backendStrategy.closureDataLookup as ClosureDataLookup<ir.Node>)
      .run(definition.node);
}

/// AST visitor for computing inference data for a member.
class TypeMaskIrComputer extends IrDataExtractor
    with ComputeValueMixin<ir.Node> {
  final GlobalTypeInferenceResults<ir.Node> results;
  GlobalTypeInferenceElementResult<ir.Node> result;
  final KernelToElementMapForBuilding _elementMap;
  final KernelToLocalsMap _localsMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;

  TypeMaskIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap,
      this._elementMap,
      MemberEntity member,
      this._localsMap,
      this.results,
      this._closureDataLookup)
      : result = results.resultOfMember(member),
        super(reporter, actualMap);

  @override
  visitFunctionExpression(ir.FunctionExpression node) {
    GlobalTypeInferenceElementResult<ir.Node> oldResult = result;
    ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
    result = results.resultOfMember(info.callMethod);
    super.visitFunctionExpression(node);
    result = oldResult;
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    GlobalTypeInferenceElementResult<ir.Node> oldResult = result;
    ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
    result = results.resultOfMember(info.callMethod);
    super.visitFunctionDeclaration(node);
    result = oldResult;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.VariableDeclaration && node.parent is ir.FunctionNode) {
      Local parameter = _localsMap.getLocalVariable(node);
      return getParameterValue(parameter);
    } else if (node is ir.FunctionExpression ||
        node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    } else if (node is ir.MethodInvocation) {
      return getTypeMaskValue(result.typeOfSend(node));
    } else if (node is ir.PropertyGet) {
      return getTypeMaskValue(result.typeOfGetter(node));
    } else if (node is ir.PropertySet) {
      return getTypeMaskValue(result.typeOfSend(node));
    } else if (node is ir.ForInStatement) {
      if (id.kind == IdKind.iterator) {
        return getTypeMaskValue(result.typeOfIterator(node));
      } else if (id.kind == IdKind.current) {
        return getTypeMaskValue(result.typeOfIteratorCurrent(node));
      } else if (id.kind == IdKind.moveNext) {
        return getTypeMaskValue(result.typeOfIteratorMoveNext(node));
      }
    }
    return null;
  }
}
