// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:compiler/src/types/types.dart';
import 'package:expect/expect.dart';

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';
import 'enumerator.dart';

checkCode(String annotatedCode) async {
  AnnotatedCode code = new AnnotatedCode(annotatedCode);
  Map<Id, String> expectedMap = computeExpectedMap(code);
  Compiler compiler =
      compilerFor(memorySourceFiles: {'main.dart': code.sourceCode});
  compiler.stopAfterTypeInference = true;
  Uri mainUri = Uri.parse('memory:main.dart');
  await compiler.run(mainUri);
  compiler.mainApp.forEachLocalMember((member) {
    if (member.isFunction) {
      checkMember(compiler, expectedMap, member);
    } else if (member.isClass) {
      member.forEachLocalMember((member) {
        checkMember(compiler, expectedMap, member);
      });
    }
  });
  expectedMap.forEach((Id id, String expected) {
    reportHere(
        compiler.reporter,
        new SourceSpan(mainUri, id.value, id.value + 1),
        'expected:${expected},actual:null');
  });
}

void checkMember(
    Compiler compiler, Map<Id, String> expectedMap, MemberElement member) {
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  compiler.reporter.withCurrentElement(member.implementation, () {
    resolvedAst.node.accept(new TypeMaskChecker(
        compiler.reporter,
        expectedMap,
        resolvedAst.elements,
        compiler.globalInference.results.resultOf(member)));
  });
}

Map<Id, String> computeExpectedMap(AnnotatedCode code) {
  Map<Id, String> map = <Id, String>{};
  for (Annotation annotation in code.annotations) {
    map[new Id(annotation.offset)] = annotation.text;
  }
  return map;
}

class TypeMaskChecker extends Visitor with AstEnumeratorMixin {
  final DiagnosticReporter reporter;
  final Map<Id, String> expectedMap;
  final TreeElements elements;
  final GlobalTypeInferenceElementResult result;

  TypeMaskChecker(this.reporter, this.expectedMap, this.elements, this.result);

  visitNode(Node node) {
    node.visitChildren(this);
  }

  String annotationForId(Id id) {
    if (id == null) return null;
    return expectedMap.remove(id);
  }

  void checkValue(Node node, String expected, TypeMask value) {
    if (value != null || expected != null) {
      String valueText = '$value';
      if (valueText != expected) {
        reportHere(reporter, node, 'expected:${expected},actual:${value}');
      }
      Expect.equals(expected, valueText);
    }
  }

  void checkSend(Send node) {
    Id id = computeId(node);
    TypeMask value = result.typeOfSend(node);
    String expected = annotationForId(id);
    checkValue(node, expected, value);
  }

  visitSend(Send node) {
    checkSend(node);
    visitNode(node);
  }

  visitSendSet(SendSet node) {
    checkSend(node);
    visitNode(node);
  }
}
