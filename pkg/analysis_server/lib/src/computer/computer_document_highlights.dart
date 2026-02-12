// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class DartDocumentHighlightsComputer {
  final CompilationUnit _unit;

  DartDocumentHighlightsComputer(this._unit);

  /// Computes matching highlight tokens for the requested offset.
  List<Token> compute(int requestedOffset) {
    var coveringNode = _unit.nodeCovering(offset: requestedOffset);
    if (coveringNode == null) return [];

    var targets = _computeTargets(coveringNode);
    if (targets == null) return [];

    var visitor = _DartDocumentHighlightsVisitor(targets);
    _unit.accept(visitor);
    return visitor.tokens.toList();
  }

  /// Computes the highlight target (elements and/or nodes) from the covering
  /// node at the requested offset.
  _HighlightTargets? _computeTargets(AstNode coveringNode) {
    // Handle node targets (loop keyword etc.).
    var targetNode = _getTargetNode(coveringNode);
    if (targetNode != null) {
      return _HighlightTargets.node(targetNode);
    }

    // Add the obvious target element.
    var mainTarget = _canonicalizeElement(_getTargetElement(coveringNode));

    // For pattern variables in implicit pattern fields (where the field name
    // is inferred from the variable name), also include the field element.

    var additionalTarget = switch (coveringNode) {
      VariablePattern(parent: PatternField(:var element, :var name))
          when name?.name == null =>
        _canonicalizeElement(element),
      _ => null,
    };

    return _HighlightTargets.elements(mainTarget, additionalTarget);
  }

  /// Gets the target [AstNode] for [node] if it's a node-based highlight group
  /// such as a loop keyword.
  AstNode? _getTargetNode(AstNode node) {
    return switch (node) {
      // Loop/switch keywords are targets.
      ForStatement() ||
      WhileStatement() ||
      DoStatement() ||
      SwitchStatement() => node,

      // Break/continue keywords target their respective targets.
      BreakStatement(:var target?) || ContinueStatement(:var target?) => target,

      // Return/yield target the function body.
      ReturnStatement() ||
      YieldStatement() => node.thisOrAncestorOfType<FunctionBody>(),

      _ => null,
    };
  }

  /// Canonicalizes an element so that field formal parameters map to their
  /// fields and property accessors map to their variables.
  static Element? _canonicalizeElement(Element? element) {
    if (element == null) return null;
    return switch (element) {
      FieldFormalParameterElement(:var field) => field?.baseElement,
      PropertyAccessorElement(:var variable)
          when variable.isOriginDeclaration =>
        variable.baseElement,
      _ => element.baseElement,
    };
  }

  /// Returns the target element for a given node, if one exists.
  static Element? _getTargetElement(AstNode node) {
    return switch (node) {
      // We don't consider primary constructor bodies as something we ever
      // provide highlights for.
      PrimaryConstructorBody() => null,

      // In references to constructors where the constructor has no name, we map
      // the (type) name to the constructor element.
      NamedType(parent: ConstructorName(name: null, :var element?)) => element,

      // And in constructor declarations that do have names, we map the type
      // name to the class element.
      Identifier(parent: ConstructorDeclaration parent)
          when parent.name != null && node == parent.typeName =>
        parent.declaredFragment?.element.enclosingElement,

      // For variable patterns with joins, use the base variable element.
      DeclaredVariablePattern(
        declaredFragment: BindPatternVariableFragment(
          element: BindPatternVariableElement(:var join?),
        ),
      ) =>
        join,

      // Otherwise, default ElementLocator result.
      _ => ElementLocator.locate(node),
    };
  }
}

class _DartDocumentHighlightsVisitor extends GeneralizingAstVisitor<void> {
  final _HighlightTargets _target;

  /// Collected tokens matching the target.
  final Set<Token> tokens = {};

  /// Stack to track the current function for return/yield keywords.
  final List<AstNode> _functionStack = [];

  _DartDocumentHighlightsVisitor(this._target);

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
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitCatchClauseParameter(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.namePart.typeName);

    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _addOccurrence(
      node.declaredFragment?.element,
      node.name ?? node.typeName?.beginToken,
    );

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
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var declaredElement = node.declaredFragment?.element;
    _addOccurrence(declaredElement?.join ?? declaredElement, node.name);

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _addNodeOccurrence(node, node.doKeyword);

    super.visitDoStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.namePart.typeName);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

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
      node.declaredFragment?.element,
      node.primaryConstructor.typeName,
    );

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFormalParameter(FormalParameter node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitFormalParameter(node);
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
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _addOccurrence(node.element, node.name);

    super.visitImportPrefixReference(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _addOccurrence(node.element, node.name);

    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    var pattern = node.pattern;
    var name = node.name?.name;

    // If no explicit field name, use the variables name.
    if (name == null && pattern is VariablePattern) {
      name = pattern.name;
    }
    _addOccurrence(node.element, name);

    super.visitPatternField(node);
  }

  @override
  void visitPrimaryConstructorName(PrimaryConstructorName node) {
    if (node.parent case PrimaryConstructorDeclaration primary) {
      _addOccurrence(primary.declaredFragment?.element, node.name);
    }

    super.visitPrimaryConstructorName(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _addNodeOccurrence(_functionStack.lastOrNull, node.returnKeyword);

    super.visitReturnStatement(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // For unnamed constructors, we don't want to add an occurrence for the
    // class name here because visitConstructorDeclaration will have added one
    // for the constructor (not the type).
    if (node.parent case ConstructorDeclaration(
      :var name,
      :var typeName,
    ) when name == null && node == typeName) {
      return;
    }

    _addOccurrence(node.writeOrReadElement, node.token);

    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _addNodeOccurrence(node, node.switchKeyword);

    super.visitSwitchStatement(node);
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitTypeAlias(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name);

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
    // Only add the occurrence if it matches our target node.
    if (node != null && _target.matchesNode(node)) {
      tokens.add(token);
    }
  }

  void _addOccurrence(Element? element, Token? token) {
    if (element == null || token == null) return;

    var canonicalElement = DartDocumentHighlightsComputer._canonicalizeElement(
      element,
    );

    // Only add the occurrence if it's one of our target elements.
    if (canonicalElement != null && _target.matchesElement(canonicalElement)) {
      tokens.add(token);
    }
  }
}

/// The highlight target(s) computed from the provided position.
///
/// Usually this will contain a single element or a single node, however in some
/// cases (such as a variable pattern) there may be multiple target elements
/// (such as a variable and the matched getter).
class _HighlightTargets {
  final Element? _targetElement1;
  final Element? _targetElement2;
  final AstNode? _targetNode;

  _HighlightTargets.elements([this._targetElement1, this._targetElement2])
    : _targetNode = null;

  _HighlightTargets.node(this._targetNode)
    : _targetElement1 = null,
      _targetElement2 = null;

  bool matchesElement(Element element) {
    return element == _targetElement1 || element == _targetElement2;
  }

  bool matchesNode(AstNode node) {
    return node == _targetNode;
  }
}
