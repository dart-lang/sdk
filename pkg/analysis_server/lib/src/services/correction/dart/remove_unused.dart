// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedElement extends _RemoveUnused {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_ELEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final sourceRanges = <SourceRange>[];
    final referencedNode = node.parent;
    if (referencedNode is ClassDeclaration ||
        referencedNode is EnumDeclaration ||
        referencedNode is FunctionDeclaration ||
        referencedNode is FunctionTypeAlias ||
        referencedNode is MethodDeclaration ||
        referencedNode is VariableDeclaration) {
      final element = referencedNode is Declaration
          ? referencedNode.declaredElement
          : (referencedNode as NamedCompilationUnitMember).declaredElement;
      final references = _findAllReferences(unit, element);
      // todo (pq): consider filtering for references that are limited to within the class.
      if (references.length == 1) {
        SourceRange sourceRange;
        if (referencedNode is VariableDeclaration) {
          VariableDeclarationList parent = referencedNode.parent;
          if (parent.variables.length == 1) {
            sourceRange = utils.getLinesRange(range.node(parent.parent));
          } else {
            sourceRange = range.nodeInList(parent.variables, referencedNode);
          }
        } else {
          sourceRange = utils.getLinesRange(range.node(referencedNode));
        }
        sourceRanges.add(sourceRange);
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnusedElement newInstance() => RemoveUnusedElement();
}

class RemoveUnusedField extends _RemoveUnused {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_FIELD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.parent;
    if (declaration is! VariableDeclaration) {
      return;
    }

    final element = (declaration as VariableDeclaration).declaredElement;
    if (element is! FieldElement) {
      return;
    }

    final sourceRanges = <SourceRange>[];
    final references = _findAllReferences(unit, element);
    for (var reference in references) {
      // todo (pq): consider scoping this to parent or parent.parent.
      final referenceNode = reference.thisOrAncestorMatching((node) =>
          node is VariableDeclaration ||
          node is ExpressionStatement ||
          node is ConstructorFieldInitializer ||
          node is FieldFormalParameter);
      if (referenceNode == null) {
        return;
      }
      SourceRange sourceRange;
      if (referenceNode is VariableDeclaration) {
        sourceRange = _forVariableDeclaration(referenceNode);
      } else if (referenceNode is ConstructorFieldInitializer) {
        sourceRange = _forConstructorFieldInitializer(referenceNode);
      } else if (referenceNode is FieldFormalParameter) {
        sourceRange = _forFieldFormalParameter(referenceNode);
      } else {
        sourceRange = utils.getLinesRange(range.node(referenceNode));
      }
      sourceRanges.add(sourceRange);
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }

  SourceRange _forConstructorFieldInitializer(
    ConstructorFieldInitializer node,
  ) {
    final constructor = node.parent as ConstructorDeclaration;
    if (constructor.initializers.length == 1) {
      return range.endEnd(constructor.parameters, node);
    } else {
      return range.nodeInList(constructor.initializers, node);
    }
  }

  SourceRange _forFieldFormalParameter(FieldFormalParameter node) {
    var parameter = node.parent is DefaultFormalParameter ? node.parent : node;
    var parameterList = parameter.parent as FormalParameterList;

    // (node) -> ()
    if (parameterList.parameters.length == 1) {
      return range.endStart(
        parameterList.leftParenthesis,
        parameterList.rightParenthesis,
      );
    }

    var prevToken = parameter.beginToken.previous;
    var nextToken = parameter.endToken.next;

    // (node, tail) -> (tail)
    if (nextToken.type == TokenType.COMMA) {
      nextToken = nextToken.next;
      return range.startStart(parameter.beginToken, nextToken);
    }

    // (head, node) -> (head)
    // (head, node, tail) -> (head, tail)
    var isFirstOptional = prevToken.type == TokenType.OPEN_CURLY_BRACKET ||
        prevToken.type == TokenType.OPEN_SQUARE_BRACKET;
    if (isFirstOptional) {
      prevToken = prevToken.previous;
    }
    if (isFirstOptional) {
      var isLastOptional = nextToken.type == TokenType.CLOSE_CURLY_BRACKET ||
          nextToken.type == TokenType.CLOSE_SQUARE_BRACKET;
      if (isLastOptional) {
        nextToken = nextToken.next;
      }
    }
    return range.endStart(prevToken.previous, nextToken);
  }

  SourceRange _forVariableDeclaration(VariableDeclaration node) {
    VariableDeclarationList parent = node.parent;
    if (parent.variables.length == 1) {
      return utils.getLinesRange(range.node(parent.parent));
    } else {
      return range.nodeInList(parent.variables, node);
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnusedField newInstance() => RemoveUnusedField();
}

class _ElementReferenceCollector extends RecursiveAstVisitor<void> {
  final Element element;
  final List<SimpleIdentifier> references = [];

  _ElementReferenceCollector(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final staticElement = node.writeOrReadElement;
    if (staticElement == element) {
      references.add(node);
    } else if (staticElement is PropertyAccessorElement) {
      if (staticElement.variable == element) {
        references.add(node);
      }
    } else if (staticElement is FieldFormalParameterElement) {
      if (staticElement.field == element) {
        references.add(node);
      }
    }
  }
}

abstract class _RemoveUnused extends CorrectionProducer {
  List<SimpleIdentifier> _findAllReferences(AstNode root, Element element) {
    var collector = _ElementReferenceCollector(element);
    root.accept(collector);
    return collector.references;
  }
}
