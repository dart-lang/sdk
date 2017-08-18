// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:compiler/src/types/types.dart';

import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

/// Compute type inference data for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeMemberAstTypeMasks(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new TypeMaskComputer(compiler.reporter, actualMap, resolvedAst,
            compiler.globalInference.results)
        .run();
  });
}

/// AST visitor for computing inference data for a member.
class TypeMaskComputer extends AbstractResolvedAstComputer {
  final GlobalTypeInferenceResults results;
  final GlobalTypeInferenceElementResult result;

  TypeMaskComputer(DiagnosticReporter reporter, Map<Id, ActualData> actualMap,
      ResolvedAst resolvedAst, this.results)
      : result = results.resultOfMember(resolvedAst.element as MemberElement),
        super(reporter, actualMap, resolvedAst);

  @override
  String computeElementValue(AstElement element) {
    GlobalTypeInferenceElementResult elementResult;
    if (element.isParameter) {
      ParameterElement parameter = element;
      elementResult = results.resultOfParameter(parameter);
    } else if (element.isLocal) {
      LocalFunctionElement localFunction = element;
      elementResult = results.resultOfMember(localFunction.callMethod);
    } else {
      MemberElement member = element;
      elementResult = results.resultOfMember(member);
    }

    TypeMask value =
        element.isFunction ? elementResult.returnType : elementResult.type;
    return value != null ? '$value' : null;
  }

  @override
  String computeNodeValue(Node node, [AstElement element]) {
    if (node is Send) {
      TypeMask value = result.typeOfSend(node);
      return value != null ? '$value' : null;
    } else if (element != null && element.isLocal) {
      return computeElementValue(element);
    }
    return null;
  }
}
