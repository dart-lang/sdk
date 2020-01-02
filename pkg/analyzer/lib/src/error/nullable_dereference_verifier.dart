// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for checking potentially nullable dereferences.
class NullableDereferenceVerifier {
  /// Properties on the object class which are safe to call on nullable types.
  ///
  /// Note that this must include tear-offs.
  ///
  /// TODO(mfairhurst): Calculate these fields rather than hard-code them.
  static const _objectPropertyNames = {
    'hashCode',
    'runtimeType',
    'noSuchMethod',
    'toString',
  };

  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;

  NullableDereferenceVerifier({
    @required TypeSystemImpl typeSystem,
    @required ErrorReporter errorReporter,
  })  : _typeSystem = typeSystem,
        _errorReporter = errorReporter;

  bool expression(Expression expression) {
    if (!_typeSystem.isNonNullableByDefault) {
      return false;
    }

    return _check(expression, expression.staticType);
  }

  void implicitThis(AstNode errorNode, DartType thisType) {
    if (!_typeSystem.isNonNullableByDefault) {
      return;
    }

    _check(errorNode, thisType);
  }

  void methodInvocation(
    Expression receiver,
    DartType receiverType,
    String methodName,
  ) {
    if (!_typeSystem.isNonNullableByDefault) {
      return;
    }

    if (methodName == 'toString' || methodName == 'noSuchMethod') {
      return;
    }

    _check(receiver, receiverType);
  }

  void propertyAccess(AstNode errorNode, DartType receiverType, String name) {
    if (!_typeSystem.isNonNullableByDefault) {
      return;
    }

    if (_objectPropertyNames.contains(name)) {
      return;
    }

    _check(errorNode, receiverType);
  }

  /// If the [receiverType] is potentially nullable, report it.
  ///
  /// The [errorNode] is usually the receiver of the invocation, but if the
  /// receiver is the implicit `this`, the name of the invocation.
  bool _check(AstNode errorNode, DartType receiverType) {
    if (identical(receiverType, DynamicTypeImpl.instance) ||
        !_typeSystem.isPotentiallyNullable(receiverType)) {
      return false;
    }

    var errorCode = receiverType == _typeSystem.typeProvider.nullType
        ? StaticWarningCode.INVALID_USE_OF_NULL_VALUE
        : StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE;
    _errorReporter.reportErrorForNode(errorCode, errorNode);
    return true;
  }
}
