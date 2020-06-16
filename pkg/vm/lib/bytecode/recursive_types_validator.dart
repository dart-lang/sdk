// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.recursive_types_validator;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_algebra.dart' show Substitution;

import 'generics.dart'
    show flattenInstantiatorTypeArguments, hasFreeTypeParameters;

/// Detect recursive types and validates that finalized (flattened)
/// representation of generic types is valid (finite).
class RecursiveTypesValidator {
  final CoreTypes coreTypes;
  final Set<DartType> _validatedTypes = <DartType>{};
  final Set<DartType> _recursiveTypes = <DartType>{};
  final Set<Class> _validatedClases = <Class>{};

  RecursiveTypesValidator(this.coreTypes);

  /// Validates [type].
  void validateType(DartType type) {
    if (!isValidated(type)) {
      final visitor = new _RecursiveTypesVisitor(this);
      visitor.visit(type);
      _validatedTypes.addAll(visitor.validated);
      _recursiveTypes.addAll(visitor.recursive);
    }
  }

  bool isValidated(DartType type) => _validatedTypes.contains(type);

  /// Returns true if [type] is recursive.
  /// Should be called only after validating [type].
  bool isRecursive(DartType type) {
    assert(isValidated(type));
    return _recursiveTypes.contains(type);
  }

  void validateClass(Class cls) {
    if (_validatedClases.add(cls)) {
      try {
        validateType(
            cls.getThisType(coreTypes, cls.enclosingLibrary.nonNullable));
      } on IllegalRecursiveTypeException catch (e) {
        _validatedClases.remove(cls);
        throw e;
      }
    }
  }
}

class IllegalRecursiveTypeException {
  final DartType type;
  IllegalRecursiveTypeException(this.type);
}

class _RecursiveTypesVisitor extends DartTypeVisitor<void> {
  final RecursiveTypesValidator validator;
  final Set<DartType> validated = <DartType>{};
  final Set<DartType> recursive = <DartType>{};
  final Set<DartType> _visited = new Set<DartType>();
  final List<DartType> _stack = <DartType>[];

  _RecursiveTypesVisitor(this.validator);

  void visit(DartType type) {
    if (validator.isValidated(type)) {
      return;
    }

    if (!_visited.add(type)) {
      final int start = _stack.lastIndexOf(type);
      _verifyRecursiveType(start, type);
      for (int i = start; i < _stack.length; ++i) {
        recursive.add(_stack[i]);
      }
      return;
    }

    _stack.add(type);

    type.accept(this);

    _stack.removeLast();
    _visited.remove(type);

    validated.add(type);
  }

  @override
  void defaultDartType(DartType node) =>
      throw 'Unexpected type ${node.runtimeType} $node';

  @override
  void visitInvalidType(InvalidType node) {}

  @override
  void visitDynamicType(DynamicType node) {}

  @override
  void visitVoidType(VoidType node) {}

  @override
  void visitBottomType(BottomType node) {}

  @override
  void visitNeverType(NeverType node) {}

  @override
  void visitTypeParameterType(TypeParameterType node) {}

  @override
  void visitInterfaceType(InterfaceType node) {
    // Validate class declaration type separately
    // to avoid failures due to types in the current _stack.
    validator.validateClass(node.classNode);

    for (var typeArg in node.typeArguments) {
      visit(typeArg);
    }
    final flatTypeArgs =
        flattenInstantiatorTypeArguments(node.classNode, node.typeArguments);
    for (var typeArg in flatTypeArgs.getRange(
        0, flatTypeArgs.length - node.typeArguments.length)) {
      visit(typeArg);
    }
  }

  @override
  void visitFutureOrType(FutureOrType node) {
    visit(node.typeArgument);
  }

  @override
  void visitTypedefType(TypedefType node) => visit(node.unalias);

  @override
  void visitFunctionType(FunctionType node) {
    for (var p in node.positionalParameters) {
      visit(p);
    }
    for (var p in node.namedParameters) {
      visit(p.type);
    }
    visit(node.returnType);
  }

  void _verifyRecursiveType(int start, DartType type) {
    if (type is InterfaceType) {
      if (!hasFreeTypeParameters(type.typeArguments)) {
        return;
      }

      for (int i = start + 1; i < _stack.length; ++i) {
        final other = _stack[i];
        if (other is InterfaceType &&
            other.classNode == type.classNode &&
            hasFreeTypeParameters(other.typeArguments)) {
          if (!listEquals(_eraseTypeParameters(type.typeArguments),
              _eraseTypeParameters(other.typeArguments))) {
            throw IllegalRecursiveTypeException(type);
          }
        }
      }
    } else {
      throw 'Unexpected recursive type ${type.runtimeType} $type';
    }
  }

  List<DartType> _eraseTypeParameters(List<DartType> typeArgs) {
    return typeArgs
        .map((DartType t) =>
            const _EraseTypeParametersToDynamic().substituteType(t))
        .toList();
  }
}

class _EraseTypeParametersToDynamic extends Substitution {
  const _EraseTypeParametersToDynamic();

  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return const DynamicType();
  }
}
