// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:meta/meta.dart';

class BodyInferenceContext {
  static const _key = 'BodyInferenceContext';

  final TypeSystemImpl _typeSystem;
  final bool _isAsynchronous;
  final bool _isGenerator;

  /// The context type, computed from the imposed return type schema.
  /// Might be `null` if an empty typing context.
  final DartType contextType;

  /// Types of all `return` or `yield` statements in the body.
  final List<DartType> _returnTypes = [];

  factory BodyInferenceContext({
    @required TypeSystemImpl typeSystem,
    @required FunctionBody node,
    @required DartType imposedType,
  }) {
    var contextType = _contextTypeForImposed(typeSystem, node, imposedType);

    var bodyContext = BodyInferenceContext._(
      typeSystem: typeSystem,
      isAsynchronous: node.isAsynchronous,
      isGenerator: node.isGenerator,
      contextType: contextType,
    );
    node.setProperty(_key, bodyContext);

    return bodyContext;
  }

  BodyInferenceContext._({
    @required TypeSystemImpl typeSystem,
    @required bool isAsynchronous,
    @required bool isGenerator,
    @required this.contextType,
  })  : _typeSystem = typeSystem,
        _isAsynchronous = isAsynchronous,
        _isGenerator = isGenerator;

  TypeProvider get _typeProvider => _typeSystem.typeProvider;

  void addReturnExpression(Expression expression) {
    if (expression == null) {
      _returnTypes.add(_typeProvider.nullType);
    } else {
      var type = expression.staticType;
      if (_isAsynchronous) {
        type = _typeSystem.flatten(type);
      }
      _returnTypes.add(type);
    }
  }

  void addYield(YieldStatement node) {
    var expressionType = node.expression.staticType;

    if (node.star == null) {
      _returnTypes.add(expressionType);
      return;
    }

    if (_isGenerator) {
      var requiredClass = _isAsynchronous
          ? _typeProvider.streamElement
          : _typeProvider.iterableElement;
      var type = _argumentOf(expressionType, requiredClass);
      if (type != null) {
        _returnTypes.add(type);
      }
    }
  }

  DartType computeInferredReturnType({
    @required bool endOfBlockIsReachable,
  }) {
    var actualReturnedType = _computeActualReturnedType(
      endOfBlockIsReachable: endOfBlockIsReachable,
    );

    var clampedReturnedType = _clampToContextType(actualReturnedType);

    if (_isGenerator) {
      if (_isAsynchronous) {
        return _typeProvider.streamType2(clampedReturnedType);
      } else {
        return _typeProvider.iterableType2(clampedReturnedType);
      }
    } else {
      if (_isAsynchronous) {
        return _typeProvider.futureType2(
          _typeSystem.flatten(clampedReturnedType),
        );
      } else {
        return clampedReturnedType;
      }
    }
  }

  /// Let `T` be the **actual returned type** of a function literal.
  DartType _clampToContextType(DartType T) {
    // Let `R` be the greatest closure of the typing context `K`.
    var R = contextType;
    if (R == null) {
      return T;
    }

    // If `R` is `void`, or the function literal is marked `async` and `R` is
    // `FutureOr<void>`, let `S` be `void`.
    if (_typeSystem.isNonNullableByDefault) {
      if (R.isVoid ||
          _isAsynchronous &&
              R is InterfaceType &&
              R.isDartAsyncFutureOr &&
              R.typeArguments[0].isVoid) {
        return VoidTypeImpl.instance;
      }
    }

    // Otherwise, if `T <: R` then let `S` be `T`.
    if (_typeSystem.isSubtypeOf2(T, R)) {
      return T;
    }

    // Otherwise, let `S` be `R`.
    return _typeSystem.nonNullifyLegacy(R);
  }

  DartType _computeActualReturnedType({
    @required bool endOfBlockIsReachable,
  }) {
    if (_isGenerator) {
      if (_returnTypes.isEmpty) {
        return DynamicTypeImpl.instance;
      }
      return _returnTypes.reduce(_typeSystem.getLeastUpperBound);
    }

    var initialType = endOfBlockIsReachable
        ? _typeProvider.nullType
        : _typeProvider.neverType;
    return _returnTypes.fold(initialType, _typeSystem.getLeastUpperBound);
  }

  static BodyInferenceContext of(FunctionBody node) {
    return node.getProperty(_key);
  }

  static DartType _argumentOf(DartType type, ClassElement element) {
    var elementType = type.asInstanceOf(element);
    if (elementType != null) {
      return elementType.typeArguments[0];
    }
    return null;
  }

  static DartType _contextTypeForImposed(
    TypeSystemImpl typeSystem,
    FunctionBody node,
    DartType imposedType,
  ) {
    if (imposedType == null) {
      return null;
    }

    // If the function expression is neither `async` nor a generator, then the
    // context type is the imposed return type.
    if (!node.isAsynchronous && !node.isGenerator) {
      return imposedType;
    }

    // If the function expression is declared `async*` and the imposed return
    // type is of the form `Stream<S>` for some `S`, then the context type
    // is `S`.
    if (node.isGenerator && node.isAsynchronous) {
      var elementType = _argumentOf(
        imposedType,
        typeSystem.typeProvider.streamElement,
      );
      if (elementType != null) {
        return elementType;
      }
    }

    // If the function expression is declared `sync*` and the imposed return
    // type is of the form `Iterable<S>` for some `S`, then the context type
    // is `S`.
    if (node.isGenerator && node.isSynchronous) {
      var elementType = _argumentOf(
        imposedType,
        typeSystem.typeProvider.iterableElement,
      );
      if (elementType != null) {
        return elementType;
      }
    }

    // Otherwise the context type is `FutureOr<futureValueTypeSchema(S)>`,
    // where `S` is the imposed return type.
    return typeSystem.typeProvider.futureOrType2(
      typeSystem.futureValueType(imposedType),
    );
  }
}
