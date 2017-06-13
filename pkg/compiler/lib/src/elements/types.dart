// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
/// implementated directly but other entity systems, for instance based directly
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

  /// Is `true` if this type is a malformed type.
  bool get isMalformed => false;

  /// Whether this type contains a type variable.
  bool get containsTypeVariables => false;

  /// Applies [f] to each occurence of a [ResolutionTypeVariableType] within
  /// this type.
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
  DartType subst(List<DartType> arguments, List<DartType> parameters);

  /// Calls the visit method on [visitor] corresponding to this type.
  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument);
}

class InterfaceType extends DartType {
  final ClassEntity element;
  final List<DartType> typeArguments;

  InterfaceType(this.element, this.typeArguments);

  bool get containsTypeVariables =>
      typeArguments.any((type) => type.containsTypeVariables);

  void forEachTypeVariable(f(TypeVariableType variable)) {
    typeArguments.forEach((type) => type.forEachTypeVariable(f));
  }

  InterfaceType subst(List<DartType> arguments, List<DartType> parameters) {
    if (typeArguments.isEmpty) {
      // Return fast on non-generic types.
      return this;
    }
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    List<DartType> newTypeArguments =
        _substTypes(typeArguments, arguments, parameters);
    if (!identical(typeArguments, newTypeArguments)) {
      // Create a new type only if necessary.
      return new InterfaceType(element, newTypeArguments);
    }
    return this;
  }

  bool get treatAsRaw {
    for (DartType type in typeArguments) {
      if (!type.treatAsDynamic) return false;
    }
    return true;
  }

  @override
  R accept<R, A>(DartTypeVisitor visitor, A argument) =>
      visitor.visitInterfaceType(this, argument);

  int get hashCode {
    int hash = element.hashCode;
    for (DartType argument in typeArguments) {
      int argumentHash = argument != null ? argument.hashCode : 0;
      hash = 17 * hash + 3 * argumentHash;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is! InterfaceType) return false;
    return identical(element, other.element) &&
        equalElements(typeArguments, other.typeArguments);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(element.name);
    if (typeArguments.isNotEmpty) {
      sb.write('<');
      bool needsComma = false;
      for (DartType typeArgument in typeArguments) {
        if (needsComma) {
          sb.write(',');
        }
        sb.write(typeArgument);
        needsComma = true;
      }
      sb.write('>');
    }
    return sb.toString();
  }
}

class TypeVariableType extends DartType {
  final TypeVariableEntity element;

  TypeVariableType(this.element);

  bool get isTypeVariable => true;

  bool get containsTypeVariables => true;

  void forEachTypeVariable(f(TypeVariableType variable)) {
    f(this);
  }

  DartType subst(List<DartType> arguments, List<DartType> parameters) {
    assert(arguments.length == parameters.length);
    if (parameters.isEmpty) {
      // Return fast on empty substitutions.
      return this;
    }
    int index = parameters.indexOf(this);
    if (index != -1) {
      return arguments[index];
    }
    // The type variable was not substituted.
    return this;
  }

  @override
  R accept<R, A>(DartTypeVisitor visitor, A argument) =>
      visitor.visitTypeVariableType(this, argument);

  int get hashCode => 17 * element.hashCode;

  bool operator ==(other) {
    if (other is! TypeVariableType) return false;
    return identical(other.element, element);
  }

  String toString() => '${element.typeDeclaration.name}.${element.name}';
}

class VoidType extends DartType {
  const VoidType();

  bool get isVoid => true;

  DartType subst(List<DartType> arguments, List<DartType> parameters) {
    // `void` cannot be substituted.
    return this;
  }

  @override
  R accept<R, A>(DartTypeVisitor visitor, A argument) =>
      visitor.visitVoidType(this, argument);

  int get hashCode => 6007;

  String toString() => 'void';
}

class DynamicType extends DartType {
  const DynamicType();

  @override
  bool get isDynamic => true;

  @override
  bool get treatAsDynamic => true;

  DartType subst(List<DartType> arguments, List<DartType> parameters) {
    // `dynamic` cannot be substituted.
    return this;
  }

  @override
  R accept<R, A>(DartTypeVisitor visitor, A argument) =>
      visitor.visitDynamicType(this, argument);

  int get hashCode => 91;

  String toString() => 'dynamic';
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

  FunctionType(
      this.returnType,
      this.parameterTypes,
      this.optionalParameterTypes,
      this.namedParameters,
      this.namedParameterTypes);

  bool get containsTypeVariables {
    return returnType.containsTypeVariables ||
        parameterTypes.any((type) => type.containsTypeVariables) ||
        optionalParameterTypes.any((type) => type.containsTypeVariables) ||
        namedParameterTypes.any((type) => type.containsTypeVariables);
  }

  void forEachTypeVariable(f(TypeVariableType variable)) {
    returnType.forEachTypeVariable(f);
    parameterTypes.forEach((type) => type.forEachTypeVariable(f));
    optionalParameterTypes.forEach((type) => type.forEachTypeVariable(f));
    namedParameterTypes.forEach((type) => type.forEachTypeVariable(f));
  }

  bool get isFunctionType => true;

  DartType subst(List<DartType> arguments, List<DartType> parameters) {
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    DartType newReturnType = returnType.subst(arguments, parameters);
    bool changed = !identical(newReturnType, returnType);
    List<DartType> newParameterTypes =
        _substTypes(parameterTypes, arguments, parameters);
    List<DartType> newOptionalParameterTypes =
        _substTypes(optionalParameterTypes, arguments, parameters);
    List<DartType> newNamedParameterTypes =
        _substTypes(namedParameterTypes, arguments, parameters);
    if (!changed &&
        (!identical(parameterTypes, newParameterTypes) ||
            !identical(optionalParameterTypes, newOptionalParameterTypes) ||
            !identical(namedParameterTypes, newNamedParameterTypes))) {
      changed = true;
    }
    if (changed) {
      // Create a new type only if necessary.
      return new FunctionType(newReturnType, newParameterTypes,
          newOptionalParameterTypes, namedParameters, newNamedParameterTypes);
    }
    return this;
  }

  @override
  R accept<R, A>(DartTypeVisitor visitor, A argument) =>
      visitor.visitFunctionType(this, argument);

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

  bool operator ==(other) {
    if (other is! FunctionType) return false;
    return returnType == other.returnType &&
        equalElements(parameterTypes, other.parameterTypes) &&
        equalElements(optionalParameterTypes, other.optionalParameterTypes) &&
        equalElements(namedParameters, other.namedParameters) &&
        equalElements(namedParameterTypes, other.namedParameterTypes);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(returnType);
    sb.write(' Function(');
    bool needsComma = false;
    for (DartType parameterType in parameterTypes) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write(parameterType);
      needsComma = true;
    }
    if (optionalParameterTypes.isNotEmpty) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write('[');
      bool needsOptionalComma = false;
      for (DartType typeArgument in optionalParameterTypes) {
        if (needsOptionalComma) {
          sb.write(',');
        }
        sb.write(typeArgument);
        needsOptionalComma = true;
      }
      sb.write(']');
      needsComma = true;
    }
    if (namedParameters.isNotEmpty) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write('{');
      bool needsNamedComma = false;
      for (int index = 0; index < namedParameters.length; index++) {
        if (needsNamedComma) {
          sb.write(',');
        }
        sb.write(namedParameterTypes[index]);
        sb.write(' ');
        sb.write(namedParameters[index]);
        needsNamedComma = true;
      }
      sb.write('}');
    }
    return sb.toString();
  }
}

/// Helper method for performing substitution of a list of types.
///
/// If no types are changed by the substitution, the [types] is returned
/// instead of a newly created list.
List<DartType> _substTypes(
    List<DartType> types, List<DartType> arguments, List<DartType> parameters) {
  bool changed = false;
  List<DartType> result =
      new List<DartType>.generate(types.length, (int index) {
    DartType type = types[index];
    DartType argument = type.subst(arguments, parameters);
    if (!changed && !identical(argument, type)) {
      changed = true;
    }
    return argument;
  });
  // Use the new List only if necessary.
  return changed ? result : types;
}

abstract class DartTypeVisitor<R, A> {
  const DartTypeVisitor();

  R visit(DartType type, A argument) => type.accept(this, argument);

  R visitVoidType(VoidType type, A argument) => null;

  R visitTypeVariableType(TypeVariableType type, A argument) => null;

  R visitFunctionType(FunctionType type, A argument) => null;

  R visitInterfaceType(InterfaceType type, A argument) => null;

  R visitDynamicType(DynamicType type, A argument) => null;
}

abstract class BaseDartTypeVisitor<R, A> extends DartTypeVisitor<R, A> {
  const BaseDartTypeVisitor();

  R visitType(DartType type, A argument);

  @override
  R visitVoidType(VoidType type, A argument) => visitType(type, argument);

  @override
  R visitTypeVariableType(TypeVariableType type, A argument) =>
      visitType(type, argument);

  @override
  R visitFunctionType(FunctionType type, A argument) =>
      visitType(type, argument);

  @override
  R visitInterfaceType(InterfaceType type, A argument) =>
      visitType(type, argument);

  @override
  R visitDynamicType(DynamicType type, A argument) => visitType(type, argument);
}

/// Abstract visitor for determining relations between types.
abstract class AbstractTypeRelation
    extends BaseDartTypeVisitor<bool, DartType> {
  CommonElements get commonElements;

  /// Ensures that the super hierarchy of [type] is computed.
  void ensureResolved(InterfaceType type) {}

  /// Returns the unaliased version of [type].
  DartType getUnaliased(DartType type) => type.unaliased;

  /// Returns [type] as an instance of [cls], or `null` if [type] is not subtype
  /// if [cls].
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls);

  /// Returns the type of the `call` method on [type], or `null` if the class
  /// of [type] does not have a `call` method.
  FunctionType getCallType(InterfaceType type);

  /// Returns the declared bound of [element].
  DartType getTypeVariableBound(TypeVariableEntity element);

  bool visitType(DartType t, DartType s) {
    throw 'internal error: unknown type ${t}';
  }

  bool visitVoidType(VoidType t, DartType s) {
    assert(s is! VoidType);
    return false;
  }

  bool invalidTypeArguments(DartType t, DartType s);

  bool invalidFunctionReturnTypes(DartType t, DartType s);

  bool invalidFunctionParameterTypes(DartType t, DartType s);

  bool invalidTypeVariableBounds(DartType bound, DartType s);

  bool invalidCallableType(DartType callType, DartType s);

  bool visitInterfaceType(InterfaceType t, DartType s) {
    ensureResolved(t);

    bool checkTypeArguments(InterfaceType instance, InterfaceType other) {
      List<DartType> tTypeArgs = instance.typeArguments;
      List<DartType> sTypeArgs = other.typeArguments;
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

  bool visitFunctionType(FunctionType t, DartType s) {
    if (s == commonElements.functionType) {
      return true;
    }
    if (s is! FunctionType) return false;
    FunctionType tf = t;
    FunctionType sf = s;
    if (invalidFunctionReturnTypes(tf.returnType, sf.returnType)) {
      return false;
    }

    // TODO(johnniwinther): Rewrite the function subtyping to be more readable
    // but still as efficient.

    // For the comments we use the following abbreviations:
    //  x.p     : parameterTypes on [:x:],
    //  x.o     : optionalParameterTypes on [:x:], and
    //  len(xs) : length of list [:xs:].

    Iterator<DartType> tps = tf.parameterTypes.iterator;
    Iterator<DartType> sps = sf.parameterTypes.iterator;
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
      List<DartType> tTypes = tf.namedParameterTypes;
      List<String> sNames = sf.namedParameters;
      List<DartType> sTypes = sf.namedParameterTypes;
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

  bool visitTypeVariableType(TypeVariableType t, DartType s) {
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
}

abstract class MoreSpecificVisitor extends AbstractTypeRelation {
  bool isMoreSpecific(DartType t, DartType s) {
    if (identical(t, s) || s.treatAsDynamic || t == commonElements.nullType) {
      return true;
    }
    if (t.isVoid || s.isVoid) {
      return false;
    }
    if (t.treatAsDynamic) {
      return false;
    }
    if (s == commonElements.objectType) {
      return true;
    }
    t = getUnaliased(t);
    s = getUnaliased(s);

    return t.accept(this, s);
  }

  bool invalidTypeArguments(DartType t, DartType s) {
    return !isMoreSpecific(t, s);
  }

  bool invalidFunctionReturnTypes(DartType t, DartType s) {
    if (s.treatAsDynamic && t.isVoid) return true;
    return !s.isVoid && !isMoreSpecific(t, s);
  }

  bool invalidFunctionParameterTypes(DartType t, DartType s) {
    return !isMoreSpecific(t, s);
  }

  bool invalidTypeVariableBounds(DartType bound, DartType s) {
    return !isMoreSpecific(bound, s);
  }

  bool invalidCallableType(DartType callType, DartType s) {
    return !isMoreSpecific(callType, s);
  }
}

/// Type visitor that determines the subtype relation two types.
abstract class SubtypeVisitor extends MoreSpecificVisitor {
  bool isSubtype(DartType t, DartType s) {
    return t.treatAsDynamic || isMoreSpecific(t, s);
  }

  bool isAssignable(DartType t, DartType s) {
    return isSubtype(t, s) || isSubtype(s, t);
  }

  bool invalidTypeArguments(DartType t, DartType s) {
    return !isSubtype(t, s);
  }

  bool invalidFunctionReturnTypes(DartType t, DartType s) {
    return !s.isVoid && !isAssignable(t, s);
  }

  bool invalidFunctionParameterTypes(DartType t, DartType s) {
    return !isAssignable(t, s);
  }

  bool invalidTypeVariableBounds(DartType bound, DartType s) {
    return !isSubtype(bound, s);
  }

  bool invalidCallableType(DartType callType, DartType s) {
    return !isSubtype(callType, s);
  }
}

/// Type visitor that determines one type could a subtype of another given the
/// right type variable substitution. The computation is approximate and returns
/// `false` only if we are sure no such substitution exists.
abstract class PotentialSubtypeVisitor extends SubtypeVisitor {
  bool isSubtype(DartType t, DartType s) {
    if (t is TypeVariableType || s is TypeVariableType) {
      return true;
    }
    return super.isSubtype(t, s);
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
  bool isPotentialSubtype(DartType t, DartType s);

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
  /// For instance `asInstanceOf(List<String>, Iterable) = Iterable<String>`.
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
  Iterable<InterfaceType> getSupertypes(ClassEntity cls);

  /// Returns the type of the `call` method on [type], or `null` if the class
  /// of [type] does not have a `call` method.
  FunctionType getCallType(InterfaceType type);

  /// Checks the type arguments of [type] against the type variable bounds
  /// declared on `type.element`. Calls [checkTypeVariableBound] on each type
  /// argument and bound.
  void checkTypeVariableBounds(
      InterfaceType type,
      void checkTypeVariableBound(InterfaceType type, DartType typeArgument,
          TypeVariableType typeVariable, DartType bound));

  /// Returns the [ClassEntity] which declares the type variables occurring in
  // [type], or `null` if [type] does not contain type variables.
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
