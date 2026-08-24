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
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddTypeAnnotation extends ResolvedCorrectionProducer {
  @override
  final CorrectionApplicability applicability;

  final bool forRepresentationField;

  /// Initializes a newly created instance that can't apply bulk and in-file
  /// fixes.
  new({required super.context})
    : applicability = CorrectionApplicability.singleLocation,
      forRepresentationField = false;

  /// Initializes a newly created instance that can apply bulk and in-file
  /// fixes.
  new bulkFixable({required super.context})
    : applicability = CorrectionApplicability.automatically,
      forRepresentationField = false;

  /// Initializes a newly created instance that will replace the keyword with
  /// the added type.
  new forRepresentationField({required super.context})
    : applicability = CorrectionApplicability.singleLocation,
      forRepresentationField = true;

  @override
  AssistKind get assistKind => DartAssistKind.addTypeAnnotation;

  @override
  FixKind get fixKind => DartFixKind.addTypeAnnotation;

  @override
  FixKind get multiFixKind => DartFixKind.addTypeAnnotationMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;

    if (node is RegularFormalParameter) {
      await _forRegularFormalParameter(builder, node);
      return;
    }

    if (node is DeclaredVariablePattern) {
      var type = node.matchedValueType;
      var keyword = node.keyword;
      await _applyChange(builder, keyword, node.name, type!);
      return;
    }

    if (node case TypedLiteral(:var typeArguments)
        when typeArguments == null || typeArguments.isSynthetic) {
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
      if (builder.canWriteType(type, offset: name.offset)) {
        if (keyword != null &&
            (forRepresentationField || keyword.keyword == Keyword.VAR)) {
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

  Future<void> _forRegularFormalParameter(
    ChangeBuilder builder,
    RegularFormalParameter parameter,
  ) async {
    // Ensure that there isn't already a type annotation.
    if (parameter.type != null) {
      return;
    }
    // Ensure that the parameter has a named.
    var name = parameter.name;
    if (name == null) {
      return;
    }
    // Prepare the type.
    var type = parameter.declaredFragment!.element.type;
    // TODO(scheglov): If the parameter is in a method declaration, and if the
    //  method overrides a method that has a type for the corresponding
    //  parameter, it would be nice to copy down the type from the overridden
    //  method.
    if (type is! InterfaceType &&
        // type is! FunctionType &&
        type is! RecordType) {
      return;
    }
    var keyword = forRepresentationField
        ? parameter.constFinalOrVarKeyword
        : null;
    await _applyChange(builder, keyword, name, type);
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

    var offset = switch (node) {
      ListLiteral() => node.leftBracket.offset,
      SetOrMapLiteral() => node.leftBracket.offset,
    };

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
    var laterStatements = statements.sublist(index + 1);
    var visitor = _AssignedTypeCollector(typeSystem, element);
    for (var laterStatement in laterStatements) {
      laterStatement.accept(visitor);
    }
    var type = visitor.bestType;
    if (type == null) {
      return null;
    }
    // If none of the later statements is guaranteed to assign a value to
    // the variable (for example, because the only assignment is inside the
    // body of a loop, a single-branch `if`, or a `try` block), then the
    // variable might still hold its implicit initial value, `null`, so the
    // inferred type needs to be nullable.
    if (!laterStatements.any((s) => _isDefinitelyAssigned(s, element))) {
      type = (type as TypeImpl).withNullability(NullabilitySuffix.question);
    }
    return type;
  }

  /// Returns whether executing [statement] to normal completion is
  /// guaranteed to assign a value to [variable].
  ///
  /// This is a heuristic, not a full definite-assignment analysis: in
  /// particular, the [Block] case doesn't account for a preceding statement
  /// exiting the block early (for example via `break`, `continue`, `return`,
  /// or a thrown exception) before an assigning statement is reached. Such a
  /// case can cause this method to incorrectly report that a variable is
  /// definitely assigned, which in turn can cause the computed type to be
  /// non-nullable when it should be nullable.
  static bool _isDefinitelyAssigned(
    Statement statement,
    LocalVariableElement variable,
  ) {
    switch (statement) {
      case ExpressionStatement(:var expression):
        return switch (expression) {
          AssignmentExpression(leftHandSide: SimpleIdentifier(:var element)) =>
            element == variable,
          _ => _isDefinitelyAssignedByImmediateInvocation(expression, variable),
        };
      case Block(:var statements):
        return statements.any((s) => _isDefinitelyAssigned(s, variable));
      case IfStatement(:var thenStatement, :var elseStatement):
        return elseStatement != null &&
            _isDefinitelyAssigned(thenStatement, variable) &&
            _isDefinitelyAssigned(elseStatement, variable);
      case TryStatement(:var finallyBlock):
        // A `finally` block runs no matter how the `try` statement
        // completes (including via an exception), so if it definitely
        // assigns the variable, so does the whole `try` statement.
        return finallyBlock != null &&
            _isDefinitelyAssigned(finallyBlock, variable);
      case DoStatement(:var body):
        // The body of a `do`-`while` loop always runs at least once.
        return _isDefinitelyAssigned(body, variable);
      case LabeledStatement(:var statement):
        return _isDefinitelyAssigned(statement, variable);
      default:
        return false;
    }
  }

  /// Returns whether [expression] is the invocation of a synchronous,
  /// non-generator closure literal that's called immediately (an IIFE), and
  /// whose body is guaranteed to assign a value to [variable]. Such an
  /// invocation runs the closure body to completion as part of evaluating
  /// [expression].
  static bool _isDefinitelyAssignedByImmediateInvocation(
    Expression expression,
    LocalVariableElement variable,
  ) {
    if (expression is! FunctionExpressionInvocation) {
      return false;
    }
    var function = expression.function;
    if (function is! FunctionExpression) {
      return false;
    }
    var body = function.body;
    if (body is! BlockFunctionBody || !body.isSynchronous || body.isGenerator) {
      return false;
    }
    return _isDefinitelyAssigned(body.block, variable);
  }
}

class _AssignedTypeCollector extends RecursiveAstVisitor<void> {
  /// The type system used to compute the best type.
  final TypeSystem typeSystem;

  final LocalVariableElement variable;

  /// The types that are assigned to the variable.
  final Set<DartType> assignedTypes = {};

  new(this.typeSystem, this.variable);

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
