// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

/// See https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#function-literal-return-type-inference
class BodyInferenceContext {
  final TypeSystemImpl _typeSystem;
  final bool isAsynchronous;
  final bool isGenerator;

  /// The imposed return type, from the typing context.
  /// Might be `null` if an empty typing context.
  final TypeImpl? imposedType;

  /// The context type, computed from [imposedType].
  /// Might be `null` if an empty typing context.
  final TypeImpl? contextType;

  /// Types of all `return` or `yield` statements in the body.
  final List<DartType> _returnTypes = [];

  /// Whether the execution flow can reach the end of the body.
  ///
  /// For example here, because there is no `return` at the end.
  /// ```
  /// void f() {}
  /// ```
  bool mayCompleteNormally = true;

  factory BodyInferenceContext({
    required TypeSystemImpl typeSystem,
    required FunctionBodyImpl node,
    required TypeImpl? imposedType,
  }) {
    var contextType = _contextTypeForImposed(typeSystem, node, imposedType);

    var bodyContext = BodyInferenceContext._(
      typeSystem: typeSystem,
      isAsynchronous: node.isAsynchronous,
      isGenerator: node.isGenerator,
      imposedType: imposedType,
      contextType: contextType,
    );
    node.bodyContext = bodyContext;

    return bodyContext;
  }

  BodyInferenceContext._({
    required TypeSystemImpl typeSystem,
    required this.isAsynchronous,
    required this.isGenerator,
    required this.imposedType,
    required this.contextType,
  }) : _typeSystem = typeSystem;

  bool get isSynchronous => !isAsynchronous;

  TypeProviderImpl get _typeProvider => _typeSystem.typeProvider;

  void addReturnExpression(Expression? expression) {
    if (expression == null) {
      // If the enclosing function is not marked `sync*` or `async*`:
      //   For each `return;` statement in the block, update
      //   `T` to be `UP(Null, T)`.
      if (!isGenerator) {
        _returnTypes.add(_typeProvider.nullType);
      }
    } else {
      var type = expression.typeOrThrow;
      if (isAsynchronous) {
        type = _typeSystem.flatten(type);
      }
      _returnTypes.add(type);
    }
  }

  void addYield(YieldStatement node) {
    var expressionType = node.expression.typeOrThrow;

    if (node.star == null) {
      _returnTypes.add(expressionType);
      return;
    }

    if (isGenerator) {
      var requiredClass = isAsynchronous
          ? _typeProvider.streamElement
          : _typeProvider.iterableElement;
      var type = _argumentOf(expressionType, requiredClass);
      if (type != null) {
        _returnTypes.add(type);
      }
    }
  }

  TypeImpl computeInferredReturnType({required bool endOfBlockIsReachable}) {
    var actualReturnedType = _computeActualReturnedType(
      endOfBlockIsReachable: endOfBlockIsReachable,
    );

    var clampedReturnedType = _clampToContextType(actualReturnedType);

    if (isGenerator) {
      if (isAsynchronous) {
        return _typeProvider.streamType(clampedReturnedType);
      } else {
        return _typeProvider.iterableType(clampedReturnedType);
      }
    } else {
      if (isAsynchronous) {
        return _typeProvider.futureType(
          _typeSystem.flatten(clampedReturnedType),
        );
      } else {
        return clampedReturnedType;
      }
    }
  }

  /// Let `T` be the **actual returned type** of a function literal.
  TypeImpl _clampToContextType(TypeImpl T) {
    // Let `R` be the greatest closure of the typing context `K`.
    var R = contextType;
    if (R == null) {
      return T;
    }

    // If `R` is `void`, or the function literal is marked `async` and `R` is
    // `FutureOr<void>`, let `S` be `void`.
    if (R is VoidType ||
        isAsynchronous &&
            R is InterfaceTypeImpl &&
            R.isDartAsyncFutureOr &&
            R.typeArguments[0] is VoidType) {
      return VoidTypeImpl.instance;
    }

    // Otherwise, if `T <: R` then let `S` be `T`.
    if (_typeSystem.isSubtypeOf(T, R)) {
      return T;
    }

    // Otherwise, let `S` be `R`.
    return R;
  }

  TypeImpl _computeActualReturnedType({required bool endOfBlockIsReachable}) {
    if (isGenerator) {
      if (_returnTypes.isEmpty) {
        return DynamicTypeImpl.instance;
      }
      // TODO(paulberry): eliminate this cast by changing the type of
      // `_returnTypes` to `List<TypeImpl>`.
      return _returnTypes.cast<TypeImpl>().reduce(_typeSystem.leastUpperBound);
    }

    var initialType = endOfBlockIsReachable
        ? _typeProvider.nullType
        : _typeProvider.neverType;
    // TODO(paulberry): eliminate this cast by changing the type of
    // `_returnTypes` to `List<TypeImpl>`.
    return _returnTypes.cast<TypeImpl>().fold(
      initialType,
      _typeSystem.leastUpperBound,
    );
  }

  static TypeImpl? _argumentOf(TypeImpl type, InterfaceElement element) {
    var elementType = type.asInstanceOf(element);
    return elementType?.typeArguments[0];
  }

  static TypeImpl? _contextTypeForImposed(
    TypeSystemImpl typeSystem,
    FunctionBody node,
    TypeImpl? imposedType,
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
    return typeSystem.typeProvider.futureOrType(
      typeSystem.futureValueType(imposedType),
    );
  }
}
