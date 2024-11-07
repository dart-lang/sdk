// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedElement extends _RemoveUnused {
  RemoveUnusedElement({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // Not predictably the correct action.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_ELEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var sourceRanges = <SourceRange>[];

    var node = this.node;

    if (node is ConstructorDeclaration) {
      await _constructorDeclaration(builder: builder, node: node);
      return;
    }

    Element2? element;
    if (node is FragmentDeclaration) {
      element = node.declaredFragment?.element;
    }
    if (element == null) {
      return;
    }

    var references = _findAllReferences(unit, element);
    // TODO(pq): consider filtering for references that are limited to within the class.
    if (references.isEmpty) {
      var parent = node.parent;
      var grandParent = parent?.parent;
      SourceRange sourceRange;
      if (node is VariableDeclaration &&
          parent is VariableDeclarationList &&
          grandParent != null) {
        if (parent.variables.length == 1) {
          sourceRange = utils.getLinesRange(range.node(grandParent));
        } else {
          sourceRange = range.nodeInList(parent.variables, node);
        }
      } else {
        sourceRange = utils.getLinesRange(range.node(node));
      }
      sourceRanges.add(sourceRange);
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }

  Future<void> _constructorDeclaration({
    required ChangeBuilder builder,
    required ConstructorDeclaration node,
  }) async {
    NodeList<ClassMember> members;
    switch (node.parent) {
      case ClassDeclaration classDeclaration:
        members = classDeclaration.members;
      case EnumDeclaration enumDeclaration:
        members = enumDeclaration.members;
      case _:
        return;
    }

    var nodeRange = range.nodeInList(members, node);

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(nodeRange);
    });
  }
}

class RemoveUnusedField extends _RemoveUnused {
  RemoveUnusedField({required super.context});

  @override
  // Not predictably the correct action.
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_FIELD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = node;
    if (declaration is! VariableDeclaration) {
      return;
    }

    var element = declaration.declaredFragment!.element;
    if (element is! FieldElement2) {
      return;
    }

    var sourceRanges = <SourceRange>[];
    var references = [node, ..._findAllReferences(unit, element)];
    for (var reference in references) {
      // TODO(pq): consider scoping this to parent or parent.parent.
      var referenceNode = reference.thisOrAncestorMatching(
        (node) =>
            node is VariableDeclaration ||
            node is ExpressionStatement ||
            node is ConstructorFieldInitializer ||
            node is FieldFormalParameter,
      );
      if (referenceNode == null) {
        return;
      }
      var parent = referenceNode.parent;
      var grandParent = parent?.parent;
      SourceRange sourceRange;
      if (referenceNode is VariableDeclaration &&
          parent is VariableDeclarationList &&
          grandParent != null) {
        sourceRange = _forVariableDeclaration(
          referenceNode,
          parent,
          grandParent,
        );
      } else if (referenceNode is ConstructorFieldInitializer) {
        sourceRange = _forConstructorFieldInitializer(referenceNode);
      } else if (referenceNode is FieldFormalParameter) {
        sourceRange = _forFieldFormalParameter(referenceNode);
      } else {
        sourceRange = utils.getLinesRange(range.node(referenceNode));
      }
      sourceRanges.add(sourceRange);
    }

    var uniqueSourceRanges = _uniqueSourceRanges(sourceRanges);
    await builder.addDartFileEdit(file, (builder) {
      for (var sourceRange in uniqueSourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }

  SourceRange _forConstructorFieldInitializer(
    ConstructorFieldInitializer node,
  ) {
    var constructor = node.parent as ConstructorDeclaration;
    if (constructor.initializers.length == 1) {
      return range.endEnd(constructor.parameters, node);
    } else {
      return range.nodeInList(constructor.initializers, node);
    }
  }

  SourceRange _forFieldFormalParameter(FieldFormalParameter node) {
    var parent = node.parent;
    var parameter = parent is DefaultFormalParameter ? parent : node;
    var parameterList = parameter.parent as FormalParameterList;

    // (node) -> ()
    if (parameterList.parameters.length == 1) {
      return range.endStart(
        parameterList.leftParenthesis,
        parameterList.rightParenthesis,
      );
    }

    var prevToken = parameter.beginToken.previous!;
    var nextToken = parameter.endToken.next!;

    // (node, tail) -> (tail)
    if (nextToken.type == TokenType.COMMA) {
      nextToken = nextToken.next!;
      return range.startStart(parameter.beginToken, nextToken);
    }

    // (head, node) -> (head)
    // (head, node, tail) -> (head, tail)
    var isFirstOptional =
        prevToken.type == TokenType.OPEN_CURLY_BRACKET ||
        prevToken.type == TokenType.OPEN_SQUARE_BRACKET;
    if (isFirstOptional) {
      prevToken = prevToken.previous!;
    }
    if (isFirstOptional) {
      var isLastOptional =
          nextToken.type == TokenType.CLOSE_CURLY_BRACKET ||
          nextToken.type == TokenType.CLOSE_SQUARE_BRACKET;
      if (isLastOptional) {
        nextToken = nextToken.next!;
      }
    }
    return range.endStart(prevToken.previous!, nextToken);
  }

  SourceRange _forVariableDeclaration(
    VariableDeclaration node,
    VariableDeclarationList parent,
    AstNode grandParent,
  ) {
    if (parent.variables.length == 1) {
      return utils.getLinesRange(range.node(grandParent));
    } else {
      return range.nodeInList(parent.variables, node);
    }
  }

  /// Return [SourceRange]s that are not covered by other in [ranges].
  /// If there is any intersection, it must be fully covered, never partially.
  List<SourceRange> _uniqueSourceRanges(List<SourceRange> ranges) {
    var result = <SourceRange>[];
    candidates:
    for (var candidate in ranges) {
      for (var other in ranges) {
        if (identical(candidate, other)) {
          continue;
        } else if (candidate.coveredBy(other)) {
          continue candidates;
        }
      }
      result.add(candidate);
    }
    return result;
  }
}

class _ElementReferenceCollector extends RecursiveAstVisitor<void> {
  final Element2 element;
  final List<AstNode> references = [];

  _ElementReferenceCollector(this.element);

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment!.element;
    if (declaredElement is FieldFormalParameterElement2) {
      if (declaredElement.field2 == element) {
        references.add(node);
      }
    }

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.element2 == element) {
      references.add(node);
    }

    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.writeOrReadElement2;
    if (staticElement == element) {
      references.add(node);
    } else if (staticElement is GetterElement) {
      if (staticElement.variable3 == element) {
        references.add(node);
      }
    } else if (staticElement is SetterElement) {
      if (staticElement.variable3 == element) {
        references.add(node);
      }
    } else if (staticElement is FieldFormalParameterElement2) {
      if (staticElement.field2 == element) {
        references.add(node);
      }
    }
  }
}

abstract class _RemoveUnused extends ResolvedCorrectionProducer {
  _RemoveUnused({required super.context});

  List<AstNode> _findAllReferences(AstNode root, Element2 element) {
    var collector = _ElementReferenceCollector(element);
    root.accept(collector);
    return collector.references;
  }
}
