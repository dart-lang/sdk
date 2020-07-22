// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddReturnType extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.ADD_RETURN_TYPE;

  @override
  FixKind get fixKind => DartFixKind.ADD_RETURN_TYPE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    SyntacticEntity insertBeforeEntity;
    FunctionBody body;
    if (node is SimpleIdentifier) {
      var executable = node.parent;
      if (executable is MethodDeclaration && executable.name == node) {
        if (executable.returnType != null) {
          return;
        }
        if (isLintEnabled(LintNames.avoid_return_types_on_setters) &&
            executable.isSetter) {
          return;
        }
        insertBeforeEntity = executable.propertyKeyword ?? executable.name;
        body = executable.body;
      } else if (executable is FunctionDeclaration && executable.name == node) {
        if (executable.returnType != null) {
          return;
        }
        if (isLintEnabled(LintNames.avoid_return_types_on_setters) &&
            executable.isSetter) {
          return;
        }
        insertBeforeEntity = executable.propertyKeyword ?? executable.name;
        body = executable.functionExpression.body;
      } else {
        return;
      }
    }

    var returnType = _inferReturnType(body);
    if (returnType == null) {
      return null;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertBeforeEntity.offset, (builder) {
        if (returnType.isDynamic) {
          builder.write('dynamic');
        } else {
          builder.writeType(returnType);
        }
        builder.write(' ');
      });
    });
  }

  /// Return the type of value returned by the function [body], or `null` if a
  /// type can't be inferred.
  DartType _inferReturnType(FunctionBody body) {
    DartType baseType;
    if (body is ExpressionFunctionBody) {
      baseType = body.expression.staticType;
    } else if (body is BlockFunctionBody) {
      var computer = _ReturnTypeComputer(resolvedResult.typeSystem);
      body.block.accept(computer);
      baseType = computer.returnType;
      if (baseType == null && computer.hasReturn) {
        baseType = typeProvider.voidType;
      }
    }

    if (baseType == null) {
      return null;
    }

    var isAsynchronous = body.isAsynchronous;
    var isGenerator = body.isGenerator;
    if (isAsynchronous) {
      if (isGenerator) {
        return typeProvider.streamElement.instantiate(
          typeArguments: [baseType],
          nullabilitySuffix: baseType.nullabilitySuffix,
        );
      } else {
        return typeProvider.futureElement.instantiate(
          typeArguments: [baseType],
          nullabilitySuffix: baseType.nullabilitySuffix,
        );
      }
    } else if (isGenerator) {
      return typeProvider.iterableElement.instantiate(
        typeArguments: [baseType],
        nullabilitySuffix: baseType.nullabilitySuffix,
      );
    }
    return baseType;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddReturnType newInstance() => AddReturnType();
}

/// Copied from lib/src/services/refactoring/extract_method.dart", but
/// [hasReturn] was added.
// TODO(brianwilkerson) Decide whether to unify the two classes.
class _ReturnTypeComputer extends RecursiveAstVisitor<void> {
  final TypeSystem typeSystem;

  DartType returnType;

  /// A flag indicating whether at least one return statement was found.
  bool hasReturn = false;

  _ReturnTypeComputer(this.typeSystem);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    hasReturn = true;
    // prepare expression
    var expression = node.expression;
    if (expression == null) {
      return;
    }
    // prepare type
    var type = expression.staticType;
    if (type.isBottom) {
      return;
    }
    // combine types
    if (returnType == null) {
      returnType = type;
    } else {
      if (returnType is InterfaceType && type is InterfaceType) {
        returnType = InterfaceType.getSmartLeastUpperBound(returnType, type);
      } else {
        returnType = typeSystem.leastUpperBound(returnType, type);
      }
    }
  }
}
