// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file implements a "mini type system" that's similar to full Dart types,
// but light weight enough to be suitable for unit testing of code in the
// `_fe_analyzer_shared` package.

import 'dart:core' as core show Type;
import 'dart:core' hide Type;

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:collection/collection.dart';

/// Surrounds [s] with parentheses if [condition] is `true`, otherwise returns
/// [s] unchanged.
String _parenthesizeIf(bool condition, String s) => condition ? '($s)' : s;

/// Representation of the type `dynamic` suitable for unit testing of code in
/// the `_fe_analyzer_shared` package.
class DynamicType extends _SpecialSimpleType implements SharedDynamicType {
  static final instance = DynamicType._();

  DynamicType._() : super._(TypeRegistry.dynamic_);

  @override
  bool get isQuestionType => false;

  @override
  Type asQuestionType(bool isQuestionType) => this;
}

/// Factory for creating fresh type parameters.
///
/// Generated type parameters will have names of the form `Tn`, where `n` is a
/// small non-negative integer.
class FreshTypeParameterGenerator {
  final _namesToExclude = <String>{};
  int _counter = 0;

  /// Ensures that when [generate] is called, the type parameter it returns will
  /// have a name that's distinct from all identifiers in [type].
  void excludeNamesUsedIn(Type type) {
    type.gatherUsedIdentifiers(_namesToExclude);
  }

  /// Generates a fresh type parameter.
  TypeParameter generate() {
    while (true) {
      var name = 'T${_counter++}';
      if (_namesToExclude.add(name)) {
        return TypeParameter._(name);
      }
    }
  }
}

/// Representation of a function type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class FunctionType extends Type implements SharedFunctionType {
  final Type returnType;

  @override
  List<TypeParameter> typeParametersShared;

  /// A list of the types of positional parameters.
  final List<Type> positionalParameters;

  @override
  final int requiredPositionalParameterCount;

  /// A list of the named parameters, sorted by name.
  final List<NamedFunctionParameter> namedParameters;

  FunctionType(
    this.returnType,
    this.positionalParameters, {
    this.typeParametersShared = const [],
    int? requiredPositionalParameterCount,
    this.namedParameters = const [],
    super.isQuestionType = false,
  }) : requiredPositionalParameterCount =
           requiredPositionalParameterCount ?? positionalParameters.length,
       super._() {
    for (var i = 1; i < namedParameters.length; i++) {
      assert(
        namedParameters[i - 1].name.compareTo(namedParameters[i].name) < 0,
        'namedParameters not properly sorted',
      );
    }
  }

  @override
  int get hashCode {
    if (typeParametersShared.isNotEmpty) {
      // Generic function types need to have the same hash if they are the same
      // after renaming of type formals. To ensure this, we rename the type
      // formals to a consistent sent of names and then hash the result.
      //
      // Note that it's essential *not* to call
      // `FreshTypeParameterGenerator.excludeNamesUsedIn` here, to ensure that
      // a consistent set of type parameter names is generated regardless of the
      // the names used in the function type. To see why, consider the types
      // `U Function<U>()` and `T0 Function<T0>()` (which are equivalent and
      // therefore should have the same `hashCode`).
      //
      // If `FreshTypeParameterGenerator.excludeNamesUsedIn` were used here,
      // then the substitution generated for `U Function<U>()` would be
      // `U -> T0`, so its hashCode would be based on hashing the type
      // `T0 Function()`, whereas the substitution generated for
      // `T0 Function<T0>()` would be `T0 -> T1`, so its hashCode would be based
      // on hashing the type `T1 Function()` (and therefore it would likely be
      // different).
      //
      // A consequence of not calling
      // `FreshTypeParameterGenerator.excludeNamesUsedIn` here is that the
      // result of the substitution might appear to conflate two type parameters
      // that ought to be distinguished. For example, if `this` is
      // `X Function<X>(T0)` (where `T0` is a type parameter defined somewhere
      // else), then the substitution `X -> T0` will be generated, so the result
      // of the substitution will be `T0 Function(T0)`, which appears to
      // conflate the two `T0`s. But this is not a problem for two reasons:
      //
      // - In point of fact, the two `T0`s are still distinguishable; the one
      //   appearing in the substituted type's return type points to the type
      //   parameter that was freshly generated, whereas the one appearing in
      //   the substituted type's parameter list points to the same type
      //   parameter as the `T0` appearing in the parameter list of `this`.
      //
      // - It doesn't actually matter, because the purpose of this method is to
      //   compute a hash code, and it's ok in rare circumstances for hash codes
      //   to be equal even if the underlying objects are not equal.
      var freshTypeParameterGenerator = FreshTypeParameterGenerator();
      var substitution = {
        for (var typeFormal in typeParametersShared)
          typeFormal: TypeParameterType(freshTypeParameterGenerator.generate()),
      };
      return substitute(substitution, dropTypeFormals: true).hashCode;
    } else {
      return Object.hash(
        returnType,
        const ListEquality().hash(positionalParameters),
        requiredPositionalParameterCount,
        const ListEquality().hash(namedParameters),
        isQuestionType,
      );
    }
  }

  List<Type> get positionalParameterTypes => positionalParameters;

  @override
  List<Type> get positionalParameterTypesShared => positionalParameterTypes;

  @override
  Type get returnTypeShared => returnType;

  @override
  List<NamedFunctionParameter> get sortedNamedParametersShared =>
      namedParameters;

  @override
  bool operator ==(Object other) {
    if (other is! FunctionType) return false;
    if (typeParametersShared.length != other.typeParametersShared.length) {
      return false;
    }
    if (typeParametersShared.isNotEmpty) {
      // Check if types are equal under a consistent renaming of type formals
      var freshTypeParameterGenerator = FreshTypeParameterGenerator()
        ..excludeNamesUsedIn(this)
        ..excludeNamesUsedIn(other);
      var thisSubstitution = <TypeParameter, Type>{};
      var otherSubstitution = <TypeParameter, Type>{};
      var thisTypeFormalBounds = <Type>[];
      var otherTypeFormalBounds = <Type>[];
      for (var i = 0; i < typeParametersShared.length; i++) {
        var freshTypeParameterType = TypeParameterType(
          freshTypeParameterGenerator.generate(),
        );
        thisSubstitution[typeParametersShared[i]] = freshTypeParameterType;
        otherSubstitution[other.typeParametersShared[i]] =
            freshTypeParameterType;
        thisTypeFormalBounds.add(typeParametersShared[i].bound);
        otherTypeFormalBounds.add(other.typeParametersShared[i].bound);
      }
      return const ListEquality().equals(
            thisTypeFormalBounds.substitute(thisSubstitution) ??
                thisTypeFormalBounds,
            otherTypeFormalBounds.substitute(otherSubstitution) ??
                otherTypeFormalBounds,
          ) &&
          substitute(thisSubstitution, dropTypeFormals: true) ==
              other.substitute(otherSubstitution, dropTypeFormals: true);
    } else {
      return returnType == other.returnType &&
          const ListEquality().equals(
            positionalParameters,
            other.positionalParameters,
          ) &&
          requiredPositionalParameterCount ==
              other.requiredPositionalParameterCount &&
          const ListEquality().equals(namedParameters, other.namedParameters) &&
          isQuestionType == other.isQuestionType;
    }
  }

  @override
  Type asQuestionType(bool isQuestionType) => FunctionType(
    returnType,
    positionalParameters,
    typeParametersShared: typeParametersShared,
    requiredPositionalParameterCount: requiredPositionalParameterCount,
    namedParameters: namedParameters,
    isQuestionType: isQuestionType,
  );

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    Type? newReturnType = returnType.closureWithRespectToUnknown(
      covariant: covariant,
    );
    List<Type>? newPositionalParameters = positionalParameters
        .closureWithRespectToUnknown(covariant: !covariant);
    List<NamedFunctionParameter>? newNamedParameters = namedParameters
        .closureWithRespectToUnknown(covariant: !covariant);
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null) {
      return null;
    }
    return FunctionType(
      newReturnType ?? returnType,
      newPositionalParameters ?? positionalParameters,
      typeParametersShared: typeParametersShared,
      requiredPositionalParameterCount: requiredPositionalParameterCount,
      namedParameters: newNamedParameters ?? namedParameters,
      isQuestionType: isQuestionType,
    );
  }

  @override
  void gatherUsedIdentifiers(Set<String> identifiers) {
    returnType.gatherUsedIdentifiers(identifiers);
    for (var positionalParameter in positionalParameters) {
      positionalParameter.gatherUsedIdentifiers(identifiers);
    }
    for (var typeFormal in typeParametersShared) {
      identifiers.add(typeFormal.name);
      typeFormal.explicitBound?.gatherUsedIdentifiers(identifiers);
    }
    for (var namedParameter in namedParameters) {
      // As explained in the documentation for `Type.gatherUsedIdentifiers`,
      // to reduce the risk of confusion, this method is generous in which
      // identifiers it reports. So report `namedParameter.name` even though
      // it's not strictly necessary.
      identifiers.add(namedParameter.name);
      namedParameter.type.gatherUsedIdentifiers(identifiers);
    }
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newReturnType = returnType.recursivelyDemote(covariant: covariant);
    List<Type>? newPositionalParameters = positionalParameters
        .recursivelyDemote(covariant: !covariant);
    List<NamedFunctionParameter>? newNamedParameters = namedParameters
        .recursivelyDemote(covariant: !covariant);
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null) {
      return null;
    }
    return FunctionType(
      newReturnType ?? returnType,
      newPositionalParameters ?? positionalParameters,
      typeParametersShared: typeParametersShared,
      requiredPositionalParameterCount: requiredPositionalParameterCount,
      namedParameters: newNamedParameters ?? namedParameters,
      isQuestionType: isQuestionType,
    );
  }

  @override
  FunctionType? substitute(
    Map<TypeParameter, Type> substitution, {
    bool dropTypeFormals = false,
  }) {
    List<TypeParameter>? newTypeFormals;
    if (typeParametersShared.isNotEmpty) {
      if (dropTypeFormals) {
        newTypeFormals = const <TypeParameter>[];
      } else {
        // Check if any of the type formal bounds will be changed by the
        // substitution.
        if (typeParametersShared.any(
          (typeFormal) =>
              typeFormal.explicitBound?.substitute(substitution) != null,
        )) {
          // Yes, at least one of the type formal bounds will be changed by the
          // substitution. So that type formal will have to be replaced by a
          // fresh one. Since type formal bounds can refer to other type
          // formals, other type formals might need to be replaced by fresh ones
          // too. To make things easier, go ahead and replace all the type
          // formals. Also, extend the substitution so that any references to
          // old type formals will be replaced by references to the new type
          // formals.
          substitution = {...substitution};
          newTypeFormals = [];
          for (var typeFormal in typeParametersShared) {
            var newTypeFormal = TypeParameter._(typeFormal.name);
            newTypeFormals.add(newTypeFormal);
            substitution[typeFormal] = TypeParameterType(newTypeFormal);
          }
          // Now that the substitution has been created, fix up all the bounds.
          for (var i = 0; i < typeParametersShared.length; i++) {
            if (typeParametersShared[i].explicitBound case var bound?) {
              newTypeFormals[i].explicitBound =
                  bound.substitute(substitution) ?? bound;
            }
          }
        }
      }
    }

    var newReturnType = returnType.substitute(substitution);
    var newPositionalParameters = positionalParameters.substitute(substitution);
    var newNamedParameters = namedParameters.substitute(substitution);
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newTypeFormals == null &&
        newNamedParameters == null) {
      return null;
    } else {
      return FunctionType(
        newReturnType ?? returnType,
        newPositionalParameters ?? positionalParameters,
        typeParametersShared: newTypeFormals ?? typeParametersShared,
        requiredPositionalParameterCount: requiredPositionalParameterCount,
        namedParameters: newNamedParameters ?? namedParameters,
        isQuestionType: isQuestionType,
      );
    }
  }

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) {
    var formals = '';
    if (typeParametersShared.isNotEmpty) {
      var formalStrings = <String>[];
      for (var typeFormal in typeParametersShared) {
        if (typeFormal.explicitBound case var bound?) {
          formalStrings.add('${typeFormal.name} extends $bound');
        } else {
          formalStrings.add(typeFormal.name);
        }
      }
      formals = '<${formalStrings.join(', ')}>';
    }
    var parameters = <Object>[
      ...positionalParameters.sublist(0, requiredPositionalParameterCount),
    ];
    if (requiredPositionalParameterCount < positionalParameters.length) {
      var optionalPositionalParameters = positionalParameters.sublist(
        requiredPositionalParameterCount,
      );
      parameters.add('[${optionalPositionalParameters.join(', ')}]');
    }
    if (namedParameters.isNotEmpty) {
      parameters.add('{${namedParameters.join(', ')}}');
    }
    return _parenthesizeIf(
      parenthesizeIfComplex,
      '$returnType Function$formals(${parameters.join(', ')})',
    );
  }
}

/// Representation of the type `FutureOr<T>` suitable for unit testing of code
/// in the `_fe_analyzer_shared` package.
class FutureOrType extends PrimaryType {
  FutureOrType(Type typeArgument, {super.isQuestionType = false})
    : super._special(TypeRegistry.futureOr, args: [typeArgument]);

  Type get typeArgument => args.single;

  @override
  Type asQuestionType(bool isQuestionType) =>
      FutureOrType(typeArgument, isQuestionType: isQuestionType);

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    Type? newArg = typeArgument.closureWithRespectToUnknown(
      covariant: covariant,
    );
    if (newArg == null) return null;
    return FutureOrType(newArg, isQuestionType: isQuestionType);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newArg = typeArgument.recursivelyDemote(covariant: covariant);
    if (newArg == null) return null;
    return FutureOrType(newArg, isQuestionType: isQuestionType);
  }

  @override
  Type? substitute(Map<TypeParameter, Type> substitution) {
    var newArg = typeArgument.substitute(substitution);
    if (newArg == null) return null;
    return FutureOrType(newArg, isQuestionType: isQuestionType);
  }
}

/// A type name that represents an ordinary interface type.
class InterfaceTypeName extends TypeNameInfo {
  InterfaceTypeName._(super.name) : super(expectedRuntimeType: PrimaryType);
}

/// Representation of an invalid type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class InvalidType extends _SpecialSimpleType implements SharedInvalidType {
  static final instance = InvalidType._();

  InvalidType._() : super._(TypeRegistry.error_);

  @override
  Type asQuestionType(bool isQuestionType) => this;
}

/// A named parameter of a function type.
class NamedFunctionParameter
    implements
        SharedNamedFunctionParameter,
        _Substitutable<NamedFunctionParameter> {
  final String name;

  final Type type;

  @override
  final bool isRequired;

  NamedFunctionParameter({
    required this.isRequired,
    required this.name,
    required this.type,
  });

  @override
  int get hashCode => Object.hash(name, type, isRequired);

  @override
  String get nameShared => name;

  @override
  Type get typeShared => type;

  @override
  bool operator ==(Object other) =>
      other is NamedFunctionParameter &&
      name == other.name &&
      type == other.type &&
      isRequired == other.isRequired;

  @override
  NamedFunctionParameter? substitute(Map<TypeParameter, Type> substitution) {
    var newType = type.substitute(substitution);
    if (newType == null) return null;
    return NamedFunctionParameter(
      isRequired: isRequired,
      name: name,
      type: newType,
    );
  }

  @override
  String toString() => [if (isRequired) 'required', type, name].join(' ');
}

class NamedType implements SharedNamedType, _Substitutable<NamedType> {
  final String name;

  final Type type;

  NamedType({required this.name, required this.type});

  @override
  int get hashCode => Object.hash(name, type);

  @override
  String get nameShared => name;

  @override
  Type get typeShared => type;

  @override
  bool operator ==(Object other) =>
      other is NamedType && name == other.name && type == other.type;

  @override
  NamedType? substitute(Map<TypeParameter, Type> substitution) {
    var newType = type.substitute(substitution);
    if (newType == null) return null;
    return NamedType(name: name, type: newType);
  }
}

/// Representation of the type `Never` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class NeverType extends _SpecialSimpleType {
  static final instance = NeverType._();

  NeverType._({super.isQuestionType = false}) : super._(TypeRegistry.never);

  @override
  Type asQuestionType(bool isQuestionType) =>
      NeverType._(isQuestionType: isQuestionType);
}

/// Representation of the type `Null` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class NullType extends _SpecialSimpleType implements SharedNullType {
  static final instance = NullType._();

  NullType._() : super._(TypeRegistry.null_, isQuestionType: false);

  @override
  Type asQuestionType(bool isQuestionType) => this;
}

/// Exception thrown if a type fails to parse properly.
class ParseError extends Error {
  final String message;

  ParseError(this.message);

  @override
  String toString() => message;
}

/// Representation of a primary type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.  A primary type is either an interface type
/// with zero or more type parameters (e.g. `double`, or `Map<int, String>`) or
/// one of the special types whose name is a single word (e.g. `dynamic`).
class PrimaryType extends Type {
  /// Information about the type name.
  final TypeNameInfo nameInfo;

  /// The type arguments, or `const []` if there are no type arguments.
  final List<Type> args;

  PrimaryType(
    InterfaceTypeName nameInfo, {
    List<Type> args = const [],
    bool isQuestionType = false,
  }) : this._(nameInfo, args: args, isQuestionType: isQuestionType);

  PrimaryType._(
    this.nameInfo, {
    this.args = const [],
    super.isQuestionType = false,
  }) : super._() {
    assert(
      runtimeType == nameInfo._expectedRuntimeType,
      '${nameInfo.name} should use ${nameInfo._expectedRuntimeType}, but '
      'constructed $runtimeType instead',
    );
  }

  PrimaryType._special(
    SpecialTypeName nameInfo, {
    List<Type> args = const [],
    bool isQuestionType = false,
  }) : this._(nameInfo, args: args, isQuestionType: isQuestionType);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    nameInfo,
    const ListEquality().hash(args),
    isQuestionType,
  );

  bool get isInterfaceType {
    return nameInfo is InterfaceTypeName;
  }

  /// The name of the type.
  String get name => nameInfo.name;

  @override
  bool operator ==(Object other) =>
      other is PrimaryType &&
      nameInfo == other.nameInfo &&
      const ListEquality().equals(args, other.args) &&
      isQuestionType == other.isQuestionType;

  @override
  Type asQuestionType(bool isQuestionType) =>
      PrimaryType._(nameInfo, args: args, isQuestionType: isQuestionType);

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newArgs = args.closureWithRespectToUnknown(
      covariant: covariant,
    );
    if (newArgs == null) return null;
    return PrimaryType._(
      nameInfo,
      args: newArgs,
      isQuestionType: isQuestionType,
    );
  }

  @override
  void gatherUsedIdentifiers(Set<String> identifiers) {
    identifiers.add(name);
    for (var arg in args) {
      arg.gatherUsedIdentifiers(identifiers);
    }
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newArgs = args.recursivelyDemote(covariant: covariant);
    if (newArgs == null) return null;
    return PrimaryType._(
      nameInfo,
      args: newArgs,
      isQuestionType: isQuestionType,
    );
  }

  @override
  Type? substitute(Map<TypeParameter, Type> substitution) {
    var newArgs = args.substitute(substitution);
    if (newArgs == null) return null;
    return PrimaryType._(
      nameInfo,
      args: newArgs,
      isQuestionType: isQuestionType,
    );
  }

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) =>
      args.isEmpty ? name : '$name<${args.join(', ')}>';
}

class RecordType extends Type implements SharedRecordType {
  final List<Type> positionalTypes;

  final List<NamedType> namedTypes;

  RecordType({
    required this.positionalTypes,
    required this.namedTypes,
    super.isQuestionType = false,
  }) : super._() {
    for (var i = 1; i < namedTypes.length; i++) {
      assert(
        namedTypes[i - 1].name.compareTo(namedTypes[i].name) < 0,
        'namedTypes not properly sorted',
      );
    }
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const ListEquality().hash(positionalTypes),
    const ListEquality().hash(namedTypes),
    isQuestionType,
  );

  @override
  List<Type> get positionalTypesShared => positionalTypes;

  List<NamedType> get sortedNamedTypes => namedTypes;

  @override
  List<SharedNamedType> get sortedNamedTypesShared => sortedNamedTypes;

  @override
  bool operator ==(Object other) =>
      other is RecordType &&
      const ListEquality().equals(positionalTypes, other.positionalTypes) &&
      const ListEquality().equals(namedTypes, other.namedTypes) &&
      isQuestionType == other.isQuestionType;

  @override
  Type asQuestionType(bool isQuestionType) => RecordType(
    positionalTypes: positionalTypes,
    namedTypes: namedTypes,
    isQuestionType: isQuestionType,
  );

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newPositional;
    for (var i = 0; i < positionalTypes.length; i++) {
      var newType = positionalTypes[i].closureWithRespectToUnknown(
        covariant: covariant,
      );
      if (newType != null) {
        newPositional ??= positionalTypes.toList();
        newPositional[i] = newType;
      }
    }

    List<NamedType>? newNamed = _closureWithRespectToUnknownNamed(
      covariant: covariant,
    );

    if (newPositional == null && newNamed == null) {
      return null;
    }
    return RecordType(
      positionalTypes: newPositional ?? positionalTypes,
      namedTypes: newNamed ?? namedTypes,
      isQuestionType: isQuestionType,
    );
  }

  @override
  void gatherUsedIdentifiers(Set<String> identifiers) {
    for (var type in positionalTypes) {
      type.gatherUsedIdentifiers(identifiers);
    }
    for (var namedType in namedTypes) {
      // As explained in the documentation for `Type.gatherUsedIdentifiers`,
      // to reduce the risk of confusion, this method is generous in which
      // identifiers it reports. So report `namedType.name` even though it's
      // not strictly necessary.
      identifiers.add(namedType.name);
      namedType.type.gatherUsedIdentifiers(identifiers);
    }
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newPositional;
    for (var i = 0; i < positionalTypes.length; i++) {
      var newType = positionalTypes[i].recursivelyDemote(covariant: covariant);
      if (newType != null) {
        newPositional ??= positionalTypes.toList();
        newPositional[i] = newType;
      }
    }

    List<NamedType>? newNamed = _recursivelyDemoteNamed(covariant: covariant);

    if (newPositional == null && newNamed == null) {
      return null;
    }
    return RecordType(
      positionalTypes: newPositional ?? positionalTypes,
      namedTypes: newNamed ?? namedTypes,
      isQuestionType: isQuestionType,
    );
  }

  @override
  Type? substitute(Map<TypeParameter, Type> substitution) {
    var newPositionalTypes = positionalTypes.substitute(substitution);
    var newNamedTypes = namedTypes.substitute(substitution);
    if (newPositionalTypes == null && newNamedTypes == null) return null;
    return RecordType(
      positionalTypes: newPositionalTypes ?? positionalTypes,
      namedTypes: newNamedTypes ?? namedTypes,
      isQuestionType: isQuestionType,
    );
  }

  List<NamedType>? _closureWithRespectToUnknownNamed({
    required bool covariant,
  }) {
    List<NamedType>? newNamed;
    for (var i = 0; i < namedTypes.length; i++) {
      var namedType = namedTypes[i];
      var newType = namedType.type.closureWithRespectToUnknown(
        covariant: covariant,
      );
      if (newType != null) {
        (newNamed ??= namedTypes.toList())[i] = NamedType(
          name: namedType.name,
          type: newType,
        );
      }
    }
    return newNamed;
  }

  List<NamedType>? _recursivelyDemoteNamed({required bool covariant}) {
    List<NamedType>? newNamed;
    for (var i = 0; i < namedTypes.length; i++) {
      var namedType = namedTypes[i];
      var newType = namedType.type.recursivelyDemote(covariant: covariant);
      if (newType != null) {
        (newNamed ??= namedTypes.toList())[i] = NamedType(
          name: namedType.name,
          type: newType,
        );
      }
    }
    return newNamed;
  }

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) {
    var positionalStr = positionalTypes.join(', ');
    var namedStr = namedTypes.map((e) => '${e.type} ${e.name}').join(', ');
    if (namedStr.isNotEmpty) {
      return positionalTypes.isNotEmpty
          ? '($positionalStr, {$namedStr})'
          : '({$namedStr})';
    } else {
      return positionalTypes.length == 1
          ? '($positionalStr,)'
          : '($positionalStr)';
    }
  }
}

/// A type name that represents one of Dart's built-in "special" types, such as:
/// - `dynamic`
/// - `error` (to represent an invalid type)
/// - `FutureOr`
/// - `Never`
/// - `Null`
/// - `void`
class SpecialTypeName extends TypeNameInfo {
  SpecialTypeName._(super.name, {required super.expectedRuntimeType});
}

/// Representation of a type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
abstract class Type implements SharedType, _Substitutable<Type> {
  @override
  final bool isQuestionType;

  factory Type(String typeStr) => _TypeParser.parse(typeStr);

  const Type._({this.isQuestionType = false});

  String get type => toString();

  @override
  Type asQuestionType(bool isQuestionType);

  /// Finds the nearest type that doesn't involve the unknown type (`_`).
  ///
  /// If [covariant] is `true`, a supertype will be returned (replacing `_` with
  /// `Object?`); otherwise a subtype will be returned (replacing `_` with
  /// `Never`).
  Type? closureWithRespectToUnknown({required bool covariant});

  /// Recursively visits `this`, gathering up all the identifiers that appear in
  /// it, and adds them to the set [identifiers].
  ///
  /// This method is intended to aid in choosing safe names for substitutions.
  /// For example, it can be used to determine that in a type like
  /// `T Function<U>(U)`, it's not safe to rename the type variable `U` to `T`,
  /// since that would conflict with an existing use of `T`.
  ///
  /// To lower the risk of confusion, it is generous in which identifiers it
  /// reports. For example, in the type `void Function<T>({T X})`, it reports
  /// `X` as a used identifier. This is because even though it would technically
  /// be safe to rename the type variable `T` to `X`, to do so would be result
  /// in a confusing type.
  void gatherUsedIdentifiers(Set<String> identifiers);

  @override
  String getDisplayString() => type;

  @override
  bool isStructurallyEqualTo(SharedType other) => '$this' == '$other';

  /// Finds the nearest type that doesn't involve any type parameter promotion.
  /// If `covariant` is `true`, a supertype will be returned (replacing promoted
  /// type parameters with their unpromoted counterparts); otherwise a subtype
  /// will be returned (replacing promoted type parameters with `Never`).
  ///
  /// Returns `null` if this type is already free from type promotion.
  Type? recursivelyDemote({required bool covariant});

  /// Returns a string representation of this type.
  ///
  /// If [parenthesizeIfComplex] is `true`, then the result will be surrounded
  /// by parenthesis if it takes any of the following forms:
  /// - A type with a trailing `?` or `*`
  /// - A function type (e.g. `void Function()`)
  /// - A promoted type variable type (e.g. `T&int`)
  @override
  String toString({bool parenthesizeIfComplex = false}) => isQuestionType
      ? _parenthesizeIf(
          parenthesizeIfComplex,
          '${_toStringWithoutSuffix(parenthesizeIfComplex: true)}'
          '?',
        )
      : _toStringWithoutSuffix(parenthesizeIfComplex: parenthesizeIfComplex);

  /// Returns a string representation of the portion of this string that
  /// precedes the nullability suffix.
  ///
  /// If [parenthesizeIfComplex] is `true`, then the result will be surrounded
  /// by parenthesis if it takes any of the following forms:
  /// - A function type (e.g. `void Function()`)
  /// - A promoted type variable type (e.g. `T&int`)
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex});
}

/// Information about a single type name recognized by the [Type] parser.
sealed class TypeNameInfo {
  final String name;

  /// The runtime type that should be used for [Type] objects that refer to
  /// `this`.
  ///
  /// An assertion in the [PrimaryType] constructor verifies this.
  ///
  /// This ensures that the methods [Type.closureWithRespectToUnknown],
  /// [Type.recursivelyDemote], [Type.substitute], and
  /// [Type.asQuestionType] (which create new instances of [Type] based on
  /// old ones) create the appropriate subtype of [Type]. It also ensures that
  /// when [Type] objects are directly constructed (as they are in this file and
  /// in `mini_ast.dart`), the appropriate subtype of [Type] is used.
  final core.Type _expectedRuntimeType;

  TypeNameInfo(this.name, {required core.Type expectedRuntimeType})
    : _expectedRuntimeType = expectedRuntimeType;
}

/// A type name that represents a type variable.
class TypeParameter extends TypeNameInfo implements SharedTypeParameter {
  /// The type variable's bound. If `null`, the bound is `Object?`.
  ///
  /// This is non-final because it needs to be possible to set it after
  /// construction, in order to create "F-bounded" type parameters (type
  /// parameters whose bound refers to the type parameter itself).
  Type? explicitBound;

  TypeParameter._(super.name) : super(expectedRuntimeType: TypeParameterType);

  Type get bound => explicitBound ?? Type('Object?');

  @override
  Type? get boundShared => bound;

  @override
  String get displayName => name;

  @override
  int get hashCode {
    // To ensure that generic function types with different type formal names
    // have the same hash code, [FunctionType.hashCode] substitutes in a
    // consistently-named set of synthetic type formals in place of the type
    // formals. Since a fresh set of synthetic type formals will be created each
    // time [FunctionType.hashCode] is called, it's important that two type
    // formals with the same name (and bound) have the same hash code.
    return Object.hash(name, bound);
  }

  @override
  String toString() => name;

  @override
  // TODO(paulberry): Implement isLegacyCovariant.
  bool get isLegacyCovariant => true;

  @override
  // TODO(paulberry): Implement variance.
  Variance get variance => Variance.covariant;
}

/// Representation of a type parameter type suitable for unit testing of code in
/// the `_fe_analyzer_shared` package. A type parameter type might be promoted,
/// in which case it is often written using the syntax `a&b`, where `a` is the
/// type parameter and `b` is what it's promoted to.  For example, `T&int`
/// represents the type parameter `T`, promoted to `int`.
class TypeParameterType extends Type {
  /// The type parameter this type is based on.
  final TypeParameter typeParameter;

  /// If non-null, the promoted type.
  final Type? promotion;

  TypeParameterType(
    this.typeParameter, {
    this.promotion,
    super.isQuestionType = false,
  }) : super._();

  /// The type parameter's bound.
  Type get bound => typeParameter.bound;

  @override
  int get hashCode =>
      Object.hash(runtimeType, typeParameter, promotion, isQuestionType);

  @override
  bool operator ==(Object other) =>
      other is TypeParameterType &&
      typeParameter == other.typeParameter &&
      promotion == other.promotion &&
      isQuestionType == other.isQuestionType;

  @override
  Type asQuestionType(bool isQuestionType) => TypeParameterType(
    typeParameter,
    promotion: promotion,
    isQuestionType: isQuestionType,
  );

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    var newPromotion = promotion?.closureWithRespectToUnknown(
      covariant: covariant,
    );
    if (newPromotion == null) return null;
    return TypeParameterType(
      typeParameter,
      promotion: newPromotion,
      isQuestionType: isQuestionType,
    );
  }

  @override
  void gatherUsedIdentifiers(Set<String> identifiers) {
    identifiers.add(typeParameter.name);
    promotion?.gatherUsedIdentifiers(identifiers);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    if (!covariant) {
      return NeverType.instance.asQuestionType(isQuestionType);
    } else if (promotion == null) {
      return null;
    } else {
      return TypeParameterType(typeParameter, isQuestionType: isQuestionType);
    }
  }

  @override
  Type? substitute(Map<TypeParameter, Type> substitution) =>
      substitution[typeParameter];

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) {
    if (promotion case var promotion?) {
      return _parenthesizeIf(
        parenthesizeIfComplex,
        '${typeParameter.name}&'
        '${promotion.toString(parenthesizeIfComplex: true)}',
      );
    } else {
      return typeParameter.name;
    }
  }
}

/// Container for static methods that can be used to customize the "mini types"
/// representation used in `_fe_analyzer_shared` unit tests.
///
/// Thanks to Dart's scoping rules, it's possible for a single identifier to
/// represent an interface type in some contexts, a special type like `Null` in
/// other contexts, and a type parameter name in other contexts. But allowing a
/// single name to have multiple meanings isn't useful in `_fe_analyzer_shared`
/// unit tests, and opens up greater risk of confusion. Therefore, the "mini
/// types" representation does not permit it; every test must register each type
/// name it intends to use, specifying its meaning, before using that name in a
/// call to the [Type] constructor. This registration can happen either within
/// the test itself or in a callback passed to `setUp`.
abstract final class TypeRegistry {
  /// Type names that have been registered using [_add].
  static Map<String, TypeNameInfo>? _typeNameInfoMap;

  /// The [TypeNameInfo] object representing the special type `dynamic`.
  static final dynamic_ = SpecialTypeName._(
    'dynamic',
    expectedRuntimeType: DynamicType,
  );

  /// The [TypeNameInfo] object representing the special type `error`.
  static final error_ = SpecialTypeName._(
    'error',
    expectedRuntimeType: InvalidType,
  );

  /// The [TypeNameInfo] object representing the interface type `Future`.
  static final future = InterfaceTypeName._('Future');

  /// The [TypeNameInfo] object representing the special type `FutureOr`.
  static final futureOr = SpecialTypeName._(
    'FutureOr',
    expectedRuntimeType: FutureOrType,
  );

  /// The [TypeNameInfo] object representing the interface type `Iterable`.
  static final iterable = InterfaceTypeName._('Iterable');

  /// The [TypeNameInfo] object representing the interface type `List`.
  static final list = InterfaceTypeName._('List');

  /// The [TypeNameInfo] object representing the interface type `Map`.
  static final map = InterfaceTypeName._('Map');

  /// The [TypeNameInfo] object representing the special type `Never`.
  static final never = SpecialTypeName._(
    'Never',
    expectedRuntimeType: NeverType,
  );

  /// The [TypeNameInfo] object representing the special type `Null`.
  static final null_ = SpecialTypeName._('Null', expectedRuntimeType: NullType);

  /// The [TypeNameInfo] object representing the interface type `Stream`.
  static final stream = InterfaceTypeName._('Stream');

  /// The [TypeNameInfo] object representing the special type `void`.
  static final void_ = SpecialTypeName._('void', expectedRuntimeType: VoidType);

  /// Gets [_typeNameInfoMap], throwing an exception if it has not been
  /// initialized.
  static Map<String, TypeNameInfo> get _typeNameInfoMapOrThrow =>
      _typeNameInfoMap ??
      (throw StateError(
        'TypeRegistry not initialized (call `TypeRegistry.init` from a test '
        '`setUp` callback)',
      ));

  factory TypeRegistry._() => throw StateError('Do not construct');

  /// Registers [name] as the name of an ordinary interface type.
  static InterfaceTypeName addInterfaceTypeName(String name) {
    var interfaceTypeName = InterfaceTypeName._(name);
    _add(interfaceTypeName);
    return interfaceTypeName;
  }

  /// Registers [name] as the name of a type parameter.
  static TypeParameter addTypeParameter(String name) {
    var typeParameter = TypeParameter._(name);
    _add(typeParameter);
    return typeParameter;
  }

  /// Initializes the "mini type" infrastructure.
  ///
  /// This method must be called from a `setUp` callback before any unit test
  /// that makes use of mini types.
  static void init() {
    assert(
      StackTrace.current.toString().contains('runSetUps'),
      'Should be called from a test `setUp` method',
    );
    if (_typeNameInfoMap != null) {
      throw StateError(
        'init() already called. Did you forget to call uninit() from '
        '`tearDown`?',
      );
    }
    _typeNameInfoMap = {};
    // Set up some common built-in type names.
    addInterfaceTypeName('bool');
    addInterfaceTypeName('double');
    _add(dynamic_);
    _add(error_);
    _add(future);
    _add(futureOr);
    addInterfaceTypeName('int');
    _add(iterable);
    _add(list);
    _add(map);
    _add(never);
    _add(null_);
    addInterfaceTypeName('num');
    addInterfaceTypeName('Object');
    _add(stream);
    addInterfaceTypeName('String');
    addInterfaceTypeName('StackTrace');
    _add(void_);
  }

  /// Retrieves the [TypeNameInfo] corresponding to [name].
  static TypeNameInfo lookup(String name) =>
      _typeNameInfoMapOrThrow[name] ??
      (throw StateError(
        'Unknown type name $name (use `TypeRegistry.add...` first)',
      ));

  /// Un-does the operation of [init], rendering the "mini type" infrastructure
  /// unusable.
  ///
  /// This method should be called from a `tearDown` callback, complementing the
  /// call to [init] in a `setUp` callback.
  static void uninit() {
    // Note: don't complain if `_typeNameInfoMap` is `null`, because we don't
    // want to produce confusing failure messages if a test runs into trouble
    // while trying to initialize itself.
    _typeNameInfoMap = null;
  }

  /// Registers [info] as information about a type name.
  static void _add(TypeNameInfo info) {
    var name = info.name;
    var infoMap = _typeNameInfoMapOrThrow;
    if (infoMap.containsKey(name)) {
      throw StateError('Type name $name already registered');
    }
    infoMap[name] = info;
  }
}

class TypeSystem {
  static final Map<String, List<Type> Function(List<Type>)>
  _coreSuperInterfaceTemplates = {
    'bool': (_) => [Type('Object')],
    'double': (_) => [Type('num'), Type('Object')],
    'Future': (_) => [Type('Object')],
    'int': (_) => [Type('num'), Type('Object')],
    'Iterable': (_) => [Type('Object')],
    'List': (args) => [
      PrimaryType(TypeRegistry.iterable, args: args),
      Type('Object'),
    ],
    'Map': (_) => [Type('Object')],
    'Object': (_) => [],
    'num': (_) => [Type('Object')],
    'StackTrace': (_) => [Type('Object')],
    'String': (_) => [Type('Object')],
  };

  static final _objectQuestionType = Type('Object?');

  static final _objectType = Type('Object');

  final Map<String, List<Type> Function(List<Type>)> _superInterfaceTemplates =
      Map.of(_coreSuperInterfaceTemplates);

  void addSuperInterfaces(
    String className,
    List<Type> Function(List<Type>) template,
  ) {
    _superInterfaceTemplates[className] = template;
  }

  Type factor(Type t, Type s) {
    // If T <: S then Never
    if (isSubtype(t, s)) return NeverType.instance;

    // Else if T is R? and Null <: S then factor(R, S)
    if (t.isQuestionType && isSubtype(NullType.instance, s)) {
      return factor(t.asQuestionType(false), s);
    }

    // Else if T is R? then factor(R, S)?
    if (t.isQuestionType) {
      return factor(t.asQuestionType(false), s).asQuestionType(true);
    }

    // Else if T is FutureOr<R> and Future<R> <: S then factor(R, S)
    if (t is FutureOrType) {
      var r = t.typeArgument;
      if (isSubtype(PrimaryType(TypeRegistry.future, args: [r]), s)) {
        return factor(r, s);
      }
    }

    // Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
    if (t is FutureOrType) {
      var r = t.typeArgument;
      if (isSubtype(r, s)) {
        return factor(PrimaryType(TypeRegistry.future, args: [r]), s);
      }
    }

    // Else T
    return t;
  }

  bool isSubtype(Type t0, Type t1) {
    // Reflexivity: if T0 and T1 are the same type then T0 <: T1
    //
    // - Note that this check is necessary as the base case for primitive types,
    //   and type variables but not for composite types.  We only check it for
    //   types with a single name and no type arguments (this covers both
    //   primitive types and type variables).
    switch ((t0, t1)) {
      case (InvalidType(), _):
      case (_, InvalidType()):
        // `InvalidType` is treated as a top and a bottom type, which is
        // consistent with CFE and analyzer implementations.
        return true;
      case (
            PrimaryType(nameInfo: var t0Info, isQuestionType: false, args: []),
            PrimaryType(nameInfo: var t1Info, isQuestionType: false, args: []),
          )
          when t0Info == t1Info:
      case (
            TypeParameterType(
              typeParameter: var x0,
              promotion: null,
              isQuestionType: false,
            ),
            TypeParameterType(
              typeParameter: var x1,
              promotion: null,
              isQuestionType: false,
            ),
          )
          when x0 == x1:
        return true;
    }

    // Unknown types (note: this is not in the spec, but necessary because there
    // are circumstances where we do subtype tests between types and type
    // schemas): if T0 or T1 is the unknown type then T0 <: T1.
    if (t0 is UnknownType || t1 is UnknownType) return true;

    // Right Top: if T1 is a top type (i.e. dynamic, or void, or Object?) then
    // T0 <: T1
    if (_isTop(t1)) return true;

    // Left Top: if T0 is dynamic or void then T0 <: T1 if Object? <: T1
    if (t0 is DynamicType || t0 is VoidType) {
      return isSubtype(_objectQuestionType, t1);
    }

    // Left Bottom: if T0 is Never then T0 <: T1
    if (t0 is NeverType && !t0.isQuestionType) {
      return true;
    }

    // Right Object: if T1 is Object then:
    if (t1 is PrimaryType &&
        !t1.isQuestionType &&
        t1.args.isEmpty &&
        t1.name == 'Object') {
      // - if T0 is an unpromoted type variable with bound B then T0 <: T1 iff
      //   B <: Object
      if (t0 case TypeParameterType(
        bound: var b,
        promotion: null,
        isQuestionType: false,
      )) {
        return isSubtype(b, _objectType);
      }

      // - if T0 is a promoted type variable X & S then T0 <: T1 iff S <: Object
      if (t0 case TypeParameterType(promotion: var s?, isQuestionType: false)) {
        return isSubtype(s, _objectType);
      }

      // - if T0 is FutureOr<S> for some S, then T0 <: T1 iff S <: Object.
      if (t0 is FutureOrType && !t0.isQuestionType) {
        return isSubtype(t0.typeArgument, _objectType);
      }

      // - if T0 is Null, dynamic, void, or S? for any S, then the subtyping
      //   does not hold (per above, the result of the subtyping query is
      //   false).
      if (t0 is NullType ||
          t0 is DynamicType ||
          t0 is VoidType ||
          t0.isQuestionType) {
        return false;
      }

      // - Otherwise T0 <: T1 is true.
      return true;
    }

    // Left Null: if T0 is Null then:
    if (t0 is NullType) {
      // - if T1 is a type variable (promoted or not) the query is false
      if (t1 case TypeParameterType(isQuestionType: false)) {
        return false;
      }

      // - If T1 is FutureOr<S> for some S, then the query is true iff
      //   Null <: S.
      if (t1 is FutureOrType && !t1.isQuestionType) {
        return isSubtype(NullType.instance, t1.typeArgument);
      }

      // - If T1 is Null or S? for some S, then the query is true.
      if (t1 is NullType || t1.isQuestionType) {
        return true;
      }

      // - Otherwise, the query is false
      return false;
    }

    // Left FutureOr: if T0 is FutureOr<S0> then:
    if (t0 is FutureOrType && !t0.isQuestionType) {
      var s0 = t0.typeArgument;

      // - T0 <: T1 iff Future<S0> <: T1 and S0 <: T1
      return isSubtype(PrimaryType(TypeRegistry.future, args: [s0]), t1) &&
          isSubtype(s0, t1);
    }

    // Left Nullable: if T0 is S0? then:
    if (t0.isQuestionType) {
      // - T0 <: T1 iff S0 <: T1 and Null <: T1
      return isSubtype(t0.asQuestionType(false), t1) &&
          isSubtype(NullType.instance, t1);
    }

    // Type Variable Reflexivity 1: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 then:
    if ((t0, t1) case (
      TypeParameterType(typeParameter: var x0, isQuestionType: false),
      TypeParameterType(
        typeParameter: var x1,
        promotion: null,
        isQuestionType: false,
      ),
    ) when x0 == x1) {
      // - T0 <: T1
      return true;
    }

    // Type Variable Reflexivity 2: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 & S1 then:
    if ((t0, t1) case (
      TypeParameterType(typeParameter: var x0, isQuestionType: false),
      TypeParameterType(
        typeParameter: var x1,
        promotion: var s1?,
        isQuestionType: false,
      ),
    ) when x0 == x1) {
      // - T0 <: T1 iff T0 <: S1.
      return isSubtype(t0, s1);
    }

    // Right Promoted Variable: if T1 is a promoted type variable X1 & S1 then:
    if (t1 case TypeParameterType(
      typeParameter: var x1,
      promotion: var s1?,
      isQuestionType: false,
    )) {
      // - T0 <: T1 iff T0 <: X1 and T0 <: S1
      return isSubtype(t0, TypeParameterType(x1)) && isSubtype(t0, s1);
    }

    // Right FutureOr: if T1 is FutureOr<S1> then:
    if (t1 is FutureOrType && !t1.isQuestionType) {
      var s1 = t1.typeArgument;

      // - T0 <: T1 iff any of the following hold:
      //   - either T0 <: Future<S1>
      if (isSubtype(t0, PrimaryType(TypeRegistry.future, args: [s1]))) {
        return true;
      }
      //   - or T0 <: S1
      if (isSubtype(t0, s1)) return true;
      //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
      if (t0 case TypeParameterType(
        bound: var s0,
        promotion: null,
      ) when isSubtype(s0, t1)) {
        return true;
      }
      //   - or T0 is X0 & S0 and S0 <: T1
      if (t0 case TypeParameterType(
        promotion: var s0?,
      ) when isSubtype(s0, t1)) {
        return true;
      }
      return false;
    }

    // Right Nullable: if T1 is S1? then:
    if (t1.isQuestionType) {
      var s1 = t1.asQuestionType(false);

      // - T0 <: T1 iff any of the following hold:
      //   - either T0 <: S1
      if (isSubtype(t0, s1)) return true;
      //   - or T0 <: Null
      if (isSubtype(t0, NullType.instance)) return true;
      //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
      if (t0 case TypeParameterType(
        bound: var s0,
        promotion: null,
      ) when isSubtype(s0, t1)) {
        return true;
      }
      //   - or T0 is X0 & S0 and S0 <: T1
      if (t0 case TypeParameterType(
        promotion: var s0?,
      ) when isSubtype(s0, t1)) {
        return true;
      }
      return false;
    }

    // Left Promoted Variable: T0 is a promoted type variable X0 & S0
    if (t0 case TypeParameterType(promotion: var s0?)) {
      // - and S0 <: T1
      if (isSubtype(s0, t1)) return true;
    }

    // Left Type Variable Bound: T0 is a type variable X0 with bound B0
    if (t0 case TypeParameterType(bound: var b0, promotion: null)) {
      // - and B0 <: T1
      if (isSubtype(b0, t1)) return true;
    }

    // Function Type/Function: T0 is a function type and T1 is Function
    if (t0 is FunctionType &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t1.name == 'Function') {
      return true;
    }

    // Record Type/Record: T0 is a record type and T1 is Record
    if (t0 is RecordType &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t1.name == 'Record') {
      return true;
    }

    bool isInterfaceCompositionalitySubtype() {
      // Interface Compositionality: T0 is an interface type C0<S0, ..., Sk> and
      // T1 is C0<U0, ..., Uk>
      if (t0 is! PrimaryType ||
          t1 is! PrimaryType ||
          t0.args.length != t1.args.length ||
          t0.name != t1.name) {
        return false;
      }
      // - and each Si <: Ui
      for (int i = 0; i < t0.args.length; i++) {
        if (!isSubtype(t0.args[i], t1.args[i])) {
          return false;
        }
      }
      return true;
    }

    if (isInterfaceCompositionalitySubtype()) return true;

    // Super-Interface: T0 is an interface type with super-interfaces S0,...Sn
    bool isSuperInterfaceSubtype() {
      if (t0 is! PrimaryType) return false;
      var superInterfaceTemplate = _superInterfaceTemplates[t0.name];
      if (superInterfaceTemplate == null) {
        assert(false, 'Superinterfaces for $t0 not known');
        return false;
      }
      var superInterfaces = superInterfaceTemplate(t0.args);

      // - and Si <: T1 for some i
      for (var superInterface in superInterfaces) {
        if (isSubtype(superInterface, t1)) return true;
      }
      return false;
    }

    if (isSuperInterfaceSubtype()) return true;

    bool isPositionalFunctionSubtype() {
      // Positional Function Types: T0 is U0 Function<X0 extends B00, ...,
      // Xk extends B0k>(V0 x0, ..., Vn xn, [Vn+1 xn+1, ..., Vm xm])
      if (t0 is! FunctionType || t0.namedParameters.isNotEmpty) return false;
      var n = t0.requiredPositionalParameterCount;
      var m = t0.positionalParameters.length;

      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sp yp, [Sp+1 yp+1, ..., Sq yq])
      if (t1 is! FunctionType || t1.namedParameters.isNotEmpty) return false;
      var p = t1.requiredPositionalParameterCount;
      var q = t1.positionalParameters.length;

      // - and p >= n
      if (p < n) return false;

      // - and m >= q
      if (m < q) return false;

      // (Note: no substitution is needed in the code below; we don't support
      // type arguments on function types)

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...q
      for (int i = 0; i < q; i++) {
        if (!isSubtype(
          t1.positionalParameters[i],
          t0.positionalParameters[i],
        )) {
          return false;
        }
      }

      // - and U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]
      if (!isSubtype(t0.returnType, t1.returnType)) return false;

      // - and B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk] for i in 0...k
      // - where the Zi are fresh type variables with bounds B0i[Z0/X0, ...,
      //   Zk/Xk]
      // (No check needed here since we don't support type arguments on function
      // types)
      return true;
    }

    if (isPositionalFunctionSubtype()) return true;

    bool isNamedFunctionSubtype() {
      // Named Function Types: T0 is U0 Function<X0 extends B00, ..., Xk extends
      // B0k>(V0 x0, ..., Vn xn, {r0n+1 Vn+1 xn+1, ..., r0m Vm xm}) where r0j is
      // empty or required for j in n+1...m
      if (t0 is! FunctionType) return false;
      var n = t0.positionalParameters.length;
      if (t0.requiredPositionalParameterCount != n) return false;

      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sn yn, {r1n+1 Sn+1 yn+1, ..., r1q Sq yq}) where r1j is empty or
      //   required for j in n+1...q
      if (t1 is! FunctionType ||
          t1.positionalParameters.length != n ||
          t1.requiredPositionalParameterCount != n) {
        return false;
      }

      // - and {yn+1, ... , yq} subsetof {xn+1, ... , xm}
      var t1IndexToT0Index = <int>[];
      for (
        var i = 0, j = 0;
        i < t0.namedParameters.length || j < t1.namedParameters.length;
      ) {
        if (i >= t0.namedParameters.length) break;
        if (j >= t1.namedParameters.length) return false;
        switch (t0.namedParameters[i].name.compareTo(
          t1.namedParameters[j].name,
        )) {
          case < 0:
            i++;
          case > 0:
            return false;
          default: // == 0
            t1IndexToT0Index.add(i);
            i++;
            j++;
        }
      }

      // (Note: no substitution is needed in the code below; we don't support
      // type arguments on function types)

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...n
      for (var i = 0; i < n; i++) {
        if (!isSubtype(
          t1.positionalParameters[i],
          t0.positionalParameters[i],
        )) {
          return false;
        }
      }

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Tj[Z0/X0, ..., Zk/Xk] for i in n+1...q,
      //   yj = xi
      for (var j = 0; j < t1IndexToT0Index.length; j++) {
        var i = t1IndexToT0Index[j];
        if (!isSubtype(
          t1.namedParameters[j].type,
          t0.namedParameters[i].type,
        )) {
          return false;
        }
      }

      // - and for each j such that r0j is required, then there exists an i in
      //   n+1...q such that xj = yi, and r1i is required
      for (var j = 0; j < t1IndexToT0Index.length; j++) {
        var i = t1IndexToT0Index[j];
        if (t1.namedParameters[j].isRequired &&
            !t0.namedParameters[i].isRequired) {
          return false;
        }
      }

      // - and U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]
      if (!isSubtype(t0.returnType, t1.returnType)) return false;

      // - and B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk] for i in 0...k
      // - where the Zi are fresh type variables with bounds B0i[Z0/X0, ...,
      //   Zk/Xk]
      // (No check needed here since we don't support type arguments on function
      // types)
      return true;
    }

    if (isNamedFunctionSubtype()) return true;

    // Record Types: T0 is (V0, ..., Vn, {Vn+1 dn+1, ..., Vm dm})
    //
    // - and T1 is (S0, ..., Sn, {Sn+1 dn+1, ..., Sm dm})
    // - and Vi <: Si for i in 0...m
    bool isRecordSubtype() {
      if (t0 is! RecordType || t1 is! RecordType) return false;
      if (t0.positionalTypes.length != t1.positionalTypes.length) return false;
      for (int i = 0; i < t0.positionalTypes.length; i++) {
        if (!isSubtype(t0.positionalTypes[i], t1.positionalTypes[i])) {
          return false;
        }
      }
      if (t0.namedTypes.length != t1.namedTypes.length) return false;
      var t1NamedMap = {
        for (var NamedType(:name, :type) in t1.namedTypes) name: type,
      };
      for (var NamedType(:name, type: vi) in t0.namedTypes) {
        var si = t1NamedMap[name];
        if (si == null) return false;
        if (!isSubtype(vi, si)) return false;
      }
      return true;
    }

    if (isRecordSubtype()) return true;

    return false;
  }

  bool _isTop(Type t) {
    if (t is PrimaryType) {
      return t is DynamicType || t is InvalidType || t is VoidType;
    } else if (t.isQuestionType) {
      return t is PrimaryType && t.args.isEmpty && t.name == 'Object';
    }
    return false;
  }
}

/// Representation of the unknown type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class UnknownType extends Type implements SharedUnknownType {
  const UnknownType({super.isQuestionType = false}) : super._();

  @override
  int get hashCode => Object.hash(runtimeType, isQuestionType);

  @override
  bool operator ==(Object other) =>
      other is UnknownType && isQuestionType == other.isQuestionType;

  @override
  Type asQuestionType(bool isQuestionType) =>
      UnknownType(isQuestionType: isQuestionType);

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) =>
      covariant ? Type('Object?') : NeverType.instance;

  @override
  void gatherUsedIdentifiers(Set<String> identifiers) {}

  @override
  Type? recursivelyDemote({required bool covariant}) => null;

  @override
  Type? substitute(Map<TypeParameter, Type> substitution) => null;

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) => '_';
}

/// Representation of the type `void` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class VoidType extends _SpecialSimpleType implements SharedVoidType {
  static final instance = VoidType._();

  VoidType._() : super._(TypeRegistry.void_, isQuestionType: false);

  @override
  Type asQuestionType(bool isQuestionType) => this;
}

/// Representation of a [FunctionType] that has been parsed but hasn't had
/// meaning assigned to its identifiers yet.
class _PreFunctionType extends _PreType {
  final _PreType returnType;
  final List<_PreTypeFormal> typeFormals;
  final List<_PreType> positionalParameterTypes;
  final int requiredPositionalParameterCount;
  final List<_PreNamedFunctionParameter> namedParameters;

  _PreFunctionType({
    required this.returnType,
    required this.typeFormals,
    required this.positionalParameterTypes,
    required this.requiredPositionalParameterCount,
    required this.namedParameters,
  });

  @override
  Type materialize({required Map<String, TypeParameter> typeFormalScope}) {
    List<TypeParameter> materializedTypeFormals;
    if (typeFormals.isNotEmpty) {
      materializedTypeFormals = <TypeParameter>[];
      typeFormalScope = Map.of(typeFormalScope);
      for (var typeFormal in typeFormals) {
        var materializedTypeFormal = TypeParameter._(typeFormal.name);
        materializedTypeFormals.add(materializedTypeFormal);
        typeFormalScope[typeFormal.name] = materializedTypeFormal;
      }
      for (var i = 0; i < typeFormals.length; i++) {
        if (typeFormals[i].bound case var bound?) {
          materializedTypeFormals[i].explicitBound = bound.materialize(
            typeFormalScope: typeFormalScope,
          );
        }
      }
    } else {
      materializedTypeFormals = const [];
    }
    return FunctionType(
      returnType.materialize(typeFormalScope: typeFormalScope),
      [
        for (var positionalParameterType in positionalParameterTypes)
          positionalParameterType.materialize(typeFormalScope: typeFormalScope),
      ],
      typeParametersShared: materializedTypeFormals,
      requiredPositionalParameterCount: requiredPositionalParameterCount,
      namedParameters: [
        for (var namedParameter in namedParameters)
          NamedFunctionParameter(
            isRequired: namedParameter.isRequired,
            name: namedParameter.name,
            type: namedParameter.type.materialize(
              typeFormalScope: typeFormalScope,
            ),
          ),
      ],
    );
  }
}

/// Representation of a named function parameter in a [_PreFunctionType].
class _PreNamedFunctionParameter {
  final String name;
  final _PreType type;
  final bool isRequired;

  _PreNamedFunctionParameter({
    required this.name,
    required this.type,
    required this.isRequired,
  });
}

/// Representation of a named component of a [_PreRecordType].
class _PreNamedType {
  final String name;
  final _PreType type;

  _PreNamedType({required this.name, required this.type});
}

/// Representation of a [PrimaryType] or [TypeParameterType] that has been
/// parsed but hasn't had meaning assigned to its identifiers yet.
class _PrePrimaryType extends _PreType {
  final String typeName;
  final List<_PreType> typeArgs;

  _PrePrimaryType({required this.typeName, required this.typeArgs});

  @override
  Type materialize({required Map<String, TypeParameter> typeFormalScope}) {
    var nameInfo = typeFormalScope[typeName] ?? TypeRegistry.lookup(typeName);
    switch (nameInfo) {
      case TypeParameter():
        if (typeArgs.isNotEmpty) {
          throw ParseError('Type parameter types do not accept type arguments');
        }
        return TypeParameterType(nameInfo);
      case InterfaceTypeName():
        return PrimaryType(
          nameInfo,
          args: [
            for (var typeArg in typeArgs)
              typeArg.materialize(typeFormalScope: typeFormalScope),
          ],
        );
      case SpecialTypeName():
        if (typeName == 'dynamic') {
          if (typeArgs.isNotEmpty) {
            throw ParseError('`dynamic` does not accept type arguments');
          }
          return DynamicType.instance;
        } else if (typeName == 'error') {
          if (typeArgs.isNotEmpty) {
            throw ParseError('`error` does not accept type arguments');
          }
          return InvalidType.instance;
        } else if (typeName == 'FutureOr') {
          if (typeArgs.length != 1) {
            throw ParseError('`FutureOr` requires exactly one type argument');
          }
          return FutureOrType(
            typeArgs.single.materialize(typeFormalScope: typeFormalScope),
          );
        } else if (typeName == 'Never') {
          if (typeArgs.isNotEmpty) {
            throw ParseError('`Never` does not accept type arguments');
          }
          return NeverType.instance;
        } else if (typeName == 'Null') {
          if (typeArgs.isNotEmpty) {
            throw ParseError('`Null` does not accept type arguments');
          }
          return NullType.instance;
        } else if (typeName == 'void') {
          if (typeArgs.isNotEmpty) {
            throw ParseError('`void` does not accept type arguments');
          }
          return VoidType.instance;
        } else {
          throw UnimplementedError('Unknown special type name: $typeName');
        }
    }
  }
}

/// Representation of a promoted [TypeParameterType] that has been parsed but
/// hasn't had meaning assigned to its identifiers yet.
class _PrePromotedType extends _PreType {
  final _PreType inner;
  final _PreType promotion;

  _PrePromotedType({required this.inner, required this.promotion});

  @override
  Type materialize({required Map<String, TypeParameter> typeFormalScope}) {
    var type = inner.materialize(typeFormalScope: typeFormalScope);
    if (type case TypeParameterType(promotion: null)) {
      return TypeParameterType(
        type.typeParameter,
        promotion: promotion.materialize(typeFormalScope: typeFormalScope),
      );
    } else {
      throw ParseError(
        'The type to the left of & must be an unpromoted type parameter',
      );
    }
  }
}

/// Representation of a [RecordType] that has been parsed but hasn't had
/// meaning assigned to its identifiers yet.
class _PreRecordType extends _PreType {
  final List<_PreType> positionalTypes;
  final List<_PreNamedType> namedTypes;

  _PreRecordType({required this.positionalTypes, required this.namedTypes});

  @override
  Type materialize({required Map<String, TypeParameter> typeFormalScope}) =>
      RecordType(
        positionalTypes: [
          for (var positionalType in positionalTypes)
            positionalType.materialize(typeFormalScope: typeFormalScope),
        ],
        namedTypes: [
          for (var namedType in namedTypes)
            NamedType(
              name: namedType.name,
              type: namedType.type.materialize(
                typeFormalScope: typeFormalScope,
              ),
            ),
        ],
      );
}

/// Representation of a [Type] that has been parsed but hasn't had meaning
/// assigned to its identifiers yet.
sealed class _PreType {
  /// Translates `this` into a [Type].
  ///
  /// The meaning of identifiers in `this` is determined by looking them up
  /// first in [typeFormalScope], and then, if they are not found, in the
  /// [TypeRegistry].
  Type materialize({required Map<String, TypeParameter> typeFormalScope});
}

/// Representation of a formal parameter of a function type that has been parsed
/// but hasn't had meaning assigned to its identifiers yet.
class _PreTypeFormal {
  final String name;
  final _PreType? bound;

  _PreTypeFormal({required this.name, required this.bound});
}

/// Representation of a [Type] with a nullability suffix that has been parsed
/// but hasn't had meaning assigned to its identifiers yet.
class _PreTypeWithNullability extends _PreType {
  final _PreType inner;
  final bool isQuestionType;

  _PreTypeWithNullability({required this.inner, required this.isQuestionType});

  @override
  Type materialize({required Map<String, TypeParameter> typeFormalScope}) =>
      inner
          .materialize(typeFormalScope: typeFormalScope)
          .asQuestionType(isQuestionType);
}

/// Representation of an [UnknownType] that has been parsed but hasn't had
/// meaning assigned to its identifiers yet.
class _PreUnknownType extends _PreType {
  @override
  Type materialize({required Map<String, TypeParameter> typeFormalScope}) =>
      const UnknownType();
}

/// Shared implementation of the types `void`, `dynamic`, `null`, `Never`, and
/// the invalid type.
///
/// These types share the property that they are special cases of [PrimaryType]
/// that don't need special functionality for the [closureWithRespectToUnknown]
/// and [recursivelyDemote] methods.
abstract class _SpecialSimpleType extends PrimaryType {
  _SpecialSimpleType._(super.nameInfo, {super.isQuestionType = false})
    : super._special();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) => null;

  @override
  Type? recursivelyDemote({required bool covariant}) => null;

  @override
  Type? substitute(Map<TypeParameter, Type> substitution) => null;
}

/// Interface for [Type] and the data structures that comprise it, allowing
/// type substitutions to be performed.
abstract class _Substitutable<T extends _Substitutable<T>> {
  /// If `this` contains any references to a [TypeParameter] matching one of the
  /// keys in [substitution], returns a clone of `this` with those references
  /// replaced by the corresponding value. Otherwise returns `null`.
  ///
  /// For example, if `t` is a reference to the [TypeParameter] object
  /// representing `T`, then `Type('Map<T, U>`).substitute({t: Type('int')})`
  /// returns a [Type] object representing `Map<int, U>`.
  T? substitute(Map<TypeParameter, Type> substitution);
}

class _TypeParser {
  static final _typeTokenizationRegexp = RegExp(
    _identifierPattern + r'|\(|\)|<|>|,|\?|\*|&|{|}|\[|\]',
  );

  static const _identifierPattern = '[_a-zA-Z][_a-zA-Z0-9]*';

  static final _identifierRegexp = RegExp(_identifierPattern);

  final String _typeStr;

  final List<String> _tokens;

  int _i = 0;

  _TypeParser._(this._typeStr, this._tokens);

  String get _currentToken => _tokens[_i];

  void _next() {
    _i++;
  }

  Never _parseFailure(String message) {
    throw ParseError(
      'Error parsing type `$_typeStr` at token $_currentToken: $message',
    );
  }

  List<_PreNamedFunctionParameter> _parseNamedFunctionParameters() {
    assert(_currentToken == '{');
    _next();
    var namedParameters = <_PreNamedFunctionParameter>[];
    while (true) {
      var isRequired = _currentToken == 'required';
      if (isRequired) {
        _next();
      }
      var type = _parseType();
      var name = _currentToken;
      if (_identifierRegexp.matchAsPrefix(name) == null) {
        _parseFailure('Expected an identifier');
      }
      namedParameters.add(
        _PreNamedFunctionParameter(
          name: name,
          type: type,
          isRequired: isRequired,
        ),
      );
      _next();
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == '}') {
        break;
      }
      _parseFailure('Expected `}` or `,`');
    }
    _next();
    namedParameters.sort((a, b) => a.name.compareTo(b.name));
    return namedParameters;
  }

  void _parseOptionalFunctionParameters(
    List<_PreType> positionalParameterTypes,
  ) {
    assert(_currentToken == '[');
    _next();
    while (true) {
      var type = _parseType();
      positionalParameterTypes.add(type);
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == ']') {
        break;
      }
      _parseFailure('Expected `]` or `,`');
    }
    _next();
  }

  List<_PreNamedType> _parseRecordTypeNamedFields() {
    assert(_currentToken == '{');
    _next();
    var namedTypes = <_PreNamedType>[];
    while (_currentToken != '}') {
      var type = _parseType();
      var name = _currentToken;
      if (_identifierRegexp.matchAsPrefix(name) == null) {
        _parseFailure('Expected an identifier');
      }
      namedTypes.add(_PreNamedType(name: name, type: type));
      _next();
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == '}') {
        break;
      }
      _parseFailure('Expected `}` or `,`');
    }
    if (namedTypes.isEmpty) {
      _parseFailure('Must have at least one named type between {}');
    }
    _next();
    namedTypes.sort((a, b) => a.name.compareTo(b.name));
    return namedTypes;
  }

  _PreRecordType _parseRecordTypeRest(List<_PreType> positionalTypes) {
    List<_PreNamedType>? namedTypes;
    while (_currentToken != ')') {
      if (_currentToken == '{') {
        namedTypes = _parseRecordTypeNamedFields();
        if (_currentToken != ')') {
          _parseFailure('Expected `)`');
        }
        break;
      }
      positionalTypes.add(_parseType());
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == ')') {
        break;
      }
      _parseFailure('Expected `)` or `,`');
    }
    _next();
    return _PreRecordType(
      positionalTypes: positionalTypes,
      namedTypes: namedTypes ?? const [],
    );
  }

  _PreType? _parseSuffix(_PreType type) {
    if (_currentToken == '?') {
      _next();
      return _PreTypeWithNullability(inner: type, isQuestionType: true);
    } else if (_currentToken == '&') {
      _next();
      var promotion = _parseUnsuffixedType();
      return _PrePromotedType(inner: type, promotion: promotion);
    } else if (_currentToken == 'Function') {
      _next();
      List<_PreTypeFormal> typeFormals;
      if (_currentToken == '<') {
        typeFormals = _parseTypeFormals();
      } else {
        typeFormals = const [];
      }
      if (_currentToken != '(') {
        _parseFailure('Expected `(`');
      }
      _next();
      var positionalParameterTypes = <_PreType>[];
      List<_PreNamedFunctionParameter>? namedFunctionParameters;
      int? requiredPositionalParameterCount;
      if (_currentToken != ')') {
        while (true) {
          if (_currentToken == '{') {
            namedFunctionParameters = _parseNamedFunctionParameters();
            if (_currentToken != ')') {
              _parseFailure('Expected `)`');
            }
            break;
          } else if (_currentToken == '[') {
            requiredPositionalParameterCount = positionalParameterTypes.length;
            _parseOptionalFunctionParameters(positionalParameterTypes);
            if (_currentToken != ')') {
              _parseFailure('Expected `)`');
            }
            break;
          }
          positionalParameterTypes.add(_parseType());
          if (_currentToken == ')') break;
          if (_currentToken != ',') {
            _parseFailure('Expected `,` or `)`');
          }
          _next();
        }
      }
      _next();
      return _PreFunctionType(
        returnType: type,
        positionalParameterTypes: positionalParameterTypes,
        requiredPositionalParameterCount:
            requiredPositionalParameterCount ?? positionalParameterTypes.length,
        namedParameters: namedFunctionParameters ?? const [],
        typeFormals: typeFormals,
      );
    } else {
      return null;
    }
  }

  _PreType _parseType() {
    // We currently accept the following grammar for types:
    //   type := unsuffixedType nullability suffix*
    //   unsuffixedType := identifier typeArgs?
    //                   | `_`
    //                   | `(` type `)`
    //                   | `(` recordTypeFields `,` recordTypeNamedFields `)`
    //                   | `(` recordTypeFields `,`? `)`
    //                   | `(` recordTypeNamedFields? `)`
    //   recordTypeFields := type (`,` type)*
    //   recordTypeNamedFields := `{` recordTypeNamedField
    //                            (`,` recordTypeNamedField)* `,`? `}`
    //   recordTypeNamedField := type identifier
    //   typeArgs := `<` type (`,` type)* `>`
    //   nullability := `?`?
    //   suffix := `Function` typeParameters? `(` type (`,` type)* `)`
    //           | `Function` typeParameters? `(` (type `,`)*
    //             namedFunctionParameters `)`
    //           | `Function` typeParameters? `(` (type `,`)*
    //             optionalFunctionParameters `)`
    //           | `?`
    //           | `&` unsuffixedType
    //   namedFunctionParameters := `{` namedFunctionParameter
    //                              (`,` namedFunctionParameter)* `}`
    //   namedFunctionParameter := `required`? type identifier
    //   optionalFunctionParameters := `[` type (`,` type)* `]`
    //   typeParameters := `<` typeParameter (`,` typeParameter)* `>`
    //   typeParameter := identifier
    // TODO(paulberry): support more syntax if needed
    var result = _parseUnsuffixedType();
    while (true) {
      var newResult = _parseSuffix(result);
      if (newResult == null) break;
      result = newResult;
    }
    return result;
  }

  List<_PreTypeFormal> _parseTypeFormals() {
    assert(_currentToken == '<');
    _next();
    var typeFormals = <_PreTypeFormal>[];
    while (true) {
      var name = _currentToken;
      if (_identifierRegexp.matchAsPrefix(name) == null) {
        _parseFailure('Expected an identifier');
      }
      _next();
      _PreType? bound;
      if (_currentToken == 'extends') {
        _next();
        bound = _parseType();
      }
      typeFormals.add(_PreTypeFormal(name: name, bound: bound));
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == '>') {
        break;
      }
      _parseFailure('Expected `>` or `,`');
    }
    _next();
    return typeFormals;
  }

  _PreType _parseUnsuffixedType() {
    if (_currentToken == '_') {
      _next();
      return _PreUnknownType();
    }
    if (_currentToken == '(') {
      _next();
      if (_currentToken == ')' || _currentToken == '{') {
        return _parseRecordTypeRest([]);
      }
      var type = _parseType();
      if (_currentToken == ',') {
        _next();
        return _parseRecordTypeRest([type]);
      }
      if (_currentToken != ')') {
        _parseFailure('Expected `)` or `,`');
      }
      _next();
      return type;
    }
    var typeName = _currentToken;
    if (_identifierRegexp.matchAsPrefix(typeName) == null) {
      _parseFailure('Expected an identifier, `_`, or `(`');
    }
    _next();
    List<_PreType> typeArgs;
    if (_currentToken == '<') {
      _next();
      typeArgs = [];
      while (true) {
        typeArgs.add(_parseType());
        if (_currentToken == '>') break;
        if (_currentToken != ',') {
          _parseFailure('Expected `,` or `>`');
        }
        _next();
      }
      _next();
    } else {
      typeArgs = const [];
    }
    return _PrePrimaryType(typeName: typeName, typeArgs: typeArgs);
  }

  static Type parse(String typeStr) {
    var parser = _TypeParser._(typeStr, _tokenizeTypeStr(typeStr));
    var result = parser._parseType();
    if (parser._currentToken != '<END>') {
      throw ParseError(
        'Extra tokens after parsing type `$typeStr`: '
        '${parser._tokens.sublist(parser._i, parser._tokens.length - 1)}',
      );
    }
    return result.materialize(typeFormalScope: const {});
  }

  static List<String> _tokenizeTypeStr(String typeStr) {
    var result = <String>[];
    int lastMatchEnd = 0;
    for (var match in _typeTokenizationRegexp.allMatches(typeStr)) {
      var extraChars = typeStr.substring(lastMatchEnd, match.start).trim();
      if (extraChars.isNotEmpty) {
        throw ParseError(
          'Unrecognized character(s) in type `$typeStr`: $extraChars',
        );
      }
      result.add(typeStr.substring(match.start, match.end));
      lastMatchEnd = match.end;
    }
    var extraChars = typeStr.substring(lastMatchEnd).trim();
    if (extraChars.isNotEmpty) {
      throw ParseError(
        'Unrecognized character(s) in type `$typeStr`: $extraChars',
      );
    }
    result.add('<END>');
    return result;
  }
}

extension on List<NamedFunctionParameter> {
  /// Calls [Type.closureWithRespectToUnknown] to translate every list member
  /// into a type that doesn't involve the unknown type (`_`).  If no type would
  /// be changed by this operation, returns `null`.
  List<NamedFunctionParameter>? closureWithRespectToUnknown({
    required bool covariant,
  }) {
    List<NamedFunctionParameter>? newList;
    for (int i = 0; i < length; i++) {
      NamedFunctionParameter namedFunctionParameter = this[i];
      Type? newType = namedFunctionParameter.type.closureWithRespectToUnknown(
        covariant: covariant,
      );
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(
        newType == null
            ? namedFunctionParameter
            : NamedFunctionParameter(
                isRequired: namedFunctionParameter.isRequired,
                name: namedFunctionParameter.name,
                type: newType,
              ),
      );
    }
    return newList;
  }

  /// Calls [Type.recursivelyDemote] to translate every list member into a type
  /// that doesn't involve any type promotion.  If no type would be changed by
  /// this operation, returns `null`.
  List<NamedFunctionParameter>? recursivelyDemote({required bool covariant}) {
    List<NamedFunctionParameter>? newList;
    for (int i = 0; i < length; i++) {
      NamedFunctionParameter namedFunctionParameter = this[i];
      Type? newType = namedFunctionParameter.type.recursivelyDemote(
        covariant: covariant,
      );
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(
        newType == null
            ? namedFunctionParameter
            : NamedFunctionParameter(
                isRequired: namedFunctionParameter.isRequired,
                name: namedFunctionParameter.name,
                type: newType,
              ),
      );
    }
    return newList;
  }
}

extension on List<Type> {
  /// Calls [Type.closureWithRespectToUnknown] to translate every list member
  /// into a type that doesn't involve the unknown type (`_`).  If no type would
  /// be changed by this operation, returns `null`.
  List<Type>? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newList;
    for (int i = 0; i < length; i++) {
      Type type = this[i];
      Type? newType = type.closureWithRespectToUnknown(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType ?? type);
    }
    return newList;
  }

  /// Calls [Type.recursivelyDemote] to translate every list member into a type
  /// that doesn't involve any type promotion.  If no type would be changed by
  /// this operation, returns `null`.
  List<Type>? recursivelyDemote({required bool covariant}) {
    List<Type>? newList;
    for (int i = 0; i < length; i++) {
      Type type = this[i];
      Type? newType = type.recursivelyDemote(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType ?? type);
    }
    return newList;
  }
}

extension<T extends _Substitutable<T>> on List<T> {
  /// Helper method for performing substitutions on the constituent parts of a
  /// [Type] that are stored in lists.
  ///
  /// Calls [_Substitutable.substitute] on each element of the list; if all
  /// those calls returned `null` (meaning no substitutions were done), returns
  /// `null`. Otherwise returns a new [List] in which each element requiring
  /// substitutions is replaced with the substitution result.
  List<T>? substitute(Map<TypeParameter, Type> substitution) {
    List<T>? result;
    for (int i = 0; i < length; i++) {
      var oldListElement = this[i];
      var newType = oldListElement.substitute(substitution);
      if (newType != null && result == null) {
        result = sublist(0, i);
      }
      result?.add(newType ?? oldListElement);
    }
    return result;
  }
}
