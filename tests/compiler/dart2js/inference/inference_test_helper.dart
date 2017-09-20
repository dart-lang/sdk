// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';

/// Compute type inference data for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data.
void computeMemberAstTypeMasks(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new TypeMaskAstComputer(compiler.reporter, actualMap, resolvedAst,
            compiler.globalInference.results)
        .run();
  });
}

abstract class ComputeValueMixin<T> {
  GlobalTypeInferenceResults<T> get results;

  String getMemberValue(MemberEntity member) {
    GlobalTypeInferenceMemberResult<T> memberResult =
        results.resultOfMember(member);
    return getTypeMaskValue(member.isFunction || member.isConstructor
        ? memberResult.returnType
        : memberResult.type);
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

/// AST visitor for computing inference data for a member.
class TypeMaskAstComputer extends AstDataExtractor
    with ComputeValueMixin<ast.Node> {
  final GlobalTypeInferenceResults<ast.Node> results;
  final GlobalTypeInferenceElementResult<ast.Node> result;

  TypeMaskAstComputer(DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap, ResolvedAst resolvedAst, this.results)
      : result = results.resultOfMember(resolvedAst.element as MemberElement),
        super(reporter, actualMap, resolvedAst);

  @override
  String computeElementValue(Id id, AstElement element) {
    if (element.isParameter) {
      ParameterElement parameter = element;
      return getParameterValue(parameter);
    } else if (element.isLocal && element.isFunction) {
      LocalFunctionElement localFunction = element;
      return getMemberValue(localFunction.callMethod);
    } else {
      MemberElement member = element;
      return getMemberValue(member);
    }
  }

  @override
  String computeNodeValue(Id id, ast.Node node, [AstElement element]) {
    if (element != null && element.isLocal && element.isFunction) {
      return computeElementValue(id, element);
    } else if (element != null && element.isParameter) {
      return computeElementValue(id, element);
    } else if (node is ast.SendSet) {
      if (id.kind == IdKind.invoke) {
        return getTypeMaskValue(result.typeOfOperator(node));
      } else if (id.kind == IdKind.update) {
        return getTypeMaskValue(result.typeOfSend(node));
      } else if (id.kind == IdKind.node) {
        return getTypeMaskValue(result.typeOfGetter(node));
      }
    } else if (node is ast.Send) {
      return getTypeMaskValue(result.typeOfSend(node));
    } else if (node is ast.ForIn) {
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
  final GlobalTypeInferenceElementResult<ir.Node> result;
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
