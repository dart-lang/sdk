// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the Dart types hierarchy in 'types.dart' specifically
/// tailored to the resolution phase of the compiler.

library resolution_types;

import 'dart:math' show min;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../common_elements.dart';
import '../ordered_typeset.dart' show OrderedTypeSet;
import '../util/util.dart' show equalElements;
import 'elements.dart';
import 'entities.dart';
import 'modelx.dart' show TypeDeclarationElementX;
import 'names.dart';
import 'types.dart';

enum ResolutionTypeKind {
  FUNCTION,
  INTERFACE,
  TYPEDEF,
  TYPE_VARIABLE,
  MALFORMED_TYPE,
  DYNAMIC,
  VOID,
}

abstract class ResolutionDartType implements DartType {
  String get name;

  ResolutionTypeKind get kind;

  const ResolutionDartType();

  /**
   * Returns the [Element] which declared this type.
   *
   * This can be [ClassElement] for classes, [TypedefElement] for typedefs,
   * [TypeVariableElement] for type variables and [FunctionElement] for
   * function types.
   *
   * Invariant: [element] must be a declaration element.
   */
  Element get element;

  /**
   * Performs the substitution [: [arguments[i]/parameters[i]]this :].
   *
   * The notation is known from this lambda calculus rule:
   *
   *     (lambda x.e0)e1 -> [e1/x]e0.
   *
   * See [ResolutionTypeVariableType] for a motivation for this method.
   *
   * Invariant: There must be the same number of [arguments] and [parameters].
   */
  ResolutionDartType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters);

  /// Performs the substitution of the type arguments of [type] for their
  /// corresponding type variables in this type.
  ResolutionDartType substByContext(GenericType type) {
    return subst(type.typeArguments, type.element.typeVariables);
  }

  /// Computes the unaliased type of this type.
  ///
  /// The unaliased type of a typedef'd type is the unaliased type to which its
  /// name is bound. The unaliased version of any other type is the type itself.
  ///
  /// For example, the unaliased type of `typedef A Func<A,B>(B b)` is the
  /// function type `(B) -> A` and the unaliased type of `Func<int,String>`
  /// is the function type `(String) -> int`.
  // TODO(johnniwinther): Maybe move this to [TypedefType].
  void computeUnaliased(Resolution resolution) {}

  /// Returns the unaliased type of this type.
  ///
  /// The unaliased type of a typedef'd type is the unaliased type to which its
  /// name is bound. The unaliased version of any other type is the type itself.
  ///
  /// For example, the unaliased type of `typedef A Func<A,B>(B b)` is the
  /// function type `(B) -> A` and the unaliased type of `Func<int,String>`
  /// is the function type `(String) -> int`.
  ResolutionDartType get unaliased => this;

  /**
   * If this type is malformed or a generic type created with the wrong number
   * of type arguments then [userProvidedBadType] holds the bad type provided
   * by the user.
   */
  ResolutionDartType get userProvidedBadType => null;

  /// Is [: true :] if this type has no explict type arguments.
  bool get isRaw => true;

  /// Returns the raw version of this type.
  ResolutionDartType asRaw() => this;

  /// Is [: true :] if this type has no non-dynamic type arguments.
  bool get treatAsRaw => isRaw;

  /// Is [: true :] if this type should be treated as the dynamic type.
  bool get treatAsDynamic => false;

  /// Is [: true :] if this type is the dynamic type.
  bool get isDynamic => kind == ResolutionTypeKind.DYNAMIC;

  /// Is [: true :] if this type is the void type.
  bool get isVoid => kind == ResolutionTypeKind.VOID;

  /// Is [: true :] if this is the type of `Object` from dart:core.
  bool get isObject => false;

  /// Is [: true :] if this type is an interface type.
  bool get isInterfaceType => kind == ResolutionTypeKind.INTERFACE;

  /// Is [: true :] if this type is a typedef.
  bool get isTypedef => kind == ResolutionTypeKind.TYPEDEF;

  /// Is [: true :] if this type is a function type.
  bool get isFunctionType => kind == ResolutionTypeKind.FUNCTION;

  /// Is [: true :] if this type is a type variable.
  bool get isTypeVariable => kind == ResolutionTypeKind.TYPE_VARIABLE;

  /// Is [: true :] if this type is a malformed type.
  bool get isMalformed => false;

  /// Is `true` if this type is declared by an enum.
  bool get isEnumType => false;

  /// Returns an occurrence of a type variable within this type, if any.
  ResolutionTypeVariableType get typeVariableOccurrence => null;

  /// Applies [f] to each occurence of a [ResolutionTypeVariableType] within
  /// this type.
  void forEachTypeVariable(f(ResolutionTypeVariableType variable)) {}

  ResolutionTypeVariableType _findTypeVariableOccurrence(
      List<ResolutionDartType> types) {
    for (ResolutionDartType type in types) {
      ResolutionTypeVariableType typeVariable = type.typeVariableOccurrence;
      if (typeVariable != null) {
        return typeVariable;
      }
    }
    return null;
  }

  /// Is [: true :] if this type contains any type variables.
  bool get containsTypeVariables => typeVariableOccurrence != null;

  /// Returns a textual representation of this type as if it was the type
  /// of a member named [name].
  String getStringAsDeclared(String name) {
    return new TypeDeclarationFormatter().format(this, name);
  }

  R accept<R, A>(covariant ResolutionDartTypeVisitor<R, A> visitor, A argument);

  void visitChildren<R, A>(
      ResolutionDartTypeVisitor<R, A> visitor, A argument) {}

  static void visitList<R, A>(List<ResolutionDartType> types,
      ResolutionDartTypeVisitor<R, A> visitor, A argument) {
    for (ResolutionDartType type in types) {
      type.accept(visitor, argument);
    }
  }

  /// Returns a [ResolutionDartType] which corresponds to [this] except that
  /// each contained [MethodTypeVariableType] is replaced by a
  /// [ResolutionDynamicType].
  /// GENERIC_METHODS: Temporary, only used with '--generic-method-syntax'.
  ResolutionDartType get dynamifyMethodTypeVariableType => this;

  /// Returns true iff [this] is or contains a [MethodTypeVariableType].
  /// GENERIC_METHODS: Temporary, only used with '--generic-method-syntax'
  bool get containsMethodTypeVariableType => false;
}

/**
 * Represents a type variable, that is the type parameters of a class type.
 *
 * For example, in [: class Array<E> { ... } :], E is a type variable.
 *
 * Each class should have its own unique type variables, one for each type
 * parameter. A class with type parameters is said to be parameterized or
 * generic.
 *
 * Non-static members, constructors, and factories of generic
 * class/interface can refer to type variables of the current class
 * (not of supertypes).
 *
 * When using a generic type, also known as an application or
 * instantiation of the type, the actual type arguments should be
 * substituted for the type variables in the class declaration.
 *
 * For example, given a box, [: class Box<T> { T value; } :], the
 * type of the expression [: new Box<String>().value :] is
 * [: String :] because we must substitute [: String :] for the
 * the type variable [: T :].
 */
class ResolutionTypeVariableType extends ResolutionDartType
    implements TypeVariableType {
  final TypeVariableElement element;

  ResolutionTypeVariableType(this.element);

  ResolutionTypeKind get kind => ResolutionTypeKind.TYPE_VARIABLE;

  String get name => element.name;

  ResolutionDartType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters) {
    assert(arguments.length == parameters.length);
    if (parameters.isEmpty) {
      // Return fast on empty substitutions.
      return this;
    }
    for (int index = 0; index < arguments.length; index++) {
      ResolutionTypeVariableType parameter = parameters[index];
      ResolutionDartType argument = arguments[index];
      if (parameter == this) {
        return argument;
      }
    }
    // The type variable was not substituted.
    return this;
  }

  ResolutionTypeVariableType get typeVariableOccurrence => this;

  void forEachTypeVariable(f(ResolutionTypeVariableType variable)) {
    f(this);
  }

  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitTypeVariableType(this, argument);
  }

  int get hashCode => 17 * element.hashCode;

  bool operator ==(other) {
    if (other is! ResolutionTypeVariableType) return false;
    return identical(other.element, element);
  }

  String toString() => '${element.typeDeclaration.name}.$name';
}

/// Provides a thin model of method type variables: They are treated as if
/// their value were `dynamic` when used in a type annotation, and as a
/// malformed type when used in an `as` or `is` expression.
class MethodTypeVariableType extends ResolutionTypeVariableType {
  MethodTypeVariableType(TypeVariableElement element) : super(element);

  @override
  bool get treatAsDynamic => true;

  @override
  bool get isMalformed => true;

  @override
  ResolutionDartType get dynamifyMethodTypeVariableType =>
      const ResolutionDynamicType();

  @override
  get containsMethodTypeVariableType => true;
}

class ResolutionVoidType extends ResolutionDartType implements VoidType {
  const ResolutionVoidType();

  ResolutionTypeKind get kind => ResolutionTypeKind.VOID;

  String get name => 'void';

  Element get element => null;

  ResolutionDartType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters) {
    // Void cannot be substituted.
    return this;
  }

  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitVoidType(this, argument);
  }

  String toString() => name;

  int get hashCode => 6007;
}

class MalformedType extends ResolutionDartType {
  final ErroneousElement element;

  /**
   * [declaredType] holds the type which the user wrote in code.
   *
   * For instance, for a resolved but malformed type like [: Map<String> :] the
   * [declaredType] is [: Map<String> :] whereas for an unresolved type
   * [userProvidedBadType] is [: null :].
   */
  final ResolutionDartType userProvidedBadType;

  /**
   * Type arguments for the malformed typed, if these cannot fit in the
   * [declaredType].
   *
   * This field is for instance used for [: dynamic<int> :] and [: T<int> :]
   * where [: T :] is a type variable, in which case [declaredType] holds
   * [: dynamic :] and [: T :], respectively, or for [: X<int> :] where [: X :]
   * is not resolved or does not imply a type.
   */
  final List<ResolutionDartType> typeArguments;

  final int hashCode = _nextHash = (_nextHash + 1).toUnsigned(30);
  static int _nextHash = 43765;

  MalformedType(this.element, this.userProvidedBadType,
      [this.typeArguments = null]);

  ResolutionTypeKind get kind => ResolutionTypeKind.MALFORMED_TYPE;

  String get name => element.name;

  ResolutionDartType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters) {
    // Malformed types are not substitutable.
    return this;
  }

  // Malformed types are treated as dynamic.
  bool get treatAsDynamic => true;

  @override
  bool get isMalformed => true;

  R accept<R, A>(
      covariant ResolutionDartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitMalformedType(this, argument);
  }

  String toString() {
    var sb = new StringBuffer();
    if (typeArguments != null) {
      if (userProvidedBadType != null) {
        sb.write(userProvidedBadType.name);
      } else {
        sb.write(element.name);
      }
      if (!typeArguments.isEmpty) {
        sb.write('<');
        sb.write(typeArguments.join(', '));
        sb.write('>');
      }
    } else {
      sb.write(userProvidedBadType.toString());
    }
    return sb.toString();
  }
}

abstract class GenericType extends ResolutionDartType {
  final TypeDeclarationElement element;
  final List<ResolutionDartType> typeArguments;

  GenericType(
      TypeDeclarationElement element, List<ResolutionDartType> typeArguments,
      {bool checkTypeArgumentCount: true})
      : this.element = element,
        this.typeArguments = typeArguments,
        this.containsMethodTypeVariableType =
            typeArguments.any(_typeContainsMethodTypeVariableType) {
    assert(
        element != null,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE, "Missing element for generic type."));
    assert(() {
      if (!checkTypeArgumentCount) return true;
      if (element is TypeDeclarationElementX) {
        return element.thisTypeCache == null ||
            typeArguments.length == element.typeVariables.length;
      }
      return true;
    },
        failedAt(
            element,
            'Invalid type argument count on ${element.thisType}. '
            'Provided type arguments: $typeArguments.'));
  }

  /// Creates a new instance of this type using the provided type arguments.
  GenericType createInstantiation(List<ResolutionDartType> newTypeArguments);

  GenericType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters) {
    if (typeArguments.isEmpty) {
      // Return fast on non-generic types.
      return this;
    }
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    List<ResolutionDartType> newTypeArguments =
        Types.substTypes(typeArguments, arguments, parameters);
    if (!identical(typeArguments, newTypeArguments)) {
      // Create a new type only if necessary.
      return createInstantiation(newTypeArguments);
    }
    return this;
  }

  ResolutionTypeVariableType get typeVariableOccurrence {
    return _findTypeVariableOccurrence(typeArguments);
  }

  void forEachTypeVariable(f(ResolutionTypeVariableType variable)) {
    for (ResolutionDartType type in typeArguments) {
      type.forEachTypeVariable(f);
    }
  }

  void visitChildren<R, A>(
      ResolutionDartTypeVisitor<R, A> visitor, var argument) {
    ResolutionDartType.visitList(typeArguments, visitor, argument);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(name);
    if (!isRaw) {
      sb.write('<');
      sb.write(typeArguments.join(', '));
      sb.write('>');
    }
    return sb.toString();
  }

  @override
  final bool containsMethodTypeVariableType;

  @override
  ResolutionDartType get dynamifyMethodTypeVariableType {
    if (!containsMethodTypeVariableType) return this;
    List<ResolutionDartType> newTypeArguments = typeArguments
        .map((ResolutionDartType type) => type.dynamifyMethodTypeVariableType)
        .toList();
    return createInstantiation(newTypeArguments);
  }

  int get hashCode {
    int hash = element.hashCode;
    for (ResolutionDartType argument in typeArguments) {
      int argumentHash = argument != null ? argument.hashCode : 0;
      hash = 17 * hash + 3 * argumentHash;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is! GenericType) return false;
    return kind == other.kind &&
        element == other.element &&
        equalElements(typeArguments, other.typeArguments);
  }

  /// Returns `true` if the declaration of this type has type variables.
  bool get isGeneric => !typeArguments.isEmpty;

  bool get isRaw => typeArguments.isEmpty || identical(this, element.rawType);

  GenericType asRaw() => element.rawType;

  bool get treatAsRaw {
    if (isRaw) return true;
    for (ResolutionDartType type in typeArguments) {
      if (!type.treatAsDynamic) return false;
    }
    return true;
  }
}

class ResolutionInterfaceType extends GenericType implements InterfaceType {
  int _hashCode;

  ResolutionInterfaceType(ClassElement element,
      [List<ResolutionDartType> typeArguments = const <ResolutionDartType>[]])
      : super(element, typeArguments) {
    assert(element.isDeclaration, failedAt(element));
  }

  ResolutionInterfaceType.forUserProvidedBadType(ClassElement element,
      [List<ResolutionDartType> typeArguments = const <ResolutionDartType>[]])
      : super(element, typeArguments, checkTypeArgumentCount: false);

  ClassElement get element => super.element;

  ResolutionTypeKind get kind => ResolutionTypeKind.INTERFACE;

  String get name => element.name;

  bool get isObject => element.isObject;

  bool get isEnumType => element.isEnumClass;

  ResolutionInterfaceType createInstantiation(
      List<ResolutionDartType> newTypeArguments) {
    return new ResolutionInterfaceType(element, newTypeArguments);
  }

  /**
   * Returns the type as an instance of class [other], if possible, null
   * otherwise.
   */
  ResolutionInterfaceType asInstanceOf(ClassElement other) {
    other = other.declaration;
    if (element == other) return this;
    ResolutionInterfaceType supertype = element.asInstanceOf(other);
    if (supertype != null) {
      List<ResolutionDartType> arguments = Types.substTypes(
          supertype.typeArguments, typeArguments, element.typeVariables);
      return new ResolutionInterfaceType(supertype.element, arguments);
    }
    return null;
  }

  MemberSignature lookupInterfaceMember(Name name) {
    MemberSignature member = element.lookupInterfaceMember(name);
    if (member != null && isGeneric) {
      return new InterfaceMember(this, member);
    }
    return member;
  }

  MemberSignature lookupClassMember(Name name) {
    MemberSignature member = element.lookupClassMember(name);
    if (member != null && isGeneric) {
      return new InterfaceMember(this, member);
    }
    return member;
  }

  int get hashCode => _hashCode ??= super.hashCode;

  ResolutionInterfaceType asRaw() => super.asRaw();

  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitInterfaceType(this, argument);
  }

  /// Returns the type of the 'call' method in this interface type, or
  /// `null` if the interface type has no 'call' method.
  ResolutionFunctionType get callType {
    ResolutionFunctionType type = element.callType;
    return type != null && isGeneric ? type.substByContext(this) : type;
  }

  ResolutionInterfaceType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters) {
    return super.subst(arguments, parameters);
  }
}

/// Special subclass of [ResolutionInterfaceType] used for generic interface
/// types created with the wrong number of type arguments.
///
/// The type uses `dynamic` for all it s type arguments.
class BadInterfaceType extends ResolutionInterfaceType {
  final ResolutionInterfaceType userProvidedBadType;

  BadInterfaceType(
      ClassElement element, ResolutionInterfaceType this.userProvidedBadType)
      : super(element, element.rawType.typeArguments);

  String toString() {
    return userProvidedBadType.toString();
  }
}

/**
 * Special subclass of [ResolutionTypedefType] used for generic typedef types
 * created with the wrong number of type arguments.
 *
 * The type uses [:dynamic:] for all it s type arguments.
 */
class BadTypedefType extends ResolutionTypedefType {
  final ResolutionTypedefType userProvidedBadType;

  BadTypedefType(
      TypedefElement element, ResolutionTypedefType this.userProvidedBadType)
      : super(element, element.rawType.typeArguments);

  String toString() {
    return userProvidedBadType.toString();
  }
}

class ResolutionFunctionType extends ResolutionDartType
    implements FunctionType {
  final FunctionTypedElement element;
  final ResolutionDartType returnType;
  final List<ResolutionDartType> parameterTypes;
  final List<ResolutionDartType> optionalParameterTypes;

  /**
   * The names of the named parameters ordered lexicographically.
   */
  final List<String> namedParameters;

  /**
   * The types of the named parameters in the order corresponding to the
   * [namedParameters].
   */
  final List<ResolutionDartType> namedParameterTypes;

  factory ResolutionFunctionType(FunctionTypedElement element,
      [ResolutionDartType returnType = const ResolutionDynamicType(),
      List<ResolutionDartType> parameterTypes = const <ResolutionDartType>[],
      List<ResolutionDartType> optionalParameterTypes =
          const <ResolutionDartType>[],
      List<String> namedParameters = const <String>[],
      List<ResolutionDartType> namedParameterTypes =
          const <ResolutionDartType>[]]) {
    assert(element != null, failedAt(CURRENT_ELEMENT_SPANNABLE));
    assert(element.isDeclaration, failedAt(element));
    return new ResolutionFunctionType.internal(
        element,
        returnType,
        parameterTypes,
        optionalParameterTypes,
        namedParameters,
        namedParameterTypes);
  }

  factory ResolutionFunctionType.synthesized(
      [ResolutionDartType returnType = const ResolutionDynamicType(),
      List<ResolutionDartType> parameterTypes = const <ResolutionDartType>[],
      List<ResolutionDartType> optionalParameterTypes =
          const <ResolutionDartType>[],
      List<String> namedParameters = const <String>[],
      List<ResolutionDartType> namedParameterTypes =
          const <ResolutionDartType>[]]) {
    return new ResolutionFunctionType.internal(null, returnType, parameterTypes,
        optionalParameterTypes, namedParameters, namedParameterTypes);
  }

  factory ResolutionFunctionType.generalized(
      ResolutionDartType returnType,
      List<ResolutionDartType> parameterTypes,
      List<ResolutionDartType> optionalParameterTypes,
      List<String> namedParameters,
      List<ResolutionDartType> namedParameterTypes) {
    return new ResolutionFunctionType.internal(null, returnType, parameterTypes,
        optionalParameterTypes, namedParameters, namedParameterTypes);
  }

  ResolutionFunctionType.internal(FunctionTypedElement this.element,
      [ResolutionDartType returnType = const ResolutionDynamicType(),
      List<ResolutionDartType> parameterTypes = const <ResolutionDartType>[],
      List<ResolutionDartType> optionalParameterTypes =
          const <ResolutionDartType>[],
      List<String> namedParameters = const <String>[],
      List<ResolutionDartType> namedParameterTypes =
          const <ResolutionDartType>[]])
      : this.returnType = returnType,
        this.parameterTypes = parameterTypes,
        this.optionalParameterTypes = optionalParameterTypes,
        this.namedParameters = namedParameters,
        this.namedParameterTypes = namedParameterTypes,
        this.containsMethodTypeVariableType = returnType
                .containsMethodTypeVariableType ||
            parameterTypes.any(_typeContainsMethodTypeVariableType) ||
            optionalParameterTypes.any(_typeContainsMethodTypeVariableType) ||
            namedParameterTypes.any(_typeContainsMethodTypeVariableType) {
    assert(element == null || element.isDeclaration,
        failedAt(CURRENT_ELEMENT_SPANNABLE));
    // Assert that optional and named parameters are not used at the same time.
    assert(optionalParameterTypes.isEmpty || namedParameterTypes.isEmpty);
    assert(namedParameters.length == namedParameterTypes.length);
  }

  ResolutionTypeKind get kind => ResolutionTypeKind.FUNCTION;

  ResolutionDartType getNamedParameterType(String name) {
    for (int i = 0; i < namedParameters.length; i++) {
      if (namedParameters[i] == name) {
        return namedParameterTypes[i];
      }
    }
    return null;
  }

  ResolutionDartType subst(covariant List<ResolutionDartType> arguments,
      covariant List<ResolutionDartType> parameters) {
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    ResolutionDartType newReturnType = returnType.subst(arguments, parameters);
    bool changed = !identical(newReturnType, returnType);
    List<ResolutionDartType> newParameterTypes =
        Types.substTypes(parameterTypes, arguments, parameters);
    List<ResolutionDartType> newOptionalParameterTypes =
        Types.substTypes(optionalParameterTypes, arguments, parameters);
    List<ResolutionDartType> newNamedParameterTypes =
        Types.substTypes(namedParameterTypes, arguments, parameters);
    if (!changed &&
        (!identical(parameterTypes, newParameterTypes) ||
            !identical(optionalParameterTypes, newOptionalParameterTypes) ||
            !identical(namedParameterTypes, newNamedParameterTypes))) {
      changed = true;
    }
    if (changed) {
      // Create a new type only if necessary.
      return new ResolutionFunctionType.internal(
          element,
          newReturnType,
          newParameterTypes,
          newOptionalParameterTypes,
          namedParameters,
          newNamedParameterTypes);
    }
    return this;
  }

  ResolutionTypeVariableType get typeVariableOccurrence {
    ResolutionTypeVariableType typeVariableType =
        returnType.typeVariableOccurrence;
    if (typeVariableType != null) return typeVariableType;

    typeVariableType = _findTypeVariableOccurrence(parameterTypes);
    if (typeVariableType != null) return typeVariableType;

    typeVariableType = _findTypeVariableOccurrence(optionalParameterTypes);
    if (typeVariableType != null) return typeVariableType;

    return _findTypeVariableOccurrence(namedParameterTypes);
  }

  void forEachTypeVariable(f(ResolutionTypeVariableType variable)) {
    returnType.forEachTypeVariable(f);
    parameterTypes.forEach((ResolutionDartType type) {
      type.forEachTypeVariable(f);
    });
    optionalParameterTypes.forEach((ResolutionDartType type) {
      type.forEachTypeVariable(f);
    });
    namedParameterTypes.forEach((ResolutionDartType type) {
      type.forEachTypeVariable(f);
    });
  }

  R accept<R, A>(covariant DartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitFunctionType(this, argument);
  }

  void visitChildren<R, A>(
      ResolutionDartTypeVisitor<R, A> visitor, var argument) {
    returnType.accept(visitor, argument);
    ResolutionDartType.visitList(parameterTypes, visitor, argument);
    ResolutionDartType.visitList(optionalParameterTypes, visitor, argument);
    ResolutionDartType.visitList(namedParameterTypes, visitor, argument);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('(');
    sb.write(parameterTypes.join(', '));
    bool first = parameterTypes.isEmpty;
    if (!optionalParameterTypes.isEmpty) {
      if (!first) {
        sb.write(', ');
      }
      sb.write('[');
      sb.write(optionalParameterTypes.join(', '));
      sb.write(']');
      first = false;
    }
    if (!namedParameterTypes.isEmpty) {
      if (!first) {
        sb.write(', ');
      }
      sb.write('{');
      first = true;
      for (int i = 0; i < namedParameters.length; i++) {
        if (!first) {
          sb.write(', ');
        }
        sb.write(namedParameterTypes[i]);
        sb.write(' ');
        sb.write(namedParameters[i]);
        first = false;
      }
      sb.write('}');
    }
    sb.write(') -> ${returnType}');
    return sb.toString();
  }

  String get name => 'Function';

  @override
  ResolutionDartType get dynamifyMethodTypeVariableType {
    if (!containsMethodTypeVariableType) return this;
    ResolutionDartType eraseIt(ResolutionDartType type) =>
        type.dynamifyMethodTypeVariableType;
    ResolutionDartType newReturnType =
        returnType.dynamifyMethodTypeVariableType;
    List<ResolutionDartType> newParameterTypes =
        parameterTypes.map(eraseIt).toList();
    List<ResolutionDartType> newOptionalParameterTypes =
        optionalParameterTypes.map(eraseIt).toList();
    List<ResolutionDartType> newNamedParameterTypes =
        namedParameterTypes.map(eraseIt).toList();
    return new ResolutionFunctionType.internal(
        element,
        newReturnType,
        newParameterTypes,
        newOptionalParameterTypes,
        namedParameters,
        newNamedParameterTypes);
  }

  @override
  final bool containsMethodTypeVariableType;

  int get hashCode {
    int hash = 3 * returnType.hashCode;
    for (ResolutionDartType parameter in parameterTypes) {
      hash = 17 * hash + 5 * parameter.hashCode;
    }
    for (ResolutionDartType parameter in optionalParameterTypes) {
      hash = 19 * hash + 7 * parameter.hashCode;
    }
    for (String name in namedParameters) {
      hash = 23 * hash + 11 * name.hashCode;
    }
    for (ResolutionDartType parameter in namedParameterTypes) {
      hash = 29 * hash + 13 * parameter.hashCode;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is! ResolutionFunctionType) return false;
    return returnType == other.returnType &&
        equalElements(parameterTypes, other.parameterTypes) &&
        equalElements(optionalParameterTypes, other.optionalParameterTypes) &&
        equalElements(namedParameters, other.namedParameters) &&
        equalElements(namedParameterTypes, other.namedParameterTypes);
  }
}

bool _typeContainsMethodTypeVariableType(ResolutionDartType type) =>
    type.containsMethodTypeVariableType;

class ResolutionTypedefType extends GenericType {
  ResolutionDartType _unaliased;

  ResolutionTypedefType(TypedefElement element,
      [List<ResolutionDartType> typeArguments = const <ResolutionDartType>[]])
      : super(element, typeArguments);

  ResolutionTypedefType.forUserProvidedBadType(TypedefElement element,
      [List<ResolutionDartType> typeArguments = const <ResolutionDartType>[]])
      : super(element, typeArguments, checkTypeArgumentCount: false);

  TypedefElement get element => super.element;

  ResolutionTypeKind get kind => ResolutionTypeKind.TYPEDEF;

  String get name => element.name;

  ResolutionTypedefType createInstantiation(
      List<ResolutionDartType> newTypeArguments) {
    return new ResolutionTypedefType(element, newTypeArguments);
  }

  void computeUnaliased(Resolution resolution) {
    if (_unaliased == null) {
      element.ensureResolved(resolution);
      if (element.isMalformed) {
        _unaliased = const ResolutionDynamicType();
        return;
      }
      element.checkCyclicReference(resolution);
      element.alias.computeUnaliased(resolution);
      _unaliased = element.alias.unaliased.substByContext(this);
    }
  }

  ResolutionDartType get unaliased {
    if (_unaliased == null) {
      ResolutionDartType definition = element.alias.unaliased;
      _unaliased = definition.substByContext(this);
    }
    return _unaliased;
  }

  int get hashCode => super.hashCode;

  ResolutionTypedefType asRaw() => super.asRaw();

  R accept<R, A>(
      covariant ResolutionDartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitTypedefType(this, argument);
  }
}

/**
 * Special type for the `dynamic` type.
 */
class ResolutionDynamicType extends ResolutionDartType implements DynamicType {
  const ResolutionDynamicType();

  Element get element => null;

  String get name => 'dynamic';

  bool get treatAsDynamic => true;

  ResolutionTypeKind get kind => ResolutionTypeKind.DYNAMIC;

  ResolutionDartType subst(covariant List<ResolutionDartType> arguments,
          covariant List<ResolutionDartType> parameters) =>
      this;

  R accept<R, A>(DartTypeVisitor<R, A> visitor, A argument) {
    return visitor.visitDynamicType(this, argument);
  }

  int get hashCode => 91;

  String toString() => name;
}

/**
 * [InterfaceMember] encapsulates a member (method, field, property) with
 * the types of the declarer and receiver in order to do substitution on the
 * member type.
 *
 * Consider for instance these classes and the variable `B<String> b`:
 *
 *     class A<E> {
 *       E field;
 *     }
 *     class B<F> extends A<F> {}
 *
 * In an [InterfaceMember] for `b.field` the [receiver] is the type
 * `B<String>` and the declarer is the type `A<F>`, which is the supertype of
 * `B<F>` from which `field` has been inherited. To compute the type of
 * `b.field` we must first substitute `E` by `F` using the relation between
 * `A<E>` and `A<F>`, and then `F` by `String` using the relation between
 * `B<F>` and `B<String>`.
 */
class InterfaceMember implements MemberSignature {
  final ResolutionInterfaceType instance;
  final MemberSignature member;

  InterfaceMember(this.instance, this.member);

  Name get name => member.name;

  ResolutionDartType get type => member.type.substByContext(instance);

  ResolutionFunctionType get functionType =>
      member.functionType.substByContext(instance);

  bool get isGetter => member.isGetter;

  bool get isSetter => member.isSetter;

  bool get isMethod => member.isMethod;

  Iterable<Member> get declarations => member.declarations;
}

abstract class ResolutionDartTypeVisitor<R, A> extends DartTypeVisitor<R, A> {
  const ResolutionDartTypeVisitor();

  R visitMalformedType(MalformedType type, A argument) => null;

  R visitTypedefType(ResolutionTypedefType type, A argument) => null;
}

abstract class BaseResolutionDartTypeVisitor<R, A>
    extends BaseDartTypeVisitor<R, A>
    implements ResolutionDartTypeVisitor<R, A> {
  const BaseResolutionDartTypeVisitor();

  @override
  R visitMalformedType(MalformedType type, A argument) =>
      visitType(type, argument);

  R visitGenericType(GenericType type, A argument) => visitType(type, argument);

  @override
  R visitInterfaceType(covariant ResolutionInterfaceType type, A argument) =>
      visitGenericType(type, argument);

  @override
  R visitTypedefType(ResolutionTypedefType type, A argument) =>
      visitGenericType(type, argument);
}

abstract class AbstractTypeRelationMixin
    implements
        AbstractTypeRelation<ResolutionDartType>,
        ResolutionDartTypeVisitor<bool, ResolutionDartType> {
  Resolution get resolution;

  @override
  CommonElements get commonElements => resolution.commonElements;

  /// Ensures that the super hierarchy of [type] is computed.
  void ensureResolved(covariant ResolutionInterfaceType type) {
    // TODO(johnniwinther): Currently needed since literal types like int,
    // double, bool etc. might not have been resolved yet.
    type.element.ensureResolved(resolution);
  }

  /// Returns the unaliased version of [type].
  ResolutionDartType getUnaliased(covariant ResolutionDartType type) {
    type.computeUnaliased(resolution);
    return type.unaliased;
  }

  @override
  DartType getTypeVariableBound(covariant TypeVariableElement element) =>
      element.bound;

  @override
  FunctionType getCallType(covariant ResolutionInterfaceType type) =>
      type.callType;

  @override
  InterfaceType asInstanceOf(
          covariant ResolutionInterfaceType type, ClassEntity cls) =>
      type.asInstanceOf(cls);

  /// Handle as dynamic for both subtype and more specific relation to avoid
  /// spurious errors from malformed types.
  bool visitMalformedType(MalformedType t, ResolutionDartType s) => true;

  bool visitTypedefType(ResolutionTypedefType t, ResolutionDartType s) =>
      visitType(t, s);
}

class ResolutionMoreSpecificVisitor
    extends MoreSpecificVisitor<ResolutionDartType>
    with AbstractTypeRelationMixin {
  final Resolution resolution;

  ResolutionMoreSpecificVisitor(this.resolution);
}

class ResolutionSubtypeVisitor extends SubtypeVisitor<ResolutionDartType>
    with AbstractTypeRelationMixin {
  final Resolution resolution;

  ResolutionSubtypeVisitor(this.resolution);
}

class ResolutionPotentialSubtypeVisitor
    extends PotentialSubtypeVisitor<ResolutionDartType>
    with AbstractTypeRelationMixin {
  final Resolution resolution;

  ResolutionPotentialSubtypeVisitor(this.resolution);
}

/**
 * Callback used to check whether the [typeArgument] of [type] is a valid
 * substitute for the bound of [typeVariable]. [bound] holds the bound against
 * which [typeArgument] should be checked.
 */
typedef void CheckTypeVariableBound(GenericType type, DartType typeArgument,
    TypeVariableType typeVariable, DartType bound);

class Types extends DartTypes {
  final Resolution resolution;
  final ResolutionMoreSpecificVisitor moreSpecificVisitor;
  final ResolutionSubtypeVisitor subtypeVisitor;
  final ResolutionPotentialSubtypeVisitor potentialSubtypeVisitor;

  CommonElements get commonElements => resolution.commonElements;

  DiagnosticReporter get reporter => resolution.reporter;

  Types(Resolution resolution)
      : this.resolution = resolution,
        this.moreSpecificVisitor =
            new ResolutionMoreSpecificVisitor(resolution),
        this.subtypeVisitor = new ResolutionSubtypeVisitor(resolution),
        this.potentialSubtypeVisitor =
            new ResolutionPotentialSubtypeVisitor(resolution);

  Types copy(Resolution resolution) {
    return new Types(resolution);
  }

  @override
  InterfaceType asInstanceOf(
      covariant ResolutionInterfaceType type, ClassEntity cls) {
    return type.asInstanceOf(cls);
  }

  @override
  ResolutionDartType substByContext(covariant ResolutionDartType base,
      covariant ResolutionInterfaceType context) {
    return base.substByContext(context);
  }

  @override
  InterfaceType getThisType(covariant ClassElement cls) => cls.thisType;

  @override
  ResolutionInterfaceType getSupertype(covariant ClassElement cls) =>
      cls.supertype;

  @override
  Iterable<InterfaceType> getSupertypes(covariant ClassElement cls) {
    assert(cls.allSupertypes != null,
        failedAt(cls, 'Supertypes have not been computed for $cls.'));
    return cls.allSupertypes;
  }

  @override
  FunctionType getCallType(covariant ResolutionInterfaceType type) =>
      type.callType;

  /// Flatten [type] by recursively removing enclosing `Future` annotations.
  ///
  /// Defined in the language specification as:
  ///
  ///   If T = Future<S> then flatten(T) = flatten(S).
  ///   Otherwise if T <: Future then let S be a type such that T << Future<S>
  ///   and for all R, if T << Future<R> then S << R. Then flatten(T) =  S.
  ///   In any other circumstance, flatten(T) = T.
  ///
  /// For instance:
  ///     flatten(T) = T
  ///     flatten(Future<T>) = T
  ///     flatten(Future<Future<T>>) = T
  ///
  /// This method is used in the static typing of await and type checking of
  /// return.
  ResolutionDartType flatten(ResolutionDartType type) {
    if (type is ResolutionInterfaceType) {
      if (type.element == commonElements.futureClass) {
        // T = Future<S>
        return flatten(type.typeArguments.first);
      }
      ResolutionInterfaceType futureType =
          type.asInstanceOf(commonElements.futureClass);
      if (futureType != null) {
        // T << Future<S>
        return futureType.typeArguments.single;
      }
    }
    return type;
  }

  /// Returns true if [t] is more specific than [s].
  bool isMoreSpecific(ResolutionDartType t, ResolutionDartType s) {
    return moreSpecificVisitor.isMoreSpecific(t, s);
  }

  /// Returns the most specific type of [t] and [s] or `null` if neither is more
  /// specific than the other.
  ResolutionDartType getMostSpecific(
      ResolutionDartType t, ResolutionDartType s) {
    if (isMoreSpecific(t, s)) {
      return t;
    } else if (isMoreSpecific(s, t)) {
      return s;
    } else {
      return null;
    }
  }

  /** Returns true if t is a subtype of s */
  bool isSubtype(
      covariant ResolutionDartType t, covariant ResolutionDartType s) {
    return subtypeVisitor.isSubtype(t, s);
  }

  bool isAssignable(
      covariant ResolutionDartType r, covariant ResolutionDartType s) {
    return subtypeVisitor.isAssignable(r, s);
  }

  bool isPotentialSubtype(
      covariant ResolutionDartType t, covariant ResolutionDartType s) {
    // TODO(johnniwinther): Return a set of variable points in the positive
    // cases.
    return potentialSubtypeVisitor.isSubtype(t, s);
  }

  @override
  void checkTypeVariableBounds(
      covariant ResolutionInterfaceType type,
      void checkTypeVariableBound(InterfaceType type, DartType typeArgument,
          TypeVariableType typeVariable, DartType bound)) {
    void f(DartType type, DartType typeArgument, TypeVariableType typeVariable,
            DartType bound) =>
        checkTypeVariableBound(type, typeArgument, typeVariable, bound);
    genericCheckTypeVariableBounds(type, f);
  }

  /**
   * Checks the type arguments of [type] against the type variable bounds
   * declared on [element]. Calls [checkTypeVariableBound] on each type
   * argument and bound.
   */
  void genericCheckTypeVariableBounds(
      GenericType type, CheckTypeVariableBound checkTypeVariableBound) {
    TypeDeclarationElement element = type.element;
    List<ResolutionDartType> typeArguments = type.typeArguments;
    List<ResolutionDartType> typeVariables = element.typeVariables;
    assert(typeVariables.length == typeArguments.length);
    for (int index = 0; index < typeArguments.length; index++) {
      ResolutionTypeVariableType typeVariable = typeVariables[index];
      ResolutionDartType bound =
          typeVariable.element.bound.substByContext(type);
      ResolutionDartType typeArgument = typeArguments[index];
      checkTypeVariableBound(type, typeArgument, typeVariable, bound);
    }
  }

  /**
   * Helper method for performing substitution of a list of types.
   *
   * If no types are changed by the substitution, the [types] is returned
   * instead of a newly created list.
   */
  static List<ResolutionDartType> substTypes(List<ResolutionDartType> types,
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters) {
    bool changed = false;
    List<ResolutionDartType> result =
        new List<ResolutionDartType>.generate(types.length, (index) {
      ResolutionDartType type = types[index];
      ResolutionDartType argument = type.subst(arguments, parameters);
      if (!changed && !identical(argument, type)) {
        changed = true;
      }
      return argument;
    });
    // Use the new List only if necessary.
    return changed ? result : types;
  }

  /**
   * A `compareTo` function that globally orders types using
   * [Elements.compareByPosition] to order types defined by a declaration.
   *
   * The order is:
   * * void
   * * dynamic
   * * interface, typedef, type variables ordered by element order
   *   - interface and typedef of the same element are ordered by
   *     the order of their type arguments
   * * function types, ordered by
   *   - return type
   *   - required parameter types
   *   - optional parameter types
   *   - named parameter names
   *   - named parameter types
   * * malformed types
   * * statement types
   */
  static int compare(ResolutionDartType a, ResolutionDartType b) {
    if (a == b) return 0;
    if (a.isVoid) {
      // [b] is not void => a < b.
      return -1;
    } else if (b.isVoid) {
      // [a] is not void => a > b.
      return 1;
    }
    if (a.isDynamic) {
      // [b] is not dynamic => a < b.
      return -1;
    } else if (b.isDynamic) {
      // [a] is not dynamic => a > b.
      return 1;
    }
    bool isDefinedByDeclaration(ResolutionDartType type) {
      return type.isInterfaceType || type.isTypedef || type.isTypeVariable;
    }

    if (isDefinedByDeclaration(a)) {
      if (isDefinedByDeclaration(b)) {
        int result = Elements.compareByPosition(a.element, b.element);
        if (result != 0) return result;
        if (a.isTypeVariable) {
          return b.isTypeVariable
              ? 0
              : 1; // [b] is not a type variable => a > b.
        } else {
          if (b.isTypeVariable) {
            // [a] is not a type variable => a < b.
            return -1;
          } else {
            return compareList((a as GenericType).typeArguments,
                (b as GenericType).typeArguments);
          }
        }
      } else {
        // [b] is neither an interface, typedef, type variable, dynamic,
        // nor void => a < b.
        return -1;
      }
    } else if (isDefinedByDeclaration(b)) {
      // [a] is neither an interface, typedef, type variable, dynamic,
      // nor void => a > b.
      return 1;
    }
    if (a.isFunctionType) {
      if (b.isFunctionType) {
        ResolutionFunctionType aFunc = a;
        ResolutionFunctionType bFunc = b;
        int result = compare(aFunc.returnType, bFunc.returnType);
        if (result != 0) return result;
        result = compareList(aFunc.parameterTypes, bFunc.parameterTypes);
        if (result != 0) return result;
        result = compareList(
            aFunc.optionalParameterTypes, bFunc.optionalParameterTypes);
        if (result != 0) return result;
        // TODO(karlklose): reuse [compareList].
        Iterator<String> aNames = aFunc.namedParameters.iterator;
        Iterator<String> bNames = bFunc.namedParameters.iterator;
        while (aNames.moveNext() && bNames.moveNext()) {
          int result = aNames.current.compareTo(bNames.current);
          if (result != 0) return result;
        }
        if (aNames.moveNext()) {
          // [aNames] is longer that [bNames] => a > b.
          return 1;
        } else if (bNames.moveNext()) {
          // [bNames] is longer that [aNames] => a < b.
          return -1;
        }
        return compareList(
            aFunc.namedParameterTypes, bFunc.namedParameterTypes);
      } else {
        // [b] is a malformed or statement type => a < b.
        return -1;
      }
    } else if (b.isFunctionType) {
      // [b] is a malformed or statement type => a > b.
      return 1;
    }
    assert(a.isMalformed);
    assert(b.isMalformed);
    // TODO(johnniwinther): Can we do this better?
    return Elements.compareByPosition(a.element, b.element);
  }

  static int compareList(
      List<ResolutionDartType> a, List<ResolutionDartType> b) {
    for (int index = 0; index < min(a.length, b.length); index++) {
      int result = compare(a[index], b[index]);
      if (result != 0) return result;
    }
    if (a.length > b.length) {
      return 1;
    } else if (a.length < b.length) {
      return -1;
    }
    return 0;
  }

  static List<ResolutionDartType> sorted(Iterable<ResolutionDartType> types) {
    return types.toList()..sort(compare);
  }

  /// Computes the least upper bound of two interface types [a] and [b].
  ResolutionInterfaceType computeLeastUpperBoundInterfaces(
      ResolutionInterfaceType a, ResolutionInterfaceType b) {
    /// Returns the set of supertypes of [type] at depth [depth].
    Set<ResolutionDartType> getSupertypesAtDepth(
        ResolutionInterfaceType type, int depth) {
      OrderedTypeSet types = type.element.allSupertypesAndSelf;
      Set<ResolutionDartType> set = new Set<ResolutionDartType>();
      types.forEach(depth, (_supertype) {
        ResolutionInterfaceType supertype = _supertype;
        set.add(supertype.substByContext(type));
      });
      return set;
    }

    ClassElement aClass = a.element;
    ClassElement bClass = b.element;
    int maxCommonDepth = min(aClass.hierarchyDepth, bClass.hierarchyDepth);
    for (int depth = maxCommonDepth; depth >= 0; depth--) {
      Set<ResolutionDartType> aTypeSet = getSupertypesAtDepth(a, depth);
      Set<ResolutionDartType> bTypeSet = getSupertypesAtDepth(b, depth);
      Set<ResolutionDartType> intersection = aTypeSet..retainAll(bTypeSet);
      if (intersection.length == 1) {
        return intersection.first;
      }
    }

    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'No least upper bound computed for $a and $b.');
    return null;
  }

  /// Computes the least upper bound of the types in the longest prefix of [a]
  /// and [b].
  List<ResolutionDartType> computeLeastUpperBoundsTypes(
      List<ResolutionDartType> a, List<ResolutionDartType> b) {
    if (a.isEmpty || b.isEmpty) return const <ResolutionDartType>[];
    int prefixLength = min(a.length, b.length);
    List<ResolutionDartType> types = new List<ResolutionDartType>(prefixLength);
    for (int index = 0; index < prefixLength; index++) {
      types[index] = computeLeastUpperBound(a[index], b[index]);
    }
    return types;
  }

  /// Computes the least upper bound of two function types [a] and [b].
  ///
  /// If the required parameter count of [a] and [b] does not match, `Function`
  /// is returned.
  ///
  /// Otherwise, a function type is returned whose return type and
  /// parameter types are the least upper bound of those of [a] and [b],
  /// respectively. In addition, the optional parameters are the least upper
  /// bound of the longest common prefix of the optional parameters of [a] and
  /// [b], and the named parameters are the least upper bound of those common to
  /// [a] and [b].
  ResolutionDartType computeLeastUpperBoundFunctionTypes(
      ResolutionFunctionType a, ResolutionFunctionType b) {
    if (a.parameterTypes.length != b.parameterTypes.length) {
      ResolutionInterfaceType functionType = commonElements.functionType;
      return functionType;
    }
    ResolutionDartType returnType =
        computeLeastUpperBound(a.returnType, b.returnType);
    List<ResolutionDartType> parameterTypes =
        computeLeastUpperBoundsTypes(a.parameterTypes, b.parameterTypes);
    List<ResolutionDartType> optionalParameterTypes =
        computeLeastUpperBoundsTypes(
            a.optionalParameterTypes, b.optionalParameterTypes);
    List<String> namedParameters = <String>[];
    List<String> aNamedParameters = a.namedParameters;
    List<String> bNamedParameters = b.namedParameters;
    List<ResolutionDartType> namedParameterTypes = <ResolutionDartType>[];
    List<ResolutionDartType> aNamedParameterTypes = a.namedParameterTypes;
    List<ResolutionDartType> bNamedParameterTypes = b.namedParameterTypes;
    int aIndex = 0;
    int bIndex = 0;
    while (
        aIndex < aNamedParameters.length && bIndex < bNamedParameters.length) {
      String aNamedParameter = aNamedParameters[aIndex];
      String bNamedParameter = bNamedParameters[bIndex];
      int result = aNamedParameter.compareTo(bNamedParameter);
      if (result == 0) {
        namedParameters.add(aNamedParameter);
        namedParameterTypes.add(computeLeastUpperBound(
            aNamedParameterTypes[aIndex], bNamedParameterTypes[bIndex]));
      }
      if (result <= 0) {
        aIndex++;
      }
      if (result >= 0) {
        bIndex++;
      }
    }
    return new ResolutionFunctionType.synthesized(returnType, parameterTypes,
        optionalParameterTypes, namedParameters, namedParameterTypes);
  }

  /// Computes the least upper bound of two types of which at least one is a
  /// type variable. The least upper bound of a type variable is defined in
  /// terms of its bound, but to ensure reflexivity we need to check for common
  /// bounds transitively.
  ResolutionDartType computeLeastUpperBoundTypeVariableTypes(
      ResolutionDartType a, ResolutionDartType b) {
    Set<ResolutionDartType> typeVariableBounds = new Set<ResolutionDartType>();
    while (a.isTypeVariable) {
      if (a == b) return a;
      typeVariableBounds.add(a);
      TypeVariableElement element = a.element;
      a = element.bound;
    }
    while (b.isTypeVariable) {
      if (typeVariableBounds.contains(b)) return b;
      TypeVariableElement element = b.element;
      b = element.bound;
    }
    return computeLeastUpperBound(a, b);
  }

  /// Computes the least upper bound for [a] and [b].
  ResolutionDartType computeLeastUpperBound(
      ResolutionDartType a, ResolutionDartType b) {
    if (a == b) return a;

    if (a.isTypeVariable || b.isTypeVariable) {
      return computeLeastUpperBoundTypeVariableTypes(a, b);
    }

    a.computeUnaliased(resolution);
    a = a.unaliased;
    b.computeUnaliased(resolution);
    b = b.unaliased;

    if (a.treatAsDynamic || b.treatAsDynamic)
      return const ResolutionDynamicType();
    if (a.isVoid || b.isVoid) return const ResolutionVoidType();

    if (a.isFunctionType && b.isFunctionType) {
      return computeLeastUpperBoundFunctionTypes(a, b);
    }

    if (a.isFunctionType) {
      ResolutionInterfaceType functionType = commonElements.functionType;
      a = functionType;
    }
    if (b.isFunctionType) {
      ResolutionInterfaceType functionType = commonElements.functionType;
      b = functionType;
    }

    if (a.isInterfaceType && b.isInterfaceType) {
      return computeLeastUpperBoundInterfaces(a, b);
    }
    return const ResolutionDynamicType();
  }

  /// Computes the unaliased type of the first non type variable bound of
  /// [type].
  ///
  /// This is used to normalize malformed types, type variables and typedef
  /// before use in typechecking.
  ///
  /// Malformed types are normalized to `dynamic`. Typedefs are normalized to
  /// their alias, or `dynamic` if cyclic. Type variables are normalized to the
  /// normalized type of their bound, or `Object` if cyclic.
  ///
  /// For instance for these types:
  ///
  ///     class Foo<T extends Bar, S extends T, U extends Baz> {}
  ///     class Bar<X extends Y, Y extends X> {}
  ///     typedef Baz();
  ///
  /// the unaliased bounds types are:
  ///
  ///     unaliasedBound(Foo) = Foo
  ///     unaliasedBound(Bar) = Bar
  ///     unaliasedBound(Unresolved) = `dynamic`
  ///     unaliasedBound(Baz) = ()->dynamic
  ///     unaliasedBound(T) = Bar
  ///     unaliasedBound(S) = unaliasedBound(T) = Bar
  ///     unaliasedBound(U) = unaliasedBound(Baz) = ()->dynamic
  ///     unaliasedBound(X) = unaliasedBound(Y) = `Object`
  ///
  static ResolutionDartType computeUnaliasedBound(
      Resolution resolution, ResolutionDartType type) {
    ResolutionDartType originalType = type;
    while (type.isTypeVariable) {
      ResolutionTypeVariableType variable = type;
      type = variable.element.bound;
      if (type == originalType) {
        ResolutionInterfaceType objectType =
            resolution.commonElements.objectType;
        type = objectType;
      }
    }
    if (type.isMalformed) {
      return const ResolutionDynamicType();
    }
    type.computeUnaliased(resolution);
    return type.unaliased;
  }

  /// Computes the interface type of [type], which is the type that defines
  /// the property of [type].
  ///
  /// For an interface type it is the type itself, for a type variable it is the
  /// interface type of the bound, for function types and typedefs it is the
  /// `Function` type. For other types, like `dynamic`, `void` and malformed
  /// types, there is no interface type and `null` is returned.
  ///
  /// For instance for these types:
  ///
  ///     class Foo<T extends Bar, S extends T, U extends Baz> {}
  ///     class Bar {}
  ///     typedef Baz();
  ///
  /// the interface types are:
  ///
  ///     interfaceType(Foo) = Foo
  ///     interfaceType(Bar) = Bar
  ///     interfaceType(Baz) = interfaceType(()->dynamic) = Function
  ///     interfaceType(T) = interfaceType(Bar) = Bar
  ///     interfaceType(S) = interfaceType(T) = interfaceType(Bar) = Bar
  ///     interfaceType(U) = interfaceType(Baz)
  ///                      = intefaceType(()->dynamic) = Function
  ///
  /// When typechecking `o.foo` the interface type of the static type of `o` is
  /// used to lookup the existence and type of `foo`.
  ///
  static ResolutionInterfaceType computeInterfaceType(
      Resolution resolution, ResolutionDartType type) {
    type = computeUnaliasedBound(resolution, type);
    if (type.treatAsDynamic) {
      return null;
    }
    if (type.isFunctionType) {
      ResolutionInterfaceType functionType =
          resolution.commonElements.functionType;
      type = functionType;
    }
    assert(type.isInterfaceType,
        failedAt(NO_LOCATION_SPANNABLE, "unexpected type kind ${type.kind}."));
    return type;
  }
}

/// Visitor used to compute an instantiation of a generic type that is more
/// specific than a given type.
///
/// The visitor tries to compute constraints for all type variables in the
/// visited type by structurally matching it with the argument type. If the
/// constraints are too complex or the two types are too different, `false`
/// is returned. Otherwise, the [constraintMap] holds the valid constraints.
class MoreSpecificSubtypeVisitor
    extends BaseResolutionDartTypeVisitor<bool, ResolutionDartType> {
  final Types types;
  Map<ResolutionTypeVariableType, ResolutionDartType> constraintMap;

  MoreSpecificSubtypeVisitor(this.types);

  /// Compute an instance of [element] which is more specific than [supertype].
  /// If no instance is found, `null` is returned.
  ///
  /// Note that this computation is a heuristic. It does not find a suggestion
  /// in all possible cases.
  ResolutionInterfaceType computeMoreSpecific(
      ClassElement element, ResolutionInterfaceType supertype) {
    ResolutionInterfaceType supertypeInstance =
        element.thisType.asInstanceOf(supertype.element);
    if (supertypeInstance == null) return null;

    constraintMap = new Map<ResolutionTypeVariableType, ResolutionDartType>();
    element.typeVariables.forEach((ResolutionDartType typeVariable) {
      constraintMap[typeVariable] = const ResolutionDynamicType();
    });
    if (supertypeInstance.accept(this, supertype)) {
      List<ResolutionDartType> variables = element.typeVariables;
      List<ResolutionDartType> typeArguments =
          new List<ResolutionDartType>.generate(
              variables.length, (int index) => constraintMap[variables[index]]);
      return element.thisType.createInstantiation(typeArguments);
    }
    return null;
  }

  bool visitType(
      covariant ResolutionDartType type, ResolutionDartType argument) {
    return types.isMoreSpecific(type, argument);
  }

  bool visitTypes(List<ResolutionDartType> a, List<ResolutionDartType> b) {
    int prefixLength = min(a.length, b.length);
    for (int index = 0; index < prefixLength; index++) {
      if (!a[index].accept(this, b[index])) return false;
    }
    return prefixLength == a.length && a.length == b.length;
  }

  bool visitTypeVariableType(
      covariant ResolutionTypeVariableType type, ResolutionDartType argument) {
    ResolutionDartType constraint =
        types.getMostSpecific(constraintMap[type], argument);
    constraintMap[type] = constraint;
    return constraint != null;
  }

  bool visitFunctionType(
      covariant ResolutionFunctionType type, ResolutionDartType argument) {
    if (argument is ResolutionFunctionType) {
      if (type.parameterTypes.length != argument.parameterTypes.length) {
        return false;
      }
      if (type.optionalParameterTypes.length !=
          argument.optionalParameterTypes.length) {
        return false;
      }
      if (type.namedParameters != argument.namedParameters) {
        return false;
      }

      if (!type.returnType.accept(this, argument.returnType)) return false;
      if (visitTypes(type.parameterTypes, argument.parameterTypes)) {
        return false;
      }
      if (visitTypes(
          type.optionalParameterTypes, argument.optionalParameterTypes)) {
        return false;
      }
      return visitTypes(type.namedParameterTypes, argument.namedParameterTypes);
    }
    return false;
  }

  bool visitGenericType(GenericType type, ResolutionDartType argument) {
    if (argument is GenericType) {
      if (type.element != argument.element) return false;
      return visitTypes(type.typeArguments, argument.typeArguments);
    }
    return false;
  }
}

/// Visitor used to print type annotation like they used in the source code.
/// The visitor is especially for printing a function type like
/// `(Foo,[Bar])->Baz` as `Baz m(Foo a1, [Bar a2])`.
class TypeDeclarationFormatter
    extends BaseResolutionDartTypeVisitor<dynamic, String> {
  Set<String> usedNames;
  StringBuffer sb;

  /// Creates textual representation of [type] as if a member by the [name] were
  /// declared. For instance 'String foo' for `format(String, 'foo')`.
  String format(ResolutionDartType type, String name) {
    sb = new StringBuffer();
    usedNames = new Set<String>();
    type.accept(this, name);
    usedNames = null;
    return sb.toString();
  }

  String createName(String name) {
    if (name != null && !usedNames.contains(name)) {
      usedNames.add(name);
      return name;
    }
    int index = usedNames.length;
    String proposal;
    do {
      proposal = '${name}${index++}';
    } while (usedNames.contains(proposal));
    usedNames.add(proposal);
    return proposal;
  }

  void visit(covariant ResolutionDartType type, [_]) {
    type.accept(this, null);
  }

  void visitTypes(List<ResolutionDartType> types, String prefix) {
    bool needsComma = false;
    for (ResolutionDartType type in types) {
      if (needsComma) {
        sb.write(', ');
      }
      type.accept(this, prefix);
      needsComma = true;
    }
  }

  void visitType(covariant ResolutionDartType type, String name) {
    if (name == null) {
      sb.write(type);
    } else {
      sb.write('$type ${createName(name)}');
    }
  }

  void visitGenericType(GenericType type, String name) {
    sb.write(type.name);
    if (!type.treatAsRaw) {
      sb.write('<');
      visitTypes(type.typeArguments, null);
      sb.write('>');
    }
    if (name != null) {
      sb.write(' ');
      sb.write(createName(name));
    }
  }

  void visitFunctionType(covariant ResolutionFunctionType type, String name) {
    visit(type.returnType);
    sb.write(' ');
    if (name != null) {
      sb.write(name);
    } else {
      sb.write(createName('f'));
    }
    sb.write('(');
    visitTypes(type.parameterTypes, 'a');
    bool needsComma = !type.parameterTypes.isEmpty;
    if (!type.optionalParameterTypes.isEmpty) {
      if (needsComma) {
        sb.write(', ');
      }
      sb.write('[');
      visitTypes(type.optionalParameterTypes, 'a');
      sb.write(']');
      needsComma = true;
    }
    if (!type.namedParameterTypes.isEmpty) {
      if (needsComma) {
        sb.write(', ');
      }
      sb.write('{');
      List<String> namedParameters = type.namedParameters;
      List<ResolutionDartType> namedParameterTypes = type.namedParameterTypes;
      needsComma = false;
      for (int index = 0; index < namedParameters.length; index++) {
        if (needsComma) {
          sb.write(', ');
        }
        namedParameterTypes[index].accept(this, namedParameters[index]);
        needsComma = true;
      }
      sb.write('}');
    }
    sb.write(')');
  }
}
