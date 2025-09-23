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

  AddAwait.forIn({required super.context})
    : _correctionKind = _CorrectionKind.forIn;

  AddAwait.nonBool({required super.context})
    : _correctionKind = _CorrectionKind.nonBool;

  AddAwait.unawaited({required super.context})
    : _correctionKind = _CorrectionKind.unawaited;

  @override
  CorrectionApplicability get applicability =>
      // Adding `await` can change behaviour and is not clearly the right
      // choice. See https://github.com/dart-lang/sdk/issues/54022.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_AWAIT;

  FunctionBody? get _functionBodyIfNotAsync {
    var body = node.thisOrAncestorOfType<FunctionBody>();
    if (body != null && !body.isAsynchronous && body.star == null) {
      return body;
    }
    return null;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    switch (_correctionKind) {
      case _CorrectionKind.argumentType:
        if (_isValidFutureType(
          expectedTypeFromExp: (exp) => exp.argumentType,
        )) {
          await _addAwait(builder, convertToAsync: _functionBodyIfNotAsync);
        }
      case _CorrectionKind.invalidAssignment:
        if (_isValidFutureType(
          expectedTypeFromExp: (exp) => exp.assignmentType,
        )) {
          await _addAwait(builder, convertToAsync: _functionBodyIfNotAsync);
        }
      case _CorrectionKind.nonBool:
        if (_isValidFutureType(isValid: (type) => type.isDartCoreBool)) {
          await _addAwait(builder, convertToAsync: _functionBodyIfNotAsync);
        }
      case _CorrectionKind.unawaited:
        if (node is CascadeExpression) {
          // If this is the target of a cascade, than adding `await` is not
          // necesarily correct because parentheses may be needed.
          // For example, `a..b().c` should become `await (a..b()).c`.
          // So we don't do anything here.
          return;
        }
        // The reported node may be the `identifier` in a PrefixedIdentifier,
        // the `propertyName` in a PropertyAccess, or the `methodName` in a
        // MethodInvocation. Check whether the grandparent is a
        // CascadeExpression. If it is, we cannot simply add an await
        // expression; we must also change the cascade(s) into a regular
        // property access or method call.
        // If this is ever broken we must fix here and at:
        // - DartFixKind.ADD_ASYNC
        // - DartFixKind.WRAP_IN_UNAWAITED
        if (node.parent case AstNode(
          :var offset,
          :var parent,
        ) when parent is! CascadeExpression) {
          await _addAwait(builder, offset: offset);
        }
      case _CorrectionKind.forIn:
        if (node.parent case ForEachPartsWithDeclaration(
          :var iterable,
          :var parent,
        ) when iterable == node) {
          var type = iterable.staticType;
          var isStream =
              type != null &&
              typeSystem.isAssignableTo(type, typeProvider.streamDynamicType);
          if (isStream ||
              _isValidFutureType(
                isValid: (type) => typeSystem.isAssignableTo(
                  type,
                  typeProvider.iterableDynamicType,
                ),
              )) {
            await _addAwait(
              builder,
              offset: isStream ? parent.offset : null,
              convertToAsync: _functionBodyIfNotAsync,
            );
          }
        }
    }
  }

  Future<void> _addAwait(
    ChangeBuilder builder, {
    int? offset,
    FunctionBody? convertToAsync,
  }) async {
    await builder.addDartFileEdit(file, (builder) {
      if (convertToAsync != null) {
        builder.convertFunctionFromSyncToAsync(
          body: convertToAsync,
          typeSystem: typeSystem,
          typeProvider: typeProvider,
        );
      }
      builder.addSimpleInsertion(
        offset ?? diagnosticOffset ?? node.offset,
        'await ',
      );
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
  bool _isValidFutureType({
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
enum _CorrectionKind {
  argumentType,
  invalidAssignment,
  nonBool,
  unawaited,
  forIn,
}

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
      VariableDeclaration variableDeclaration =>
        variableDeclaration.declaredFragment!.element.type,
      AssignmentExpression assignment => assignment.writeType,
      _ => null,
    };
  }
}
