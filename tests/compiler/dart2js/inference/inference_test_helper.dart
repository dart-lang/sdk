// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:compiler/src/types/types.dart';
import 'package:expect/expect.dart';

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';
import 'enumerator.dart';

typedef void CheckMemberFunction(
    Compiler compiler, Map<Id, String> expectedMap, MemberElement member);

/// Compiles the [annotatedCode] with the provided [options] and calls
/// [checkMember] for each member in the code providing the map from [Id] to
/// annotation. Any [Id] left in the map will be reported as missing.
checkCode(String annotatedCode, CheckMemberFunction checkMember,
    {List<String> options: const <String>[]}) async {
  AnnotatedCode code = new AnnotatedCode.fromText(annotatedCode, '/*', '*/');
  Map<Id, String> expectedMap = computeExpectedMap(code);
  Compiler compiler = compilerFor(
      memorySourceFiles: {'main.dart': code.sourceCode}, options: options);
  compiler.stopAfterTypeInference = true;
  Uri mainUri = Uri.parse('memory:main.dart');
  await compiler.run(mainUri);
  LibraryElement mainApp =
      compiler.frontendStrategy.elementEnvironment.mainLibrary;
  mainApp.forEachLocalMember((dynamic member) {
    if (member.isClass) {
      member.forEachLocalMember((member) {
        checkMember(compiler, expectedMap, member);
      });
    } else if (member.isTypedef) {
      // Skip.
    } else {
      checkMember(compiler, expectedMap, member);
    }
  });
  expectedMap.forEach((Id id, String expected) {
    reportHere(
        compiler.reporter,
        computeSpannable(compiler.resolution.elementEnvironment, mainUri, id),
        'expected:${expected},actual:null');
  });
  Expect.isTrue(expectedMap.isEmpty, "Ids not found: $expectedMap.");
}

void checkMemberAstTypeMasks(
    Compiler compiler, Map<Id, String> expectedMap, MemberElement member) {
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new TypeMaskChecker(compiler.reporter, expectedMap, resolvedAst,
            compiler.globalInference.results)
        .check();
  });
}

Spannable computeSpannable(
    ElementEnvironment elementEnvironment, Uri mainUri, Id id) {
  if (id is NodeId) {
    return new SourceSpan(mainUri, id.value, id.value + 1);
  } else if (id is ElementId) {
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    if (id.className != null) {
      ClassEntity cls =
          elementEnvironment.lookupClass(library, id.className, required: true);
      return elementEnvironment.lookupClassMember(cls, id.memberName);
    } else {
      return elementEnvironment.lookupLibraryMember(library, id.memberName);
    }
  }
  throw new UnsupportedError('Unsupported id $id.');
}

Map<Id, String> computeExpectedMap(AnnotatedCode code) {
  Map<Id, String> map = <Id, String>{};
  for (Annotation annotation in code.annotations) {
    String text = annotation.text;
    int colonPos = text.indexOf(':');
    Id id;
    String expected;
    if (colonPos == -1) {
      id = new NodeId(annotation.offset);
      expected = text;
    } else {
      id = new ElementId(text.substring(0, colonPos));
      expected = text.substring(colonPos + 1);
    }
    map[id] = expected;
  }
  return map;
}

class TypeMaskChecker extends Visitor with AstEnumeratorMixin {
  final DiagnosticReporter reporter;
  final Map<Id, String> expectedMap;
  final ResolvedAst resolvedAst;
  final GlobalTypeInferenceResults results;
  final GlobalTypeInferenceElementResult result;

  TypeMaskChecker(
      this.reporter, this.expectedMap, this.resolvedAst, this.results)
      : result = results.resultOfMember(resolvedAst.element as MemberElement);

  TreeElements get elements => resolvedAst.elements;

  void check() {
    resolvedAst.node.accept(this);
  }

  visitNode(Node node) {
    node.visitChildren(this);
  }

  void checkElement(AstElement element) {
    ElementId id = computeElementId(element);
    GlobalTypeInferenceElementResult elementResult =
        results.resultOfElement(element);
    TypeMask value =
        element.isFunction ? elementResult.returnType : elementResult.type;
    String expected = annotationForId(id);
    checkValue(element, expected, value);
  }

  String annotationForId(Id id) {
    if (id == null) return null;
    return expectedMap.remove(id);
  }

  void checkValue(Spannable spannable, String expected, TypeMask value) {
    if (value != null || expected != null) {
      String valueText = '$value';
      if (valueText != expected) {
        reportHere(reporter, spannable, 'expected:${expected},actual:${value}');
      }
      Expect.equals(expected, valueText);
    }
  }

  void checkSend(Send node) {
    NodeId id = computeNodeId(node);
    TypeMask value = result.typeOfSend(node);
    String expected = annotationForId(id);
    checkValue(node, expected, value);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    for (Node child in node.definitions) {
      AstElement element = elements[child];
      if (element == null) {
        reportHere(reporter, child, 'No element for variable.');
      } else if (!element.isLocal) {
        checkElement(element);
      }
    }
    visitNode(node);
  }

  visitFunctionExpression(FunctionExpression node) {
    AstElement element = elements.getFunctionDefinition(node);
    checkElement(element);
    visitNode(node);
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
