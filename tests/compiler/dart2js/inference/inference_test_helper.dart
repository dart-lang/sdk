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

void checkMemberAstTypeMasks(
    Compiler compiler, Map<Id, String> expectedMap, MemberEntity _member) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new TypeMaskChecker(compiler.reporter, expectedMap, resolvedAst,
            compiler.globalInference.results)
        .check();
  });
}

class TypeMaskChecker extends AbstractResolvedAstChecker {
  final GlobalTypeInferenceResults results;
  final GlobalTypeInferenceElementResult result;

  TypeMaskChecker(DiagnosticReporter reporter, Map<Id, String> expectedMap,
      ResolvedAst resolvedAst, this.results)
      : result = results.resultOfMember(resolvedAst.element as MemberElement),
        super(reporter, expectedMap, resolvedAst);

  @override
  String computeElementValue(AstElement element) {
    GlobalTypeInferenceElementResult elementResult =
        results.resultOfElement(element);
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
