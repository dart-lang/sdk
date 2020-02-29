// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/names.dart';
import '../common_elements.dart';
import '../serialization/serialization.dart';
import '../util/util.dart' show equalElements;
import 'entities.dart';

/// Hierarchy to describe types in Dart.
///
/// This hierarchy is a super hierarchy of the use-case specific hierarchies
/// used in different parts of the compiler. This hierarchy abstracts details
/// not generally needed or required for the Dart type hierarchy. For instance,
/// the hierarchy in 'resolution_types.dart' has properties supporting lazy
/// computation (like computeAlias) and distinctions between 'Foo' and
/// 'Foo<dynamic>', features that are not needed for code generation and not
/// supported from kernel.
///
/// Current only 'resolution_types.dart' implement this hierarchy but when the
/// compiler moves to use [Entity] instead of [Element] this hierarchy can be
/// implemented directly but other entity systems, for instance based directly
/// on kernel ir without the need for [Element].

extension on DataSource {
  List<DartType> _readDartTypes(
      List<FunctionTypeVariable> functionTypeVariables) {
    int count = readInt();
    List<DartType> types = List<DartType>(count);
    for (int index = 0; index < count; index++) {
      types[index] = DartType.readFromDataSource(this, functionTypeVariables);
    }
    return types;
  }
}

extension on DataSink {
  void _writeDartTypes(
      List<DartType> types, List<FunctionTypeVariable> functionTypeVariables) {
    writeInt(types.length);
    for (DartType type in types) {
      type.writeToDataSink(this, functionTypeVariables);
    }
  }
}

abstract class DartType {
  const DartType();

  factory DartType.readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    DartTypeKind kind = source.readEnum(DartTypeKind.values);
    switch (kind) {
      case DartTypeKind.none:
        return null;
      case DartTypeKind.legacyType:
        return LegacyType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.nullableType:
        return NullableType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.neverType:
        return NeverType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.voidType:
        return VoidType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.typeVariable:
        return TypeVariableType._readFromDataSource(
            source, functionTypeVariables);
      case DartTypeKind.functionTypeVariable:
        return FunctionTypeVariable._readFromDataSource(
            source, functionTypeVariables);
      case DartTypeKind.functionType:
        return FunctionType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.interfaceType:
        return InterfaceType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.dynamicType:
        return DynamicType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.erasedType:
        return ErasedType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.anyType:
        return AnyType._readFromDataSource(source, functionTypeVariables);
      case DartTypeKind.futureOr:
        return FutureOrType._readFromDataSource(source, functionTypeVariables);
    }
    throw UnsupportedError('Unexpected DartTypeKind $kind');
  }

  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables);

  /// Returns the base type if this is a [LegacyType] or [NullableType] and
  /// returns this type otherwise.
  DartType get withoutNullability => this;

  /// Is `true` if this type is a top type but not a legacy top type.
  bool _isStrongTop(bool useNullSafety) => false;

  /// Is `true` if this type is a top type.
  bool _isTop(bool useNullSafety) => _isStrongTop(useNullSafety);

  /// Is `true` if every type argument of this type is a top type.
  // TODO(fishythefish): Should we instead check if each type argument is at its
  // bound?
  bool _treatAsRaw(bool useNullSafety) => true;

  /// Whether this type contains a type variable.
  bool get containsTypeVariables => false;

  /// Whether this type contains a free class type variable or function type
  /// variable.
  // TODO(sra): Review uses of [containsTypeVariables] for update with
  // [containsFreeTypeVariables].
  bool get containsFreeTypeVariables =>
      _ContainsFreeTypeVariablesVisitor().run(this);

  /// Is `true` if this type is the `Object` type defined in `dart:core`.
  bool get isObject => false;

  /// Is `true` if this type is the `Null` type defined in `dart:core`.
  bool get isNull => false;

  /// Applies [f] to each occurrence of a [TypeVariableType] within this
  /// type. This excludes function type variables, whether free or bound.
  void forEachTypeVariable(f(TypeVariableType variable)) {}

  /// Calls the visit method on [visitor] corresponding to this type.
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument);

  bool _equals(DartType other, _Assumptions assumptions);

  @override
  String toString() => _DartTypeToStringVisitor().run(this);
}

/// Pairs of [FunctionTypeVariable]s that are currently assumed to be
/// equivalent.
///
/// This is used to compute the equivalence relation on types coinductively.
class _Assumptions {
  Map<FunctionTypeVariable, Set<FunctionTypeVariable>> _assumptionMap =
      <FunctionTypeVariable, Set<FunctionTypeVariable>>{};

  void _addAssumption(FunctionTypeVariable a, FunctionTypeVariable b) {
    _assumptionMap
        .putIfAbsent(a, () => new Set<FunctionTypeVariable>.identity())
        .add(b);
  }

  /// Assume that [a] and [b] are equivalent.
  void assume(FunctionTypeVariable a, FunctionTypeVariable b) {
    _addAssumption(a, b);
    _addAssumption(b, a);
  }

  void assumePairs(
      List<FunctionTypeVariable> as, List<FunctionTypeVariable> bs) {
    int length = as.length;
    assert(length == bs.length);
    for (int i = 0; i < length; i++) {
      assume(as[i], bs[i]);
    }
  }

  void _removeAssumption(FunctionTypeVariable a, FunctionTypeVariable b) {
    Set<FunctionTypeVariable> set = _assumptionMap[a];
    if (set != null) {
      set.remove(b);
      if (set.isEmpty) {
        _assumptionMap.remove(a);
      }
    }
  }

  /// Remove the assumption that [a] and [b] are equivalent.
  void forget(FunctionTypeVariable a, FunctionTypeVariable b) {
    _removeAssumption(a, b);
    _removeAssumption(b, a);
  }

  void forgetPairs(
      List<FunctionTypeVariable> as, List<FunctionTypeVariable> bs) {
    int length = as.length;
    assert(length == bs.length);
    for (int i = 0; i < length; i++) {
      forget(as[i], bs[i]);
    }
  }

  /// Returns `true` if [a] and [b] are assumed to be equivalent.
  bool isAssumed(FunctionTypeVariable a, FunctionTypeVariable b) {
    return _assumptionMap[a]?.contains(b) ?? false;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('_Assumptions(');
    String comma = '';
    _assumptionMap
        .forEach((FunctionTypeVariable a, Set<FunctionTypeVariable> set) {
      sb.write('$comma$a (${identityHashCode(a)})->'
          '{${set.map((b) => '$b (${identityHashCode(b)})').join(',')}}');
      comma = ',';
    });
    sb.write(')');
    return sb.toString();
  }
}

class LegacyType extends DartType {
  final DartType baseType;

  const LegacyType._(this.baseType);

  factory LegacyType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    DartType baseType =
        DartType.readFromDataSource(source, functionTypeVariables);
    return LegacyType._(baseType);
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.legacyType);
    baseType.writeToDataSink(sink, functionTypeVariables);
  }

  @override
  DartType get withoutNullability => baseType;

  @override
  bool _isTop(bool useNullSafety) => baseType.isObject;

  @override
  bool _treatAsRaw(bool useNullSafety) => baseType._treatAsRaw(useNullSafety);

  @override
  bool get containsTypeVariables => baseType.containsTypeVariables;

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    baseType.forEachTypeVariable(f);
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitLegacyType(this, argument);

  @override
  int get hashCode => baseType.hashCode * 31;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! LegacyType) return false;
    return _equalsInternal(other, null);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! LegacyType) return false;
    return _equalsInternal(other, assumptions);
  }

  bool _equalsInternal(LegacyType other, _Assumptions assumptions) =>
      baseType._equals(other.baseType, assumptions);
}

class NullableType extends DartType {
  final DartType baseType;

  const NullableType._(this.baseType);

  factory NullableType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    DartType baseType =
        DartType.readFromDataSource(source, functionTypeVariables);
    return NullableType._(baseType);
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.nullableType);
    baseType.writeToDataSink(sink, functionTypeVariables);
  }

  @override
  DartType get withoutNullability => baseType;

  @override
  bool _isStrongTop(bool isLegacy) => baseType.isObject;

  @override
  bool _treatAsRaw(bool useNullSafety) => baseType._treatAsRaw(useNullSafety);

  @override
  bool get containsTypeVariables => baseType.containsTypeVariables;

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    baseType.forEachTypeVariable(f);
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitNullableType(this, argument);

  @override
  int get hashCode => baseType.hashCode * 37;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NullableType) return false;
    return _equalsInternal(other, null);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! NullableType) return false;
    return _equalsInternal(other, assumptions);
  }

  bool _equalsInternal(NullableType other, _Assumptions assumptions) =>
      baseType._equals(other.baseType, assumptions);
}

class InterfaceType extends DartType {
  final ClassEntity element;
  final List<DartType> typeArguments;

  InterfaceType._(this.element, this.typeArguments)
      : assert(typeArguments.every((e) => e != null));

  factory InterfaceType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    ClassEntity element = source.readClass();
    List<DartType> typeArguments = source._readDartTypes(functionTypeVariables);
    return InterfaceType._(element, typeArguments);
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.interfaceType);
    sink.writeClass(element);
    sink._writeDartTypes(typeArguments, functionTypeVariables);
  }

  @override
  bool _isStrongTop(bool useNullSafety) => useNullSafety ? false : isObject;

  @override
  bool get isObject =>
      element.name == 'Object' &&
      element.library.canonicalUri == Uris.dart_core;

  @override
  bool get isNull =>
      element.name == 'Null' && element.library.canonicalUri == Uris.dart_core;

  @override
  bool get containsTypeVariables =>
      typeArguments.any((type) => type.containsTypeVariables);

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    typeArguments.forEach((type) => type.forEachTypeVariable(f));
  }

  @override
  bool _treatAsRaw(bool useNullSafety) {
    for (DartType type in typeArguments) {
      if (!type._isTop(useNullSafety)) return false;
    }
    return true;
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitInterfaceType(this, argument);

  @override
  int get hashCode {
    int hash = element.hashCode;
    for (DartType argument in typeArguments) {
      int argumentHash = argument != null ? argument.hashCode : 0;
      hash = 17 * hash + 3 * argumentHash;
    }
    return hash;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! InterfaceType) return false;
    return _equalsInternal(other, null);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! InterfaceType) return false;
    return _equalsInternal(other, assumptions);
  }

  bool _equalsInternal(InterfaceType other, _Assumptions assumptions) {
    return identical(element, other.element) &&
        _equalTypes(typeArguments, other.typeArguments, assumptions);
  }
}

class TypeVariableType extends DartType {
  final TypeVariableEntity element;

  const TypeVariableType._(this.element);

  factory TypeVariableType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    TypeVariableEntity element = source.readTypeVariable();
    return TypeVariableType._(element);
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.typeVariable);
    sink.writeTypeVariable(element);
  }

  @override
  bool get containsTypeVariables => true;

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    f(this);
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitTypeVariableType(this, argument);

  @override
  int get hashCode => 17 * element.hashCode;

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      other is TypeVariableType && identical(other.element, element);

  @override
  bool _equals(DartType other, _Assumptions assumptions) => this == other;
}

/// A type variable declared on a function type.
///
/// For instance `T` in
///     void Function<T>(T t)
///
/// Such a type variable is different from a [TypeVariableType] because it
/// doesn't have a unique identity; is is equal to any other
/// [FunctionTypeVariable] used similarly in another structurally equivalent
/// function type.
class FunctionTypeVariable extends DartType {
  /// The index of this type within the type variables of the declaring function
  /// type.
  final int index;

  /// The bound of this function type variable.
  DartType _bound;

  FunctionTypeVariable._(this.index);

  factory FunctionTypeVariable._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    int index = source.readInt();
    assert(0 <= index && index < functionTypeVariables.length);
    return functionTypeVariables[index];
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    int index = functionTypeVariables.indexOf(this);
    if (index == -1) {
      // TODO(johnniwinther): Avoid free variables.
      const DynamicType._().writeToDataSink(sink, functionTypeVariables);
    } else {
      sink.writeEnum(DartTypeKind.functionTypeVariable);
      sink.writeInt(index);
    }
  }

  DartType get bound {
    assert(_bound != null, "Bound has not been set.");
    return _bound;
  }

  void set bound(DartType value) {
    assert(_bound == null, "Bound has already been set.");
    _bound = value;
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! FunctionTypeVariable) return false;
    if (assumptions != null) return assumptions.isAssumed(this, other);
    return false;
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitFunctionTypeVariable(this, argument);
}

class NeverType extends DartType {
  const NeverType._();

  factory NeverType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    return const NeverType._();
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.neverType);
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitNeverType(this, argument);

  @override
  int get hashCode => 43;

  @override
  bool operator ==(other) => identical(this, other) || other is NeverType;

  @override
  bool _equals(DartType other, _Assumptions assumptions) => this == other;
}

class VoidType extends DartType {
  const VoidType._();

  factory VoidType._readFromDataSource(DataSource source,
          List<FunctionTypeVariable> functionTypeVariables) =>
      const VoidType._();

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.voidType);
  }

  @override
  bool _isStrongTop(bool useNullSafety) => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitVoidType(this, argument);

  @override
  int get hashCode => 6007;

  @override
  bool operator ==(other) => identical(this, other) || other is VoidType;

  @override
  bool _equals(DartType other, _Assumptions assumptions) => this == other;
}

class DynamicType extends DartType {
  const DynamicType._();

  factory DynamicType._readFromDataSource(DataSource source,
          List<FunctionTypeVariable> functionTypeVariables) =>
      const DynamicType._();

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.dynamicType);
  }

  @override
  bool _isStrongTop(bool useNullSafety) => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitDynamicType(this, argument);

  @override
  int get hashCode => 91;

  @override
  bool operator ==(other) => identical(this, other) || other is DynamicType;

  @override
  bool _equals(DartType other, _Assumptions assumptions) => this == other;
}

class ErasedType extends DartType {
  const ErasedType._();

  factory ErasedType._readFromDataSource(DataSource source,
          List<FunctionTypeVariable> functionTypeVariables) =>
      const ErasedType._();

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.erasedType);
  }

  @override
  bool _isStrongTop(bool useNullSafety) => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitErasedType(this, argument);

  @override
  int get hashCode => 119;

  @override
  bool operator ==(other) => identical(this, other) || other is ErasedType;

  @override
  bool _equals(DartType other, _Assumptions assumptions) => this == other;
}

/// Represents a type which is simultaneously top and bottom.
///
/// This is not a standard Dart type, but an extension of the standard Dart type
/// system for dart2js. Because 'any' is both top and bottom, it is useful for
/// ensuring that type checks succeed so that we can avoid spurious failures
/// when our analysis is incorrect or incomplete.
///
/// Use cases include:
/// * Representing inscrutable JS-interop types.
/// * Representing types appearing as generic method bounds which contain type
/// variables. (See issue 33422.)
class AnyType extends DartType {
  const AnyType._();

  factory AnyType._readFromDataSource(DataSource source,
          List<FunctionTypeVariable> functionTypeVariables) =>
      const AnyType._();

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.anyType);
  }

  @override
  bool _isStrongTop(bool useNullSafety) => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitAnyType(this, argument);

  @override
  int get hashCode => 95;

  @override
  bool operator ==(other) => identical(this, other) || other is AnyType;

  @override
  bool _equals(DartType other, _Assumptions assumptions) => this == other;
}

class FunctionType extends DartType {
  final DartType returnType;
  final List<DartType> parameterTypes;
  final List<DartType> optionalParameterTypes;

  /// The names of the named parameters ordered lexicographically.
  final List<String> namedParameters;

  /// The types of the named parameters in the order corresponding to the
  /// [namedParameters].
  final List<DartType> namedParameterTypes;

  final List<FunctionTypeVariable> typeVariables;

  FunctionType._(
      this.returnType,
      this.parameterTypes,
      this.optionalParameterTypes,
      this.namedParameters,
      this.namedParameterTypes,
      this.typeVariables) {
    assert(returnType != null, "Invalid return type in $this.");
    assert(!parameterTypes.contains(null), "Invalid parameter types in $this.");
    assert(!optionalParameterTypes.contains(null),
        "Invalid optional parameter types in $this.");
    assert(
        !namedParameters.contains(null), "Invalid named parameters in $this.");
    assert(!namedParameterTypes.contains(null),
        "Invalid named parameter types in $this.");
    assert(!typeVariables.contains(null), "Invalid type variables in $this.");
  }

  factory FunctionType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    int typeVariableCount = source.readInt();
    List<FunctionTypeVariable> typeVariables =
        List<FunctionTypeVariable>.generate(
            typeVariableCount, (int index) => FunctionTypeVariable._(index));
    functionTypeVariables = List<FunctionTypeVariable>.of(functionTypeVariables)
      ..addAll(typeVariables);
    for (int index = 0; index < typeVariableCount; index++) {
      typeVariables[index].bound =
          DartType.readFromDataSource(source, functionTypeVariables);
    }
    DartType returnType =
        DartType.readFromDataSource(source, functionTypeVariables);
    List<DartType> parameterTypes =
        source._readDartTypes(functionTypeVariables);
    List<DartType> optionalParameterTypes =
        source._readDartTypes(functionTypeVariables);
    List<DartType> namedParameterTypes =
        source._readDartTypes(functionTypeVariables);
    List<String> namedParameters = List<String>(namedParameterTypes.length);
    for (int i = 0; i < namedParameters.length; i++) {
      namedParameters[i] = source.readString();
    }
    return FunctionType._(returnType, parameterTypes, optionalParameterTypes,
        namedParameters, namedParameterTypes, typeVariables);
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.functionType);
    functionTypeVariables = List<FunctionTypeVariable>.of(functionTypeVariables)
      ..addAll(typeVariables);
    sink.writeInt(typeVariables.length);
    for (FunctionTypeVariable variable in typeVariables) {
      variable.bound.writeToDataSink(sink, functionTypeVariables);
    }
    returnType.writeToDataSink(sink, functionTypeVariables);
    sink._writeDartTypes(parameterTypes, functionTypeVariables);
    sink._writeDartTypes(optionalParameterTypes, functionTypeVariables);
    sink._writeDartTypes(namedParameterTypes, functionTypeVariables);
    for (String namedParameter in namedParameters) {
      sink.writeString(namedParameter);
    }
  }

  @override
  bool get containsTypeVariables {
    return typeVariables.any((type) => type.bound.containsTypeVariables) ||
        returnType.containsTypeVariables ||
        parameterTypes.any((type) => type.containsTypeVariables) ||
        optionalParameterTypes.any((type) => type.containsTypeVariables) ||
        namedParameterTypes.any((type) => type.containsTypeVariables);
  }

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    typeVariables.forEach((type) => type.bound.forEachTypeVariable(f));
    returnType.forEachTypeVariable(f);
    parameterTypes.forEach((type) => type.forEachTypeVariable(f));
    optionalParameterTypes.forEach((type) => type.forEachTypeVariable(f));
    namedParameterTypes.forEach((type) => type.forEachTypeVariable(f));
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitFunctionType(this, argument);

  @override
  int get hashCode {
    int hash = 3 * returnType.hashCode;
    for (DartType parameter in parameterTypes) {
      hash = 17 * hash + 5 * parameter.hashCode;
    }
    for (DartType parameter in optionalParameterTypes) {
      hash = 19 * hash + 7 * parameter.hashCode;
    }
    for (String name in namedParameters) {
      hash = 23 * hash + 11 * name.hashCode;
    }
    for (DartType parameter in namedParameterTypes) {
      hash = 29 * hash + 13 * parameter.hashCode;
    }
    return hash;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! FunctionType) return false;
    return _equalsInternal(other, null);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! FunctionType) return false;
    return _equalsInternal(other, assumptions);
  }

  bool _equalsInternal(FunctionType other, _Assumptions assumptions) {
    if (typeVariables.length != other.typeVariables.length) return false;
    assumptions ??= _Assumptions();
    assumptions.assumePairs(typeVariables, other.typeVariables);
    try {
      for (int index = 0; index < typeVariables.length; index++) {
        if (!typeVariables[index]
            .bound
            ._equals(other.typeVariables[index].bound, assumptions)) {
          return false;
        }
      }
      return returnType._equals(other.returnType, assumptions) &&
          _equalTypes(parameterTypes, other.parameterTypes, assumptions) &&
          _equalTypes(optionalParameterTypes, other.optionalParameterTypes,
              assumptions) &&
          equalElements(namedParameters, other.namedParameters) &&
          _equalTypes(
              namedParameterTypes, other.namedParameterTypes, assumptions);
    } finally {
      assumptions.forgetPairs(typeVariables, other.typeVariables);
    }
  }
}

class FutureOrType extends DartType {
  final DartType typeArgument;

  const FutureOrType._(this.typeArgument);

  factory FutureOrType._readFromDataSource(
      DataSource source, List<FunctionTypeVariable> functionTypeVariables) {
    DartType typeArgument =
        DartType.readFromDataSource(source, functionTypeVariables);
    return FutureOrType._(typeArgument);
  }

  @override
  void writeToDataSink(
      DataSink sink, List<FunctionTypeVariable> functionTypeVariables) {
    sink.writeEnum(DartTypeKind.futureOr);
    typeArgument.writeToDataSink(sink, functionTypeVariables);
  }

  @override
  bool get containsTypeVariables => typeArgument.containsTypeVariables;

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    typeArgument.forEachTypeVariable(f);
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitFutureOrType(this, argument);

  @override
  int get hashCode => typeArgument.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! FutureOrType) return false;
    return _equalsInternal(other, null);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! FutureOrType) return false;
    return _equalsInternal(other, assumptions);
  }

  bool _equalsInternal(FutureOrType other, _Assumptions assumptions) {
    return typeArgument._equals(other.typeArgument, assumptions);
  }
}

bool _equalTypes(List<DartType> a, List<DartType> b, _Assumptions assumptions) {
  if (a.length != b.length) return false;
  for (int index = 0; index < a.length; index++) {
    if (!a[index]._equals(b[index], assumptions)) {
      return false;
    }
  }
  return true;
}

abstract class DartTypeVisitor<R, A> {
  const DartTypeVisitor();

  R visit(covariant DartType type, A argument) => type.accept(this, argument);

  R visitLegacyType(covariant LegacyType type, A argument) => null;

  R visitNullableType(covariant NullableType type, A argument) => null;

  R visitNeverType(covariant NeverType type, A argument) => null;

  R visitVoidType(covariant VoidType type, A argument) => null;

  R visitTypeVariableType(covariant TypeVariableType type, A argument) => null;

  R visitFunctionTypeVariable(
          covariant FunctionTypeVariable type, A argument) =>
      null;

  R visitFunctionType(covariant FunctionType type, A argument) => null;

  R visitInterfaceType(covariant InterfaceType type, A argument) => null;

  R visitDynamicType(covariant DynamicType type, A argument) => null;

  R visitErasedType(covariant ErasedType type, A argument) => null;

  R visitAnyType(covariant AnyType type, A argument) => null;

  R visitFutureOrType(covariant FutureOrType type, A argument) => null;
}

abstract class BaseDartTypeVisitor<R, A> extends DartTypeVisitor<R, A> {
  const BaseDartTypeVisitor();

  R visitType(covariant DartType type, A argument);

  @override
  R visitLegacyType(covariant LegacyType type, A argument) =>
      visitType(type, argument);

  @override
  R visitNullableType(covariant NullableType type, A argument) =>
      visitType(type, argument);

  @override
  R visitNeverType(covariant NeverType type, A argument) =>
      visitType(type, argument);

  @override
  R visitVoidType(covariant VoidType type, A argument) =>
      visitType(type, argument);

  @override
  R visitTypeVariableType(covariant TypeVariableType type, A argument) =>
      visitType(type, argument);

  @override
  R visitFunctionTypeVariable(
          covariant FunctionTypeVariable type, A argument) =>
      visitType(type, argument);

  @override
  R visitFunctionType(covariant FunctionType type, A argument) =>
      visitType(type, argument);

  @override
  R visitInterfaceType(covariant InterfaceType type, A argument) =>
      visitType(type, argument);

  @override
  R visitDynamicType(covariant DynamicType type, A argument) =>
      visitType(type, argument);

  @override
  R visitErasedType(covariant ErasedType type, A argument) =>
      visitType(type, argument);

  @override
  R visitAnyType(covariant AnyType type, A argument) =>
      visitType(type, argument);

  @override
  R visitFutureOrType(covariant FutureOrType type, A argument) =>
      visitType(type, argument);
}

abstract class DartTypeSubstitutionVisitor<A>
    extends DartTypeVisitor<DartType, A> {
  DartTypes get dartTypes;

  // The input type is a DAG and we must preserve the sharing.
  Map<DartType, DartType> _map = Map.identity();

  DartType _mapped(DartType oldType, DartType newType) {
    assert(_map[oldType] == null);
    return _map[oldType] = newType;
  }

  /// Returns the replacement for the type variable [type]. Returns the original
  /// [type] if not substituted. The substitution algorithm sometimes visits the
  /// same subterm more than once. When this happens, [freshReference] is `true`
  /// on only one visit. This allows the substitution visitor to count the
  /// number of times the replacement term occurs in the final term.
  DartType substituteTypeVariableType(
      TypeVariableType type, A argument, bool freshReference);

  /// Returns the replacement for the function type variable [type]. Returns the
  /// original [type] if not substituted. The substitution algorithm sometimes
  /// visits the same subterm more than once. When this happens,
  /// [freshReference] is `true` on only one visit. This allows the substitution
  /// visitor to count the number of times the replacement term occurs in the
  /// final term.
  DartType substituteFunctionTypeVariable(
          FunctionTypeVariable type, A argument, bool freshReference) =>
      type;

  @override
  DartType visitLegacyType(covariant LegacyType type, A argument) {
    DartType probe = _map[type];
    if (probe != null) return probe;

    DartType newBaseType = visit(type.baseType, argument);
    // Create a new type only if necessary.
    if (identical(type.baseType, newBaseType)) {
      return _mapped(type, type);
    }
    return _mapped(type, dartTypes.legacyType(newBaseType));
  }

  @override
  DartType visitNullableType(covariant NullableType type, A argument) {
    DartType probe = _map[type];
    if (probe != null) return probe;

    DartType newBaseType = visit(type.baseType, argument);
    // Create a new type only if necessary.
    if (identical(type.baseType, newBaseType)) {
      return _mapped(type, type);
    }
    return _mapped(type, dartTypes.nullableType(newBaseType));
  }

  @override
  DartType visitNeverType(covariant NeverType type, A argument) => type;

  @override
  DartType visitTypeVariableType(covariant TypeVariableType type, A argument) {
    return substituteTypeVariableType(type, argument, true);
  }

  @override
  DartType visitFunctionTypeVariable(
      covariant FunctionTypeVariable type, A argument) {
    // Function type variables are added to the map only for type variables that
    // need to be replaced with updated bounds.
    DartType probe = _map[type];
    if (probe != null) return probe;
    return substituteFunctionTypeVariable(type, argument, true);
  }

  @override
  DartType visitVoidType(covariant VoidType type, A argument) => type;

  @override
  DartType visitFunctionType(covariant FunctionType type, A argument) {
    DartType probe = _map[type];
    if (probe != null) return probe;

    List<FunctionTypeVariable> newTypeVariables =
        _handleFunctionTypeVariables(type.typeVariables, argument);

    DartType newReturnType = visit(type.returnType, argument);
    List<DartType> newParameterTypes =
        _substTypes(type.parameterTypes, argument);
    List<DartType> newOptionalParameterTypes =
        _substTypes(type.optionalParameterTypes, argument);
    List<DartType> newNamedParameterTypes =
        _substTypes(type.namedParameterTypes, argument);

    // Create a new type only if necessary.
    if (identical(type.typeVariables, newTypeVariables) &&
        identical(type.returnType, newReturnType) &&
        identical(type.parameterTypes, newParameterTypes) &&
        identical(type.optionalParameterTypes, newOptionalParameterTypes) &&
        identical(type.namedParameterTypes, newNamedParameterTypes)) {
      return _mapped(type, type);
    }

    List<FunctionTypeVariable> normalizableVariables = [];
    for (int i = 0; i < newTypeVariables.length; i++) {
      FunctionTypeVariable t = newTypeVariables[i];
      if (identical(t, type.typeVariables[i])) continue;
      DartType bound = t.bound;
      if (bound is NeverType) {
        normalizableVariables.add(t);
      }
    }

    return _mapped(
        type,
        dartTypes.subst(
            List<DartType>.filled(
                normalizableVariables.length, dartTypes.neverType()),
            normalizableVariables,
            dartTypes.functionType(
                newReturnType,
                newParameterTypes,
                newOptionalParameterTypes,
                type.namedParameters,
                newNamedParameterTypes,
                newTypeVariables)));
  }

  List<FunctionTypeVariable> _handleFunctionTypeVariables(
      List<FunctionTypeVariable> variables, A argument) {
    if (variables.isEmpty) return variables;

    // Are the function type variables being substituted (i.e. generic function
    // type instantiation).
    // TODO(sra): This should happen only from via
    // [FunctionType.instantiate]. Perhaps it would be handled better there.
    int count = 0;
    for (int i = 0; i < variables.length; i++) {
      FunctionTypeVariable variable = variables[i];
      if (variable !=
          substituteFunctionTypeVariable(variable, argument, false)) {
        count++;
      }
    }
    if (count == variables.length) return const <FunctionTypeVariable>[];
    assert(count == 0, 'Generic function type instantiation is all-or-none');

    // Type variables may depend on each other. Consider:
    //
    //     <A extends List<B>,
    //      B extends Set<A>,
    //      C extends D,
    //      D extends Map<B, F>>(){}
    //
    // A and B have a cycle but are not changed by the subsitution of F->G. C is
    // indirectly changed by the substitution of F. When D is replaced by `D2
    // extends Map<B,G>`, C must be replaced by `C2 extends D2`.

    List<FunctionTypeVariable> undecided = variables.toList();
    List<FunctionTypeVariable> newVariables;

    _DependencyCheck<A> dependencyCheck = _DependencyCheck<A>(this, argument);

    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < undecided.length; i++) {
        FunctionTypeVariable variable = undecided[i];
        if (variable == null) continue;
        if (dependencyCheck.run(variable.bound)) {
          changed = true;
          undecided[i] = null;
          newVariables ??= variables.toList();
          FunctionTypeVariable newVariable =
              dartTypes.functionTypeVariable(variable.index);
          newVariables[i] = newVariable;
          _mapped(variable, newVariable);
        }
      }
    }
    if (newVariables == null) return variables;

    // Substitute the bounds of the new variables;
    for (int i = 0; i < newVariables.length; i++) {
      FunctionTypeVariable oldVariable = variables[i];
      FunctionTypeVariable newVariable = newVariables[i];
      if (identical(oldVariable, newVariable)) continue;
      newVariable.bound = visit(oldVariable.bound, argument);
    }
    return newVariables;
  }

  @override
  DartType visitInterfaceType(covariant InterfaceType type, A argument) {
    List<DartType> typeArguments = type.typeArguments;
    if (typeArguments.isEmpty) {
      // Return fast on non-generic types.
      return type;
    }

    DartType probe = _map[type];
    if (probe != null) return probe;

    List<DartType> newTypeArguments = _substTypes(typeArguments, argument);
    // Create a new type only if necessary.
    if (identical(typeArguments, newTypeArguments)) {
      return _mapped(type, type);
    }
    return _mapped(
        type, dartTypes.interfaceType(type.element, newTypeArguments));
  }

  @override
  DartType visitDynamicType(covariant DynamicType type, A argument) => type;

  @override
  DartType visitErasedType(covariant ErasedType type, A argument) => type;

  @override
  DartType visitAnyType(covariant AnyType type, A argument) => type;

  @override
  DartType visitFutureOrType(covariant FutureOrType type, A argument) {
    DartType probe = _map[type];
    if (probe != null) return probe;

    DartType newTypeArgument = visit(type.typeArgument, argument);
    // Create a new type only if necessary.
    if (identical(type.typeArgument, newTypeArgument)) {
      return _mapped(type, type);
    }
    return _mapped(type, dartTypes.futureOrType(newTypeArgument));
  }

  List<DartType> _substTypes(List<DartType> types, A argument) {
    List<DartType> result;
    for (int i = 0; i < types.length; i++) {
      DartType oldType = types[i];
      DartType newType = visit(oldType, argument);
      if (!identical(newType, oldType)) {
        result ??= types.sublist(0, i);
      }
      result?.add(newType);
    }
    return result ?? types;
  }
}

class _DependencyCheck<A> extends DartTypeStructuralPredicateVisitor {
  final DartTypeSubstitutionVisitor<A> _substitutionVisitor;
  final A argument;

  _DependencyCheck(this._substitutionVisitor, this.argument);

  @override
  bool handleTypeVariableType(TypeVariableType type) {
    return !identical(type,
        _substitutionVisitor.substituteTypeVariableType(type, argument, false));
  }

  @override
  bool handleFreeFunctionTypeVariable(FunctionTypeVariable type) {
    // Function type variables are added to the map for type variables that need
    // to be replaced with updated bounds.
    DartType probe = _substitutionVisitor._map[type];
    if (probe != null) return probe != type;
    return !identical(
        type,
        _substitutionVisitor.substituteFunctionTypeVariable(
            type, argument, false));
  }
}

/// A visitor that by default visits the substructure of the type until some
/// visit returns `true`.  The default handlers return `false` which will search
/// the whole structure unless overridden.
abstract class DartTypeStructuralPredicateVisitor
    extends DartTypeVisitor<bool, List<FunctionTypeVariable>> {
  const DartTypeStructuralPredicateVisitor();

  bool run(DartType type) => visit(type, null);

  bool handleLegacyType(LegacyType type) => false;
  bool handleNullableType(NullableType type) => false;
  bool handleNeverType(NeverType type) => false;
  bool handleVoidType(VoidType type) => false;
  bool handleTypeVariableType(TypeVariableType type) => false;
  bool handleBoundFunctionTypeVariable(FunctionTypeVariable type) => false;
  bool handleFreeFunctionTypeVariable(FunctionTypeVariable type) => false;
  bool handleFunctionType(FunctionType type) => false;
  bool handleInterfaceType(InterfaceType type) => false;
  bool handleDynamicType(DynamicType type) => false;
  bool handleErasedType(ErasedType type) => false;
  bool handleAnyType(AnyType type) => false;
  bool handleFutureOrType(FutureOrType type) => false;

  @override
  bool visitLegacyType(LegacyType type, List<FunctionTypeVariable> bindings) =>
      handleLegacyType(type) || visit(type.baseType, bindings);

  @override
  bool visitNullableType(
          NullableType type, List<FunctionTypeVariable> bindings) =>
      handleNullableType(type) || visit(type.baseType, bindings);

  @override
  bool visitNeverType(NeverType type, List<FunctionTypeVariable> bindings) =>
      false;

  @override
  bool visitVoidType(VoidType type, List<FunctionTypeVariable> bindings) =>
      handleVoidType(type);

  @override
  bool visitTypeVariableType(
          TypeVariableType type, List<FunctionTypeVariable> bindings) =>
      handleTypeVariableType(type);

  @override
  bool visitFunctionTypeVariable(
      FunctionTypeVariable type, List<FunctionTypeVariable> bindings) {
    return bindings != null && bindings.indexOf(type) >= 0
        ? handleBoundFunctionTypeVariable(type)
        : handleFreeFunctionTypeVariable(type);
  }

  @override
  bool visitFunctionType(
      FunctionType type, List<FunctionTypeVariable> bindings) {
    if (handleFunctionType(type)) return true;
    List<FunctionTypeVariable> typeVariables = type.typeVariables;
    if (typeVariables.isNotEmpty) {
      bindings ??= <FunctionTypeVariable>[];
      bindings.addAll(typeVariables);
    }

    bool result = visit(type.returnType, bindings);
    result = result ||
        _visitAll(type.typeVariables.map((variable) => variable.bound).toList(),
            bindings);
    result = result || _visitAll(type.parameterTypes, bindings);
    result = result || _visitAll(type.optionalParameterTypes, bindings);
    result = result || _visitAll(type.namedParameterTypes, bindings);

    bindings?.length -= typeVariables.length;
    return result;
  }

  @override
  bool visitInterfaceType(
      InterfaceType type, List<FunctionTypeVariable> bindings) {
    if (handleInterfaceType(type)) return true;
    return _visitAll(type.typeArguments, bindings);
  }

  @override
  bool visitDynamicType(
          DynamicType type, List<FunctionTypeVariable> bindings) =>
      handleDynamicType(type);

  @override
  bool visitErasedType(ErasedType type, List<FunctionTypeVariable> bindings) =>
      handleErasedType(type);

  @override
  bool visitAnyType(AnyType type, List<FunctionTypeVariable> bindings) =>
      handleAnyType(type);

  @override
  bool visitFutureOrType(
      FutureOrType type, List<FunctionTypeVariable> bindings) {
    if (handleFutureOrType(type)) return true;
    return visit(type.typeArgument, bindings);
  }

  bool _visitAll(List<DartType> types, List<FunctionTypeVariable> bindings) {
    for (DartType type in types) {
      if (visit(type, bindings)) return true;
    }
    return false;
  }
}

class _ContainsFreeTypeVariablesVisitor
    extends DartTypeStructuralPredicateVisitor {
  @override
  bool handleTypeVariableType(TypeVariableType type) => true;

  @override
  bool handleFreeFunctionTypeVariable(FunctionTypeVariable type) => true;
}

class SimpleDartTypeSubstitutionVisitor
    extends DartTypeSubstitutionVisitor<Null> {
  @override
  final DartTypes dartTypes;
  final List<DartType> arguments;
  final List<DartType> parameters;

  SimpleDartTypeSubstitutionVisitor(
      this.dartTypes, this.arguments, this.parameters);

  DartType substitute(DartType input) => visit(input, null);

  @override
  DartType substituteTypeVariableType(
      TypeVariableType type, Null _, bool freshReference) {
    int index = parameters.indexOf(type);
    if (index != -1) {
      return arguments[index];
    }
    // The type variable was not substituted.
    return type;
  }

  @override
  DartType substituteFunctionTypeVariable(
      covariant FunctionTypeVariable type, Null _, bool freshReference) {
    int index = parameters.indexOf(type);
    if (index != -1) {
      return arguments[index];
    }
    // The type variable was not substituted.
    return type;
  }
}

class _DeferredName {
  String name;
  _DeferredName();
  @override
  String toString() => name;
}

class _DartTypeToStringVisitor extends DartTypeVisitor<void, void> {
  final List _fragments = []; // Strings and _DeferredNames
  bool _lastIsIdentifier = false;
  List<FunctionTypeVariable> _boundVariables;
  Map<FunctionTypeVariable, _DeferredName> _variableToName;
  Set<FunctionType> _genericFunctions;

  String run(DartType type) {
    _visit(type);
    if (_variableToName != null &&
        _variableToName.values.any((deferred) => deferred.name == null)) {
      // Assign names to _DeferredNames that were not assigned while visiting a
      // generic function type.
      Set<String> usedNames =
          _variableToName.values.map((deferred) => deferred.name).toSet();
      int startGroup = (_genericFunctions?.length ?? 0) + 1;
      for (var entry in _variableToName.entries) {
        if (entry.value.name != null) continue;
        for (int group = startGroup;; group++) {
          String name = _functionTypeVariableName(entry.key, group);
          if (!usedNames.add(name)) continue;
          entry.value.name = name;
          break;
        }
      }
    }
    return _fragments.join();
  }

  String _functionTypeVariableName(FunctionTypeVariable variable, int group) {
    String prefix = String.fromCharCode(0x41 + variable.index);
    String suffix = group == 1 ? '' : '$group';
    return prefix + suffix;
  }

  void _identifier(String text) {
    if (_lastIsIdentifier) _fragments.add(' ');
    _fragments.add(text);
    _lastIsIdentifier = true;
  }

  void _deferredNameIdentifier(_DeferredName name) {
    if (_lastIsIdentifier) _fragments.add(' ');
    _fragments.add(name);
    _lastIsIdentifier = true;
  }

  void _token(String text) {
    _fragments.add(text);
    _lastIsIdentifier = false;
  }

  bool _comma(bool needsComma) {
    if (needsComma) _token(',');
    return true;
  }

  void _visit(DartType type) {
    type.accept(this, null);
  }

  @override
  void visitLegacyType(covariant LegacyType type, _) {
    _visit(type.baseType);
    // We do not emit the '*' token for legacy types because this is a purely
    // internal notion. The language specification does not define a '*' token
    // in the type language, and no such token should be surfaced to users.
    // TODO(fishythefish): Add a flag to enable printing '*'.
  }

  @override
  void visitNullableType(covariant NullableType type, _) {
    _visit(type.baseType);
    _token('?');
  }

  @override
  void visitNeverType(covariant NeverType type, _) {
    _identifier('Never');
  }

  @override
  void visitVoidType(covariant VoidType type, _) {
    _identifier('void');
  }

  @override
  void visitDynamicType(covariant DynamicType type, _) {
    _identifier('dynamic');
  }

  @override
  void visitErasedType(covariant ErasedType type, _) {
    _identifier('erased');
  }

  @override
  void visitAnyType(covariant AnyType type, _) {
    _identifier('any');
  }

  @override
  void visitTypeVariableType(covariant TypeVariableType type, _) {
    _identifier(type.element.typeDeclaration.name);
    _token('.');
    _identifier(type.element.name);
  }

  _DeferredName _nameFor(FunctionTypeVariable type) {
    _variableToName ??= Map.identity();
    return _variableToName[type] ??= _DeferredName();
  }

  @override
  void visitFunctionTypeVariable(covariant FunctionTypeVariable type, _) {
    // The first letter of the variable name indicates the 'index'.  Names have
    // suffixes corresponding to the different generic function types (A, A2,
    // A3, etc).
    _token('#');
    _deferredNameIdentifier(_nameFor(type));
    if (_boundVariables == null || !_boundVariables.contains(type)) {
      _token('/*free*/');
    }
  }

  @override
  void visitFunctionType(covariant FunctionType type, _) {
    if (type.typeVariables.isNotEmpty) {
      // Enter function type variable scope.
      _boundVariables ??= [];
      _boundVariables.addAll(type.typeVariables);
      // Assign names for the function type variables. We could have already
      // assigned names for this node if we are printing a DAG.
      _genericFunctions ??= Set.identity();
      if (_genericFunctions.add(type)) {
        int group = _genericFunctions.length;
        for (FunctionTypeVariable variable in type.typeVariables) {
          _DeferredName deferredName = _nameFor(variable);
          // If there is a structural error where one FunctionTypeVariable is
          // used in two [FunctionType]s it might already have a name.
          deferredName.name ??= _functionTypeVariableName(variable, group);
        }
      }
    }
    _visit(type.returnType);
    _token(' ');
    _identifier('Function');
    if (type.typeVariables.isNotEmpty) {
      _token('<');
      bool needsComma = false;
      for (FunctionTypeVariable typeVariable in type.typeVariables) {
        needsComma = _comma(needsComma);
        _visit(typeVariable);
        DartType bound = typeVariable.bound;
        if (!bound.isObject) {
          _token(' extends ');
          _visit(typeVariable.bound);
        }
      }
      _token('>');
    }
    _token('(');
    bool needsComma = false;
    for (DartType parameterType in type.parameterTypes) {
      needsComma = _comma(needsComma);
      _visit(parameterType);
    }
    if (type.optionalParameterTypes.isNotEmpty) {
      needsComma = _comma(needsComma);
      _token('[');
      bool needsOptionalComma = false;
      for (DartType typeArgument in type.optionalParameterTypes) {
        needsOptionalComma = _comma(needsOptionalComma);
        _visit(typeArgument);
      }
      _token(']');
    }
    if (type.namedParameters.isNotEmpty) {
      needsComma = _comma(needsComma);
      _token('{');
      bool needsNamedComma = false;
      for (int index = 0; index < type.namedParameters.length; index++) {
        needsNamedComma = _comma(needsNamedComma);
        _visit(type.namedParameterTypes[index]);
        _token(' ');
        _identifier(type.namedParameters[index]);
      }
      _token('}');
    }
    _token(')');
    // Exit function type variable scope.
    _boundVariables?.length -= type.typeVariables.length;
  }

  @override
  void visitInterfaceType(covariant InterfaceType type, _) {
    _identifier(type.element.name);
    _optionalTypeArguments(type.typeArguments);
  }

  void _optionalTypeArguments(List<DartType> types) {
    if (types.isNotEmpty) {
      _token('<');
      bool needsComma = false;
      for (DartType typeArgument in types) {
        needsComma = _comma(needsComma);
        _visit(typeArgument);
      }
      _token('>');
    }
  }

  @override
  void visitFutureOrType(covariant FutureOrType type, _) {
    _identifier('FutureOr');
    _token('<');
    _visit(type.typeArgument);
    _token('>');
  }
}

/// Basic interface for the Dart type system.
abstract class DartTypes {
  /// The types defined in 'dart:core'.
  CommonElements get commonElements;

  bool get useNullSafety;
  bool get useLegacySubtyping;

  DartType bottomType() =>
      useLegacySubtyping ? commonElements.nullType : neverType();

  DartType legacyType(DartType baseType) {
    DartType result;
    if (isTopType(baseType) ||
        baseType.isNull ||
        baseType is LegacyType ||
        baseType is NullableType) {
      result = baseType;
    } else {
      result = LegacyType._(baseType);
    }
    return result;
  }

  DartType nullableType(DartType baseType) {
    bool _isNullable(DartType t) =>
        // Note that we can assume NNBD is enabled here.
        t.isNull ||
        t is NullableType ||
        t is LegacyType && _isNullable(t.baseType) ||
        t is FutureOrType && _isNullable(t.typeArgument) ||
        _isStrongTopType(t);

    DartType result;
    if (_isStrongTopType(baseType) ||
        baseType.isNull ||
        baseType is NullableType ||
        baseType is FutureOrType && _isNullable(baseType.typeArgument)) {
      result = baseType;
    } else if (baseType is NeverType) {
      result = commonElements.nullType;
    } else if (baseType is LegacyType) {
      DartType legacyBaseType = baseType.baseType;
      if (legacyBaseType is NeverType) {
        result = commonElements.nullType;
      } else if (legacyBaseType is FutureOrType &&
          _isNullable(legacyBaseType.typeArgument)) {
        result = legacyBaseType.typeArgument;
      } else {
        result = nullableType(legacyBaseType);
      }
    } else {
      result = NullableType._(baseType);
    }
    return result;
  }

  DartType interfaceType(ClassEntity element, List<DartType> typeArguments) =>
      InterfaceType._(element, typeArguments);

  // Since all [TypeVariableType] bounds come from the CFE, we assume that no
  // bound will ever be `Never` (or else the CFE would have already normalized
  // the type variable to `Never`). Therefore, we can skip normalization.
  TypeVariableType typeVariableType(TypeVariableEntity element) =>
      TypeVariableType._(element);

  // We normalize when we substitute function types.
  DartType functionTypeVariable(int index) => FunctionTypeVariable._(index);

  DartType neverType() => const NeverType._();

  VoidType voidType() => const VoidType._();

  DynamicType dynamicType() => const DynamicType._();

  ErasedType erasedType() => const ErasedType._();

  AnyType anyType() => const AnyType._();

  FunctionType functionType(
          DartType returnType,
          List<DartType> parameterTypes,
          List<DartType> optionalParameterTypes,
          List<String> namedParameters,
          List<DartType> namedParameterTypes,
          List<FunctionTypeVariable> typeVariables) =>
      FunctionType._(returnType, parameterTypes, optionalParameterTypes,
          namedParameters, namedParameterTypes, typeVariables);

  DartType futureOrType(DartType typeArgument) {
    DartType result;
    if (isTopType(typeArgument) || typeArgument.isObject) {
      result = typeArgument;
    } else if (typeArgument is NeverType) {
      result = commonElements.futureType(typeArgument);
    } else if (typeArgument.isNull) {
      DartType futureOfNull =
          commonElements.futureType(commonElements.nullType);
      result = useNullSafety ? nullableType(futureOfNull) : futureOfNull;
    } else {
      result = FutureOrType._(typeArgument);
    }
    return result;
  }

  /// Performs the substitution `[arguments[i]/parameters[i]]t`.
  ///
  /// The notation is known from this lambda calculus rule:
  ///
  ///     (lambda x.e0)e1 -> [e1/x]e0.
  ///
  /// See [TypeVariableType] for a motivation for this method.
  ///
  /// Invariant: There must be the same number of [arguments] and [parameters].
  DartType subst(
      List<DartType> arguments, List<DartType> parameters, DartType t) {
    assert(arguments.length == parameters.length);
    if (parameters.isEmpty) return t;
    return SimpleDartTypeSubstitutionVisitor(this, arguments, parameters)
        .substitute(t);
  }

  DartType instantiate(FunctionType t, List<DartType> arguments) {
    return subst(arguments, t.typeVariables, t);
  }

  /// Returns `true` if every type argument of [t] is a top type.
  // TODO(fishythefish): Should we instead check if each type argument is at its
  // bound?
  bool treatAsRawType(DartType t) => t._treatAsRaw(useNullSafety);

  /// Returns `true` if [t] is a top type, that is, a supertype of every type.
  bool isTopType(DartType t) => t._isTop(useNullSafety);

  bool _isStrongTopType(DartType t) => t._isStrongTop(useNullSafety);

  /// Returns `true` if [s] is a subtype of [t].
  bool isSubtype(DartType s, DartType t) => _subtypeHelper(s, t);

  /// Returns `true` if [s] is assignable to [t].
  bool isAssignable(DartType s, DartType t) =>
      isSubtype(s, t) || isSubtype(t, s);

  /// Returns `true` if [s] might be a subtype of [t] for some values of
  /// type variables in [s] and [t].
  ///
  /// If [assumeInstantiations], generic function types are assumed to be
  /// potentially instantiated.
  bool isPotentialSubtype(DartType s, DartType t,
          {bool assumeInstantiations: true}) =>
      _subtypeHelper(s, t,
          allowPotentialSubtypes: true,
          assumeInstantiations: assumeInstantiations);

  bool _subtypeHelper(DartType s, DartType t,
      {bool allowPotentialSubtypes: false, bool assumeInstantiations: false}) {
    /// Based on
    /// https://github.com/dart-lang/language/blob/master/resources/type-system/subtyping.md.
    /// See also [_isSubtype] in `dart:_rti`.
    bool _isSubtype(DartType s, DartType t, _Assumptions env) {
      // Reflexivity:
      if (s == t) return true;
      if (env != null &&
          s is FunctionTypeVariable &&
          t is FunctionTypeVariable &&
          env.isAssumed(s, t)) return true;

      if (s is AnyType) return true;
      if (allowPotentialSubtypes &&
          (s is TypeVariableType || t is TypeVariableType)) return true;
      if (assumeInstantiations &&
          (s is FunctionTypeVariable || t is FunctionTypeVariable)) return true;

      // Right Top:
      if (isTopType(t)) return true;

      // Left Top:
      if (_isStrongTopType(s)) return false;

      // Left Bottom:
      if (useLegacySubtyping) {
        if (s.isNull) return true;
      } else {
        if (s is NeverType) return true;
      }

      // Left Type Variable Bound 1:
      if (s is TypeVariableType) {
        if (_isSubtype(getTypeVariableBound(s.element), t, env)) return true;
      }
      if (s is FunctionTypeVariable) {
        if (_isSubtype(s._bound, t, env)) return true;
      }

      // Left Null:
      // Note: Interchanging the Left Null and Right Object rules allows us to
      // reduce casework.
      if (!useLegacySubtyping && s.isNull) {
        if (t is FutureOrType) {
          return _isSubtype(s, t.typeArgument, env);
        }
        return t.isNull || t is LegacyType || t is NullableType;
      }

      // Right Object:
      if (!useLegacySubtyping && t.isObject) {
        if (s is FutureOrType) {
          return _isSubtype(s.typeArgument, t, env);
        }
        if (s is LegacyType) {
          return _isSubtype(s.baseType, t, env);
        }
        return s is! NullableType;
      }

      // Left Legacy:
      if (s is LegacyType) {
        return _isSubtype(s.baseType, t, env);
      }

      // Right Legacy:
      if (t is LegacyType) {
        // Note that to convert `T*` to `T?`, we can't just say `t._toNullable`.
        // The resulting type `T?` may be normalizable (e.g. if `T` is `Never`).
        return _isSubtype(
            s, useLegacySubtyping ? t.baseType : nullableType(t), env);
      }

      // Left FutureOr:
      if (s is FutureOrType) {
        DartType typeArgument = s.typeArgument;
        return _isSubtype(typeArgument, t, env) &&
            _isSubtype(commonElements.futureType(typeArgument), t, env);
      }

      // Left Nullable:
      if (s is NullableType) {
        return (useLegacySubtyping ||
                _isSubtype(commonElements.nullType, t, env)) &&
            _isSubtype(s.baseType, t, env);
      }

      // Type Variable Reflexivity 1 is subsumed by Reflexivity and therefore
      // elided.
      // Type Variable Reflexivity 2 does not apply because we do not represent
      // promoted type variables.
      // Right Promoted Variable does not apply because we do not represent
      // promoted type variables.

      // Right FutureOr:
      if (t is FutureOrType) {
        DartType typeArgument = t.typeArgument;
        return _isSubtype(s, typeArgument, env) ||
            _isSubtype(s, commonElements.futureType(typeArgument), env);
      }

      // Right Nullable:
      if (t is NullableType) {
        return (!useLegacySubtyping &&
                _isSubtype(s, commonElements.nullType, env)) ||
            _isSubtype(s, t.baseType, env);
      }

      // Left Promoted Variable does not apply because we do not represent
      // promoted type variables.

      // Left Type Variable Bound 2:
      if (s is TypeVariableType) return false;
      if (s is FunctionTypeVariable) return false;

      // Function Type/Function:
      if (s is FunctionType && t == commonElements.functionType) {
        return true;
      }

      // Positional Function Types + Named Function Types:
      // TODO(fishythefish): Disallow JavaScriptFunction as a subtype of
      // function types using features inaccessible from JavaScript.
      if (t is FunctionType) {
        if (s == commonElements.jsJavaScriptFunctionType) return true;
        if (s is FunctionType) {
          List<FunctionTypeVariable> sTypeVariables = s.typeVariables;
          List<FunctionTypeVariable> tTypeVariables = t.typeVariables;
          int length = tTypeVariables.length;
          if (length == sTypeVariables.length) {
            env ??= _Assumptions();
            env.assumePairs(sTypeVariables, tTypeVariables);
          } else if (!assumeInstantiations || length > 0) return false;
          try {
            for (int i = 0; i < length; i++) {
              DartType sBound = sTypeVariables[i].bound;
              DartType tBound = tTypeVariables[i].bound;
              if (!_isSubtype(sBound, tBound, env) ||
                  !_isSubtype(tBound, sBound, env)) {
                return false;
              }
            }

            if (!_isSubtype(s.returnType, t.returnType, env)) return false;

            // TODO(fishythefish): Support required named parameters.

            List<DartType> sRequiredPositional = s.parameterTypes;
            List<DartType> tRequiredPositional = t.parameterTypes;
            int sRequiredPositionalLength = sRequiredPositional.length;
            int tRequiredPositionalLength = tRequiredPositional.length;
            if (sRequiredPositionalLength > tRequiredPositionalLength) {
              return false;
            }
            int requiredPositionalDelta =
                tRequiredPositionalLength - sRequiredPositionalLength;

            List<DartType> sOptionalPositional = s.optionalParameterTypes;
            List<DartType> tOptionalPositional = t.optionalParameterTypes;
            int sOptionalPositionalLength = sOptionalPositional.length;
            int tOptionalPositionalLength = tOptionalPositional.length;
            if (sRequiredPositionalLength + sOptionalPositionalLength <
                tRequiredPositionalLength + tOptionalPositionalLength) {
              return false;
            }

            for (int i = 0; i < sRequiredPositionalLength; i++) {
              if (!_isSubtype(
                  tRequiredPositional[i], sRequiredPositional[i], env)) {
                return false;
              }
            }

            for (int i = 0; i < requiredPositionalDelta; i++) {
              if (!_isSubtype(
                  tRequiredPositional[sRequiredPositionalLength + i],
                  sOptionalPositional[i],
                  env)) {
                return false;
              }
            }

            for (int i = 0; i < tOptionalPositionalLength; i++) {
              if (!_isSubtype(tOptionalPositional[i],
                  sOptionalPositional[requiredPositionalDelta + i], env)) {
                return false;
              }
            }

            List<String> sOptionalNamed = s.namedParameters;
            List<String> tOptionalNamed = t.namedParameters;
            List<DartType> sOptionalNamedTypes = s.namedParameterTypes;
            List<DartType> tOptionalNamedTypes = t.namedParameterTypes;
            int sOptionalNamedLength = sOptionalNamed.length;
            int tOptionalNamedLength = tOptionalNamed.length;
            for (int i = 0, j = 0; j < tOptionalNamedLength; j++) {
              String sName;
              String tName = tOptionalNamed[j];
              int comparison;
              do {
                if (i >= sOptionalNamedLength) return false;
                sName = sOptionalNamed[i++];
                comparison = sName.compareTo(tName);
              } while (comparison < 0);
              if (comparison > 0) return false;
              if (!_isSubtype(
                  tOptionalNamedTypes[j], sOptionalNamedTypes[i - 1], env))
                return false;
            }
            return true;
          } finally {
            if (length > 0) env.forgetPairs(sTypeVariables, tTypeVariables);
          }
        }
        return false;
      }

      // Interface Compositionality + Super-Interface:
      if (s is InterfaceType) {
        if (t is InterfaceType) {
          InterfaceType instance =
              s.element == t.element ? s : asInstanceOf(s, t.element);
          if (instance == null) return false;
          List<DartType> sArgs = instance.typeArguments;
          List<DartType> tArgs = t.typeArguments;
          List<Variance> variances = getTypeVariableVariances(t.element);
          assert(sArgs.length == tArgs.length);
          assert(tArgs.length == variances.length);
          for (int i = 0; i < variances.length; i++) {
            switch (variances[i]) {
              case Variance.legacyCovariant:
              case Variance.covariant:
                if (!_isSubtype(sArgs[i], tArgs[i], env)) return false;
                break;
              case Variance.contravariant:
                if (!_isSubtype(tArgs[i], sArgs[i], env)) return false;
                break;
              case Variance.invariant:
                if (!_isSubtype(sArgs[i], tArgs[i], env) ||
                    !_isSubtype(tArgs[i], sArgs[i], env)) return false;
                break;
              default:
                throw StateError(
                    "Invalid variance ${variances[i]} used for subtype check.");
            }
          }
          return true;
        }
        return false;
      }

      return false;
    }

    return _isSubtype(s, t, null);
  }

  /// Returns [type] as an instance of [cls] or `null` if [type] is not a
  /// subtype of [cls].
  ///
  /// For example: `asInstanceOf(List<String>, Iterable) = Iterable<String>`.
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls);

  /// Return [base] where the type variable of `context.element` are replaced
  /// by the type arguments of [context].
  ///
  /// For instance
  ///
  ///     substByContext(Iterable<List.E>, List<String>) = Iterable<String>
  ///
  DartType substByContext(DartType base, InterfaceType context);

  /// Returns the 'this type' of [cls]. That is, the instantiation of [cls]
  /// where the type arguments are the type variables of [cls].
  InterfaceType getThisType(ClassEntity cls);

  /// Returns the supertype of [cls], i.e. the type in the `extends` clause of
  /// [cls].
  InterfaceType getSupertype(ClassEntity cls);

  /// Returns all supertypes of [cls].
  // TODO(johnniwinther): This should include `Function` if [cls] declares
  // a `call` method.
  Iterable<InterfaceType> getSupertypes(ClassEntity cls);

  /// Returns all types directly implemented by [cls].
  Iterable<InterfaceType> getInterfaces(ClassEntity cls);

  /// Returns the type of the `call` method on [type], or `null` if the class
  /// of [type] does not have a `call` method.
  FunctionType getCallType(InterfaceType type);

  /// Checks the type arguments of [type] against the type variable bounds
  /// declared on `type.element`. Calls [checkTypeVariableBound] on each type
  /// argument and bound.
  void checkTypeVariableBounds<T>(
      T context,
      List<DartType> typeArguments,
      List<DartType> typeVariables,
      void checkTypeVariableBound(T context, DartType typeArgument,
          TypeVariableType typeVariable, DartType bound));

  /// Returns the [ClassEntity] which declares the type variables occurring in
  // [type], or `null` if [type] does not contain class type variables.
  static ClassEntity getClassContext(DartType type) {
    ClassEntity contextClass;
    type.forEachTypeVariable((TypeVariableType typeVariable) {
      if (typeVariable.element.typeDeclaration is! ClassEntity) return;
      contextClass = typeVariable.element.typeDeclaration;
    });
    // GENERIC_METHODS: When generic method support is complete enough to
    // include a runtime value for method type variables this must be updated.
    // For full support the global assumption that all type variables are
    // declared by the same enclosing class will not hold: Both an enclosing
    // method and an enclosing class may define type variables, so the return
    // type cannot be [ClassElement] and the caller must be prepared to look in
    // two locations, not one. Currently we ignore method type variables by
    // returning in the next statement.
    return contextClass;
  }

  DartType getTypeVariableBound(TypeVariableEntity element);

  List<Variance> getTypeVariableVariances(ClassEntity cls);
}
