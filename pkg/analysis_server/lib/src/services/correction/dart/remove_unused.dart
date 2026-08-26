// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedElement extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeUnusedElement;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var sourceRanges = <SourceRange>[];

    var node = this.node;

    if (node is ConstructorDeclaration) {
      await _constructorDeclaration(builder: builder, node: node);
      return;
    }

    if (node is NameWithTypeParameters) {
      node = node.parent!;
    }

    Element? element;
    if (node is Declaration) {
      element = node.declaredFragment?.element;
    }
    if (element == null) {
      return;
    }

    var references = element.findAllReferences(unit);
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
    switch (node.parent?.parent) {
      case ClassDeclaration classDeclaration:
        if (classDeclaration.body case BlockClassBody body) {
          members = body.members;
        } else {
          return;
        }
      case EnumDeclaration enumDeclaration:
        switch (enumDeclaration.body) {
          case BlockEnumBody body:
            members = body.members;
          default:
            return;
        }
      case _:
        return;
    }

    var nodeRange = range.nodeInList(members, node);

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(nodeRange);
    });
  }
}

class RemoveUnusedField extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  // Not predictably the correct action.
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeUnusedField;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = node;

    if (declaration is EnumConstantDeclaration) {
      var body = declaration.parent;
      if (body is EnumBody && body.constants.length > 1) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.nodeInList(body.constants, declaration));
        });
      }
      return;
    }

    if (declaration is! VariableDeclaration) {
      return;
    }

    var element = declaration.declaredFragment!.element;
    if (element is! FieldElement) {
      return;
    }

    var sourceRanges = <SourceRange>[];
    var references = [node, ...element.findAllReferences(unit)];
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
        if (referenceNode.fieldName.name != element.name) return;

        sourceRange = _forConstructorFieldInitializer(referenceNode);
      } else if (referenceNode is FieldFormalParameter) {
        var constructor = referenceNode
            .thisOrAncestorOfType<ConstructorDeclaration>();
        var hasOtherReference =
            constructor != null &&
            element.hasReferenceInConstructor(constructor);
        if (hasOtherReference) {
          // TODO(srawlins): Consider converting `FieldFormalParameter` into a
          // normal formal parameter (e.g. `A(this._a) : _b = compute(_a)` ->
          // `A(int a) : _b = compute(a)`) when the field is referenced in other
          // initializers or the constructor body.
          return;
        }

        var declaration = referenceNode.thisOrAncestorMatching(
          (node) =>
              node is ClassDeclaration ||
              node is EnumDeclaration ||
              node is ExtensionTypeDeclaration,
        );
        if (declaration != null) {
          var members = switch (declaration) {
            ClassDeclaration(:BlockClassBody body) => body.members,
            EnumDeclaration(:BlockEnumBody body) => body.members,
            ExtensionTypeDeclaration(:BlockClassBody body) => body.members,
            _ => const <ClassMember>[],
          };
          for (var primaryBody in members.whereType<PrimaryConstructorBody>()) {
            if (element.hasReferenceInPrimaryConstructorBody(primaryBody)) {
              // TODO(srawlins): Consider converting `FieldFormalParameter` into
              // a normal formal parameter in primary constructors as well.
              return;
            }
          }
        }

        sourceRange = _forFieldFormalParameter(referenceNode);
      } else if (referenceNode is ExpressionStatement) {
        if (referenceNode.expression case AssignmentExpression(
          :var leftHandSide,
        )) {
          var isFieldAssignment = switch (leftHandSide) {
            SimpleIdentifier(:var name) => name == element.name,
            PropertyAccess(:var propertyName) =>
              propertyName.name == element.name,
            _ => false,
          };
          if (!isFieldAssignment) return;
        } else {
          return;
        }
        sourceRange = utils.getLinesRange(range.node(referenceNode));
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
    var parent = node.parent;
    if (parent is ConstructorDeclaration) {
      if (parent.initializers.length == 1) {
        return range.endEnd(parent.parameters, node);
      } else {
        return range.nodeInList(parent.initializers, node);
      }
    } else if (parent is PrimaryConstructorBody) {
      if (parent.initializers.length == 1) {
        return range.endEnd(parent.thisKeyword, node);
      } else {
        return range.nodeInList(parent.initializers, node);
      }
    }
    return range.node(node);
  }

  SourceRange _forFieldFormalParameter(FieldFormalParameter node) {
    var parameter = node;
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
  final Element element;
  final List<AstNode> references = [];

  new(this.element);

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is FieldFormalParameterElement &&
        declaredElement.field == element) {
      references.add(node);
    }

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.element == element) {
      references.add(node);
    }

    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.writeOrReadElement;
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

extension on VariableElement {
  /// Returns whether `this` has any references in [constructor], other than
  /// an initializer assigning to `this`.
  bool hasReferenceInConstructor(ConstructorDeclaration constructor) =>
      _hasReferenceInConstructorLike(
        initializers: constructor.initializers,
        body: constructor.body,
      );

  /// Returns whether `this` has any references in [body], other than
  /// an initializer assigning to `this`.
  bool hasReferenceInPrimaryConstructorBody(PrimaryConstructorBody body) =>
      _hasReferenceInConstructorLike(
        initializers: body.initializers,
        body: body.body,
      );

  bool _hasReferenceInConstructorLike({
    required NodeList<ConstructorInitializer> initializers,
    required FunctionBody body,
  }) {
    for (var initializer in initializers) {
      if (initializer is ConstructorFieldInitializer &&
          initializer.fieldName.name == name) {
        continue;
      }
      var references = findAllReferences(initializer);
      if (references.isNotEmpty) return true;
    }
    if (body is BlockFunctionBody) {
      var references = findAllReferences(body);
      if (references.isNotEmpty) return true;
    }
    return false;
  }
}

extension on Element {
  /// Returns all references to `this` under [root].
  List<AstNode> findAllReferences(AstNode root) {
    var collector = _ElementReferenceCollector(this);
    root.accept(collector);
    return collector.references;
  }
}
