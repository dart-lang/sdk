// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

void addDartOccurrences(OccurrencesCollector collector, CompilationUnit unit) {
  var visitor = DartUnitOccurrencesComputerVisitor();
  unit.accept(visitor);
  visitor.elementOccurrences.forEach((engineElement, nodes) {
    // For legacy protocol, we only support occurrences with the same
    // length, so we must filter the offset to only those that match the length
    // from the element.
    var serverElement = protocol.convertElement(engineElement);
    // Prefer the length from the mapped element over the element directly,
    // because 'name3' may contain 'new' for constructors which doesn't match
    // what is in the source.
    var length =
        serverElement.location?.length ?? engineElement.name?.length ?? 0;
    var offsets = nodes
        .where((node) => node.length == length)
        .map((node) => node.offset)
        .toList();

    var occurrences = protocol.Occurrences(serverElement, offsets, length);
    collector.addOccurrences(occurrences);
  });
}

/// Returns both element-based and node-based occurrences for a file.
///
/// The legacy protocol does not support occurrences that are not based on
/// elements and therefore use [addDartOccurrences]. This method is for LSP
/// which does not use elements and instead only cares about the resulting
/// ranges of code, allowing ranges for keywords like `return` and `break` to be
/// included.
List<Occurrences> getAllOccurrences(CompilationUnit unit) {
  // TODO(dantup): Since LSP always starts with a target element or node,
  //  we should consider passing it in here to avoid building the occurrences
  // for the whole file and then extracting only the matches we want.
  var visitor = DartUnitOccurrencesComputerVisitor();
  unit.accept(visitor);

  return [
    // Element-based occurrences
    for (var MapEntry(key: element, value: tokens)
        in visitor.elementOccurrences.entries)
      ElementOccurrences(element, tokens),
    // Node-based occurrences
    for (var MapEntry(key: node, value: tokens)
        in visitor.nodeOccurrences.entries)
      NodeOccurrences(node, tokens),
  ];
}

class DartUnitOccurrencesComputerVisitor extends GeneralizingAstVisitor<void> {
  /// Occurrences tracked by their elements.
  final Map<Element, List<Token>> elementOccurrences = {};

  /// Occurrences tracked by nodes (such as loops and their exit keywords).
  final Map<AstNode, List<Token>> nodeOccurrences = {};

  // Stack to track the current function for return/yield keywords
  final List<AstNode> _functionStack = [];

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var element = node.element;
    if (element != null) {
      _addOccurrence(element, node.name);
    }

    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _addNodeOccurrence(node.target, node.breakKeyword);

    super.visitBreakStatement(node);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    if (node.declaredFragment?.element case var element?) {
      _addOccurrence(element, node.name);
    }
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.namePart.typeName);

    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitClassTypeAlias(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name case var name?) {
      _addOccurrence(node.declaredFragment!.element, name);
    } else {
      _addOccurrence(
        node.declaredFragment!.element,
        node.returnType.beginToken,
      );
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // For unnamed constructors, we add an occurence for the constructor at
    // the location of the returnType.
    if (node.name == null) {
      var element = node.element;
      if (element != null) {
        _addOccurrence(element, node.type.name);
      }
      // Still visit the import prefix if there is one.
      node.type.importPrefix?.accept(this);
      return; // skip visitNamedType.
    }

    super.visitConstructorName(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _addNodeOccurrence(node.target, node.continueKeyword);

    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var declaredElement = node.declaredFragment!.element;
    if (declaredElement case BindPatternVariableElement(:var join?)) {
      _addOccurrence(join.baseElement, node.name);
    } else {
      _addOccurrence(declaredElement, node.name);
    }

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _addNodeOccurrence(node, node.doKeyword);

    super.visitDoStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.namePart.typeName);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (node case ExtensionDeclaration(:var declaredFragment?, :var name?)) {
      _addOccurrence(declaredFragment.element, name);
    }

    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _addOccurrence(node.element, node.name);

    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _addOccurrence(
      node.declaredFragment!.element,
      node.primaryConstructor.typeName,
    );

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is FieldFormalParameterElement) {
      var field = declaredElement.field;
      if (field != null) {
        _addOccurrence(field, node.name);
      }
    }

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _addNodeOccurrence(node, node.forKeyword);

    super.visitForStatement(node);
  }

  @override
  void visitFunctionBody(FunctionBody node) {
    _functionStack.add(node);
    super.visitFunctionBody(node);
    _functionStack.removeLastOrNull();
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitGenericTypeAlias(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    if (node.element case var element?) {
      _addOccurrence(element, node.name);
    }

    super.visitImportPrefixReference(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    var element = node.element;
    if (element != null) {
      _addOccurrence(element, node.name);
    }

    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    var element = node.element;
    var pattern = node.pattern;
    // If no explicit field name, use the variables name.
    var name = node.name?.name == null && pattern is VariablePattern
        ? pattern.name
        : node.name?.name;
    if (element != null && name != null) {
      _addOccurrence(element, name);
    }
    super.visitPatternField(node);
  }

  @override
  void visitPrimaryConstructorName(PrimaryConstructorName node) {
    if (node.parent case PrimaryConstructorDeclaration primary) {
      _addOccurrence(primary.declaredFragment!.element, node.name);
    }

    super.visitPrimaryConstructorName(node);
  }

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    if (node.constructorName case var constructorName?) {
      _addOccurrence(node.constructorFragment!.element, constructorName.name);
    }

    super.visitRepresentationDeclaration(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _addNodeOccurrence(_functionStack.lastOrNull, node.returnKeyword);

    super.visitReturnStatement(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var nameToken = node.name;
    if (nameToken != null) {
      _addOccurrence(node.declaredFragment!.element, nameToken);
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // For unnamed constructors, we don't want to add an occurrence for the
    // class name here because visitConstructorDeclaration will have added one
    // for the constructor (not the type).
    if (node.parent case ConstructorDeclaration(
      :var name,
      :var returnType,
    ) when name == null && node == returnType) {
      return;
    }

    var element = node.writeOrReadElement;
    if (element != null) {
      _addOccurrence(element, node.token);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _addOccurrence(node.declaredFragment!.element, node.name);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _addNodeOccurrence(node, node.switchKeyword);

    super.visitSwitchStatement(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (node case TypeParameter(:var declaredFragment?)) {
      _addOccurrence(declaredFragment.element, node.name);
    }

    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _addNodeOccurrence(node, node.whileKeyword);

    super.visitWhileStatement(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _addNodeOccurrence(_functionStack.lastOrNull, node.yieldKeyword);

    super.visitYieldStatement(node);
  }

  void _addNodeOccurrence(AstNode? node, Token token) {
    if (node == null) return;

    (nodeOccurrences[node] ??= []).add(token);
  }

  void _addOccurrence(Element element, Token token) {
    var canonicalElement = _canonicalizeElement(element);
    if (canonicalElement == null) {
      return;
    }
    (elementOccurrences[canonicalElement] ??= []).add(token);
  }

  Element? _canonicalizeElement(Element element) {
    Element? canonicalElement = element;
    if (canonicalElement is FieldFormalParameterElement) {
      canonicalElement = canonicalElement.field;
    } else if (canonicalElement case PropertyAccessorElement(
      :var variable,
    ) when !variable.isSynthetic) {
      canonicalElement = variable;
    }
    return canonicalElement?.baseElement;
  }
}

/// Occurrences grouped by an Element.
class ElementOccurrences extends Occurrences {
  final Element element;

  @override
  final List<Token> tokens;

  ElementOccurrences(this.element, this.tokens);
}

/// Occurrences grouped by a node (for example exit keywords grouped by a loop).
class NodeOccurrences extends Occurrences {
  final AstNode node;

  @override
  final List<Token> tokens;

  NodeOccurrences(this.node, this.tokens);
}

/// Base class for protocol-agnostic occurrences.
sealed class Occurrences {
  List<Token> get tokens;
}
