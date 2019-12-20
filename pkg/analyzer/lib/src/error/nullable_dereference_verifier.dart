// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

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

  NullableDereferenceVerifier(this._typeSystem, this._errorReporter);

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

  void propertyAccess(Expression receiver, DartType receiverType, String name) {
    if (!_typeSystem.isNonNullableByDefault) {
      return;
    }

    if (_objectPropertyNames.contains(name)) {
      return;
    }

    _check(receiver, receiverType);
  }

  /// If the [receiverType] is potentially nullable, report it.
  void _check(Expression receiver, DartType receiverType) {
    if (identical(receiverType, DynamicTypeImpl.instance) ||
        !_typeSystem.isPotentiallyNullable(receiverType)) {
      return;
    }

    var errorCode = receiverType == _typeSystem.typeProvider.nullType
        ? StaticWarningCode.INVALID_USE_OF_NULL_VALUE
        : StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE;
    _errorReporter.reportErrorForNode(errorCode, receiver);
  }
}
