// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declares the type system used by global type flow analysis.
library vm.transformations.type_flow.types;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';

import 'utils.dart';

/// Abstract interface to type hierarchy information used by types.
abstract class TypeHierarchy {
  /// Test if [subType] is a subtype of [superType].
  bool isSubtype(DartType subType, DartType superType);

  /// Return a more specific type for the type cone with [base] root.
  /// May return EmptyType, AnyType, ConcreteType or a SetType.
  Type specializeTypeCone(DartType base);
}

/// Basic normalization of Dart types.
/// Currently used to approximate generic and function types.
DartType _normalizeDartType(DartType type) {
  if (type is InterfaceType) {
    // TODO(alexmarkov): take generic type arguments into account
    return type.classNode.rawType;
  } else if (type is FunctionType) {
    // TODO(alexmarkov): support function types
    return const DynamicType();
  } else if (type is TypeParameterType) {
    // TODO(alexmarkov): instantiate type parameters if possible
    return _normalizeDartType(type.bound);
  }
  return type;
}

/// Base class for type expressions.
/// Type expression is either a [Type] or a statement in a summary.
abstract class TypeExpr {
  const TypeExpr();

  /// Static [DartType] approximation.
  /// May not be available for certain inferred types (such as [EmptyType] and
  /// [SetType]) as they don't have corresponding Dart types.
  DartType get staticType;

  /// Returns computed type of this type expression.
  /// [types] is the list of types computed for the statements in the summary.
  Type getComputedType(List<Type> types);
}

/// Base class for types inferred by the type flow analysis.
/// [Type] describes a specific set of values (Dart instances) and does not
/// directly correspond to a Dart type.
abstract class Type extends TypeExpr {
  const Type();

  /// Create an empty type.
  factory Type.empty() => const EmptyType();

  /// Create a non-nullable type representing a subtype cone. It contains
  /// instances of all Dart types which extend, mix-in or implement [dartType].
  factory Type.cone(DartType dartType) {
    dartType = _normalizeDartType(dartType);
    if ((dartType == const DynamicType()) || (dartType == const VoidType())) {
      return const AnyType();
    } else {
      return new ConeType(dartType);
    }
  }

  /// Create a type representing instances of a specific class (no subtypes
  /// or `null` object).
  factory Type.concrete(DartType dartType) {
    // Catch certain unexpected types before _normalizeDartType() erases them.
    assertx(dartType is! FunctionType);
    assertx(dartType is! TypeParameterType);
    return new ConcreteType(_normalizeDartType(dartType));
  }

  /// Create a nullable type - union of [t] and the `null` object.
  factory Type.nullable(Type t) => new NullableType(t);

  /// Create a Type which corresponds to a set of instances constrained by
  /// Dart type annotation [dartType].
  factory Type.fromStatic(DartType dartType) {
    dartType = _normalizeDartType(dartType);
    if ((dartType == const DynamicType()) || (dartType == const VoidType())) {
      return new Type.nullable(const AnyType());
    } else if (dartType == const BottomType()) {
      return new Type.nullable(new Type.empty());
    }
    return new Type.nullable(new ConeType(dartType));
  }

  @override
  DartType get staticType;

  Class getConcreteClass(TypeHierarchy typeHierarchy) => null;

  @override
  Type getComputedType(List<Type> types) => this;

  /// Order of precedence for evaluation of union/intersection.
  int get order;

  /// Calculate union of this and [other] types.
  Type union(Type other, TypeHierarchy typeHierarchy);

  /// Calculate intersection of this and [other] types.
  Type intersection(Type other, TypeHierarchy typeHierarchy);
}

/// Order of precedence between types for evaluation of union/intersection.
enum TypeOrder {
  Empty,
  Nullable,
  Any,
  Set,
  Cone,
  Concrete,
}

/// Type representing the empty set of instances.
class EmptyType extends Type {
  const EmptyType();

  @override
  DartType get staticType => throw 'Unable to get static type of empty type';

  @override
  int get hashCode => 997;

  @override
  bool operator ==(other) => (other is EmptyType);

  @override
  String toString() => "_T {}";

  @override
  int get order => TypeOrder.Empty.index;

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) => other;

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) => this;
}

/// Nullable type represents a union of a (non-nullable) type and the `null`
/// object. Other kinds of types do not contain `null` object (even AnyType).
class NullableType extends Type {
  final Type baseType;

  NullableType(this.baseType) {
    assertx(baseType != null);
    assertx(baseType is! NullableType);
  }

  @override
  DartType get staticType =>
      (baseType is EmptyType) ? const BottomType() : baseType.staticType;

  @override
  int get hashCode => (baseType.hashCode + 31) & kHashMask;

  @override
  bool operator ==(other) =>
      (other is NullableType) && (this.baseType == other.baseType);

  @override
  String toString() => "${baseType}?";

  @override
  int get order => TypeOrder.Nullable.index;

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    if (other is NullableType) {
      return new NullableType(baseType.union(other.baseType, typeHierarchy));
    } else {
      return new NullableType(baseType.union(other, typeHierarchy));
    }
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    if (other is NullableType) {
      return new NullableType(
          baseType.intersection(other.baseType, typeHierarchy));
    } else {
      return baseType.intersection(other, typeHierarchy);
    }
  }
}

/// Type representing any instance except `null`.
/// Semantically equivalent to ConeType of Object, but more efficient.
class AnyType extends Type {
  const AnyType();

  @override
  DartType get staticType => const DynamicType();

  @override
  int get hashCode => 991;

  @override
  bool operator ==(other) => (other is AnyType);

  @override
  String toString() => "_T ANY";

  @override
  int get order => TypeOrder.Any.index;

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    return this;
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    return other;
  }
}

/// SetType is a union of concrete types T1, T2, ..., Tn, where n >= 2.
/// It represents the set of instances which types are in the {T1, T2, ..., Tn}.
class SetType extends Type {
  final Set<ConcreteType> types;
  int _hashCode;

  SetType(this.types) {
    assertx(types.length >= 2);
  }

  @override
  DartType get staticType => throw 'Unable to get static type of set type';

  @override
  int get hashCode => _hashCode ??= _computeHashCode();

  int _computeHashCode() {
    int hash = 1237;
    // Hash code should not depend on the order of types.
    for (var t in types) {
      hash = (hash ^ t.hashCode) & kHashMask;
    }
    return hash;
  }

  @override
  bool operator ==(other) =>
      (other is SetType) &&
      // TODO(alexmarkov): make it more efficient
      (types.length == other.types.length) &&
      this.types.containsAll(other.types) &&
      other.types.containsAll(this.types);

  @override
  String toString() => "_T ${types}";

  @override
  int get order => TypeOrder.Set.index;

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    if (other is SetType) {
      return new SetType(this.types.union(other.types));
    } else if (other is ConcreteType) {
      return types.contains(other)
          ? this
          : new SetType(new Set.from(this.types)..add(other));
    } else if (other is ConeType) {
      return typeHierarchy
          .specializeTypeCone(other.dartType)
          .union(this, typeHierarchy);
    } else {
      throw 'Unexpected type $other';
    }
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    if (other is SetType) {
      Set<ConcreteType> set = this.types.intersection(other.types);
      final size = set.length;
      if (size == 0) {
        return const EmptyType();
      } else if (size == 1) {
        return set.single;
      } else {
        return new SetType(set);
      }
    } else if (other is ConcreteType) {
      return types.contains(other) ? other : const EmptyType();
    } else if (other is ConeType) {
      return typeHierarchy
          .specializeTypeCone(other.dartType)
          .intersection(this, typeHierarchy);
    } else {
      throw 'Unexpected type $other';
    }
  }
}

/// Type representing a subtype cone. It contains instances of all
/// Dart types which extend, mix-in or implement [dartType].
/// TODO(alexmarkov): Introduce cones of types which extend but not implement.
class ConeType extends Type {
  final DartType dartType;

  ConeType(this.dartType) {
    assertx(dartType != null);
  }

  @override
  DartType get staticType => dartType;

  @override
  Class getConcreteClass(TypeHierarchy typeHierarchy) => typeHierarchy
      .specializeTypeCone(dartType)
      .getConcreteClass(typeHierarchy);

  @override
  int get hashCode => (dartType.hashCode + 37) & kHashMask;

  @override
  bool operator ==(other) =>
      (other is ConeType) && (this.dartType == other.dartType);

  @override
  String toString() => "_T (${dartType})+";

  @override
  int get order => TypeOrder.Cone.index;

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    if (other is ConeType) {
      if (this == other) {
        return this;
      }
      if (typeHierarchy.isSubtype(other.dartType, this.dartType)) {
        return this;
      }
      if (typeHierarchy.isSubtype(this.dartType, other.dartType)) {
        return other;
      }
    } else if (other is ConcreteType) {
      if (typeHierarchy.isSubtype(other.dartType, this.dartType)) {
        return this;
      }
    }
    return typeHierarchy
        .specializeTypeCone(dartType)
        .union(other, typeHierarchy);
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    if (other is ConeType) {
      if (this == other) {
        return this;
      }
      if (typeHierarchy.isSubtype(other.dartType, this.dartType)) {
        return other;
      }
      if (typeHierarchy.isSubtype(this.dartType, other.dartType)) {
        return this;
      }
    } else if (other is ConcreteType) {
      if (typeHierarchy.isSubtype(other.dartType, this.dartType)) {
        return other;
      } else {
        return const EmptyType();
      }
    }
    return typeHierarchy
        .specializeTypeCone(dartType)
        .intersection(other, typeHierarchy);
  }
}

/// Type representing a set of instances of a specific Dart class (no subtypes
/// or `null` object).
class ConcreteType extends Type {
  final DartType dartType;

  ConcreteType(this.dartType) {
    assertx((dartType is FunctionType) ||
        ((dartType is InterfaceType) &&
            !(dartType as InterfaceType).classNode.isAbstract));
  }

  @override
  DartType get staticType => dartType;

  @override
  Class getConcreteClass(TypeHierarchy typeHierarchy) =>
      (dartType is InterfaceType)
          ? (dartType as InterfaceType).classNode
          : null;

  @override
  int get hashCode => (dartType.hashCode ^ 0x1234) & kHashMask;

  @override
  bool operator ==(other) =>
      (other is ConcreteType) && (this.dartType == other.dartType);

  @override
  String toString() => "_T (${dartType})";

  @override
  int get order => TypeOrder.Concrete.index;

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    if (other is ConcreteType) {
      if (this == other) {
        return this;
      } else {
        final Set<ConcreteType> types = new Set<ConcreteType>();
        types.add(this);
        types.add(other);
        return new SetType(types);
      }
    } else {
      throw 'Unexpected type $other';
    }
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    if (other is ConcreteType) {
      if (this == other) {
        return this;
      } else {
        return const EmptyType();
      }
    } else {
      throw 'Unexpected type $other';
    }
  }
}
