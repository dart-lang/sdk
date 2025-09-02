// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddTypeAnnotation extends ResolvedCorrectionProducer {
  @override
  final CorrectionApplicability applicability;

  /// Initializes a newly created instance that can't apply bulk and in-file
  /// fixes.
  AddTypeAnnotation({required super.context})
    : applicability = CorrectionApplicability.singleLocation;

  /// Initializes a newly created instance that can apply bulk and in-file fixes.
  AddTypeAnnotation.bulkFixable({required super.context})
    : applicability = CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.addTypeAnnotation;

  @override
  FixKind get fixKind => DartFixKind.ADD_TYPE_ANNOTATION;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_TYPE_ANNOTATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;

    if (node is SimpleFormalParameter) {
      await _forSimpleFormalParameter(builder, node);
      return;
    }

    if (node is DeclaredVariablePattern) {
      var type = node.matchedValueType;
      var keyword = node.keyword;
      await _applyChange(builder, keyword, node.name, type!);
      return;
    }

    if (node case TypedLiteral(
      :var typeArguments,
    ) when typeArguments == null || typeArguments.isSynthetic) {
      await _typedLiteral(builder, node);
      return;
    }

    for (var node in this.node.withAncestors) {
      if (node is VariableDeclarationList) {
        await _forVariableDeclaration(builder, node);
        return;
      } else if (node is DeclaredIdentifier) {
        await _forDeclaredIdentifier(builder, node);
        return;
      } else if (node is ForStatement) {
        var forLoopParts = node.forLoopParts;
        if (forLoopParts is ForEachParts) {
          var offset = this.node.offset;
          if (offset < forLoopParts.iterable.offset) {
            if (forLoopParts is ForEachPartsWithDeclaration) {
              await _forDeclaredIdentifier(builder, forLoopParts.loopVariable);
            }
          }
        }
        return;
      }
    }
  }

  Future<void> _applyChange(
    ChangeBuilder builder,
    Token? keyword,
    Token name,
    DartType type,
  ) async {
    await builder.addDartFileEdit(file, (builder) {
      if (builder.canWriteType(type)) {
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addReplacement(range.token(keyword), (builder) {
            builder.writeType(type);
          });
        } else {
          builder.addInsertion(name.offset, (builder) {
            builder.writeType(type);
            builder.write(' ');
          });
        }
      }
    });
  }

  Future<void> _forDeclaredIdentifier(
    ChangeBuilder builder,
    DeclaredIdentifier declaredIdentifier,
  ) async {
    // Ensure that there isn't already a type annotation.
    if (declaredIdentifier.type != null) {
      return;
    }
    var type = declaredIdentifier.declaredFragment!.element.type;
    if (type is! InterfaceType &&
        type is! FunctionType &&
        type is! RecordType &&
        type is! TypeParameterType) {
      return;
    }
    await _applyChange(
      builder,
      declaredIdentifier.keyword,
      declaredIdentifier.name,
      type,
    );
  }

  Future<void> _forSimpleFormalParameter(
    ChangeBuilder builder,
    SimpleFormalParameter parameter,
  ) async {
    // Ensure that there isn't already a type annotation.
    if (parameter.type != null) {
      return;
    }
    // Ensure that the parameter is named.
    var name = parameter.name;
    if (name == null) {
      return;
    }
    // Prepare the type.
    var type = parameter.declaredFragment!.element.type;
    // TODO(scheglov): If the parameter is in a method declaration, and if the
    // method overrides a method that has a type for the corresponding
    // parameter, it would be nice to copy down the type from the overridden
    // method.
    if (type is! InterfaceType &&
        //        type is! FunctionType &&
        type is! RecordType) {
      return;
    }
    await _applyChange(builder, null, name, type);
  }

  Future<void> _forVariableDeclaration(
    ChangeBuilder builder,
    VariableDeclarationList declarationList,
  ) async {
    // Ensure that there isn't already a type annotation.
    if (declarationList.type != null) {
      return;
    }
    var variables = declarationList.variables;
    var variable = variables[0];
    // Ensure that the selection is not after the name of the variable.
    if (selectionOffset > variable.name.end) {
      return;
    }
    // Ensure that there is an initializer to get the type from.
    var type = _typeForVariable(variable);
    if (type == null) {
      return;
    }
    // Ensure that there is a single type.
    for (var i = 1; i < variables.length; i++) {
      if (_typeForVariable(variables[i]) != type) {
        return;
      }
    }
    if ((type is! InterfaceType || type.isDartCoreNull) &&
        type is! FunctionType &&
        type is! RecordType &&
        type is! TypeParameterType) {
      return;
    }
    await _applyChange(builder, declarationList.keyword, variable.name, type);
  }

  Future<void> _typedLiteral(ChangeBuilder builder, TypedLiteral node) async {
    var type = node.staticType;
    if (type is! InterfaceType) {
      return;
    }

    int offset;
    switch (node) {
      case ListLiteral():
        offset = node.leftBracket.offset;
      case SetOrMapLiteral():
        offset = node.leftBracket.offset;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(offset, (builder) {
        builder.write('<');
        builder.writeTypes(type.typeArguments, shouldWriteDynamic: true);
        builder.write('>');
      });
    });
  }

  DartType? _typeForVariable(VariableDeclaration variable) {
    var initializer = variable.initializer;
    if (initializer != null) {
      return initializer.staticType;
    }
    // The parents should be a [VariableDeclarationList],
    // [VariableDeclarationStatement], and [Block], in that order.
    var statement = variable.parent?.parent;
    var block = statement?.parent;
    if (statement is! VariableDeclarationStatement || block is! Block) {
      return null;
    }
    var element = variable.declaredFragment?.element;
    if (element is! LocalVariableElement) {
      return null;
    }
    var statements = block.statements;
    var index = statements.indexOf(statement);
    var visitor = _AssignedTypeCollector(typeSystem, element);
    for (var i = index + 1; i < statements.length; i++) {
      statements[i].accept(visitor);
    }
    return visitor.bestType;
  }
}

class _AssignedTypeCollector extends RecursiveAstVisitor<void> {
  /// The type system used to compute the best type.
  final TypeSystem typeSystem;

  final LocalVariableElement variable;

  /// The types that are assigned to the variable.
  final Set<DartType> assignedTypes = {};

  _AssignedTypeCollector(this.typeSystem, this.variable);

  DartType? get bestType {
    if (assignedTypes.isEmpty) {
      return null;
    }
    var types = assignedTypes.toList();
    var bestType = types[0];
    for (var i = 1; i < assignedTypes.length; i++) {
      bestType = typeSystem.leastUpperBound(bestType, types[i]);
    }
    return bestType;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var leftHandSide = node.leftHandSide;
    if (leftHandSide is SimpleIdentifier && leftHandSide.element == variable) {
      var type = node.rightHandSide.staticType;
      if (type != null) {
        assignedTypes.add(type);
      }
    }
    return super.visitAssignmentExpression(node);
  }
}
