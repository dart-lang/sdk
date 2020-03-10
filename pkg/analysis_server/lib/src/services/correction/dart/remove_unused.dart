// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedElement extends _RemoveUnused {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_ELEMENT;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
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
        var sourceRange;
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

    await builder.addFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }
}

class RemoveUnusedField extends _RemoveUnused {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_FIELD;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
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
      var sourceRange;
      if (referenceNode is VariableDeclaration) {
        VariableDeclarationList parent = referenceNode.parent;
        if (parent.variables.length == 1) {
          sourceRange = utils.getLinesRange(range.node(parent.parent));
        } else {
          sourceRange = range.nodeInList(parent.variables, referenceNode);
        }
      } else if (referenceNode is ConstructorFieldInitializer) {
        ConstructorDeclaration cons =
            referenceNode.parent as ConstructorDeclaration;
        // A() : _f = 0;
        if (cons.initializers.length == 1) {
          sourceRange = range.endEnd(cons.parameters, referenceNode);
        } else {
          sourceRange = range.nodeInList(cons.initializers, referenceNode);
        }
      } else if (referenceNode is FieldFormalParameter) {
        FormalParameterList params =
            referenceNode.parent as FormalParameterList;
        if (params.parameters.length == 1) {
          sourceRange =
              range.endStart(params.leftParenthesis, params.rightParenthesis);
        } else {
          sourceRange = range.nodeInList(params.parameters, referenceNode);
        }
      } else {
        sourceRange = utils.getLinesRange(range.node(referenceNode));
      }
      sourceRanges.add(sourceRange);
    }

    await builder.addFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }
}

class _ElementReferenceCollector extends RecursiveAstVisitor<void> {
  final Element element;
  final List<SimpleIdentifier> references = [];

  _ElementReferenceCollector(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final staticElement = node.staticElement;
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
