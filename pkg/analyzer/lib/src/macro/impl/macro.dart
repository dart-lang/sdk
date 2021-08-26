// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/macro/api/code.dart';
import 'package:analyzer/src/macro/api/macro.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/library_builder.dart';

class ClassDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements ClassDeclarationBuilder {
  final LinkingUnit linkingUnit;

  /// The index of [node] among other [ast.ClassDeclarationImpl]s.
  final int nodeIndex;

  final ast.ClassDeclarationImpl node;

  ClassDeclarationBuilderImpl(
    this.linkingUnit,
    this.nodeIndex,
    this.node,
  );

  @override
  void addToClass(Declaration declaration) {
    var declarationCode = declaration.code.trim();

    // TODO(scheglov) feature set
    // TODO(scheglov) throw if errors?
    var parseResult = parseString(
      content: 'class ${node.name.name} { $declarationCode }',
    );
    var parsedDeclarations = parseResult.unit.declarations;
    var parsedClass = parsedDeclarations.single as ast.ClassDeclaration;
    var parsedMember = parsedClass.members.single;
    _rebaseOffsets(parsedMember);

    node.members.add(parsedMember);

    var macroGeneratedContent = linkingUnit.macroGeneratedContent;
    var collected = _Declaration(
      data: MacroGenerationData(
        id: macroGeneratedContent.nextId++,
        code: declarationCode,
        informative: writeDeclarationInformative(parsedMember),
        classDeclarationIndex: nodeIndex,
      ),
      node: parsedMember,
    );
    macroGeneratedContent._declarations.add(collected);
  }

  /// We parsed [node] in the context of some synthetic code string, its
  /// current offsets only have meaning relative to the begin offset of the
  /// [node]. So, we update offsets accordingly.
  static void _rebaseOffsets(ast.AstNode node) {
    var baseOffset = node.offset;
    for (Token? t = node.beginToken;
        t != null && t != node.endToken;
        t = t.next) {
      t.offset -= baseOffset;
    }
  }
}

class DeclarationBuilderImpl implements DeclarationBuilder {
  @override
  void addToLibrary(Declaration declaration) {
    // TODO: implement addToLibrary
  }

  @override
  Code typeAnnotationCode(ast.TypeAnnotation node) {
    return Fragment(node.toSource());
  }
}

class MacroGeneratedContent {
  final LinkingUnit linkingUnit;
  final List<_Declaration> _declarations = [];
  int nextId = 0;

  MacroGeneratedContent(this.linkingUnit);

  /// Finish building of elements: combine the source code of the unit with
  /// macro-generated pieces of code; update offsets of macro-generated
  /// elements to use offsets inside this combined code.
  void finish() {
    // Don't set empty values, keep it null.
    if (_declarations.isEmpty) {
      return;
    }

    // Sort declarations by:
    // 1. The top-level declaration location.
    // 2. The ordering in the top-level declaration.
    // We need (2) because `sort` is not stable.
    _declarations.sort((a, b) {
      const indexForUnit = 1 << 24;
      var aIndex = a.data.classDeclarationIndex ?? indexForUnit;
      var bIndex = b.data.classDeclarationIndex ?? indexForUnit;
      if (aIndex != bIndex) {
        return aIndex - bIndex;
      }
      return a.data.id - b.data.id;
    });

    const classMemberCodePrefix = '\n  ';
    const classMemberCodeSuffix = '\n';
    // TODO(scheglov) make it required?
    var generatedContent = linkingUnit.input.sourceContent!;
    var shift = 0;
    var classDeclarations = linkingUnit.input.unit.declarations
        .whereType<ast.ClassDeclaration>()
        .toList();
    for (var declaration in _declarations) {
      var classIndex = declaration.data.classDeclarationIndex;
      if (classIndex != null) {
        var targetClass = classDeclarations[classIndex];
        var code = classMemberCodePrefix +
            declaration.data.code +
            classMemberCodeSuffix;
        var insertOffset = shift + targetClass.rightBracket.offset;
        declaration.data.insertOffset = insertOffset;
        declaration.data.codeOffset =
            insertOffset + classMemberCodePrefix.length;
        generatedContent = generatedContent.substring(0, insertOffset) +
            code +
            generatedContent.substring(insertOffset);
        declaration.data.insertLength = code.length;
        shift += code.length;
      } else {
        throw UnimplementedError();
      }

      var node = declaration.node;
      if (node is ast.Declaration) {
        var element = node.declaredElement as ElementImpl;
        element.accept(
          _ShiftOffsetsElementVisitor(declaration.data.codeOffset),
        );
        if (element is HasMacroGenerationData) {
          (element as HasMacroGenerationData).macro = declaration.data;
        }
      }
    }

    linkingUnit.element.macroGeneratedContent = generatedContent;
    linkingUnit.element.macroGenerationDataList =
        _declarations.map((e) => e.data).toList();
  }
}

/// [MacroGenerationData] plus its linking [node] (to get the element).
class _Declaration {
  final MacroGenerationData data;
  final ast.AstNode node;

  _Declaration({
    required this.data,
    required this.node,
  });
}

/// TODO(scheglov) Enhance to support more nodes.
/// For now only nodes that are currently used in tests are supported.
/// Which is probably enough for experiments, but should be improved if this
/// is something we are going to do for real.
class _ShiftOffsetsAstVisitor extends RecursiveAstVisitor<void> {
  final int shift;

  _ShiftOffsetsAstVisitor(this.shift);

  @override
  void visitAnnotation(ast.Annotation node) {
    _token(node.atSign);
    super.visitAnnotation(node);
  }

  @override
  void visitSimpleIdentifier(ast.SimpleIdentifier node) {
    _token(node.token);
  }

  void _token(Token token) {
    token.offset += shift;
  }
}

/// Macro-generated elements are created from pieces of code that are rebased
/// to start at zero-th offset. When we later know that actual offset in the
/// combined (source + generated) code of the unit, we shift the offsets.
class _ShiftOffsetsElementVisitor extends GeneralizingElementVisitor<void> {
  final int shift;

  _ShiftOffsetsElementVisitor(this.shift);

  @override
  void visitElement(covariant ElementImpl element) {
    element.nameOffset += shift;
    _metadata(element.metadata);
    super.visitElement(element);
  }

  void _metadata(List<ElementAnnotation> metadata) {
    for (var annotation in metadata) {
      annotation as ElementAnnotationImpl;
      annotation.annotationAst.accept(
        _ShiftOffsetsAstVisitor(shift),
      );
    }
  }
}
