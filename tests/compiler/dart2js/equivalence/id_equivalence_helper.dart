// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';
import '../equivalence/id_equivalence.dart';
import '../kernel/compiler_helper.dart';

/// Function that compiles [code] with [options] and returns the [Compiler] object.
typedef Future<Compiler> CompileFunction(
    AnnotatedCode code, Uri mainUri, List<String> options);

/// Function that computes a data mapping for [member].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
typedef void ComputeMemberDataFunction(Compiler compiler, MemberEntity member,
    Map<Id, String> actualMap, Map<Id, SourceSpan> sourceSpanMap);

/// Compile [code] from .dart sources.
Future<Compiler> compileFromSource(
    AnnotatedCode code, Uri mainUri, List<String> options) async {
  Compiler compiler = compilerFor(
      memorySourceFiles: {'main.dart': code.sourceCode}, options: options);
  compiler.stopAfterTypeInference = true;
  await compiler.run(mainUri);
  return compiler;
}

/// Compile [code] from .dill sources.
Future<Compiler> compileFromDill(
    AnnotatedCode code, Uri mainUri, List<String> options) async {
  Compiler compiler = await compileWithDill(
      mainUri,
      {'main.dart': code.sourceCode},
      [Flags.disableTypeInference]..addAll(options),
      beforeRun: (Compiler compiler) {
    compiler.stopAfterTypeInference = true;
  });
  return compiler;
}

/// Compute expected and actual data for all members defined in [annotatedCode].
///
/// Actual data is computed using [computeMemberData] and [code] is compiled
/// using [compileFunction].
Future<IdData> computeData(
    String annotatedCode,
    ComputeMemberDataFunction computeMemberData,
    CompileFunction compileFunction,
    {List<String> options: const <String>[]}) async {
  AnnotatedCode code =
      new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd);
  Map<Id, String> expectedMap = computeExpectedMap(code);
  Map<Id, String> actualMap = <Id, String>{};
  Map<Id, SourceSpan> sourceSpanMap = <Id, SourceSpan>{};
  Uri mainUri = Uri.parse('memory:main.dart');
  Compiler compiler = await compileFunction(code, mainUri, options);
  ElementEnvironment elementEnvironment =
      compiler.backendClosedWorldForTesting.elementEnvironment;
  LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
  elementEnvironment.forEachClass(mainLibrary, (ClassEntity cls) {
    elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      if (cls == declarer) {
        computeMemberData(compiler, member, actualMap, sourceSpanMap);
      }
    });
  });
  elementEnvironment.forEachLibraryMember(mainLibrary, (MemberEntity member) {
    computeMemberData(compiler, member, actualMap, sourceSpanMap);
  });
  return new IdData(compiler, elementEnvironment, mainUri, expectedMap,
      actualMap, sourceSpanMap);
}

/// Data collected by [computeData].
class IdData {
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;
  final Uri mainUri;
  final Map<Id, String> expectedMap;
  final Map<Id, String> actualMap;
  final Map<Id, SourceSpan> sourceSpanMap;

  IdData(this.compiler, this.elementEnvironment, this.mainUri, this.expectedMap,
      this.actualMap, this.sourceSpanMap);
}

/// Compiles the [annotatedCode] with the provided [options] and calls
/// [computeMemberData] for each member. The result is checked against the
/// expected data derived from [annotatedCode].
Future checkCode(
    String annotatedCode,
    ComputeMemberDataFunction computeMemberData,
    CompileFunction compileFunction,
    {List<String> options: const <String>[]}) async {
  IdData data = await computeData(
      annotatedCode, computeMemberData, compileFunction,
      options: options);

  data.actualMap.forEach((Id id, String actual) {
    String expected = data.expectedMap.remove(id);
    if (actual != expected) {
      reportHere(data.compiler.reporter, data.sourceSpanMap[id],
          'expected:${expected},actual:${actual}');
    }
    Expect.equals(expected, actual);
  });

  data.expectedMap.forEach((Id id, String expected) {
    reportHere(
        data.compiler.reporter,
        computeSpannable(data.elementEnvironment, data.mainUri, id),
        'expected:${expected},actual:null');
  });
  Expect.isTrue(
      data.expectedMap.isEmpty, "Ids not found: ${data.expectedMap}.");
}

/// Compute a [Spannable] from an [id] in the library [mainUri].
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

/// Compute the expectancy map from [code].
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

/// Mixin used for computing [Id] data.
abstract class ComputerMixin {
  Map<Id, String> get actualMap;
  Map<Id, SourceSpan> get sourceSpanMap;

  void registerValue(SourceSpan sourceSpan, Id id, String value) {
    if (id != null && value != null) {
      sourceSpanMap[id] = sourceSpan;
      actualMap[id] = value;
    }
  }
}

/// Abstract AST visitor for computing [Id] data.
abstract class AbstractResolvedAstComputer extends ast.Visitor
    with AstEnumeratorMixin, ComputerMixin {
  final DiagnosticReporter reporter;
  final Map<Id, String> actualMap;
  final Map<Id, SourceSpan> sourceSpanMap;
  final ResolvedAst resolvedAst;

  AbstractResolvedAstComputer(
      this.reporter, this.actualMap, this.sourceSpanMap, this.resolvedAst);

  TreeElements get elements => resolvedAst.elements;

  void computeForElement(AstElement element) {
    ElementId id = computeElementId(element);
    if (id == null) return;
    String value = computeElementValue(element);
    registerValue(element.sourcePosition, id, value);
  }

  void computeForNode(ast.Node node, AstElement element) {
    NodeId id = computeNodeId(node, element);
    if (id == null) return;
    String value = computeNodeValue(node, element);
    SourceSpan sourceSpan = new SourceSpan(resolvedAst.sourceUri,
        node.getBeginToken().charOffset, node.getEndToken().charEnd);
    registerValue(sourceSpan, id, value);
  }

  String computeElementValue(AstElement element);

  String computeNodeValue(ast.Node node, AstElement element);

  void run() {
    resolvedAst.node.accept(this);
  }

  visitNode(ast.Node node) {
    node.visitChildren(this);
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    for (ast.Node child in node.definitions) {
      AstElement element = elements[child];
      if (element == null) {
        reportHere(reporter, child, 'No element for variable.');
      } else if (!element.isLocal) {
        computeForElement(element);
      } else {
        computeForNode(child, element);
      }
    }
    visitNode(node);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    AstElement element = elements.getFunctionDefinition(node);
    if (!element.isLocal) {
      computeForElement(element);
    } else {
      computeForNode(node, element);
    }
    visitNode(node);
  }

  visitSend(ast.Send node) {
    computeForNode(node, null);
    visitNode(node);
  }

  visitSendSet(ast.SendSet node) {
    computeForNode(node, null);
    visitNode(node);
  }
}

/// Abstract IR visitor for computing [Id] data.
abstract class AbstractIrComputer extends ir.Visitor
    with IrEnumeratorMixin, ComputerMixin {
  final Map<Id, String> actualMap;
  final Map<Id, SourceSpan> sourceSpanMap;

  AbstractIrComputer(this.actualMap, this.sourceSpanMap);

  void computeForMember(ir.Member member) {
    ElementId id = computeElementId(member);
    if (id == null) return;
    String value = computeMemberValue(member);
    registerValue(computeSpannable(member), id, value);
  }

  void computeForNode(ir.TreeNode node) {
    NodeId id = computeNodeId(node);
    if (id == null) return;
    String value = computeNodeValue(node);
    registerValue(computeSpannable(node), id, value);
  }

  Spannable computeSpannable(ir.TreeNode node) {
    return new SourceSpan(
        Uri.parse(node.location.file), node.fileOffset, node.fileOffset + 1);
  }

  String computeMemberValue(ir.Member member);

  String computeNodeValue(ir.TreeNode node);

  void run(ir.Node root) {
    root.accept(this);
  }

  defaultNode(ir.Node node) {
    node.visitChildren(this);
  }

  defaultMember(ir.Member node) {
    computeForMember(node);
    super.defaultMember(node);
  }

  visitMethodInvocation(ir.MethodInvocation node) {
    computeForNode(node);
    super.visitMethodInvocation(node);
  }

  visitPropertyGet(ir.PropertyGet node) {
    computeForNode(node);
    super.visitPropertyGet(node);
  }

  visitVariableDeclaration(ir.VariableDeclaration node) {
    computeForNode(node);
    super.visitVariableDeclaration(node);
  }

  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    computeForNode(node);
    super.visitFunctionDeclaration(node);
  }
}
