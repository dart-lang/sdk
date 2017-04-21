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
import 'modelx.dart' show TypeDeclarationElementX;
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
  ResolutionDartType subst(
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters);

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

  accept(DartTypeVisitor visitor, var argument);

  void visitChildren(DartTypeVisitor visitor, var argument) {}

  static void visitList(
      List<ResolutionDartType> types, DartTypeVisitor visitor, var argument) {
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

  ResolutionDartType subst(
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters) {
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

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitTypeVariableType(this, argument);
  }

  int get hashCode => 17 * element.hashCode;

  bool operator ==(other) {
    if (other is! ResolutionTypeVariableType) return false;
    return identical(other.element, element);
  }

  String toString() => name;
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

  ResolutionDartType subst(
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters) {
    // Void cannot be substituted.
    return this;
  }

  accept(DartTypeVisitor visitor, var argument) {
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

  ResolutionDartType subst(
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters) {
    // Malformed types are not substitutable.
    return this;
  }

  // Malformed types are treated as dynamic.
  bool get treatAsDynamic => true;

  @override
  bool get isMalformed => true;

  accept(DartTypeVisitor visitor, var argument) {
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

abstract class GenericType<T extends GenericType> extends ResolutionDartType {
  final TypeDeclarationElement element;
  final List<ResolutionDartType> typeArguments;

  GenericType(
      TypeDeclarationElement element, List<ResolutionDartType> typeArguments,
      {bool checkTypeArgumentCount: true})
      : this.element = element,
        this.typeArguments = typeArguments,
        this.containsMethodTypeVariableType =
            typeArguments.any(_typeContainsMethodTypeVariableType) {
    assert(invariant(CURRENT_ELEMENT_SPANNABLE, element != null,
        message: "Missing element for generic type."));
    assert(invariant(element, () {
      if (!checkTypeArgumentCount) return true;
      if (element is TypeDeclarationElementX) {
        return element.thisTypeCache == null ||
            typeArguments.length == element.typeVariables.length;
      }
      return true;
    },
        message: () => 'Invalid type argument count on ${element.thisType}. '
            'Provided type arguments: $typeArguments.'));
  }

  /// Creates a new instance of this type using the provided type arguments.
  T createInstantiation(List<ResolutionDartType> newTypeArguments);

  T subst(
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters) {
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

  void visitChildren(DartTypeVisitor visitor, var argument) {
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

class ResolutionInterfaceType extends GenericType<ResolutionInterfaceType>
    implements InterfaceType {
  int _hashCode;

  ResolutionInterfaceType(ClassElement element,
      [List<ResolutionDartType> typeArguments = const <ResolutionDartType>[]])
      : super(element, typeArguments) {
    assert(invariant(element, element.isDeclaration));
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

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitInterfaceType(this, argument);
  }

  /// Returns the type of the 'call' method in this interface type, or
  /// `null` if the interface type has no 'call' method.
  ResolutionFunctionType get callType {
    ResolutionFunctionType type = element.callType;
    return type != null && isGeneric ? type.substByContext(this) : type;
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
    assert(invariant(CURRENT_ELEMENT_SPANNABLE, element != null));
    assert(invariant(element, element.isDeclaration));
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
    assert(invariant(
        CURRENT_ELEMENT_SPANNABLE, element == null || element.isDeclaration));
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

  ResolutionDartType subst(
      List<ResolutionDartType> arguments, List<ResolutionDartType> parameters) {
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

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitFunctionType(this, argument);
  }

  void visitChildren(DartTypeVisitor visitor, var argument) {
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

class ResolutionTypedefType extends GenericType<ResolutionTypedefType> {
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

  accept(DartTypeVisitor visitor, var argument) {
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

  ResolutionDartType subst(List<ResolutionDartType> arguments,
          List<ResolutionDartType> parameters) =>
      this;

  accept(DartTypeVisitor visitor, var argument) {
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

abstract class DartTypeVisitor<R, A> {
  const DartTypeVisitor();

  R visit(ResolutionDartType type, A argument) => type.accept(this, argument);

  R visitVoidType(ResolutionVoidType type, A argument) => null;

  R visitTypeVariableType(ResolutionTypeVariableType type, A argument) => null;

  R visitFunctionType(ResolutionFunctionType type, A argument) => null;

  R visitMalformedType(MalformedType type, A argument) => null;

  R visitInterfaceType(ResolutionInterfaceType type, A argument) => null;

  R visitTypedefType(ResolutionTypedefType type, A argument) => null;

  R visitDynamicType(ResolutionDynamicType type, A argument) => null;
}

abstract class BaseDartTypeVisitor<R, A> extends DartTypeVisitor<R, A> {
  const BaseDartTypeVisitor();

  R visitType(ResolutionDartType type, A argument);

  @override
  R visitVoidType(ResolutionVoidType type, A argument) =>
      visitType(type, argument);

  @override
  R visitTypeVariableType(ResolutionTypeVariableType type, A argument) =>
      visitType(type, argument);

  @override
  R visitFunctionType(ResolutionFunctionType type, A argument) =>
      visitType(type, argument);

  @override
  R visitMalformedType(MalformedType type, A argument) =>
      visitType(type, argument);

  R visitGenericType(GenericType type, A argument) => visitType(type, argument);

  @override
  R visitInterfaceType(ResolutionInterfaceType type, A argument) =>
      visitGenericType(type, argument);

  @override
  R visitTypedefType(ResolutionTypedefType type, A argument) =>
      visitGenericType(type, argument);

  @override
  R visitDynamicType(ResolutionDynamicType type, A argument) =>
      visitType(type, argument);
}

/**
 * Abstract visitor for determining relations between types.
 */
abstract class AbstractTypeRelation
    extends BaseDartTypeVisitor<bool, ResolutionDartType> {
  final Resolution resolution;

  AbstractTypeRelation(this.resolution);

  CommonElements get commonElements => resolution.commonElements;

  bool visitType(ResolutionDartType t, ResolutionDartType s) {
    throw 'internal error: unknown type kind ${t.kind}';
  }

  bool visitVoidType(ResolutionVoidType t, ResolutionDartType s) {
    assert(s is! ResolutionVoidType);
    return false;
  }

  bool invalidTypeArguments(ResolutionDartType t, ResolutionDartType s);

  bool invalidFunctionReturnTypes(ResolutionDartType t, ResolutionDartType s);

  bool invalidFunctionParameterTypes(
      ResolutionDartType t, ResolutionDartType s);

  bool invalidTypeVariableBounds(
      ResolutionDartType bound, ResolutionDartType s);

  bool invalidCallableType(ResolutionDartType callType, ResolutionDartType s);

  /// Handle as dynamic for both subtype and more specific relation to avoid
  /// spurious errors from malformed types.
  bool visitMalformedType(MalformedType t, ResolutionDartType s) => true;

  bool visitInterfaceType(ResolutionInterfaceType t, ResolutionDartType s) {
    // TODO(johnniwinther): Currently needed since literal types like int,
    // double, bool etc. might not have been resolved yet.
    t.element.ensureResolved(resolution);

    bool checkTypeArguments(
        ResolutionInterfaceType instance, ResolutionInterfaceType other) {
      List<ResolutionDartType> tTypeArgs = instance.typeArguments;
      List<ResolutionDartType> sTypeArgs = other.typeArguments;
      assert(tTypeArgs.length == sTypeArgs.length);
      for (int i = 0; i < tTypeArgs.length; i++) {
        if (invalidTypeArguments(tTypeArgs[i], sTypeArgs[i])) {
          return false;
        }
      }
      return true;
    }

    if (s is ResolutionInterfaceType) {
      ResolutionInterfaceType instance = t.asInstanceOf(s.element);
      if (instance != null && checkTypeArguments(instance, s)) {
        return true;
      }
    }

    if (s == commonElements.functionType && t.element.callType != null) {
      return true;
    } else if (s is ResolutionFunctionType) {
      ResolutionFunctionType callType = t.callType;
      return callType != null && !invalidCallableType(callType, s);
    }

    return false;
  }

  bool visitFunctionType(ResolutionFunctionType t, ResolutionDartType s) {
    if (s == commonElements.functionType) {
      return true;
    }
    if (s is! ResolutionFunctionType) return false;
    ResolutionFunctionType tf = t;
    ResolutionFunctionType sf = s;
    if (invalidFunctionReturnTypes(tf.returnType, sf.returnType)) {
      return false;
    }

    // TODO(johnniwinther): Rewrite the function subtyping to be more readable
    // but still as efficient.

    // For the comments we use the following abbreviations:
    //  x.p     : parameterTypes on [:x:],
    //  x.o     : optionalParameterTypes on [:x:], and
    //  len(xs) : length of list [:xs:].

    Iterator<ResolutionDartType> tps = tf.parameterTypes.iterator;
    Iterator<ResolutionDartType> sps = sf.parameterTypes.iterator;
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
      List<ResolutionDartType> tTypes = tf.namedParameterTypes;
      List<String> sNames = sf.namedParameters;
      List<ResolutionDartType> sTypes = sf.namedParameterTypes;
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

  bool visitTypeVariableType(
      ResolutionTypeVariableType t, ResolutionDartType s) {
    // Identity check is handled in [isSubtype].
    ResolutionDartType bound = t.element.bound;
    if (bound.isTypeVariable) {
      // The bound is potentially cyclic so we need to be extra careful.
      Set<TypeVariableElement> seenTypeVariables =
          new Set<TypeVariableElement>();
      seenTypeVariables.add(t.element);
      while (bound.isTypeVariable) {
        TypeVariableElement element = bound.element;
        if (identical(bound.element, s.element)) {
          // [t] extends [s].
          return true;
        }
        if (seenTypeVariables.contains(element)) {
          // We have a cycle and have already checked all bounds in the cycle
          // against [s] and can therefore conclude that [t] is not a subtype
          // of [s].
          return false;
        }
        seenTypeVariables.add(element);
        bound = element.bound;
      }
    }
    if (invalidTypeVariableBounds(bound, s)) return false;
    return true;
  }
}

class MoreSpecificVisitor extends AbstractTypeRelation {
  MoreSpecificVisitor(Resolution resolution) : super(resolution);

  bool isMoreSpecific(ResolutionDartType t, ResolutionDartType s) {
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
    t.computeUnaliased(resolution);
    t = t.unaliased;
    s.computeUnaliased(resolution);
    s = s.unaliased;

    return t.accept(this, s);
  }

  bool invalidTypeArguments(ResolutionDartType t, ResolutionDartType s) {
    return !isMoreSpecific(t, s);
  }

  bool invalidFunctionReturnTypes(ResolutionDartType t, ResolutionDartType s) {
    if (s.treatAsDynamic && t.isVoid) return true;
    return !s.isVoid && !isMoreSpecific(t, s);
  }

  bool invalidFunctionParameterTypes(
      ResolutionDartType t, ResolutionDartType s) {
    return !isMoreSpecific(t, s);
  }

  bool invalidTypeVariableBounds(
      ResolutionDartType bound, ResolutionDartType s) {
    return !isMoreSpecific(bound, s);
  }

  bool invalidCallableType(ResolutionDartType callType, ResolutionDartType s) {
    return !isMoreSpecific(callType, s);
  }
}

/**
 * Type visitor that determines the subtype relation two types.
 */
class SubtypeVisitor extends MoreSpecificVisitor {
  SubtypeVisitor(Resolution resolution) : super(resolution);

  bool isSubtype(ResolutionDartType t, ResolutionDartType s) {
    return t.treatAsDynamic || isMoreSpecific(t, s);
  }

  bool isAssignable(ResolutionDartType t, ResolutionDartType s) {
    return isSubtype(t, s) || isSubtype(s, t);
  }

  bool invalidTypeArguments(ResolutionDartType t, ResolutionDartType s) {
    return !isSubtype(t, s);
  }

  bool invalidFunctionReturnTypes(ResolutionDartType t, ResolutionDartType s) {
    return !s.isVoid && !isAssignable(t, s);
  }

  bool invalidFunctionParameterTypes(
      ResolutionDartType t, ResolutionDartType s) {
    return !isAssignable(t, s);
  }

  bool invalidTypeVariableBounds(
      ResolutionDartType bound, ResolutionDartType s) {
    return !isSubtype(bound, s);
  }

  bool invalidCallableType(ResolutionDartType callType, ResolutionDartType s) {
    return !isSubtype(callType, s);
  }
}

/**
 * Callback used to check whether the [typeArgument] of [type] is a valid
 * substitute for the bound of [typeVariable]. [bound] holds the bound against
 * which [typeArgument] should be checked.
 */
typedef void CheckTypeVariableBound(
    GenericType type,
    ResolutionDartType typeArgument,
    ResolutionTypeVariableType typeVariable,
    ResolutionDartType bound);

/// Basic interface for the Dart type system.
abstract class DartTypes {
  /// The types defined in 'dart:core'.
  CommonElements get commonElements;

  /// Returns `true` if [t] is a subtype of [s].
  bool isSubtype(ResolutionDartType t, ResolutionDartType s);

  /// Returns `true` if [t] might be a subtype of [s] for some values of
  /// type variables in [s] and [t].
  bool isPotentialSubtype(ResolutionDartType t, ResolutionDartType s);
}

class Types implements DartTypes {
  final Resolution resolution;
  final MoreSpecificVisitor moreSpecificVisitor;
  final SubtypeVisitor subtypeVisitor;
  final PotentialSubtypeVisitor potentialSubtypeVisitor;

  CommonElements get commonElements => resolution.commonElements;

  DiagnosticReporter get reporter => resolution.reporter;

  Types(Resolution resolution)
      : this.resolution = resolution,
        this.moreSpecificVisitor = new MoreSpecificVisitor(resolution),
        this.subtypeVisitor = new SubtypeVisitor(resolution),
        this.potentialSubtypeVisitor = new PotentialSubtypeVisitor(resolution);

  Types copy(Resolution resolution) {
    return new Types(resolution);
  }

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
  bool isSubtype(ResolutionDartType t, ResolutionDartType s) {
    return subtypeVisitor.isSubtype(t, s);
  }

  bool isAssignable(ResolutionDartType r, ResolutionDartType s) {
    return subtypeVisitor.isAssignable(r, s);
  }

  static const int IS_SUBTYPE = 1;
  static const int MAYBE_SUBTYPE = 0;
  static const int NOT_SUBTYPE = -1;

  int computeSubtypeRelation(ResolutionDartType t, ResolutionDartType s) {
    // TODO(johnniwinther): Compute this directly in [isPotentialSubtype].
    if (isSubtype(t, s)) return IS_SUBTYPE;
    return isPotentialSubtype(t, s) ? MAYBE_SUBTYPE : NOT_SUBTYPE;
  }

  bool isPotentialSubtype(ResolutionDartType t, ResolutionDartType s) {
    // TODO(johnniwinther): Return a set of variable points in the positive
    // cases.
    return potentialSubtypeVisitor.isSubtype(t, s);
  }

  /**
   * Checks the type arguments of [type] against the type variable bounds
   * declared on [element]. Calls [checkTypeVariableBound] on each type
   * argument and bound.
   */
  void checkTypeVariableBounds(
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
   * Returns the [ClassElement] which declares the type variables occurring in
   * [type], or [:null:] if [type] does not contain type variables.
   */
  static ClassElement getClassContext(ResolutionDartType type) {
    ClassElement contextClass;
    type.forEachTypeVariable((ResolutionTypeVariableType typeVariable) {
      if (typeVariable.element.typeDeclaration is! ClassElement) return;
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
      types.forEach(depth, (ResolutionDartType supertype) {
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
    assert(invariant(NO_LOCATION_SPANNABLE, type.isInterfaceType,
        message: "unexpected type kind ${type.kind}."));
    return type;
  }
}

/**
 * Type visitor that determines one type could a subtype of another given the
 * right type variable substitution. The computation is approximate and returns
 * [:false:] only if we are sure no such substitution exists.
 */
class PotentialSubtypeVisitor extends SubtypeVisitor {
  PotentialSubtypeVisitor(Resolution resolution) : super(resolution);

  bool isSubtype(ResolutionDartType t, ResolutionDartType s) {
    if (t is ResolutionTypeVariableType || s is ResolutionTypeVariableType) {
      return true;
    }
    return super.isSubtype(t, s);
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
    extends BaseDartTypeVisitor<bool, ResolutionDartType> {
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
    element.typeVariables.forEach((ResolutionTypeVariableType typeVariable) {
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

  bool visitType(ResolutionDartType type, ResolutionDartType argument) {
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
      ResolutionTypeVariableType type, ResolutionDartType argument) {
    ResolutionDartType constraint =
        types.getMostSpecific(constraintMap[type], argument);
    constraintMap[type] = constraint;
    return constraint != null;
  }

  bool visitFunctionType(
      ResolutionFunctionType type, ResolutionDartType argument) {
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
class TypeDeclarationFormatter extends BaseDartTypeVisitor<dynamic, String> {
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

  void visit(ResolutionDartType type, [_]) {
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

  void visitType(ResolutionDartType type, String name) {
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

  void visitFunctionType(ResolutionFunctionType type, String name) {
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
