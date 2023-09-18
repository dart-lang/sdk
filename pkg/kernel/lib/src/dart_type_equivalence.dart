// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../core_types.dart';

class DartTypeEquivalence implements DartTypeVisitor1<bool, DartType> {
  final CoreTypes coreTypes;
  // TODO(cstefantsova): Implement also equateBottomTypes.
  final bool equateTopTypes;
  final bool ignoreAllNullabilities;
  final bool ignoreTopLevelNullability;

  bool _atTopLevel = true;
  List<Map<TypeParameter, TypeParameter>> _alphaRenamingStack = [];

  DartTypeEquivalence(this.coreTypes,
      {this.equateTopTypes = false,
      this.ignoreAllNullabilities = false,
      this.ignoreTopLevelNullability = false});

  bool areEqual(DartType type1, DartType type2) {
    _alphaRenamingStack.clear();
    _atTopLevel = true;
    return type1.accept1(this, type2);
  }

  @override
  bool defaultDartType(DartType node, DartType other) {
    throw new UnsupportedError("${node.runtimeType}");
  }

  @override
  bool visitDynamicType(DynamicType node, DartType other) {
    return equateTopTypes ? coreTypes.isTop(other) : other is DynamicType;
  }

  @override
  bool visitFunctionType(FunctionType node, DartType other) {
    if (other is FunctionType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }

      // Perform simple number checks before the checks on parts.
      if (node.typeParameters.length != other.typeParameters.length) {
        return false;
      }
      if (node.positionalParameters.length !=
          other.positionalParameters.length) {
        return false;
      }
      if (node.requiredParameterCount != other.requiredParameterCount) {
        return false;
      }
      if (node.namedParameters.length != other.namedParameters.length) {
        return false;
      }

      // Enter new static scope.  The scope must be exited before a return.  To
      // void multiple returns, the [result] variable is used below.
      _pushTypeParameters(node.typeParameters, other.typeParameters);
      bool result = true;

      for (int i = 0; result && i < node.typeParameters.length; ++i) {
        if (!node.typeParameters[i].bound
            .accept1(this, other.typeParameters[i].bound)) {
          result = false;
        }
        // Don't check defaultTypes: they are a convenience mechanism.
      }
      for (int i = 0; result && i < node.positionalParameters.length; ++i) {
        if (!node.positionalParameters[i]
            .accept1(this, other.positionalParameters[i])) {
          result = false;
        }
      }
      Map<String, DartType> nodeNamedParameters = {};
      for (int i = 0; i < node.namedParameters.length; ++i) {
        nodeNamedParameters[node.namedParameters[i].name] =
            node.namedParameters[i].type;
      }
      for (int i = 0; result && i < other.namedParameters.length; ++i) {
        String otherName = other.namedParameters[i].name;
        DartType otherType = other.namedParameters[i].type;
        if (!nodeNamedParameters.containsKey(otherName) ||
            !nodeNamedParameters[otherName]!.accept1(this, otherType)) {
          result = false;
        } else {
          nodeNamedParameters.remove(otherName);
        }
      }
      if (nodeNamedParameters.isNotEmpty) {
        result = false;
      }
      if (!node.returnType.accept1(this, other.returnType)) {
        result = false;
      }

      _dropTypeParameters();
      return result;
    }
    return false;
  }

  @override
  bool visitRecordType(RecordType node, DartType other) {
    if (other is RecordType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }

      // Perform simple number checks before the checks on parts.
      if (node.positional.length != other.positional.length) {
        return false;
      }
      if (node.named.length != other.named.length) {
        return false;
      }

      bool result = true;

      for (int i = 0; result && i < node.positional.length; ++i) {
        if (!node.positional[i].accept1(this, other.positional[i])) {
          result = false;
        }
      }

      // The named fields of [RecordType]s are supposed to be sorted and we know
      // there are the same number of named fields, so we can use a linear
      // search to compare them.
      int i = 0;
      while (result && i < node.named.length) {
        NamedType nodeNamedType = node.named[i];
        NamedType otherNamedType = other.named[i];
        if (nodeNamedType.name != otherNamedType.name) {
          result = false;
        } else {
          result = nodeNamedType.type.accept1(this, otherNamedType.type);
        }
        i++;
      }

      return result;
    }
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node, DartType other) {
    // First, check Object*, Object?.
    if (equateTopTypes && coreTypes.isTop(node)) {
      return coreTypes.isTop(other);
    }

    if (other is InterfaceType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }
      if (node.classNode != other.classNode) {
        return false;
      }
      assert(node.typeArguments.length == other.typeArguments.length);
      for (int i = 0; i < node.typeArguments.length; ++i) {
        if (!node.typeArguments[i].accept1(this, other.typeArguments[i])) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  bool visitExtensionType(ExtensionType node, DartType other) {
    // First, check Object*, Object?.
    if (equateTopTypes && coreTypes.isTop(node)) {
      return coreTypes.isTop(other);
    }

    if (other is ExtensionType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }
      if (node.extensionTypeDeclaration != other.extensionTypeDeclaration) {
        return false;
      }
      assert(node.typeArguments.length == other.typeArguments.length);
      for (int i = 0; i < node.typeArguments.length; ++i) {
        if (!node.typeArguments[i].accept1(this, other.typeArguments[i])) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType node, DartType other) {
    // First, check FutureOr<dynamic>, FutureOr<Object?>, etc.
    if (equateTopTypes && coreTypes.isTop(node)) {
      return coreTypes.isTop(other);
    }

    if (other is FutureOrType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }
      if (!node.typeArgument.accept1(this, other.typeArgument)) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  bool visitInvalidType(InvalidType node, DartType other) {
    return other is InvalidType;
  }

  @override
  bool visitNullType(NullType node, DartType other) {
    return other is NullType;
  }

  @override
  bool visitNeverType(NeverType node, DartType other) {
    if (other is NeverType) {
      return _checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability);
    }
    return false;
  }

  @override
  bool visitTypeParameterType(TypeParameterType node, DartType other) {
    if (other is TypeParameterType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }
      if (!identical(_lookup(node.parameter), other.parameter)) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  bool visitIntersectionType(IntersectionType node, DartType other) {
    if (other is IntersectionType) {
      return node.left.accept1(this, other.left) &&
          node.right.accept1(this, other.right);
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node, DartType other) {
    if (other is TypedefType) {
      if (!_checkAndRegisterNullabilities(
          node.declaredNullability, other.declaredNullability)) {
        return false;
      }
      if (node.typedefNode != other.typedefNode) {
        return false;
      }
      assert(node.typeArguments.length == other.typeArguments.length);
      for (int i = 0; i < node.typeArguments.length; ++i) {
        if (!node.typeArguments[i].accept1(this, other.typeArguments[i])) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  bool visitVoidType(VoidType node, DartType other) {
    return equateTopTypes ? coreTypes.isTop(other) : other is VoidType;
  }

  bool _checkAndRegisterNullabilities(
      Nullability nodeNullability, Nullability otherNullability) {
    bool result;
    if (nodeNullability == otherNullability ||
        ignoreAllNullabilities ||
        ignoreTopLevelNullability && _atTopLevel) {
      result = true;
    } else {
      result = false;
    }
    _atTopLevel = false;
    return result;
  }

  void _pushTypeParameters(
      List<TypeParameter> keys, List<TypeParameter> values) {
    assert(keys.length == values.length);
    Map<TypeParameter, TypeParameter> parameters =
        new Map<TypeParameter, TypeParameter>.identity();
    for (int i = 0; i < keys.length; ++i) {
      parameters[keys[i]] = values[i];
    }
    _alphaRenamingStack.add(parameters);
  }

  void _dropTypeParameters() {
    _alphaRenamingStack.removeLast();
  }

  TypeParameter _lookup(TypeParameter parameter) {
    for (int i = _alphaRenamingStack.length - 1; i >= 0; --i) {
      if (_alphaRenamingStack[i].containsKey(parameter)) {
        return _alphaRenamingStack[i][parameter]!;
      }
    }
    return parameter;
  }

  DartTypeEquivalence copy() {
    return new DartTypeEquivalence(coreTypes,
        equateTopTypes: equateTopTypes,
        ignoreAllNullabilities: ignoreAllNullabilities,
        ignoreTopLevelNullability: ignoreTopLevelNullability);
  }
}
