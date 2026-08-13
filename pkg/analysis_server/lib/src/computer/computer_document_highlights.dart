// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show DocumentHighlightKind;
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class DartDocumentHighlightsComputer {
  final CompilationUnit _unit;

  new(this._unit);

  /// Computes matching highlight tokens for the requested offset.
  List<({Token token, DocumentHighlightKind kind})> compute(
    int requestedOffset,
  ) {
    var coveringNode = _unit.nodeCovering(offset: requestedOffset);
    coveringNode = _adjustNode(requestedOffset, coveringNode);
    if (coveringNode == null) return [];

    var targets = _computeTargets(coveringNode);
    if (targets == null) return [];

    var visitor = _DartDocumentHighlightsVisitor(targets);
    _unit.accept(visitor);
    return visitor.tokens.toList();
  }

  /// Adjusts the result of `nodeCovering` for cases where a position falls
  /// between two nodes and the wrong one is selected.
  AstNode? _adjustNode(int offset, AstNode? coveringNode) {
    return switch (coveringNode) {
      // In `ClassName.new^()` nodeCovering selects the parameter list but
      // we want the constructor.
      FormalParameterList(:var parent?) when offset == coveringNode.offset =>
        parent,
      // In a constructor declaration with either a type name or a constructor
      // name, we don't treat the keyword as something that has matches. It only
      // has matches if it's `new()` or `factory()`.
      ConstructorDeclaration(
        :var typeName,
        :var name,
        newKeyword: var keyword?,
      ) ||
      ConstructorDeclaration(
        :var typeName,
        :var name,
        factoryKeyword: var keyword?,
      )
          when (typeName != null || name != null) &&
              offset >= keyword.offset &&
              offset <= keyword.end =>
        null,
      _ => coveringNode,
    };
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
    var mainTarget = _getTargetElement(coveringNode)?.canonical;

    var additionalTarget = switch (coveringNode) {
      FormalParameter(
        declaredFragment: FormalParameterFragment(
          :FieldFormalParameterElement element,
        ),
      ) =>
        element.field,
      // For pattern variables in implicit pattern fields (where the field name
      // is inferred from the variable name), also include the field element.
      VariablePattern(parent: PatternField(:var element, :var name))
          when name?.name == null =>
        element?.canonical,
      _ => null,
    };

    // Include matching elements from superclasses as targets.
    var allTargets = {
      ?mainTarget,
      ?additionalTarget,
      ...?mainTarget?.supertypeMembers,
      ...?additionalTarget?.supertypeMembers,
    };

    return _HighlightTargets.elements(allTargets);
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

  /// Collected tokens matching the target along with the kind of reference.
  final Set<({Token token, DocumentHighlightKind kind})> tokens = {};

  /// Stack to track the current function for return/yield keywords.
  final List<AstNode> _functionStack = [];

  new(this._target);

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var element = node.element;
    if (element != null) {
      _addOccurrence(element, node.name, .Write);
    }

    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _addNodeOccurrence(node.target, node.breakKeyword, .Text);

    super.visitBreakStatement(node);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitCatchClauseParameter(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addOccurrence(
      node.declaredFragment?.element,
      node.namePart.typeName,
      .Write,
    );

    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _addOccurrence(
      node.declaredFragment?.element,
      node.name ??
          node.typeName?.beginToken ??
          node.newKeyword ??
          node.factoryKeyword,
      .Write,
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
        _addOccurrence(element, node.type.name, .Read);
      }
      // Still visit the import prefix if there is one.
      node.type.importPrefix?.accept(this);
      return; // skip visitNamedType.
    }

    super.visitConstructorName(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _addNodeOccurrence(node.target, node.continueKeyword, .Text);

    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var declaredElement = node.declaredFragment?.element;
    _addOccurrence(declaredElement?.join ?? declaredElement, node.name, .Write);

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _addNodeOccurrence(node, node.doKeyword, .Text);

    super.visitDoStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _addOccurrence(
      node.declaredFragment?.element,
      node.namePart.typeName,
      .Write,
    );

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _addOccurrence(node.element, node.name, .Write);

    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _addOccurrence(
      node.declaredFragment?.element,
      node.namePart.typeName,
      .Write,
    );

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFormalParameter(FormalParameter node) {
    var element = node.declaredFragment?.element;
    if (element is FieldFormalParameterElement) {
      // These tests have to be separate because of
      // `DocumentHighlightsTest.test_field_unresolved`
      if (element.field != null) {
        _addOccurrence(element, node.name, .Write);
        _addOccurrence(element.field, node.name, .Write);
      }
    } else {
      _addOccurrence(element, node.name, .Write);
    }

    super.visitFormalParameter(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _addNodeOccurrence(node, node.forKeyword, .Text);

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
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _addOccurrence(node.element, node.name, .Read);

    super.visitImportPrefixReference(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    _addOccurrence(node.correspondingParameter, node.name, .Write);
    node.argumentExpression.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    _addOccurrence(node.element, node.name, .Read);

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
    _addOccurrence(node.element, name, .Write);

    super.visitPatternField(node);
  }

  @override
  void visitPrimaryConstructorName(PrimaryConstructorName node) {
    if (node.parent case PrimaryConstructorDeclaration primary) {
      _addOccurrence(primary.declaredFragment?.element, node.name, .Write);
    }

    super.visitPrimaryConstructorName(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _addNodeOccurrence(_functionStack.lastOrNull, node.returnKeyword, .Text);

    super.visitReturnStatement(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // For unnamed constructors, we don't want to add an occurrence for the
    // class name here because visitConstructorDeclaration will have added one
    // for the constructor (not the type).
    if (node.parent case ConstructorDeclaration(:var name, :var typeName)
        when name == null && node == typeName) {
      return;
    }

    _addOccurrence(
      node.writeOrReadElement,
      node.token,
      node.writeElement != null ? .Write : .Read,
    );

    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _addNodeOccurrence(node, node.switchKeyword, .Text);

    super.visitSwitchStatement(node);
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitTypeAlias(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addOccurrence(node.declaredFragment?.element, node.name, .Write);

    super.visitVariableDeclaration(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _addNodeOccurrence(node, node.whileKeyword, .Text);

    super.visitWhileStatement(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _addNodeOccurrence(_functionStack.lastOrNull, node.yieldKeyword, .Text);

    super.visitYieldStatement(node);
  }

  void _addNodeOccurrence(
    AstNode? node,
    Token token,
    DocumentHighlightKind kind,
  ) {
    // Only add the occurrence if it matches our target node.
    if (node != null && _target.matchesNode(node)) {
      tokens.add((token: token, kind: kind));
    }
  }

  void _addOccurrence(
    Element? element,
    Token? token,
    DocumentHighlightKind kind,
  ) {
    if (element == null || token == null) return;

    var canonicalElement = element.canonical;

    if (canonicalElement == null) {
      return;
    }

    // Do a cheap name check before looking at the hierarchy.
    if (!_target.matchesElementName(canonicalElement)) {
      return;
    }

    // This returns Iterable and will be lazily iterated by `any()` below if the
    // canonical element doesn't match.
    var supertypeMembers = canonicalElement.supertypeMembers;

    // Only add the occurrence if it's one of our target elements.
    if (_target.matchesElement(canonicalElement) ||
        supertypeMembers.any(_target.matchesElement)) {
      tokens.add((token: token, kind: kind));
    }
  }
}

/// The highlight target(s) computed from the provided position.
///
/// Usually this will contain a single element or a single node, however in some
/// cases (such as a variable pattern) there may be multiple target elements
/// (such as a variable and the matched getter).
class _HighlightTargets {
  final Set<Element> _targetElements;
  final Set<String> _targetElementNames;
  final AstNode? _targetNode;

  new elements(this._targetElements)
    : _targetNode = null,
      _targetElementNames = {
        for (var element in _targetElements) ?element.name,
      };

  new node(this._targetNode)
    : _targetElements = const {},
      _targetElementNames = const {};

  bool matchesElement(Element element) {
    return _targetElements.contains(element);
  }

  bool matchesElementName(Element canonicalElement) {
    return _targetElementNames.contains(canonicalElement.name);
  }

  bool matchesNode(AstNode node) {
    return node == _targetNode;
  }
}

extension on Element {
  /// All members in superclasses that this element overrides.
  Iterable<Element> get supertypeMembers {
    var enclosing = enclosingElement;
    if (enclosing is! InterfaceElement) return const [];

    var name = Name.forElement(this);
    if (name == null) return const [];

    var session = this.session;
    if (session is! AnalysisSessionImpl) return const [];

    // Get this member for all supertypes.
    var inheritanceManager = session.inheritanceManager;
    return enclosing.allSupertypes
        .map(
          (supertype) => inheritanceManager.getMember(supertype.element, name),
        )
        .map((element) => element?.canonical)
        .nonNulls;
  }
}
