// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';

/// A selection within a compilation unit.
class Selection {
  /// The offset of the selection.
  final int offset;

  /// The length of the selection.
  final int length;

  /// The most deeply nested node whose range completely includes the selected
  /// range of characters.
  final AstNode coveringNode;

  /// Initialize a newly created selection to include the characters starting at
  /// the [offset] and including [length] characters, all of which fall within
  /// the [coveringNode].
  Selection(
      {required this.offset, required this.length, required this.coveringNode});

  /// Returns the contiguous subset of [coveringNode] children that are at
  /// least partially covered by the selection. Touching is not enough.
  ///
  /// A list of nodes is defined to be _contiguous_ if they are syntactically
  /// adjacent with no intervening tokens other than comments or commas. For
  /// example, the nodes might be a sequence of members in a compilation unit, a
  /// sequence of statements in a block, or a sequence of parameters in a
  /// parameter list that don't cross a separator such as `{` or `[`.
  List<AstNode> nodesInRange() {
    var rangeFinder = _ChildrenFinder(SourceRange(offset, length));
    coveringNode.accept(rangeFinder);
    return rangeFinder.nodes;
  }
}

/// A visitor used to find a sequence of nodes within the node being visited
/// that together cover the range.
class _ChildrenFinder extends SimpleAstVisitor<void> {
  /// The range that the sequence of nodes must cover.
  final SourceRange range;

  /// The nodes within the range.
  List<AstNode> nodes = [];

  /// Initialize a newly created visitor.
  _ChildrenFinder(this.range);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _fromList(node.strings);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _fromList(node.arguments);
  }

  @override
  void visitAugmentationImportDirective(AugmentationImportDirective node) {
    _fromList(node.metadata);
  }

  @override
  void visitBlock(Block node) {
    _fromList(node.statements);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _fromList(node.cascadeSections);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _fromList(node.metadata) || _fromList(node.members);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _fromList(node.metadata);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // TODO(brianwilkerson) Support selecting both directives and declarations.
    _fromList(node.directives) || _fromList(node.declarations);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _fromList(node.metadata) || _fromList(node.initializers);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _fromList(node.metadata);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _fromList(node.metadata);
  }

  @override
  void visitDottedName(DottedName node) {
    _fromList(node.components);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _fromList(node.metadata);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _fromList(node.metadata) ||
        _fromList(node.constants) ||
        _fromList(node.members);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _fromList(node.metadata) ||
        _fromList(node.configurations) ||
        _fromList(node.combinators);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _fromList(node.metadata) || _fromList(node.members);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _fromList(node.metadata);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _fromList(node.metadata);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _fromList(node.metadata);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    var delimiter = node.leftDelimiter;
    if (delimiter == null || !range.contains(delimiter.offset)) {
      _fromList(node.parameters);
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _fromList(node.updaters);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _fromList(node.updaters);
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _fromList(node.updaters);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _fromList(node.metadata);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _fromList(node.metadata);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _fromList(node.metadata);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _fromList(node.metadata);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _fromList(node.hiddenNames);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _fromList(node.interfaces);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _fromList(node.metadata) ||
        _fromList(node.configurations) ||
        _fromList(node.combinators);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _fromList(node.labels);
  }

  @override
  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    _fromList(node.metadata);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _fromList(node.metadata);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _fromList(node.components);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _fromList(node.elements);
  }

  @override
  void visitListPattern(ListPattern node) {
    _fromList(node.elements);
  }

  @override
  void visitMapPattern(MapPattern node) {
    _fromList(node.elements);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _fromList(node.metadata);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _fromList(node.metadata) || _fromList(node.members);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _fromList(node.fields);
  }

  @override
  void visitOnClause(OnClause node) {
    _fromList(node.superclassConstraints);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _fromList(node.metadata);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _fromList(node.metadata);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _fromList(node.metadata);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _fromList(node.fields);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _fromList(node.fields);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _fromList(node.positionalFields);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
      RecordTypeAnnotationNamedField node) {
    _fromList(node.metadata);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
      RecordTypeAnnotationNamedFields node) {
    _fromList(node.fields);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
      RecordTypeAnnotationPositionalField node) {
    _fromList(node.metadata);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _fromList(node.elements);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _fromList(node.shownNames);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _fromList(node.metadata);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _fromList(node.elements);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _fromList(node.metadata);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _fromList(node.labels) || _fromList(node.statements);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _fromList(node.labels) || _fromList(node.statements);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _fromList(node.cases);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _fromList(node.labels) || _fromList(node.statements);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _fromList(node.members);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _fromList(node.metadata);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _fromList(node.catchClauses);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _fromList(node.arguments);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _fromList(node.metadata);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _fromList(node.typeParameters);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _fromList(node.metadata) || _fromList(node.variables);
  }

  @override
  void visitWithClause(WithClause node) {
    _fromList(node.mixinTypes);
  }

  /// If one or more of the [elements] in the list can cover the [range], then
  /// add the elements to the list of [nodes] and return `true`.
  bool _fromList(List<AstNode> elements) {
    var first = elements.length;
    for (; first > 0; first--) {
      final element = elements[first - 1];
      if (element.end <= range.offset) {
        break;
      }
    }

    var last = first;
    for (; last < elements.length; last++) {
      final element = elements[last];
      if (element.offset >= range.end) {
        break;
      }
      nodes.add(element);
    }

    return nodes.isNotEmpty;
  }
}

extension CompilationUnitExtension on CompilationUnit {
  /// Return the selection that includes the characters starting at the [offset]
  /// with the given [length].
  Selection? select({required int offset, required int length}) {
    var coveringNode = nodeCovering(offset: offset, length: length);
    if (coveringNode == null) {
      return null;
    }
    return Selection(
        offset: offset, length: length, coveringNode: coveringNode);
  }
}
