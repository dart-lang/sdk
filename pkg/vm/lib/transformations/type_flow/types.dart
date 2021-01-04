// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declares the type system used by global type flow analysis.
library vm.transformations.type_flow.types;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';

import 'package:kernel/core_types.dart';

import 'utils.dart';

/// Dart class representation used in type flow analysis.
/// For each Dart class there is a unique instance of [TFClass].
/// Each [TFClass] has unique id which could be used to sort classes.
class TFClass {
  final int id;
  final Class classNode;

  /// TFClass should not be instantiated directly.
  /// Instead, [TypeHierarchy.getTFClass] should be used to obtain [TFClass]
  /// instances specific to given [TypeHierarchy].
  TFClass(this.id, this.classNode);

  /// Returns ConcreteType corresponding to this class without
  /// any extra attributes.
  ConcreteType get concreteType => ConcreteType(this);

  @override
  int get hashCode => id;

  @override
  bool operator ==(other) => identical(this, other);

  @override
  String toString() => nodeToText(classNode);
}

abstract class GenericInterfacesInfo {
  // Return a type arguments vector which contains the immediate type parameters
  // to 'klass' as well as the type arguments to all generic supertypes of
  // 'klass', instantiated in terms of the type parameters on 'klass'.
  //
  // The offset into this vector from which a specific generic supertype's type
  // arguments can be found is given by 'genericInterfaceOffsetFor'.
  List<DartType> flattenedTypeArgumentsFor(Class klass);

  // Return the offset into the flattened type arguments vector from which a
  // specific generic supertype's type arguments can be found. The flattened
  // type arguments vector is given by 'flattenedTypeArgumentsFor'.
  int genericInterfaceOffsetFor(Class klass, Class iface);

  // Similar to 'flattenedTypeArgumentsFor', but works for non-generic classes
  // which may have recursive substitutions, e.g. 'class num implements
  // Comparable<num>'.
  //
  // Since there are no free type variables in the result, 'RuntimeType' is
  // returned instead of 'DartType'.
  List<Type> flattenedTypeArgumentsForNonGeneric(Class klass);
}

abstract class TypesBuilder {
  final CoreTypes coreTypes;
  final bool nullSafety;

  TypesBuilder(this.coreTypes, this.nullSafety);

  /// Return [TFClass] corresponding to the given [classNode].
  TFClass getTFClass(Class classNode);

  /// Create a Type which corresponds to a set of instances constrained by
  /// Dart type annotation [dartType].
  /// [canBeNull] can be set to false to further constrain the resulting
  /// type if value cannot be null.
  Type fromStaticType(DartType type, bool canBeNull) {
    Type result;
    if (type is InterfaceType) {
      final cls = type.classNode;
      result = new ConeType(getTFClass(cls));
    } else if (type == const DynamicType() || type == const VoidType()) {
      result = const AnyType();
    } else if (type == const BottomType() ||
        type is NeverType ||
        type is NullType) {
      result = const EmptyType();
    } else if (type is FunctionType) {
      // TODO(alexmarkov): support function types
      result = const AnyType();
    } else if (type is FutureOrType) {
      // TODO(alexmarkov): support FutureOr types
      result = const AnyType();
    } else if (type is TypeParameterType) {
      final bound = type.bound;
      // Protect against infinite recursion in case of cyclic type parameters
      // like 'T extends T'. As of today, front-end doesn't report errors in such
      // cases yet.
      if (bound is TypeParameterType) {
        result = const AnyType();
      } else {
        result = fromStaticType(bound, canBeNull);
      }
    } else {
      throw 'Unexpected type ${type.runtimeType} $type';
    }
    if (nullSafety && type.nullability == Nullability.nonNullable) {
      canBeNull = false;
    }
    if (canBeNull && result is! NullableType) {
      result = new Type.nullable(result);
    }
    return result;
  }
}

abstract class RuntimeTypeTranslator {
  TypeExpr instantiateConcreteType(ConcreteType type, List<DartType> typeArgs);
}

/// Abstract interface to type hierarchy information used by types.
abstract class TypeHierarchy extends TypesBuilder
    implements GenericInterfacesInfo {
  TypeHierarchy(CoreTypes coreTypes, bool nullSafety)
      : super(coreTypes, nullSafety);

  /// Test if [sub] is a subtype of [sup].
  bool isSubtype(Class sub, Class sup);

  /// Return a more specific type for the type cone with [base] root.
  /// May return EmptyType, AnyType, ConcreteType or a SetType.
  Type specializeTypeCone(TFClass base);

  Type _cachedIntType;
  Type get intType {
    return _cachedIntType ??= fromStaticType(coreTypes.intLegacyRawType, true);
  }
}

/// Base class for type expressions.
/// Type expression is either a [Type] or a statement in a summary.
abstract class TypeExpr {
  const TypeExpr();

  /// Returns computed type of this type expression.
  /// [types] is the list of types computed for the statements in the summary.
  Type getComputedType(List<Type> types);
}

/// Base class for types inferred by the type flow analysis.
/// [Type] describes a specific set of values (Dart instances) and does not
/// directly correspond to a Dart type.
/// TODO(alexmarkov): consider detaching Type hierarchy from TypeExpr/Statement.
abstract class Type extends TypeExpr {
  const Type();

  /// Create a nullable type - union of [t] and the `null` object.
  factory Type.nullable(Type t) => new NullableType(t);

  /// Create a type representing arbitrary nullable object (`dynamic`).
  factory Type.nullableAny() => new NullableType(const AnyType());

  Class getConcreteClass(TypeHierarchy typeHierarchy) => null;

  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class cls) => false;

  // Returns 'true' if this type will definitely pass a runtime type-check
  // against 'runtimeType'. Returns 'false' if the test might fail (e.g. due to
  // an approximation).
  bool isSubtypeOfRuntimeType(
      TypeHierarchy typeHierarchy, RuntimeType runtimeType);

  @override
  Type getComputedType(List<Type> types) => this;

  /// Order of precedence for evaluation of union/intersection.
  int get order;

  /// Returns true iff this type is fully specialized.
  bool get isSpecialized => true;

  /// Returns specialization of this type using the given [TypeHierarchy].
  Type specialize(TypeHierarchy typeHierarchy) => this;

  /// Calculate union of this and [other] types.
  Type union(Type other, TypeHierarchy typeHierarchy);

  /// Calculate intersection of this and [other] types.
  Type intersection(Type other, TypeHierarchy typeHierarchy);
}

/// Order of precedence between types for evaluation of union/intersection.
enum TypeOrder {
  RuntimeType,
  Unknown,
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

  bool isSubtypeOfRuntimeType(TypeHierarchy typeHierarchy, RuntimeType other) {
    return true;
  }
}

/// Nullable type represents a union of a (non-nullable) type and the `null`
/// object. Other kinds of types do not contain `null` object (even AnyType).
class NullableType extends Type {
  final Type baseType;

  NullableType(this.baseType) {
    assert(baseType != null);
    assert(baseType is! NullableType);
  }

  @override
  int get hashCode => (baseType.hashCode + 31) & kHashMask;

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is NullableType) && (this.baseType == other.baseType);

  @override
  String toString() => "${baseType}?";

  @override
  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class cls) =>
      baseType.isSubtypeOf(typeHierarchy, cls);

  bool isSubtypeOfRuntimeType(TypeHierarchy typeHierarchy, RuntimeType other) {
    if (typeHierarchy.nullSafety &&
        other.nullability == Nullability.nonNullable) {
      return false;
    }
    return baseType.isSubtypeOfRuntimeType(typeHierarchy, other);
  }

  @override
  int get order => TypeOrder.Nullable.index;

  @override
  bool get isSpecialized => baseType.isSpecialized;

  @override
  Type specialize(TypeHierarchy typeHierarchy) => baseType.isSpecialized
      ? this
      : new NullableType(baseType.specialize(typeHierarchy));

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

  bool isSubtypeOfRuntimeType(TypeHierarchy typeHierarchy, RuntimeType other) {
    final rhs = other._type;
    return (rhs is DynamicType) ||
        (rhs is VoidType) ||
        (rhs is InterfaceType &&
            rhs.classNode == typeHierarchy.coreTypes.objectClass);
  }
}

/// SetType is a union of concrete types T1, T2, ..., Tn, where n >= 2.
/// It represents the set of instances which types are in the {T1, T2, ..., Tn}.
class SetType extends Type {
  /// List of concrete types, sorted by classId.
  final List<ConcreteType> types;
  int _hashCode;

  /// Creates a new SetType using list of concrete types sorted by classId.
  SetType(this.types) {
    assert(types.length >= 2);
    assert(isSorted(types));
  }

  @override
  int get hashCode => _hashCode ??= _computeHashCode();

  int _computeHashCode() {
    int hash = 1237;
    for (var t in types) {
      hash = (((hash * 31) & kHashMask) + t.hashCode) & kHashMask;
    }
    return hash;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if ((other is SetType) && (types.length == other.types.length)) {
      for (int i = 0; i < types.length; i++) {
        if (types[i] != other.types[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => "_T ${types}";

  @override
  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class cls) =>
      types.every((ConcreteType t) => t.isSubtypeOf(typeHierarchy, cls));

  bool isSubtypeOfRuntimeType(TypeHierarchy typeHierarchy, RuntimeType other) =>
      types.every((t) => t.isSubtypeOfRuntimeType(typeHierarchy, other));

  @override
  int get order => TypeOrder.Set.index;

  static List<ConcreteType> _unionLists(
      List<ConcreteType> types1, List<ConcreteType> types2) {
    int i1 = 0;
    int i2 = 0;
    List<ConcreteType> types = <ConcreteType>[];
    while ((i1 < types1.length) && (i2 < types2.length)) {
      final t1 = types1[i1];
      final t2 = types2[i2];
      final id1 = t1.cls.id;
      final id2 = t2.cls.id;
      if (id1 < id2) {
        types.add(t1);
        ++i1;
      } else if (id1 > id2) {
        types.add(t2);
        ++i2;
      } else {
        if (t1 == t2) {
          types.add(t1);
        } else {
          // TODO(sjindel/tfa): Merge the type arguments vectors.
          // (e.g., Map<?, int> vs Map<String, int> can become Map<?, int>)
          types.add(t1.raw);
        }
        ++i1;
        ++i2;
      }
    }
    if (i1 < types1.length) {
      types.addAll(types1.getRange(i1, types1.length));
    } else if (i2 < types2.length) {
      types.addAll(types2.getRange(i2, types2.length));
    }
    return types;
  }

  static List<ConcreteType> _intersectLists(
      List<ConcreteType> types1, List<ConcreteType> types2) {
    int i1 = 0;
    int i2 = 0;
    List<ConcreteType> types = <ConcreteType>[];
    while ((i1 < types1.length) && (i2 < types2.length)) {
      final t1 = types1[i1];
      final t2 = types2[i2];
      final id1 = t1.cls.id;
      final id2 = t2.cls.id;
      if (id1 < id2) {
        ++i1;
      } else if (id1 > id2) {
        ++i2;
      } else {
        if (t1.typeArgs == null &&
            t1.constant == null &&
            t2.typeArgs == null &&
            t2.constant == null) {
          types.add(t1);
        } else {
          final intersect = t1.intersection(t2, null);
          if (intersect is! EmptyType) {
            types.add(intersect);
          }
        }
        ++i1;
        ++i2;
      }
    }
    return types;
  }

  bool _isSubList(List<ConcreteType> sublist, List<ConcreteType> list) {
    int i1 = 0;
    int i2 = 0;
    while ((i1 < sublist.length) && (i2 < list.length)) {
      final t1 = sublist[i1];
      final t2 = list[i2];
      if (identical(t1, t2)) {
        ++i1;
        ++i2;
      } else if (t1.cls.id > t2.cls.id) {
        ++i2;
      } else {
        return false;
      }
    }
    return i1 == sublist.length;
  }

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (identical(this, other)) return this;
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    if (other is SetType) {
      if (types.length >= other.types.length) {
        if (_isSubList(other.types, types)) {
          return this;
        }
      } else {
        if (_isSubList(types, other.types)) {
          return other;
        }
      }
      return new SetType(_unionLists(types, other.types));
    } else if (other is ConcreteType) {
      return types.contains(other)
          ? this
          : new SetType(_unionLists(types, <ConcreteType>[other]));
    } else if (other is ConeType) {
      return typeHierarchy
          .specializeTypeCone(other.cls)
          .union(this, typeHierarchy);
    } else {
      throw 'Unexpected type $other';
    }
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (identical(this, other)) return this;
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    if (other is SetType) {
      List<ConcreteType> list = _intersectLists(types, other.types);
      final size = list.length;
      if (size == 0) {
        return const EmptyType();
      } else if (size == 1) {
        return list.single;
      } else {
        return new SetType(list);
      }
    } else if (other is ConcreteType) {
      for (var type in types) {
        if (type == other) return other;
        if (identical(type.cls, other.cls)) {
          return type.intersection(other, typeHierarchy);
        }
      }
      return EmptyType();
    } else if (other is ConeType) {
      return typeHierarchy
          .specializeTypeCone(other.cls)
          .intersection(this, typeHierarchy);
    } else {
      throw 'Unexpected type $other';
    }
  }
}

/// Type representing a subtype cone. It contains instances of all
/// Dart types which extend, mix-in or implement certain class.
/// TODO(alexmarkov): Introduce cones of types which extend but not implement.
class ConeType extends Type {
  final TFClass cls;

  ConeType(this.cls);

  @override
  Class getConcreteClass(TypeHierarchy typeHierarchy) =>
      typeHierarchy.specializeTypeCone(cls).getConcreteClass(typeHierarchy);

  @override
  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class cls) =>
      typeHierarchy.isSubtype(this.cls.classNode, cls);

  bool isSubtypeOfRuntimeType(TypeHierarchy typeHierarchy, RuntimeType other) {
    final rhs = other._type;
    if (rhs is DynamicType || rhs is VoidType) return true;
    if (rhs is InterfaceType) {
      return cls.classNode.typeParameters.isEmpty &&
          typeHierarchy.isSubtype(cls.classNode, rhs.classNode);
    }
    return false;
  }

  @override
  int get hashCode => (cls.id + 37) & kHashMask;

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is ConeType) && identical(this.cls, other.cls);

  @override
  String toString() => "_T (${cls})+";

  @override
  int get order => TypeOrder.Cone.index;

  @override
  bool get isSpecialized => false;

  @override
  Type specialize(TypeHierarchy typeHierarchy) =>
      typeHierarchy.specializeTypeCone(cls);

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (identical(this, other)) return this;
    if (other.order < this.order) {
      return other.union(this, typeHierarchy);
    }
    if (other is ConeType) {
      if (this == other) {
        return this;
      }
      if (typeHierarchy.isSubtype(other.cls.classNode, this.cls.classNode)) {
        return this;
      }
      if (typeHierarchy.isSubtype(this.cls.classNode, other.cls.classNode)) {
        return other;
      }
    } else if (other is ConcreteType) {
      if (typeHierarchy.isSubtype(other.cls.classNode, this.cls.classNode)) {
        return this;
      }
    }
    return typeHierarchy.specializeTypeCone(cls).union(other, typeHierarchy);
  }

  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (identical(this, other)) return this;
    if (other.order < this.order) {
      return other.intersection(this, typeHierarchy);
    }
    if (other is ConeType) {
      if (this == other) {
        return this;
      }
      if (typeHierarchy.isSubtype(other.cls.classNode, this.cls.classNode)) {
        return other;
      }
      if (typeHierarchy.isSubtype(this.cls.classNode, other.cls.classNode)) {
        return this;
      }
    } else if (other is ConcreteType) {
      if (typeHierarchy.isSubtype(other.cls.classNode, this.cls.classNode)) {
        return other;
      } else {
        return const EmptyType();
      }
    }
    return typeHierarchy
        .specializeTypeCone(cls)
        .intersection(other, typeHierarchy);
  }
}

/// Type representing a set of instances of a specific Dart class (no subtypes
/// or `null` object).
class ConcreteType extends Type implements Comparable<ConcreteType> {
  final TFClass cls;
  int _hashCode;

  // May be null if there are no type arguments constraints. The type arguments
  // should represent type sets, i.e. `UnknownType` or `RuntimeType`. The type
  // arguments vector is factored against the generic interfaces implemented by
  // the class (see [TypeHierarchy.flattenedTypeArgumentsFor]).
  //
  // The 'typeArgs' vector is null for non-generic classes, even if they
  // implement a generic interface.
  //
  // 'numImmediateTypeArgs' is the length of the prefix of 'typeArgs' which
  // holds the type arguments to the class itself.
  final int numImmediateTypeArgs;
  final List<Type> typeArgs;

  // May be null if constant value is not inferred.
  final Constant constant;

  ConcreteType(this.cls, [List<Type> typeArgs_, this.constant])
      : typeArgs = typeArgs_,
        numImmediateTypeArgs =
            typeArgs_ != null ? cls.classNode.typeParameters.length : 0 {
    // TODO(alexmarkov): support closures
    assert(!cls.classNode.isAbstract);
    assert(typeArgs == null || cls.classNode.typeParameters.isNotEmpty);
    assert(typeArgs == null || typeArgs.any((t) => t is RuntimeType));
  }

  ConcreteType get raw => cls.concreteType;
  bool get isRaw => typeArgs == null && constant == null;

  @override
  Class getConcreteClass(TypeHierarchy typeHierarchy) => cls.classNode;

  @override
  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class other) =>
      typeHierarchy.isSubtype(cls.classNode, other);

  bool isSubtypeOfRuntimeType(
      TypeHierarchy typeHierarchy, RuntimeType runtimeType) {
    final rhs = runtimeType._type;
    if (rhs is DynamicType || rhs is VoidType) return true;
    if (rhs is InterfaceType) {
      if (rhs.classNode == typeHierarchy.coreTypes.functionClass) {
        // TODO(35573): "implements/extends Function" is not handled correctly by
        // the CFE. By returning "false" we force an approximation -- that a type
        // check against "Function" might fail, whatever the LHS is.
        return false;
      }

      if (!typeHierarchy.isSubtype(this.cls.classNode, rhs.classNode)) {
        return false;
      }

      if (rhs.typeArguments.isEmpty) return true;

      List<Type> usableTypeArgs = typeArgs;
      if (usableTypeArgs == null) {
        if (cls.classNode.typeParameters.isEmpty) {
          usableTypeArgs =
              typeHierarchy.flattenedTypeArgumentsForNonGeneric(cls.classNode);
        } else {
          return false;
        }
      }

      final interfaceOffset =
          typeHierarchy.genericInterfaceOffsetFor(cls.classNode, rhs.classNode);

      assert(usableTypeArgs.length - interfaceOffset >=
          runtimeType.numImmediateTypeArgs);

      for (int i = 0; i < runtimeType.numImmediateTypeArgs; ++i) {
        final ta = usableTypeArgs[i + interfaceOffset];
        if (ta is UnknownType) {
          return false;
        }
        assert(ta is RuntimeType);
        if (!ta.isSubtypeOfRuntimeType(
            typeHierarchy, runtimeType.typeArgs[i])) {
          return false;
        }
      }
      return true;
    }
    if (rhs is FutureOrType) {
      if (typeHierarchy.isSubtype(
          cls.classNode, typeHierarchy.coreTypes.futureClass)) {
        final RuntimeType lhs =
            typeArgs == null ? RuntimeType(DynamicType(), null) : typeArgs[0];
        return lhs.isSubtypeOfRuntimeType(
            typeHierarchy, runtimeType.typeArgs[0]);
      } else {
        return isSubtypeOfRuntimeType(typeHierarchy, runtimeType.typeArgs[0]);
      }
    }
    return false;
  }

  @override
  int get hashCode => _hashCode ??= _computeHashCode();

  int _computeHashCode() {
    int hash = cls.hashCode ^ 0x1234 & kHashMask;
    // We only need to hash the first type arguments vector, since the type
    // arguments of the implemented interfaces are implied by it.
    for (int i = 0; i < numImmediateTypeArgs; ++i) {
      hash = (((hash * 31) & kHashMask) + typeArgs[i].hashCode) & kHashMask;
    }
    hash = ((hash * 31) & kHashMask) + constant.hashCode;
    return hash;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is ConcreteType) {
      if (!identical(this.cls, other.cls) ||
          this.numImmediateTypeArgs != other.numImmediateTypeArgs) {
        return false;
      }
      if (this.typeArgs != null) {
        for (int i = 0; i < numImmediateTypeArgs; ++i) {
          if (this.typeArgs[i] != other.typeArgs[i]) {
            return false;
          }
        }
      }
      if (this.constant != other.constant) {
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  // Note that this may return 0 for concrete types which are not equal if the
  // difference is only in type arguments.
  @override
  int compareTo(ConcreteType other) => cls.id.compareTo(other.cls.id);

  @override
  String toString() {
    if (typeArgs == null && constant == null) {
      return "_T (${cls})";
    }
    final StringBuffer buf = new StringBuffer();
    buf.write("_T (${cls}");
    if (typeArgs != null) {
      buf.write("<${typeArgs.take(numImmediateTypeArgs).join(', ')}>");
    }
    if (constant != null) {
      buf.write(", ${nodeToText(constant)}");
    }
    buf.write(")");
    return buf.toString();
  }

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
      } else if (!identical(this.cls, other.cls)) {
        final types = (this.cls.id < other.cls.id)
            ? <ConcreteType>[this, other]
            : <ConcreteType>[other, this];
        return new SetType(types);
      } else {
        assert(typeArgs != null ||
            constant != null ||
            other.typeArgs != null ||
            other.constant != null);
        return raw;
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
      }
      if (!identical(this.cls, other.cls)) {
        return EmptyType();
      }
      if (typeArgs == null && constant == null) {
        return other;
      } else if (other.typeArgs == null && other.constant == null) {
        return this;
      }

      List<Type> mergedTypeArgs;
      if (typeArgs == null) {
        mergedTypeArgs = other.typeArgs;
      } else if (other.typeArgs == null) {
        mergedTypeArgs = typeArgs;
      } else {
        mergedTypeArgs = new List<Type>.filled(typeArgs.length, null);
        bool hasRuntimeType = false;
        for (int i = 0; i < typeArgs.length; ++i) {
          final merged =
              typeArgs[i].intersection(other.typeArgs[i], typeHierarchy);
          if (merged is EmptyType) {
            return const EmptyType();
          } else if (merged is RuntimeType) {
            hasRuntimeType = true;
          }
          mergedTypeArgs[i] = merged;
        }
        if (!hasRuntimeType) {
          mergedTypeArgs = null;
        }
      }

      Constant mergedConstant;
      if (constant == null) {
        mergedConstant = other.constant;
      } else if (other.constant == null || constant == other.constant) {
        mergedConstant = constant;
      } else {
        return const EmptyType();
      }
      return new ConcreteType(cls, mergedTypeArgs, mergedConstant);
    } else {
      throw 'Unexpected type $other';
    }
  }
}

// Unlike the other 'Type's, this represents a single type, not a set of
// values. It is used as the right-hand-side of type-tests.
//
// The type arguments are represented in a form that is factored against the
// generic interfaces implemented by the type to enable efficient type-test
// against its interfaces. See 'TypeHierarchy.flattenedTypeArgumentsFor' for
// more details.
//
// This factored representation can have cycles for some types:
//
//   class num implements Comparable<num> {}
//   class A<T> extends Comparable<A<T>> {}
//
// To avoid these cycles, we approximate generic super-bounded types (the second
// case), so the representation for 'A<String>' would be simply 'UnknownType'.
// However, approximating non-generic types like 'int' and 'num' (the first
// case) would be too coarse, so we leave an null 'typeArgs' field for these
// types. As a result, when doing an 'isSubtypeOfRuntimeType' against
// their interfaces (e.g. 'int' vs 'Comparable<int>') we approximate the result
// as 'false'.
//
// So, the invariant about 'typeArgs' is that they will be 'null' iff the class
// is non-generic, and non-null (with at least one vector) otherwise.
class RuntimeType extends Type {
  final DartType _type; // Doesn't contain type args.

  final int numImmediateTypeArgs;
  final List<RuntimeType> typeArgs;

  RuntimeType(DartType type, this.typeArgs)
      : _type = type,
        numImmediateTypeArgs = type is InterfaceType
            ? type.classNode.typeParameters.length
            : (type is FutureOrType ? 1 : 0) {
    if (_type is InterfaceType && numImmediateTypeArgs > 0) {
      assert(typeArgs != null);
      assert(typeArgs.length >= numImmediateTypeArgs);
      assert((_type as InterfaceType)
          .typeArguments
          .every((t) => t == const DynamicType()));
    } else if (_type is FutureOrType) {
      assert(typeArgs != null);
      assert(typeArgs.length >= numImmediateTypeArgs);
      DartType typeArgument = (_type as FutureOrType).typeArgument;
      assert(typeArgument == const DynamicType());
    } else {
      assert(typeArgs == null);
    }
  }

  int get order => TypeOrder.RuntimeType.index;

  Nullability get nullability => _type.declaredNullability;

  RuntimeType withNullability(Nullability n) =>
      RuntimeType(_type.withDeclaredNullability(n), typeArgs);

  DartType get representedTypeRaw => _type;

  DartType get representedType {
    final type = _type;
    if (type is InterfaceType && typeArgs != null) {
      final klass = type.classNode;
      final typeArguments = typeArgs
          .take(klass.typeParameters.length)
          .map((pt) => pt.representedType)
          .toList();
      return new InterfaceType(klass, type.nullability, typeArguments);
    } else if (type is FutureOrType) {
      return new FutureOrType(typeArgs[0].representedType, type.nullability);
    } else {
      return type;
    }
  }

  @override
  int get hashCode {
    int hash = _type.hashCode ^ 0x1234 & kHashMask;
    // Only hash by the type arguments of the class. The type arguments of
    // supertypes are are implied by them.
    for (int i = 0; i < numImmediateTypeArgs; ++i) {
      hash = (((hash * 31) & kHashMask) + typeArgs[i].hashCode) & kHashMask;
    }
    return hash;
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is RuntimeType) {
      if (other._type != _type) return false;
      assert(numImmediateTypeArgs == other.numImmediateTypeArgs);
      return typeArgs == null || listEquals(typeArgs, other.typeArgs);
    }
    return false;
  }

  @override
  String toString() {
    final head = _type is InterfaceType
        ? "${nodeToText((_type as InterfaceType).classNode)}"
        : "${nodeToText(_type)}";
    final typeArgsStrs = (numImmediateTypeArgs == 0)
        ? ""
        : "<${typeArgs.take(numImmediateTypeArgs).map((t) => "$t").join(", ")}>";
    final nullability = _type.nullability.suffix;
    return "$head$typeArgsStrs$nullability";
  }

  @override
  bool get isSpecialized =>
      throw "ERROR: RuntimeType does not support isSpecialized.";

  @override
  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class cls) =>
      throw "ERROR: RuntimeType does not support isSubtypeOf.";

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) =>
      throw "ERROR: RuntimeType does not support union.";

  // This only works between "type-set" representations ('UnknownType' and
  // 'RuntimeType') and is used when merging type arguments.
  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other is UnknownType) {
      return this;
    } else if (other is RuntimeType) {
      return this == other ? this : const EmptyType();
    }
    throw "ERROR: RuntimeType cannot intersect with ${other.runtimeType}";
  }

  @override
  Type specialize(TypeHierarchy typeHierarchy) =>
      throw "ERROR: RuntimeType does not support specialize.";

  @override
  Class getConcreteClass(TypeHierarchy typeHierarchy) =>
      throw "ERROR: ConcreteClass does not support getConcreteClass.";

  bool isSubtypeOfRuntimeType(
      TypeHierarchy typeHierarchy, RuntimeType runtimeType) {
    final rhs = runtimeType._type;
    if (typeHierarchy.nullSafety &&
        _type.nullability == Nullability.nullable &&
        rhs.nullability == Nullability.nonNullable) {
      return false;
    }
    if (rhs is DynamicType ||
        rhs is VoidType ||
        _type is BottomType ||
        _type is NeverType) {
      return true;
    }
    if (rhs is BottomType || rhs is NeverType) return false;
    if (_type is DynamicType || _type is VoidType) {
      return (rhs is InterfaceType &&
          rhs.classNode == typeHierarchy.coreTypes.objectClass);
    }

    if (rhs is FutureOrType) {
      if (_type is InterfaceType) {
        Class thisClass = (_type as InterfaceType).classNode;
        if (thisClass == typeHierarchy.coreTypes.futureClass) {
          return typeArgs[0]
              .isSubtypeOfRuntimeType(typeHierarchy, runtimeType.typeArgs[0]);
        } else {
          return isSubtypeOfRuntimeType(typeHierarchy, runtimeType.typeArgs[0]);
        }
      } else if (_type is FutureOrType) {
        return typeArgs[0]
            .isSubtypeOfRuntimeType(typeHierarchy, runtimeType.typeArgs[0]);
      }
    }

    if (_type is FutureOrType) {
      // There are more possibilities for _type to be a subtype of rhs, such as
      // the following:
      //   1. _type=FutureOr<Future<...>>, rhs=Future<dynamic>
      //   2. _type=FutureOr<X>, rhs=Future<Y>, where X and Y are type
      //      parameters declared as `X extends Y`, `Y extends Future<Y>`.
      // Since it's ok to return false when _type <: rhs in rare cases, only the
      // most common case of rhs being Object is handled here for now.
      // TODO(alexmarkov): Handle other possibilities.
      return rhs is InterfaceType &&
          rhs.classNode == typeHierarchy.coreTypes.objectClass;
    }

    final thisClass = (_type as InterfaceType).classNode;
    final otherClass = (rhs as InterfaceType).classNode;

    if (!typeHierarchy.isSubtype(thisClass, otherClass)) return false;

    // The typeHierarchy result maybe be inaccurate only if there are type
    // arguments which need to be examined.
    if (runtimeType.numImmediateTypeArgs == 0) {
      return true;
    }

    List<Type> usableTypeArgs = typeArgs;
    if (usableTypeArgs == null) {
      assert(thisClass.typeParameters.isEmpty);
      usableTypeArgs =
          typeHierarchy.flattenedTypeArgumentsForNonGeneric(thisClass);
    }
    final interfaceOffset =
        typeHierarchy.genericInterfaceOffsetFor(thisClass, otherClass);
    assert(usableTypeArgs.length - interfaceOffset >=
        runtimeType.numImmediateTypeArgs);
    for (int i = 0; i < runtimeType.numImmediateTypeArgs; ++i) {
      if (!usableTypeArgs[interfaceOffset + i]
          .isSubtypeOfRuntimeType(typeHierarchy, runtimeType.typeArgs[i])) {
        return false;
      }
    }
    return true;
  }
}

/// Type which is not known at compile time.
/// It is used as the right-hand-side of type tests.
class UnknownType extends Type {
  const UnknownType();

  @override
  int get hashCode => 1019;

  @override
  bool operator ==(other) => (other is UnknownType);

  @override
  String toString() => "UNKNOWN";

  @override
  int get order => TypeOrder.Unknown.index;

  @override
  bool isSubtypeOf(TypeHierarchy typeHierarchy, Class cls) =>
      throw "ERROR: UnknownType does not support isSubtypeOf.";

  @override
  Type union(Type other, TypeHierarchy typeHierarchy) {
    if (other is UnknownType || other is RuntimeType) {
      return this;
    }
    throw "ERROR: UnknownType does not support union with ${other.runtimeType}";
  }

  // This only works between "type-set" representations ('UnknownType' and
  // 'RuntimeType') and is used when merging type arguments.
  @override
  Type intersection(Type other, TypeHierarchy typeHierarchy) {
    if (other is UnknownType || other is RuntimeType) {
      return other;
    }
    throw "ERROR: UnknownType does not support intersection with ${other.runtimeType}";
  }

  bool isSubtypeOfRuntimeType(TypeHierarchy typeHierarchy, RuntimeType other) {
    final rhs = other._type;
    return (rhs is DynamicType) ||
        (rhs is VoidType) ||
        (rhs is InterfaceType &&
            rhs.classNode == typeHierarchy.coreTypes.objectClass &&
            rhs.nullability != Nullability.nonNullable);
  }
}
