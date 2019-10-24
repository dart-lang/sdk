// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/names.dart';
import '../common_elements.dart';
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

abstract class DartType {
  const DartType();

  /// Returns the unaliased type of this type.
  ///
  /// The unaliased type of a typedef'd type is the unaliased type to which its
  /// name is bound. The unaliased version of any other type is the type itself.
  ///
  /// For example, the unaliased type of `typedef A Func<A,B>(B b)` is the
  /// function type `(B) -> A` and the unaliased type of `Func<int,String>`
  /// is the function type `(String) -> int`.
  DartType get unaliased => this;

  /// Is `true` if this type has no non-dynamic type arguments.
  bool get treatAsRaw => true;

  /// Is `true` if this type should be treated as the dynamic type.
  bool get treatAsDynamic => false;

  /// Is `true` if this type is the dynamic type.
  bool get isDynamic => false;

  /// Is `true` if this type is the any type.
  bool get isAny => false;

  /// Is `true` if this type is the void type.
  bool get isVoid => false;

  /// Is `true` if this type is an interface type.
  bool get isInterfaceType => false;

  /// Is `true` if this type is a typedef.
  bool get isTypedef => false;

  /// Is `true` if this type is a function type.
  bool get isFunctionType => false;

  /// Is `true` if this type is a type variable.
  bool get isTypeVariable => false;

  /// Is `true` if this type is a type variable declared on a function type
  ///
  /// For instance `T` in
  ///     void Function<T>(T t)
  bool get isFunctionTypeVariable => false;

  /// Is `true` if this type is a `FutureOr` type.
  bool get isFutureOr => false;

  /// Whether this type contains a type variable.
  bool get containsTypeVariables => false;

  /// Whether this type contains a free class type variable or function type
  /// variable.
  // TODO(sra): Review uses of [containsTypeVariables] for update with
  // [containsFreeTypeVariables].
  bool get containsFreeTypeVariables =>
      _ContainsFreeTypeVariablesVisitor().run(this);

  /// Is `true` if this type is the 'Object' type defined in 'dart:core'.
  bool get isObject => false;

  /// Applies [f] to each occurrence of a [TypeVariableType] within this
  /// type. This excludes function type variables, whether free or bound.
  void forEachTypeVariable(f(TypeVariableType variable)) {}

  /// Performs the substitution `[arguments[i]/parameters[i]]this`.
  ///
  /// The notation is known from this lambda calculus rule:
  ///
  ///     (lambda x.e0)e1 -> [e1/x]e0.
  ///
  /// See [TypeVariableType] for a motivation for this method.
  ///
  /// Invariant: There must be the same number of [arguments] and [parameters].
  DartType subst(List<DartType> arguments, List<DartType> parameters) {
    assert(arguments.length == parameters.length);
    if (parameters.isEmpty) return this;
    return SimpleDartTypeSubstitutionVisitor(arguments, parameters)
        .substitute(this);
  }

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

class InterfaceType extends DartType {
  final ClassEntity element;
  final List<DartType> typeArguments;

  InterfaceType(this.element, this.typeArguments)
      : assert(typeArguments.every((e) => e != null));

  @override
  bool get isInterfaceType => true;

  @override
  bool get isObject {
    return element.name == 'Object' &&
        element.library.canonicalUri == Uris.dart_core;
  }

  @override
  bool get containsTypeVariables =>
      typeArguments.any((type) => type.containsTypeVariables);

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    typeArguments.forEach((type) => type.forEachTypeVariable(f));
  }

  @override
  bool get treatAsRaw {
    for (DartType type in typeArguments) {
      if (!type.treatAsDynamic) return false;
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

class TypedefType extends DartType {
  final TypedefEntity element;
  final List<DartType> typeArguments;
  @override
  final FunctionType unaliased;

  TypedefType(this.element, this.typeArguments, this.unaliased);

  @override
  bool get isTypedef => true;

  @override
  bool get containsTypeVariables =>
      typeArguments.any((type) => type.containsTypeVariables);

  @override
  void forEachTypeVariable(f(TypeVariableType variable)) {
    typeArguments.forEach((type) => type.forEachTypeVariable(f));
  }

  @override
  bool get treatAsRaw {
    for (DartType type in typeArguments) {
      if (!type.treatAsDynamic) return false;
    }
    return true;
  }

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitTypedefType(this, argument);

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
    if (other is! TypedefType) return false;
    return _equalsInternal(other, null);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (identical(this, other)) return true;
    if (other is! TypedefType) return false;
    return _equalsInternal(other, assumptions);
  }

  bool _equalsInternal(TypedefType other, _Assumptions assumptions) {
    return identical(element, other.element) &&
        _equalTypes(typeArguments, other.typeArguments, assumptions);
  }
}

class TypeVariableType extends DartType {
  final TypeVariableEntity element;

  TypeVariableType(this.element);

  @override
  bool get isTypeVariable => true;

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
  bool operator ==(other) {
    if (other is! TypeVariableType) return false;
    return identical(other.element, element);
  }

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    if (other is TypeVariableType) {
      return identical(other.element, element);
    }
    return false;
  }
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

  FunctionTypeVariable(this.index);

  DartType get bound {
    assert(_bound != null, "Bound has not been set.");
    return _bound;
  }

  void set bound(DartType value) {
    assert(_bound == null, "Bound has already been set.");
    _bound = value;
  }

  @override
  bool get isFunctionTypeVariable => true;

  @override
  int get hashCode => index.hashCode * 19;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! FunctionTypeVariable) return false;
    return false;
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

class VoidType extends DartType {
  const VoidType();

  @override
  bool get isVoid => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitVoidType(this, argument);

  @override
  int get hashCode => 6007;

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    return identical(this, other);
  }
}

class DynamicType extends DartType {
  const DynamicType();

  @override
  bool get isDynamic => true;

  @override
  bool get treatAsDynamic => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitDynamicType(this, argument);

  @override
  int get hashCode => 91;

  @override
  bool _equals(DartType other, _Assumptions assumptions) {
    return identical(this, other);
  }
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
  const AnyType();

  @override
  bool get isAny => true;

  @override
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) =>
      visitor.visitAnyType(this, argument);

  @override
  int get hashCode => 95;

  @override
  bool _equals(DartType other, _Assumptions assumptions) =>
      identical(this, other);
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

  FunctionType(
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
  bool get isFunctionType => true;

  FunctionType instantiate(List<DartType> arguments) {
    return subst(arguments, typeVariables);
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
    if (typeVariables.isNotEmpty) {
      assumptions ??= new _Assumptions();
      for (int index = 0; index < typeVariables.length; index++) {
        assumptions.assume(typeVariables[index], other.typeVariables[index]);
      }
      for (int index = 0; index < typeVariables.length; index++) {
        if (!typeVariables[index]
            .bound
            ._equals(other.typeVariables[index].bound, assumptions)) {
          return false;
        }
      }
    }
    bool result = returnType._equals(other.returnType, assumptions) &&
        _equalTypes(parameterTypes, other.parameterTypes, assumptions) &&
        _equalTypes(optionalParameterTypes, other.optionalParameterTypes,
            assumptions) &&
        equalElements(namedParameters, other.namedParameters) &&
        _equalTypes(
            namedParameterTypes, other.namedParameterTypes, assumptions);
    if (typeVariables.isNotEmpty) {
      for (int index = 0; index < typeVariables.length; index++) {
        assumptions.forget(typeVariables[index], other.typeVariables[index]);
      }
    }
    return result;
  }
}

class FutureOrType extends DartType {
  final DartType typeArgument;

  FutureOrType(this.typeArgument);

  @override
  bool get isFutureOr => true;

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

  R visitVoidType(covariant VoidType type, A argument) => null;

  R visitTypeVariableType(covariant TypeVariableType type, A argument) => null;

  R visitFunctionTypeVariable(
          covariant FunctionTypeVariable type, A argument) =>
      null;

  R visitFunctionType(covariant FunctionType type, A argument) => null;

  R visitInterfaceType(covariant InterfaceType type, A argument) => null;

  R visitTypedefType(covariant TypedefType type, A argument) => null;

  R visitDynamicType(covariant DynamicType type, A argument) => null;

  R visitAnyType(covariant AnyType type, A argument) => null;

  R visitFutureOrType(covariant FutureOrType type, A argument) => null;
}

abstract class BaseDartTypeVisitor<R, A> extends DartTypeVisitor<R, A> {
  const BaseDartTypeVisitor();

  R visitType(covariant DartType type, A argument);

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
  R visitAnyType(covariant AnyType type, A argument) =>
      visitType(type, argument);

  @override
  R visitFutureOrType(covariant FutureOrType type, A argument) =>
      visitType(type, argument);
}

abstract class DartTypeSubstitutionVisitor<A>
    extends DartTypeVisitor<DartType, A> {
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
  DartType visitTypeVariableType(covariant TypeVariableType type, A argument) {
    return substituteTypeVariableType(type, argument, true);
  }

  @override
  DartType visitFunctionTypeVariable(
      covariant FunctionTypeVariable type, A argument) {
    // Function type variables are added to the map only for type variables that
    // need to be replaced with updated bounds.
    DartType seen = _map[type];
    if (seen != null) return seen;
    return substituteFunctionTypeVariable(type, argument, true);
  }

  @override
  DartType visitVoidType(covariant VoidType type, A argument) => type;

  @override
  DartType visitFunctionType(covariant FunctionType type, A argument) {
    DartType seen = _map[type];
    if (seen != null) return seen;

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

    return _mapped(
        type,
        FunctionType(
            newReturnType,
            newParameterTypes,
            newOptionalParameterTypes,
            type.namedParameters,
            newNamedParameterTypes,
            newTypeVariables));
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
              FunctionTypeVariable(variable.index);
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

    DartType seen = _map[type];
    if (seen != null) return seen;

    List<DartType> newTypeArguments = _substTypes(typeArguments, argument);
    // Create a new type only if necessary.
    if (identical(typeArguments, newTypeArguments)) {
      return _mapped(type, type);
    }
    return _mapped(type, InterfaceType(type.element, newTypeArguments));
  }

  @override
  DartType visitTypedefType(covariant TypedefType type, A argument) {
    DartType seen = _map[type];
    if (seen != null) return seen;

    List<DartType> newTypeArguments = _substTypes(type.typeArguments, argument);
    FunctionType newUnaliased = visit(type.unaliased, argument);
    // Create a new type only if necessary.
    if (identical(type.typeArguments, newTypeArguments) &&
        identical(type.unaliased, newUnaliased)) {
      return _mapped(type, type);
    }
    return _mapped(
        type, TypedefType(type.element, newTypeArguments, newUnaliased));
  }

  @override
  DartType visitDynamicType(covariant DynamicType type, A argument) => type;

  @override
  DartType visitAnyType(covariant AnyType type, A argument) => type;

  @override
  DartType visitFutureOrType(covariant FutureOrType type, A argument) {
    DartType seen = _map[type];
    if (seen != null) return seen;

    DartType newTypeArgument = visit(type.typeArgument, argument);
    // Create a new type only if necessary.
    if (identical(type.typeArgument, newTypeArgument)) {
      return _mapped(type, type);
    }
    return _mapped(type, FutureOrType(newTypeArgument));
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
    DartType seen = _substitutionVisitor._map[type];
    if (seen != null) return seen != type;
    return !identical(
        type,
        _substitutionVisitor.substituteFunctionTypeVariable(
            type, argument, false));
  }
}

/// A visitor that by default visits the substructure of the type until some
/// visit returns `true`.  The default handers return `false` which will search
/// the whole structure unless overridden.
abstract class DartTypeStructuralPredicateVisitor
    extends DartTypeVisitor<bool, List<FunctionTypeVariable>> {
  const DartTypeStructuralPredicateVisitor();

  bool run(DartType type) => visit(type, null);

  bool handleVoidType(VoidType type) => false;
  bool handleTypeVariableType(TypeVariableType type) => false;
  bool handleBoundFunctionTypeVariable(FunctionTypeVariable type) => false;
  bool handleFreeFunctionTypeVariable(FunctionTypeVariable type) => false;
  bool handleFunctionType(FunctionType type) => false;
  bool handleInterfaceType(InterfaceType type) => false;
  bool handleTypedefType(TypedefType type) => false;
  bool handleDynamicType(DynamicType type) => false;
  bool handleAnyType(AnyType type) => false;
  bool handleFutureOrType(FutureOrType type) => false;

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
  bool visitTypedefType(TypedefType type, List<FunctionTypeVariable> bindings) {
    if (handleTypedefType(type)) return true;
    if (_visitAll(type.typeArguments, bindings)) return true;
    return visit(type.unaliased, bindings);
  }

  @override
  bool visitDynamicType(
          DynamicType type, List<FunctionTypeVariable> bindings) =>
      handleDynamicType(type);

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
  final List<DartType> arguments;
  final List<DartType> parameters;

  SimpleDartTypeSubstitutionVisitor(this.arguments, this.parameters);

  DartType substitute(DartType input) => visit(input, null);

  @override
  DartType substituteTypeVariableType(
      TypeVariableType type, Null _, bool freshReference) {
    int index = this.parameters.indexOf(type);
    if (index != -1) {
      return this.arguments[index];
    }
    // The type variable was not substituted.
    return type;
  }

  @override
  DartType substituteFunctionTypeVariable(
      covariant FunctionTypeVariable type, Null _, bool freshReference) {
    int index = this.parameters.indexOf(type);
    if (index != -1) {
      return this.arguments[index];
    }
    // The function type variable was not substituted.
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
  void visitVoidType(covariant VoidType type, _) {
    _identifier('void');
  }

  @override
  void visitDynamicType(covariant DynamicType type, _) {
    _identifier('dynamic');
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

  @override
  void visitTypedefType(covariant TypedefType type, _) {
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

/// Abstract visitor for determining relations between types.
abstract class AbstractTypeRelation<T extends DartType>
    extends BaseDartTypeVisitor<bool, T> {
  CommonElements get commonElements;

  final _Assumptions assumptions = new _Assumptions();

  /// Ensures that the super hierarchy of [type] is computed.
  void ensureResolved(InterfaceType type) {}

  /// Returns the unaliased version of [type].
  T getUnaliased(T type) => type.unaliased;

  /// Returns [type] as an instance of [cls], or `null` if [type] is not subtype
  /// if [cls].
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls);

  /// Returns the type of the `call` method on [type], or `null` if the class
  /// of [type] does not have a `call` method.
  FunctionType getCallType(InterfaceType type);

  /// Returns the declared bound of [element].
  DartType getTypeVariableBound(TypeVariableEntity element);

  @override
  bool visitType(T t, T s) {
    throw 'internal error: unknown type ${t}';
  }

  @override
  bool visitVoidType(VoidType t, T s) {
    assert(s is! VoidType);
    return false;
  }

  bool invalidTypeArguments(T t, T s);

  bool invalidFunctionReturnTypes(T t, T s);

  bool invalidFunctionParameterTypes(T t, T s);

  bool invalidTypeVariableBounds(T bound, T s);

  bool invalidCallableType(covariant DartType callType, covariant DartType s);

  @override
  bool visitInterfaceType(InterfaceType t, covariant DartType s) {
    ensureResolved(t);

    bool checkTypeArguments(InterfaceType instance, InterfaceType other) {
      List<T> tTypeArgs = instance.typeArguments;
      List<T> sTypeArgs = other.typeArguments;
      assert(tTypeArgs.length == sTypeArgs.length);
      for (int i = 0; i < tTypeArgs.length; i++) {
        if (invalidTypeArguments(tTypeArgs[i], sTypeArgs[i])) {
          return false;
        }
      }
      return true;
    }

    if (s is InterfaceType) {
      InterfaceType instance = asInstanceOf(t, s.element);
      if (instance != null && checkTypeArguments(instance, s)) {
        return true;
      }
    }

    FunctionType callType = getCallType(t);
    if (s == commonElements.functionType && callType != null) {
      return true;
    } else if (s is FunctionType) {
      return callType != null && !invalidCallableType(callType, s);
    }

    return false;
  }

  @override
  bool visitFunctionType(FunctionType t, DartType s) {
    if (s == commonElements.functionType) {
      return true;
    }
    if (s is! FunctionType) return false;
    FunctionType tf = t;
    FunctionType sf = s;
    int typeVariablesCount = getCommonTypeVariablesCount(tf, sf);
    if (typeVariablesCount == null) {
      return false;
    }
    for (int i = 0; i < typeVariablesCount; i++) {
      assumptions.assume(tf.typeVariables[i], sf.typeVariables[i]);
    }
    for (int i = 0; i < typeVariablesCount; i++) {
      if (!tf.typeVariables[i].bound
          ._equals(sf.typeVariables[i].bound, assumptions)) {
        return false;
      }
    }
    if (invalidFunctionReturnTypes(tf.returnType, sf.returnType)) {
      return false;
    }

    bool result = visitFunctionTypeInternal(tf, sf);
    for (int i = 0; i < typeVariablesCount; i++) {
      assumptions.forget(tf.typeVariables[i], sf.typeVariables[i]);
    }
    return result;
  }

  int getCommonTypeVariablesCount(FunctionType t, FunctionType s) {
    if (t.typeVariables.length == s.typeVariables.length) {
      return t.typeVariables.length;
    }
    return null;
  }

  bool visitFunctionTypeInternal(FunctionType tf, FunctionType sf) {
    // TODO(johnniwinther): Rewrite the function subtyping to be more readable
    // but still as efficient.

    // For the comments we use the following abbreviations:
    //  x.p     : parameterTypes on [:x:],
    //  x.o     : optionalParameterTypes on [:x:], and
    //  len(xs) : length of list [:xs:].

    Iterator<T> tps = tf.parameterTypes.iterator;
    Iterator<T> sps = sf.parameterTypes.iterator;
    bool sNotEmpty = sps.moveNext();
    bool tNotEmpty = tps.moveNext();
    tNext() => (tNotEmpty = tps.moveNext());
    sNext() => (sNotEmpty = sps.moveNext());

    bool incompatibleParameters() {
      while (tNotEmpty && sNotEmpty) {
        if (invalidFunctionParameterTypes(tps.current, sps.current)) {
          return true;
        }
        tNext();
        sNext();
      }
      return false;
    }

    if (incompatibleParameters()) return false;
    if (tNotEmpty) {
      // We must have [: len(t.p) <= len(s.p) :].
      return false;
    }
    if (!sf.namedParameters.isEmpty) {
      // We must have [: len(t.p) == len(s.p) :].
      if (sNotEmpty) {
        return false;
      }
      // Since named parameters are globally ordered we can determine the
      // subset relation with a linear search for [:sf.namedParameters:]
      // within [:tf.namedParameters:].
      List<String> tNames = tf.namedParameters;
      List<T> tTypes = tf.namedParameterTypes;
      List<String> sNames = sf.namedParameters;
      List<T> sTypes = sf.namedParameterTypes;
      int tIndex = 0;
      int sIndex = 0;
      while (tIndex < tNames.length && sIndex < sNames.length) {
        if (tNames[tIndex] == sNames[sIndex]) {
          if (invalidFunctionParameterTypes(tTypes[tIndex], sTypes[sIndex])) {
            return false;
          }
          sIndex++;
        }
        tIndex++;
      }
      if (sIndex < sNames.length) {
        // We didn't find all names.
        return false;
      }
    } else {
      // Check the remaining [: s.p :] against [: t.o :].
      tps = tf.optionalParameterTypes.iterator;
      tNext();
      if (incompatibleParameters()) return false;
      if (sNotEmpty) {
        // We must have [: len(t.p) + len(t.o) >= len(s.p) :].
        return false;
      }
      if (!sf.optionalParameterTypes.isEmpty) {
        // Check the remaining [: s.o :] against the remaining [: t.o :].
        sps = sf.optionalParameterTypes.iterator;
        sNext();
        if (incompatibleParameters()) return false;
        if (sNotEmpty) {
          // We didn't find enough parameters:
          // We must have [: len(t.p) + len(t.o) <= len(s.p) + len(s.o) :].
          return false;
        }
      } else {
        if (sNotEmpty) {
          // We must have [: len(t.p) + len(t.o) >= len(s.p) :].
          return false;
        }
      }
    }
    return true;
  }

  @override
  bool visitTypeVariableType(TypeVariableType t, T s) {
    // Identity check is handled in [isSubtype].
    DartType bound = getTypeVariableBound(t.element);
    if (bound.isTypeVariable) {
      // The bound is potentially cyclic so we need to be extra careful.
      Set<TypeVariableEntity> seenTypeVariables = new Set<TypeVariableEntity>();
      seenTypeVariables.add(t.element);
      while (bound.isTypeVariable) {
        TypeVariableType typeVariable = bound;
        if (bound == s) {
          // [t] extends [s].
          return true;
        }
        if (seenTypeVariables.contains(typeVariable.element)) {
          // We have a cycle and have already checked all bounds in the cycle
          // against [s] and can therefore conclude that [t] is not a subtype
          // of [s].
          return false;
        }
        seenTypeVariables.add(typeVariable.element);
        bound = getTypeVariableBound(typeVariable.element);
      }
    }
    if (invalidTypeVariableBounds(bound, s)) return false;
    return true;
  }

  @override
  bool visitFunctionTypeVariable(FunctionTypeVariable t, DartType s) {
    if (!s.isFunctionTypeVariable) return false;
    return assumptions.isAssumed(t, s);
  }
}

abstract class MoreSpecificVisitor<T extends DartType>
    extends AbstractTypeRelation<T> {
  bool isMoreSpecific(T t, T s) {
    if (identical(t, s) ||
        t.isAny ||
        s.isAny ||
        s.treatAsDynamic ||
        s.isVoid ||
        s == commonElements.objectType ||
        t == commonElements.nullType) {
      return true;
    }
    if (t.treatAsDynamic) {
      return false;
    }

    t = getUnaliased(t);
    s = getUnaliased(s);

    return t.accept(this, s);
  }

  @override
  bool invalidTypeArguments(T t, T s) {
    return !isMoreSpecific(t, s);
  }

  @override
  bool invalidFunctionReturnTypes(T t, T s) {
    if (s.treatAsDynamic && t.isVoid) return true;
    return !s.isVoid && !isMoreSpecific(t, s);
  }

  @override
  bool invalidFunctionParameterTypes(T t, T s) {
    return !isMoreSpecific(t, s);
  }

  @override
  bool invalidTypeVariableBounds(T bound, T s) {
    return !isMoreSpecific(bound, s);
  }

  @override
  bool invalidCallableType(covariant DartType callType, covariant DartType s) {
    return !isMoreSpecific(callType, s);
  }

  @override
  bool visitFutureOrType(FutureOrType t, covariant DartType s) {
    return false;
  }
}

/// Type visitor that determines the subtype relation two types.
abstract class SubtypeVisitor<T extends DartType>
    extends MoreSpecificVisitor<T> {
  bool isSubtype(DartType t, DartType s) {
    if (t.isAny || s.isAny) return true;
    if (s.isFutureOr) {
      FutureOrType sFutureOr = s;
      if (isSubtype(t, sFutureOr.typeArgument)) {
        return true;
      } else if (t.isInterfaceType) {
        InterfaceType tInterface = t;
        if (tInterface.element == commonElements.futureClass &&
            isSubtype(
                tInterface.typeArguments.single, sFutureOr.typeArgument)) {
          return true;
        }
      }
    }
    return isMoreSpecific(t, s);
  }

  bool isAssignable(T t, T s) {
    return isSubtype(t, s) || isSubtype(s, t);
  }

  @override
  bool invalidTypeArguments(T t, T s) {
    return !isSubtype(t, s);
  }

  @override
  bool invalidFunctionReturnTypes(T t, T s) {
    return !isSubtype(t, s);
  }

  @override
  bool invalidFunctionParameterTypes(T t, T s) {
    return !isSubtype(s, t);
  }

  @override
  bool invalidTypeVariableBounds(T bound, T s) {
    return !isSubtype(bound, s);
  }

  @override
  bool invalidCallableType(covariant DartType callType, covariant DartType s) {
    return !isSubtype(callType, s);
  }

  @override
  bool visitFutureOrType(FutureOrType t, covariant DartType s) {
    if (s.isFutureOr) {
      FutureOrType sFutureOr = s;
      return isSubtype(t.typeArgument, sFutureOr.typeArgument);
    }
    return false;
  }
}

/// Type visitor that determines one type could a subtype of another given the
/// right type variable substitution. The computation is approximate and returns
/// `false` only if we are sure no such substitution exists.
abstract class PotentialSubtypeVisitor<T extends DartType>
    extends SubtypeVisitor<T> {
  bool _assumeInstantiations = true;

  @override
  bool isSubtype(DartType t, DartType s) {
    if (t.isAny || s.isAny) return true;
    if (t is TypeVariableType || s is TypeVariableType) {
      return true;
    }
    if ((t is FunctionTypeVariable || s is FunctionTypeVariable) &&
        _assumeInstantiations) {
      return true;
    }
    return super.isSubtype(t, s);
  }

  @override
  int getCommonTypeVariablesCount(FunctionType t, FunctionType s) {
    if (t.typeVariables.length == s.typeVariables.length) {
      return t.typeVariables.length;
    }
    if (_assumeInstantiations && s.typeVariables.length == 0) {
      return 0;
    }
    return null;
  }

  bool isPotentialSubtype(DartType t, DartType s,
      {bool assumeInstantiations: true}) {
    _assumeInstantiations = assumeInstantiations;
    return isSubtype(t, s);
  }
}

/// Basic interface for the Dart type system.
abstract class DartTypes {
  /// The types defined in 'dart:core'.
  CommonElements get commonElements;

  /// Returns `true` if [t] is a subtype of [s].
  bool isSubtype(DartType t, DartType s);

  /// Returns `true` if [t] is assignable to [s].
  bool isAssignable(DartType t, DartType s);

  /// Returns `true` if [t] might be a subtype of [s] for some values of
  /// type variables in [s] and [t].
  ///
  /// If [assumeInstantiations], generic function types are assumed to be
  /// potentially instantiated.
  bool isPotentialSubtype(DartType t, DartType s,
      {bool assumeInstantiations: true});

  static const int IS_SUBTYPE = 1;
  static const int MAYBE_SUBTYPE = 0;
  static const int NOT_SUBTYPE = -1;

  /// Returns [IS_SUBTYPE], [MAYBE_SUBTYPE], or [NOT_SUBTYPE] if [t] is a
  /// (potential) subtype of [s]
  int computeSubtypeRelation(DartType t, DartType s) {
    // TODO(johnniwinther): Compute this directly in [isPotentialSubtype].
    if (isSubtype(t, s)) return IS_SUBTYPE;
    return isPotentialSubtype(t, s) ? MAYBE_SUBTYPE : NOT_SUBTYPE;
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
}
