// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';

void addDartOccurrences(OccurrencesCollector collector, CompilationUnit unit) {
  var visitor = _DartUnitOccurrencesComputerVisitor();
  unit.accept(visitor);
  visitor.elementsOffsets.forEach((engineElement, offsets) {
    var length = engineElement.nameLength;
    var serverElement = protocol.convertElement(engineElement,
        withNullability: unit.isNonNullableByDefault);
    var occurrences = protocol.Occurrences(serverElement, offsets, length);
    collector.addOccurrences(occurrences);
  });
}

class _DartUnitOccurrencesComputerVisitor extends RecursiveAstVisitor<void> {
  final Map<Element, List<int>> elementsOffsets = <Element, List<int>>{};

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    final element = node.element;
    if (element != null) {
      _addOccurrence(element, node.name.offset);
    }

    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);

    super.visitClassDeclaration(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _addOccurrence(node.declaredElement!, node.name.offset);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _addOccurrence(node.declaredElement!, node.name.offset);

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    final declaredElement = node.declaredElement;
    if (declaredElement is FieldFormalParameterElement) {
      final field = declaredElement.field;
      if (field != null) {
        _addOccurrence(field, node.name.offset);
      }
    }

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitPatternField(PatternField node) {
    final element = node.element;
    final name = node.name;
    if (element != null && name != null) {
      _addOccurrence(element, name.offset);
    }
    super.visitPatternField(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    final nameToken = node.name;
    if (nameToken != null) {
      _addOccurrence(node.declaredElement!, nameToken.offset);
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element != null) {
      _addOccurrence(element, node.offset);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _addOccurrence(node.declaredElement!, node.name.offset);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addOccurrence(node.declaredElement!, node.name.offset);
    super.visitVariableDeclaration(node);
  }

  void _addOccurrence(Element element, int offset) {
    var canonicalElement = _canonicalizeElement(element);
    if (canonicalElement == null || element == DynamicElementImpl.instance) {
      return;
    }
    var offsets = elementsOffsets[canonicalElement];
    if (offsets == null) {
      offsets = <int>[];
      elementsOffsets[canonicalElement] = offsets;
    }
    offsets.add(offset);
  }

  Element? _canonicalizeElement(Element element) {
    Element? canonicalElement = element;
    if (canonicalElement is FieldFormalParameterElement) {
      canonicalElement = canonicalElement.field;
    } else if (canonicalElement is PropertyAccessorElement) {
      canonicalElement = canonicalElement.variable;
    }
    return canonicalElement?.declaration;
  }
}
