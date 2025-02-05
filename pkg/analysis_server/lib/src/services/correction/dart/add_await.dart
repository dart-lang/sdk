// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddAwait extends ResolvedCorrectionProducer {
  /// The kind of correction to be made.
  final _CorrectionKind _correctionKind;

  AddAwait.argumentType({required super.context})
    : _correctionKind = _CorrectionKind.argumentType;

  AddAwait.assignment({required super.context})
    : _correctionKind = _CorrectionKind.invalidAssignment;

  AddAwait.nonBool({required super.context})
    : _correctionKind = _CorrectionKind.nonBool;

  AddAwait.unawaited({required super.context})
    : _correctionKind = _CorrectionKind.unawaited;

  @override
  CorrectionApplicability get applicability =>
          // Adding `await` can change behaviour and is not clearly the right
          // choice. See https://github.com/dart-lang/sdk/issues/54022.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_AWAIT;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_AWAIT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    switch (_correctionKind) {
      case _CorrectionKind.argumentType:
        if (_isValidType(expectedTypeFromExp: (exp) => exp.argumentType)) {
          await _addAwait(builder);
        }
      case _CorrectionKind.invalidAssignment:
        if (_isValidType(expectedTypeFromExp: (exp) => exp.assignmentType)) {
          await _addAwait(builder);
        }
      case _CorrectionKind.nonBool:
        if (_isValidType(isValid: (type) => type.isDartCoreBool)) {
          await _addAwait(builder);
        }
      case _CorrectionKind.unawaited:
        if (node.parent is! CascadeExpression) {
          await _addAwait(builder);
        }
    }
  }

  Future<void> _addAwait(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(errorOffset ?? node.offset, 'await ');
    });
  }

  /// If the expression is not a future it is not valid.
  /// If the expression is a future, we check if the type of the future is
  /// assignable to the expected type using either [isValid] or
  /// [expectedTypeFromExp].
  /// If [isValid] is provided, it is used to check if the future's type is
  /// valid.
  /// If [expectedTypeFromExp] is provided the return type should be the
  /// underlying expected type of the expression. The future type will then be
  /// checked if it is assignable to it.
  bool _isValidType({
    DartType? Function(Expression expr)? expectedTypeFromExp,
    bool Function(DartType type)? isValid,
  }) {
    assert(
      (isValid != null) ^ (expectedTypeFromExp != null),
      'Use either isValid or expectedTypeFromExp, but not both',
    );
    var expr = node;
    if (expr is! Expression) {
      return false;
    }
    var staticType = expr.staticType;
    if (staticType is! InterfaceType) {
      return false;
    }
    if (!staticType.isDartAsyncFuture) {
      return false;
    }

    var typeArg = expectedTypeFromExp?.call(expr);
    if (typeArg == null && isValid == null) {
      return false;
    }

    var type = staticType.typeArguments.first;
    if (typeArg == null) {
      return isValid!(type);
    } else {
      return typeSystem.isAssignableTo(type, typeArg);
    }
  }
}

/// The kinds of corrections supported by [AddAwait].
enum _CorrectionKind { argumentType, invalidAssignment, nonBool, unawaited }

extension on Expression {
  DartType? get argumentType {
    var expr = this;
    if (parent case NamedExpression named) {
      expr = named;
    }
    if (expr.parent is ArgumentList) {
      return expr.correspondingParameter?.type;
    }
    return null;
  }

  DartType? get assignmentType {
    return switch (parent) {
      VariableDeclarationImpl variableDeclaration => variableDeclaration.type,
      AssignmentExpression assignment => assignment.writeType,
      _ => null,
    };
  }
}
