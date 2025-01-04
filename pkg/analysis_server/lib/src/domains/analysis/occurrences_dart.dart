// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';

void addDartOccurrences(OccurrencesCollector collector, CompilationUnit unit) {
  var visitor = _DartUnitOccurrencesComputerVisitor();
  unit.accept(visitor);
  visitor.elementsOffsets.forEach((engineElement, offsets) {
    var length = engineElement.name3?.length ?? 0;
    var serverElement = protocol.convertElement2(engineElement);
    var occurrences = protocol.Occurrences(serverElement, offsets, length);
    collector.addOccurrences(occurrences);
  });
}

class _DartUnitOccurrencesComputerVisitor extends RecursiveAstVisitor<void> {
  final Map<Element2, List<int>> elementsOffsets = {};

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var element = node.element2;
    if (element != null) {
      _addOccurrence(element, node.name.offset);
    }

    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitClassTypeAlias(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name case var name?) {
      _addOccurrence(node.declaredFragment!.element, name.offset);
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _addOccurrence(node.declaredElement2!, node.name.offset);

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is FieldFormalParameterElement2) {
      var field = declaredElement.field2;
      if (field != null) {
        _addOccurrence(field, node.name.offset);
      }
    }

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    var element = node.element2;
    if (element != null) {
      _addOccurrence(element, node.name2.offset);
    }

    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    var element = node.element2;
    var pattern = node.pattern;
    // If no explicit field name, use the variables name.
    var name =
        node.name?.name == null && pattern is VariablePattern
            ? pattern.name
            : node.name?.name;
    if (element != null && name != null) {
      _addOccurrence(element, name.offset);
    }
    super.visitPatternField(node);
  }

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    if (node.constructorName case var constructorName?) {
      _addOccurrence(
        node.constructorFragment!.element,
        constructorName.name.offset,
      );
    }

    super.visitRepresentationDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var nameToken = node.name;
    if (nameToken != null) {
      _addOccurrence(node.declaredFragment!.element, nameToken.offset);
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement2;
    if (element != null) {
      _addOccurrence(element, node.offset);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name.offset);
    super.visitVariableDeclaration(node);
  }

  void _addOccurrence(Element2 element, int offset) {
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

  Element2? _canonicalizeElement(Element2 element) {
    Element2? canonicalElement = element;
    if (canonicalElement is FieldFormalParameterElement2) {
      canonicalElement = canonicalElement.field2;
    } else if (canonicalElement is PropertyAccessorElement2) {
      canonicalElement = canonicalElement.variable3;
    }
    return canonicalElement?.baseElement;
  }
}
