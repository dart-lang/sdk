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
import 'package:expect/expect.dart';

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';
import '../equivalence/id_equivalence.dart';

typedef void CheckMemberFunction(
    Compiler compiler, Map<Id, String> expectedMap, MemberEntity member);

/// Compiles the [annotatedCode] with the provided [options] and calls
/// [checkMember] for each member in the code providing the map from [Id] to
/// annotation. Any [Id] left in the map will be reported as missing.
checkCode(String annotatedCode, CheckMemberFunction checkMember,
    {List<String> options: const <String>[]}) async {
  AnnotatedCode code =
      new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd);
  Map<Id, String> expectedMap = computeExpectedMap(code);
  Compiler compiler = compilerFor(
      memorySourceFiles: {'main.dart': code.sourceCode}, options: options);
  compiler.stopAfterTypeInference = true;
  Uri mainUri = Uri.parse('memory:main.dart');
  await compiler.run(mainUri);
  ElementEnvironment elementEnvironment =
      compiler.backendClosedWorldForTesting.elementEnvironment;
  LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
  elementEnvironment.forEachClass(mainLibrary, (ClassEntity cls) {
    elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      if (cls == declarer) {
        checkMember(compiler, expectedMap, member);
      }
    });
  });
  elementEnvironment.forEachLibraryMember(mainLibrary, (MemberEntity member) {
    checkMember(compiler, expectedMap, member);
  });
  expectedMap.forEach((Id id, String expected) {
    reportHere(
        compiler.reporter,
        computeSpannable(elementEnvironment, mainUri, id),
        'expected:${expected},actual:null');
  });
  Expect.isTrue(expectedMap.isEmpty, "Ids not found: $expectedMap.");
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

abstract class AbstractResolvedAstChecker extends Visitor
    with AstEnumeratorMixin {
  final DiagnosticReporter reporter;
  final Map<Id, String> expectedMap;
  final ResolvedAst resolvedAst;

  AbstractResolvedAstChecker(this.reporter, this.expectedMap, this.resolvedAst);

  TreeElements get elements => resolvedAst.elements;

  void check() {
    resolvedAst.node.accept(this);
  }

  visitNode(Node node) {
    node.visitChildren(this);
  }

  void checkElement(AstElement element) {
    ElementId id = computeElementId(element);
    String expected = annotationForId(id);
    String value = computeElementValue(element);
    checkValue(element, expected, value);
  }

  String computeElementValue(AstElement element);

  String annotationForId(Id id) {
    if (id == null) return null;
    return expectedMap.remove(id);
  }

  void checkValue(Spannable spannable, String expected, String value) {
    if (value != null || expected != null) {
      if (value != expected) {
        reportHere(reporter, spannable, 'expected:${expected},actual:${value}');
      }
      Expect.equals(expected, value);
    }
  }

  void checkNode(Node node, AstElement element) {
    NodeId id = computeNodeId(node, element);
    String expected = annotationForId(id);
    String value = computeNodeValue(node, element);
    checkValue(node, expected, value);
  }

  String computeNodeValue(Node node, [AstElement element]);

  visitVariableDefinitions(VariableDefinitions node) {
    for (Node child in node.definitions) {
      AstElement element = elements[child];
      if (element == null) {
        reportHere(reporter, child, 'No element for variable.');
      } else if (!element.isLocal) {
        checkElement(element);
      } else {
        checkNode(child, element);
      }
    }
    visitNode(node);
  }

  visitFunctionExpression(FunctionExpression node) {
    AstElement element = elements.getFunctionDefinition(node);
    if (!element.isLocal) {
      checkElement(element);
    } else {
      checkNode(node, element);
    }
    visitNode(node);
  }

  visitSend(Send node) {
    checkNode(node, null);
    visitNode(node);
  }

  visitSendSet(SendSet node) {
    checkNode(node, null);
    visitNode(node);
  }
}
