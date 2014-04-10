// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_types;

import 'dart:math' show min;

import 'dart2jslib.dart' show Compiler, invariant, Script, Message;
import 'elements/modelx.dart'
    show VoidElementX,
         LibraryElementX,
         BaseClassElementX,
         TypeDeclarationElementX,
         TypedefElementX;
import 'elements/elements.dart';
import 'ordered_typeset.dart' show OrderedTypeSet;
import 'util/util.dart' show Link, LinkBuilder, CURRENT_ELEMENT_SPANNABLE;

class TypeKind {
  final String id;

  const TypeKind(String this.id);

  static const TypeKind FUNCTION = const TypeKind('function');
  static const TypeKind INTERFACE = const TypeKind('interface');
  static const TypeKind STATEMENT = const TypeKind('statement');
  static const TypeKind TYPEDEF = const TypeKind('typedef');
  static const TypeKind TYPE_VARIABLE = const TypeKind('type variable');
  static const TypeKind MALFORMED_TYPE = const TypeKind('malformed');
  static const TypeKind VOID = const TypeKind('void');

  String toString() => id;
}

abstract class DartType {
  String get name;

  TypeKind get kind;

  const DartType();

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
   * See [TypeVariableType] for a motivation for this method.
   *
   * Invariant: There must be the same number of [arguments] and [parameters].
   */
  DartType subst(Link<DartType> arguments, Link<DartType> parameters);

  /// Performs the substitution of the type arguments of [type] for their
  /// corresponding type variables in this type.
  DartType substByContext(GenericType type) =>
      subst(type.typeArguments, type.element.typeVariables);

  /**
   * Returns the unaliased type of this type.
   *
   * The unaliased type of a typedef'd type is the unaliased type to which its
   * name is bound. The unaliased version of any other type is the type itself.
   *
   * For example, the unaliased type of [: typedef A Func<A,B>(B b) :] is the
   * function type [: (B) -> A :] and the unaliased type of
   * [: Func<int,String> :] is the function type [: (String) -> int :].
   */
  DartType unalias(Compiler compiler);

  /**
   * If this type is malformed or a generic type created with the wrong number
   * of type arguments then [userProvidedBadType] holds the bad type provided
   * by the user.
   */
  DartType get userProvidedBadType => null;

  /// Is [: true :] if this type has no explict type arguments.
  bool get isRaw => true;

  /// Returns the raw version of this type.
  DartType asRaw() => this;

  /// Is [: true :] if this type has no non-dynamic type arguments.
  bool get treatAsRaw => isRaw;

  /// Is [: true :] if this type should be treated as the dynamic type.
  bool get treatAsDynamic => false;

  /// Is [: true :] if this type is the dynamic type.
  bool get isDynamic => false;

  /// Is [: true :] if this type is the void type.
  bool get isVoid => false;

  /// Returns an occurrence of a type variable within this type, if any.
  TypeVariableType get typeVariableOccurrence => null;

  /// Applies [f] to each occurence of a [TypeVariableType] within this type.
  void forEachTypeVariable(f(TypeVariableType variable)) {}

  TypeVariableType _findTypeVariableOccurrence(Link<DartType> types) {
    for (Link<DartType> link = types; !link.isEmpty ; link = link.tail) {
      TypeVariableType typeVariable = link.head.typeVariableOccurrence;
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

  static void visitList(Link<DartType> types,
                        DartTypeVisitor visitor, var argument) {
    for (Link<DartType> link = types; !link.isEmpty ; link = link.tail) {
      link.head.accept(visitor, argument);
    }
  }
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
class TypeVariableType extends DartType {
  final TypeVariableElement element;

  TypeVariableType(this.element);

  TypeKind get kind => TypeKind.TYPE_VARIABLE;

  String get name => element.name;

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    Link<DartType> parameterLink = parameters;
    Link<DartType> argumentLink = arguments;
    while (!argumentLink.isEmpty && !parameterLink.isEmpty) {
      TypeVariableType parameter = parameterLink.head;
      DartType argument = argumentLink.head;
      if (parameter == this) {
        assert(argumentLink.tail.isEmpty == parameterLink.tail.isEmpty);
        return argument;
      }
      parameterLink = parameterLink.tail;
      argumentLink = argumentLink.tail;
    }
    assert(argumentLink.isEmpty && parameterLink.isEmpty);
    // The type variable was not substituted.
    return this;
  }

  DartType unalias(Compiler compiler) => this;

  DartType get typeVariableOccurrence => this;

  void forEachTypeVariable(f(TypeVariableType variable)) {
    f(this);
  }

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitTypeVariableType(this, argument);
  }

  int get hashCode => 17 * element.hashCode;

  bool operator ==(other) {
    if (other is !TypeVariableType) return false;
    return identical(other.element, element);
  }

  String toString() => name;
}

/**
 * A statement type tracks whether a statement returns or may return.
 */
class StatementType extends DartType {
  final String stringName;

  Element get element => null;

  TypeKind get kind => TypeKind.STATEMENT;

  String get name => stringName;

  const StatementType(this.stringName);

  static const RETURNING = const StatementType('<returning>');
  static const NOT_RETURNING = const StatementType('<not returning>');
  static const MAYBE_RETURNING = const StatementType('<maybe returning>');

  /** Combine the information about two control-flow edges that are joined. */
  StatementType join(StatementType other) {
    return (identical(this, other)) ? this : MAYBE_RETURNING;
  }

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    // Statement types are not substitutable.
    return this;
  }

  DartType unalias(Compiler compiler) => this;

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitStatementType(this, argument);
  }

  int get hashCode => 17 * stringName.hashCode;

  bool operator ==(other) {
    if (other is !StatementType) return false;
    return other.stringName == stringName;
  }

  String toString() => stringName;
}

class VoidType extends DartType {
  const VoidType(this.element);

  TypeKind get kind => TypeKind.VOID;

  String get name => element.name;

  final Element element;

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    // Void cannot be substituted.
    return this;
  }

  DartType unalias(Compiler compiler) => this;

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitVoidType(this, argument);
  }

  bool get isVoid => true;

  int get hashCode => 1729;

  bool operator ==(other) => other is VoidType;

  String toString() => name;
}

class MalformedType extends DartType {
  final ErroneousElement element;

  /**
   * [declaredType] holds the type which the user wrote in code.
   *
   * For instance, for a resolved but malformed type like [: Map<String> :] the
   * [declaredType] is [: Map<String> :] whereas for an unresolved type
   * [userProvidedBadType] is [: null :].
   */
  final DartType userProvidedBadType;

  /**
   * Type arguments for the malformed typed, if these cannot fit in the
   * [declaredType].
   *
   * This field is for instance used for [: dynamic<int> :] and [: T<int> :]
   * where [: T :] is a type variable, in which case [declaredType] holds
   * [: dynamic :] and [: T :], respectively, or for [: X<int> :] where [: X :]
   * is not resolved or does not imply a type.
   */
  final Link<DartType> typeArguments;

  final int hashCode = (nextHash++) & 0x3fffffff;
  static int nextHash = 43765;

  MalformedType(this.element, this.userProvidedBadType,
                [this.typeArguments = null]);

  TypeKind get kind => TypeKind.MALFORMED_TYPE;

  String get name => element.name;

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    // Malformed types are not substitutable.
    return this;
  }

  // Malformed types are treated as dynamic.
  bool get treatAsDynamic => true;

  DartType unalias(Compiler compiler) => this;

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
        typeArguments.printOn(sb, ', ');
        sb.write('>');
      }
    } else {
      sb.write(userProvidedBadType.toString());
    }
    return sb.toString();
  }
}

abstract class GenericType extends DartType {
  final TypeDeclarationElement element;
  final Link<DartType> typeArguments;

  GenericType(TypeDeclarationElementX element,
              Link<DartType> this.typeArguments,
              {bool checkTypeArgumentCount: true})
      : this.element = element {
    assert(invariant(element,
        !checkTypeArgumentCount ||
        element.thisTypeCache == null ||
        typeArguments.slowLength() == element.typeVariables.slowLength(),
        message: () => 'Invalid type argument count on ${element.thisType}. '
                       'Provided type arguments: $typeArguments.'));
  }

  /// Creates a new instance of this type using the provided type arguments.
  GenericType createInstantiation(Link<DartType> newTypeArguments);

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    if (typeArguments.isEmpty) {
      // Return fast on non-generic types.
      return this;
    }
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    Link<DartType> newTypeArguments =
        Types.substTypes(typeArguments, arguments, parameters);
    if (!identical(typeArguments, newTypeArguments)) {
      // Create a new type only if necessary.
      return createInstantiation(newTypeArguments);
    }
    return this;
  }

  TypeVariableType get typeVariableOccurrence {
    return _findTypeVariableOccurrence(typeArguments);
  }

  void forEachTypeVariable(f(TypeVariableType variable)) {
    for (Link<DartType> link = typeArguments; !link.isEmpty; link = link.tail) {
      link.head.forEachTypeVariable(f);
    }
  }

  void visitChildren(DartTypeVisitor visitor, var argument) {
    DartType.visitList(typeArguments, visitor, argument);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(name);
    if (!isRaw) {
      sb.write('<');
      typeArguments.printOn(sb, ', ');
      sb.write('>');
    }
    return sb.toString();
  }

  int get hashCode {
    int hash = element.hashCode;
    for (Link<DartType> arguments = this.typeArguments;
         !arguments.isEmpty;
         arguments = arguments.tail) {
      int argumentHash = arguments.head != null ? arguments.head.hashCode : 0;
      hash = 17 * hash + 3 * argumentHash;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is !GenericType) return false;
    return kind == other.kind
        && element == other.element
        && typeArguments == other.typeArguments;
  }

  /// Returns `true` if the declaration of this type has type variables.
  bool get isGeneric => !typeArguments.isEmpty;

  bool get isRaw => typeArguments.isEmpty || identical(this, element.rawType);

  GenericType asRaw() => element.rawType;

  bool get treatAsRaw {
    if (isRaw) return true;
    for (Link<DartType> link = typeArguments; !link.isEmpty; link = link.tail) {
      if (!link.head.treatAsDynamic) return false;
    }
    return true;
  }
}

class InterfaceType extends GenericType {
  InterfaceType(BaseClassElementX element,
                [Link<DartType> typeArguments = const Link<DartType>()])
      : super(element, typeArguments) {
    assert(invariant(element, element.isDeclaration));
  }

  InterfaceType.forUserProvidedBadType(BaseClassElementX element,
                                       [Link<DartType> typeArguments =
                                           const Link<DartType>()])
      : super(element, typeArguments, checkTypeArgumentCount: false);

  ClassElement get element => super.element;

  TypeKind get kind => TypeKind.INTERFACE;

  String get name => element.name;

  InterfaceType createInstantiation(Link<DartType> newTypeArguments) {
    return new InterfaceType(element, newTypeArguments);
  }

  /**
   * Returns the type as an instance of class [other], if possible, null
   * otherwise.
   */
  DartType asInstanceOf(ClassElement other) {
    other = other.declaration;
    if (element == other) return this;
    for (InterfaceType supertype in element.allSupertypes) {
      ClassElement superclass = supertype.element;
      if (superclass == other) {
        Link<DartType> arguments = Types.substTypes(supertype.typeArguments,
                                                    typeArguments,
                                                    element.typeVariables);
        return new InterfaceType(superclass, arguments);
      }
    }
    return null;
  }

  DartType unalias(Compiler compiler) => this;

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

  int get hashCode => super.hashCode;

  InterfaceType asRaw() => super.asRaw();

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitInterfaceType(this, argument);
  }

  /// Returns the type of the 'call' method in this interface type, or
  /// `null` if the interface type has no 'call' method.
  FunctionType get callType {
    FunctionType type = element.callType;
    return type != null && isGeneric ? type.substByContext(this) : type;
  }
}

/**
 * Special subclass of [InterfaceType] used for generic interface types created
 * with the wrong number of type arguments.
 *
 * The type uses [:dynamic:] for all it s type arguments.
 */
class BadInterfaceType extends InterfaceType {
  final InterfaceType userProvidedBadType;

  BadInterfaceType(ClassElement element,
                   InterfaceType this.userProvidedBadType)
      : super(element, element.rawType.typeArguments);

  String toString() {
    return userProvidedBadType.toString();
  }
}


/**
 * Special subclass of [TypedefType] used for generic typedef types created
 * with the wrong number of type arguments.
 *
 * The type uses [:dynamic:] for all it s type arguments.
 */
class BadTypedefType extends TypedefType {
  final TypedefType userProvidedBadType;

  BadTypedefType(TypedefElement element,
                 TypedefType this.userProvidedBadType)
      : super(element, element.rawType.typeArguments);

  String toString() {
    return userProvidedBadType.toString();
  }
}

class FunctionType extends DartType {
  final Element element;
  final DartType returnType;
  final Link<DartType> parameterTypes;
  final Link<DartType> optionalParameterTypes;

  /**
   * The names of the named parameters ordered lexicographically.
   */
  final Link<String> namedParameters;

  /**
   * The types of the named parameters in the order corresponding to the
   * [namedParameters].
   */
  final Link<DartType> namedParameterTypes;

  FunctionType(Element this.element,
               DartType this.returnType,
               [this.parameterTypes = const Link<DartType>(),
                this.optionalParameterTypes = const Link<DartType>(),
                this.namedParameters = const Link<String>(),
                this.namedParameterTypes = const Link<DartType>()]) {
    assert(invariant(element, element.isDeclaration));
    // Assert that optional and named parameters are not used at the same time.
    assert(optionalParameterTypes.isEmpty || namedParameterTypes.isEmpty);
    assert(namedParameters.slowLength() == namedParameterTypes.slowLength());
  }

  TypeKind get kind => TypeKind.FUNCTION;

  DartType getNamedParameterType(String name) {
    Link<String> namedParameter = namedParameters;
    Link<DartType> namedParameterType = namedParameterTypes;
    while (!namedParameter.isEmpty && !namedParameterType.isEmpty) {
      if (namedParameter.head == name) {
        return namedParameterType.head;
      }
      namedParameter = namedParameter.tail;
      namedParameterType = namedParameterType.tail;
    }
    return null;
  }

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    if (parameters.isEmpty) {
      assert(arguments.isEmpty);
      // Return fast on empty substitutions.
      return this;
    }
    var newReturnType = returnType.subst(arguments, parameters);
    bool changed = !identical(newReturnType, returnType);
    var newParameterTypes =
        Types.substTypes(parameterTypes, arguments, parameters);
    var newOptionalParameterTypes =
        Types.substTypes(optionalParameterTypes, arguments, parameters);
    var newNamedParameterTypes =
        Types.substTypes(namedParameterTypes, arguments, parameters);
    if (!changed &&
        (!identical(parameterTypes, newParameterTypes) ||
         !identical(optionalParameterTypes, newOptionalParameterTypes) ||
         !identical(namedParameterTypes, newNamedParameterTypes))) {
      changed = true;
    }
    if (changed) {
      // Create a new type only if necessary.
      return new FunctionType(element,
                              newReturnType,
                              newParameterTypes,
                              newOptionalParameterTypes,
                              namedParameters,
                              newNamedParameterTypes);
    }
    return this;
  }

  DartType unalias(Compiler compiler) => this;

  DartType get typeVariableOccurrence {
    TypeVariableType typeVariableType = returnType.typeVariableOccurrence;
    if (typeVariableType != null) return typeVariableType;

    typeVariableType = _findTypeVariableOccurrence(parameterTypes);
    if (typeVariableType != null) return typeVariableType;

    typeVariableType = _findTypeVariableOccurrence(optionalParameterTypes);
    if (typeVariableType != null) return typeVariableType;

    return _findTypeVariableOccurrence(namedParameterTypes);
  }

  void forEachTypeVariable(f(TypeVariableType variable)) {
    returnType.forEachTypeVariable(f);
    parameterTypes.forEach((DartType type) {
      type.forEachTypeVariable(f);
    });
    optionalParameterTypes.forEach((DartType type) {
      type.forEachTypeVariable(f);
    });
    namedParameterTypes.forEach((DartType type) {
      type.forEachTypeVariable(f);
    });
  }

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitFunctionType(this, argument);
  }

  void visitChildren(DartTypeVisitor visitor, var argument) {
   returnType.accept(visitor, argument);
   DartType.visitList(parameterTypes, visitor, argument);
   DartType.visitList(optionalParameterTypes, visitor, argument);
   DartType.visitList(namedParameterTypes, visitor, argument);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('(');
    parameterTypes.printOn(sb, ', ');
    bool first = parameterTypes.isEmpty;
    if (!optionalParameterTypes.isEmpty) {
      if (!first) {
        sb.write(', ');
      }
      sb.write('[');
      optionalParameterTypes.printOn(sb, ', ');
      sb.write(']');
      first = false;
    }
    if (!namedParameterTypes.isEmpty) {
      if (!first) {
        sb.write(', ');
      }
      sb.write('{');
      Link<String> namedParameter = namedParameters;
      Link<DartType> namedParameterType = namedParameterTypes;
      first = true;
      while (!namedParameter.isEmpty && !namedParameterType.isEmpty) {
        if (!first) {
          sb.write(', ');
        }
        sb.write(namedParameterType.head);
        sb.write(' ');
          sb.write(namedParameter.head);
        namedParameter = namedParameter.tail;
        namedParameterType = namedParameterType.tail;
        first = false;
      }
      sb.write('}');
    }
    sb.write(') -> ${returnType}');
    return sb.toString();
  }

  String get name => 'Function';

  int computeArity() {
    int arity = 0;
    parameterTypes.forEach((_) { arity++; });
    return arity;
  }

  int get hashCode {
    int hash = 3 * returnType.hashCode;
    for (DartType parameter  in parameterTypes) {
      hash = 17 * hash + 5 * parameter.hashCode;
    }
    for (DartType parameter  in optionalParameterTypes) {
      hash = 19 * hash + 7 * parameter.hashCode;
    }
    for (String name  in namedParameters) {
      hash = 23 * hash + 11 * name.hashCode;
    }
    for (DartType parameter  in namedParameterTypes) {
      hash = 29 * hash + 13 * parameter.hashCode;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is !FunctionType) return false;
    return returnType == other.returnType
           && parameterTypes == other.parameterTypes
           && optionalParameterTypes == other.optionalParameterTypes
           && namedParameters == other.namedParameters
           && namedParameterTypes == other.namedParameterTypes;
  }
}

class TypedefType extends GenericType {
  TypedefType(TypedefElementX element,
              [Link<DartType> typeArguments = const Link<DartType>()])
      : super(element, typeArguments);

  TypedefType.forUserProvidedBadType(TypedefElementX element,
                                     [Link<DartType> typeArguments =
                                         const Link<DartType>()])
      : super(element, typeArguments, checkTypeArgumentCount: false);

  TypedefElement get element => super.element;

  TypeKind get kind => TypeKind.TYPEDEF;

  String get name => element.name;

  TypedefType createInstantiation(Link<DartType> newTypeArguments) {
    return new TypedefType(element, newTypeArguments);
  }

  DartType unalias(Compiler compiler) {
    // TODO(ahe): This should be [ensureResolved].
    compiler.resolveTypedef(element);
    element.checkCyclicReference(compiler);
    DartType definition = element.alias.unalias(compiler);
    return definition.substByContext(this);
  }

  int get hashCode => super.hashCode;

  TypedefType asRaw() => super.asRaw();

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitTypedefType(this, argument);
  }
}

/**
 * Special type to hold the [dynamic] type. Used for correctly returning
 * 'dynamic' on [toString].
 */
class DynamicType extends InterfaceType {
  DynamicType(ClassElement element) : super(element);

  String get name => 'dynamic';

  bool get treatAsDynamic => true;

  bool get isDynamic => true;

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitDynamicType(this, argument);
  }
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
  final InterfaceType instance;
  final MemberSignature member;

  InterfaceMember(this.instance, this.member);

  Name get name => member.name;

  DartType get type => member.type.substByContext(instance);

  FunctionType get functionType => member.functionType.substByContext(instance);

  bool get isGetter => member.isGetter;

  bool get isSetter => member.isSetter;

  bool get isMethod => member.isMethod;

  Iterable<Member> get declarations => member.declarations;
}

abstract class DartTypeVisitor<R, A> {
  const DartTypeVisitor();

  R visitType(DartType type, A argument);

  R visitVoidType(VoidType type, A argument) =>
      visitType(type, argument);

  R visitTypeVariableType(TypeVariableType type, A argument) =>
      visitType(type, argument);

  R visitFunctionType(FunctionType type, A argument) =>
      visitType(type, argument);

  R visitMalformedType(MalformedType type, A argument) =>
      visitType(type, argument);

  R visitStatementType(StatementType type, A argument) =>
      visitType(type, argument);

  R visitGenericType(GenericType type, A argument) =>
      visitType(type, argument);

  R visitInterfaceType(InterfaceType type, A argument) =>
      visitGenericType(type, argument);

  R visitTypedefType(TypedefType type, A argument) =>
      visitGenericType(type, argument);

  R visitDynamicType(DynamicType type, A argument) =>
      visitInterfaceType(type, argument);
}

/**
 * Abstract visitor for determining relations between types.
 */
abstract class AbstractTypeRelation extends DartTypeVisitor<bool, DartType> {
  final Compiler compiler;
  final DynamicType dynamicType;
  final VoidType voidType;

  AbstractTypeRelation(Compiler this.compiler,
                       DynamicType this.dynamicType,
                       VoidType this.voidType);

  bool visitType(DartType t, DartType s) {
    throw 'internal error: unknown type kind ${t.kind}';
  }

  bool visitVoidType(VoidType t, DartType s) {
    assert(s is! VoidType);
    return false;
  }

  bool invalidTypeArguments(DartType t, DartType s);

  bool invalidFunctionReturnTypes(DartType t, DartType s);

  bool invalidFunctionParameterTypes(DartType t, DartType s);

  bool invalidTypeVariableBounds(DartType bound, DartType s);

  /// Handle as dynamic for both subtype and more specific relation to avoid
  /// spurious errors from malformed types.
  bool visitMalformedType(MalformedType t, DartType s) => true;

  bool visitInterfaceType(InterfaceType t, DartType s) {

    // TODO(johnniwinther): Currently needed since literal types like int,
    // double, bool etc. might not have been resolved yet.
    t.element.ensureResolved(compiler);

    bool checkTypeArguments(InterfaceType instance, InterfaceType other) {
      Link<DartType> tTypeArgs = instance.typeArguments;
      Link<DartType> sTypeArgs = other.typeArguments;
      while (!tTypeArgs.isEmpty) {
        assert(!sTypeArgs.isEmpty);
        if (invalidTypeArguments(tTypeArgs.head, sTypeArgs.head)) {
          return false;
        }
        tTypeArgs = tTypeArgs.tail;
        sTypeArgs = sTypeArgs.tail;
      }
      assert(sTypeArgs.isEmpty);
      return true;
    }

    if (s is InterfaceType) {
      InterfaceType instance = t.asInstanceOf(s.element);
      return instance != null && checkTypeArguments(instance, s);
    } else {
      return false;
    }
  }

  bool visitFunctionType(FunctionType t, DartType s) {
    if (s is InterfaceType && identical(s.element, compiler.functionClass)) {
      return true;
    }
    if (s is !FunctionType) return false;
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

    Link<DartType> tps = tf.parameterTypes;
    Link<DartType> sps = sf.parameterTypes;
    while (!tps.isEmpty && !sps.isEmpty) {
      if (invalidFunctionParameterTypes(tps.head, sps.head)) return false;
      tps = tps.tail;
      sps = sps.tail;
    }
    if (!tps.isEmpty) {
      // We must have [: len(t.p) <= len(s.p) :].
      return false;
    }
    if (!sf.namedParameters.isEmpty) {
      if (!sps.isEmpty) {
        // We must have [: len(t.p) == len(s.p) :].
        return false;
      }
      // Since named parameters are globally ordered we can determine the
      // subset relation with a linear search for [:sf.namedParameters:]
      // within [:tf.namedParameters:].
      Link<String> tNames = tf.namedParameters;
      Link<DartType> tTypes = tf.namedParameterTypes;
      Link<String> sNames = sf.namedParameters;
      Link<DartType> sTypes = sf.namedParameterTypes;
      while (!tNames.isEmpty && !sNames.isEmpty) {
        if (sNames.head == tNames.head) {
          if (invalidFunctionParameterTypes(tTypes.head, sTypes.head)) {
            return false;
          }

          sNames = sNames.tail;
          sTypes = sTypes.tail;
        }
        tNames = tNames.tail;
        tTypes = tTypes.tail;
      }
      if (!sNames.isEmpty) {
        // We didn't find all names.
        return false;
      }
    } else {
      // Check the remaining [: s.p :] against [: t.o :].
      tps = tf.optionalParameterTypes;
      while (!tps.isEmpty && !sps.isEmpty) {
        if (invalidFunctionParameterTypes(tps.head, sps.head)) return false;
        tps = tps.tail;
        sps = sps.tail;
      }
      if (!sps.isEmpty) {
        // We must have [: len(t.p) + len(t.o) >= len(s.p) :].
        return false;
      }
      if (!sf.optionalParameterTypes.isEmpty) {
        // Check the remaining [: s.o :] against the remaining [: t.o :].
        sps = sf.optionalParameterTypes;
        while (!tps.isEmpty && !sps.isEmpty) {
          if (invalidFunctionParameterTypes(tps.head, sps.head)) return false;
          tps = tps.tail;
          sps = sps.tail;
        }
        if (!sps.isEmpty) {
          // We didn't find enough parameters:
          // We must have [: len(t.p) + len(t.o) <= len(s.p) + len(s.o) :].
          return false;
        }
      } else {
        if (!sps.isEmpty) {
          // We must have [: len(t.p) + len(t.o) >= len(s.p) :].
          return false;
        }
      }
    }
    return true;
  }

  bool visitTypeVariableType(TypeVariableType t, DartType s) {
    // Identity check is handled in [isSubtype].
    DartType bound = t.element.bound;
    if (bound.element.isTypeVariable()) {
      // The bound is potentially cyclic so we need to be extra careful.
      Link<TypeVariableElement> seenTypeVariables =
          const Link<TypeVariableElement>();
      seenTypeVariables = seenTypeVariables.prepend(t.element);
      while (bound.element.isTypeVariable()) {
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
        seenTypeVariables = seenTypeVariables.prepend(element);
        bound = element.bound;
      }
    }
    if (invalidTypeVariableBounds(bound, s)) return false;
    return true;
  }
}

class MoreSpecificVisitor extends AbstractTypeRelation {
  MoreSpecificVisitor(Compiler compiler,
                      DynamicType dynamicType,
                      VoidType voidType)
      : super(compiler, dynamicType, voidType);

  bool isMoreSpecific(DartType t, DartType s) {
    if (identical(t, s) || s.treatAsDynamic ||
        identical(t.element, compiler.nullClass)) {
      return true;
    }
    if (t.isVoid || s.isVoid) {
      return false;
    }
    if (t.treatAsDynamic) {
      return false;
    }
    if (identical(s.element, compiler.objectClass)) {
      return true;
    }
    t = t.unalias(compiler);
    s = s.unalias(compiler);

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
}

/**
 * Type visitor that determines the subtype relation two types.
 */
class SubtypeVisitor extends MoreSpecificVisitor {

  SubtypeVisitor(Compiler compiler,
                 DynamicType dynamicType,
                 VoidType voidType)
      : super(compiler, dynamicType, voidType);

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
    return !identical(s, voidType) && !isAssignable(t, s);
  }

  bool invalidFunctionParameterTypes(DartType t, DartType s) {
    return !isAssignable(t, s);
  }

  bool invalidTypeVariableBounds(DartType bound, DartType s) {
    return !isSubtype(bound, s);
  }

  bool visitInterfaceType(InterfaceType t, DartType s) {
    if (super.visitInterfaceType(t, s)) return true;

    if (s is InterfaceType &&
        s.element == compiler.functionClass &&
        t.element.callType != null) {
      return true;
    } else if (s is FunctionType) {
      FunctionType callType = t.callType;
      return callType != null && isSubtype(callType, s);
    }
    return false;
  }
}

/**
 * Callback used to check whether the [typeArgument] of [type] is a valid
 * substitute for the bound of [typeVariable]. [bound] holds the bound against
 * which [typeArgument] should be checked.
 */
typedef void CheckTypeVariableBound(GenericType type,
                                    DartType typeArgument,
                                    TypeVariableType typeVariable,
                                    DartType bound);

class Types {
  final Compiler compiler;
  // TODO(karlklose): should we have a class Void?
  final VoidType voidType;
  final DynamicType dynamicType;
  final MoreSpecificVisitor moreSpecificVisitor;
  final SubtypeVisitor subtypeVisitor;
  final PotentialSubtypeVisitor potentialSubtypeVisitor;

  factory Types(Compiler compiler, BaseClassElementX dynamicElement) {
    LibraryElement library = new LibraryElementX(new Script(null, null, null));
    VoidType voidType = new VoidType(new VoidElementX(library));
    DynamicType dynamicType = new DynamicType(dynamicElement);
    dynamicElement.rawTypeCache = dynamicElement.thisTypeCache = dynamicType;
    return new Types.internal(compiler, voidType, dynamicType);
  }

  Types.internal(Compiler compiler, VoidType voidType, DynamicType dynamicType)
      : this.compiler = compiler,
        this.voidType = voidType,
        this.dynamicType = dynamicType,
        this.moreSpecificVisitor =
          new MoreSpecificVisitor(compiler, dynamicType, voidType),
        this.subtypeVisitor =
          new SubtypeVisitor(compiler, dynamicType, voidType),
        this.potentialSubtypeVisitor =
          new PotentialSubtypeVisitor(compiler, dynamicType, voidType);

  Types copy(Compiler compiler) {
    return new Types.internal(compiler, voidType, dynamicType);
  }

  /** Returns true if [t] is more specific than [s]. */
  bool isMoreSpecific(DartType t, DartType s) {
    return moreSpecificVisitor.isMoreSpecific(t, s);
  }

  /**
   * Returns the most specific type of [t] and [s] or `null` if neither is more
   * specific than the other.
   */
  DartType getMostSpecific(DartType t, DartType s) {
    if (isMoreSpecific(t, s)) {
      return t;
    } else if (isMoreSpecific(s, t)) {
      return s;
    } else {
      return null;
    }
  }

  /** Returns true if t is a subtype of s */
  bool isSubtype(DartType t, DartType s) {
    return subtypeVisitor.isSubtype(t, s);
  }

  bool isAssignable(DartType r, DartType s) {
    return subtypeVisitor.isAssignable(r, s);
  }

  static const int IS_SUBTYPE = 1;
  static const int MAYBE_SUBTYPE = 0;
  static const int NOT_SUBTYPE = -1;

  int computeSubtypeRelation(DartType t, DartType s) {
    // TODO(johnniwinther): Compute this directly in [isPotentialSubtype].
    if (isSubtype(t, s)) return IS_SUBTYPE;
    return isPotentialSubtype(t, s) ? MAYBE_SUBTYPE : NOT_SUBTYPE;
  }

  bool isPotentialSubtype(DartType t, DartType s) {
    // TODO(johnniwinther): Return a set of variable points in the positive
    // cases.
    return potentialSubtypeVisitor.isSubtype(t, s);
  }

  /**
   * Checks the type arguments of [type] against the type variable bounds
   * declared on [element]. Calls [checkTypeVariableBound] on each type
   * argument and bound.
   */
  void checkTypeVariableBounds(GenericType type,
                               CheckTypeVariableBound checkTypeVariableBound) {
    TypeDeclarationElement element = type.element;
    Link<DartType> typeArguments = type.typeArguments;
    Link<DartType> typeVariables = element.typeVariables;
    while (!typeVariables.isEmpty && !typeArguments.isEmpty) {
      TypeVariableType typeVariable = typeVariables.head;
      DartType bound = typeVariable.element.bound.substByContext(type);
      DartType typeArgument = typeArguments.head;
      checkTypeVariableBound(type, typeArgument, typeVariable, bound);
      typeVariables = typeVariables.tail;
      typeArguments = typeArguments.tail;
    }
    assert(typeVariables.isEmpty && typeArguments.isEmpty);
  }

  /**
   * Helper method for performing substitution of a linked list of types.
   *
   * If no types are changed by the substitution, the [types] is returned
   * instead of a newly created linked list.
   */
  static Link<DartType> substTypes(Link<DartType> types,
                                   Link<DartType> arguments,
                                   Link<DartType> parameters) {
    bool changed = false;
    var builder = new LinkBuilder<DartType>();
    Link<DartType> typeLink = types;
    while (!typeLink.isEmpty) {
      var argument = typeLink.head.subst(arguments, parameters);
      if (!changed && !identical(argument, typeLink.head)) {
        changed = true;
      }
      builder.addLast(argument);
      typeLink = typeLink.tail;
    }
    if (changed) {
      // Create a new link only if necessary.
      return builder.toLink();
    }
    return types;
  }

  /**
   * Returns the [ClassElement] which declares the type variables occurring in
   * [type], or [:null:] if [type] does not contain type variables.
   */
  static ClassElement getClassContext(DartType type) {
    TypeVariableType typeVariable = type.typeVariableOccurrence;
    if (typeVariable == null) return null;
    return typeVariable.element.enclosingElement;
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
  static int compare(DartType a, DartType b) {
    if (a == b) return 0;
    if (a.kind == TypeKind.VOID) {
      // [b] is not void => a < b.
      return -1;
    } else if (b.kind == TypeKind.VOID) {
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
    bool isDefinedByDeclaration(DartType type) {
      return type.kind == TypeKind.INTERFACE ||
             type.kind == TypeKind.TYPEDEF ||
             type.kind == TypeKind.TYPE_VARIABLE;
    }

    if (isDefinedByDeclaration(a)) {
      if (isDefinedByDeclaration(b)) {
        int result = Elements.compareByPosition(a.element, b.element);
        if (result != 0) return result;
        if (a.kind == TypeKind.TYPE_VARIABLE) {
          return b.kind == TypeKind.TYPE_VARIABLE
              ? 0
              : 1; // [b] is not a type variable => a > b.
        } else {
          if (b.kind == TypeKind.TYPE_VARIABLE) {
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
    if (a.kind == TypeKind.FUNCTION) {
      if (b.kind == TypeKind.FUNCTION) {
        FunctionType aFunc = a;
        FunctionType bFunc = b;
        int result = compare(aFunc.returnType, bFunc.returnType);
        if (result != 0) return result;
        result = compareList(aFunc.parameterTypes, bFunc.parameterTypes);
        if (result != 0) return result;
        result = compareList(aFunc.optionalParameterTypes,
                             bFunc.optionalParameterTypes);
        if (result != 0) return result;
        Link<String> aNames = aFunc.namedParameters;
        Link<String> bNames = bFunc.namedParameters;
        while (!aNames.isEmpty && !bNames.isEmpty) {
          int result = aNames.head.compareTo(bNames.head);
          if (result != 0) return result;
          aNames = aNames.tail;
          bNames = bNames.tail;
        }
        if (!aNames.isEmpty) {
          // [aNames] is longer that [bNames] => a > b.
          return 1;
        } else if (!bNames.isEmpty) {
          // [bNames] is longer that [aNames] => a < b.
          return -1;
        }
        return compareList(aFunc.namedParameterTypes,
                           bFunc.namedParameterTypes);
      } else {
        // [b] is a malformed or statement type => a < b.
        return -1;
      }
    } else if (b.kind == TypeKind.FUNCTION) {
      // [b] is a malformed or statement type => a > b.
      return 1;
    }
    if (a.kind == TypeKind.STATEMENT) {
      if (b.kind == TypeKind.STATEMENT) {
        return (a as StatementType).stringName.compareTo(
               (b as StatementType).stringName);
      } else {
        // [b] is a malformed type => a > b.
        return 1;
      }
    } else if (b.kind == TypeKind.STATEMENT) {
      // [a] is a malformed type => a < b.
      return -1;
    }
    assert (a.kind == TypeKind.MALFORMED_TYPE);
    assert (b.kind == TypeKind.MALFORMED_TYPE);
    // TODO(johnniwinther): Can we do this better?
    return Elements.compareByPosition(a.element, b.element);
  }

  static int compareList(Link<DartType> a, Link<DartType> b) {
    while (!a.isEmpty && !b.isEmpty) {
      int result = compare(a.head, b.head);
      if (result != 0) return result;
      a = a.tail;
      b = b.tail;
    }
    if (!a.isEmpty) {
      // [a] is longer than [b] => a > b.
      return 1;
    } else if (!b.isEmpty) {
      // [b] is longer than [a] => a < b.
      return -1;
    }
    return 0;
  }

  static List<DartType> sorted(Iterable<DartType> types) {
    return types.toList()..sort(compare);
  }

  /// Computes the least upper bound of two interface types [a] and [b].
  InterfaceType computeLeastUpperBoundInterfaces(InterfaceType a,
                                                 InterfaceType b) {

    /// Returns the set of supertypes of [type] at depth [depth].
    Set<DartType> getSupertypesAtDepth(InterfaceType type, int depth) {
      OrderedTypeSet types = type.element.allSupertypesAndSelf;
      Set<DartType> set = new Set<DartType>();
      types.forEach(depth, (DartType supertype) {
        set.add(supertype.substByContext(type));
      });
      return set;
    }

    ClassElement aClass = a.element;
    ClassElement bClass = b.element;
    int maxCommonDepth = min(aClass.hierarchyDepth, bClass.hierarchyDepth);
    for (int depth = maxCommonDepth; depth >= 0; depth--) {
      Set<DartType> aTypeSet = getSupertypesAtDepth(a, depth);
      Set<DartType> bTypeSet = getSupertypesAtDepth(b, depth);
      Set<DartType> intersection = aTypeSet..retainAll(bTypeSet);
      if (intersection.length == 1) {
        return intersection.first;
      }
    }
    invariant(CURRENT_ELEMENT_SPANNABLE, false,
        message: 'No least upper bound computed for $a and $b.');
    return null;
  }

  /// Computes the least upper bound of the types in the longest prefix of [a]
  /// and [b].
  Link<DartType> computeLeastUpperBoundsTypes(Link<DartType> a,
                                              Link<DartType> b) {
    if (a.isEmpty || b.isEmpty) return const Link<DartType>();
    LinkBuilder<DartType> types = new LinkBuilder<DartType>();
    while (!a.isEmpty && !b.isEmpty) {
      types.addLast(computeLeastUpperBound(a.head, b.head));
      a = a.tail;
      b = b.tail;
    }
    return types.toLink();
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
  DartType computeLeastUpperBoundFunctionTypes(FunctionType a,
                                               FunctionType b) {
    if (a.parameterTypes.slowLength() != b.parameterTypes.slowLength()) {
      return compiler.functionClass.rawType;
    }
    DartType returnType = computeLeastUpperBound(a.returnType, b.returnType);
    Link<DartType> parameterTypes =
        computeLeastUpperBoundsTypes(a.parameterTypes, b.parameterTypes);
    Link<DartType> optionalParameterTypes =
        computeLeastUpperBoundsTypes(a.optionalParameterTypes,
                                     b.optionalParameterTypes);
    LinkBuilder<String> namedParameters = new LinkBuilder<String>();
    Link<String> aNamedParameters = a.namedParameters;
    Link<String> bNamedParameters = b.namedParameters;
    LinkBuilder<DartType> namedParameterTypes = new LinkBuilder<DartType>();
    Link<DartType> aNamedParameterTypes = a.namedParameterTypes;
    Link<DartType> bNamedParameterTypes = b.namedParameterTypes;
    while (!aNamedParameters.isEmpty && !bNamedParameters.isEmpty) {
      String aNamedParameter = aNamedParameters.head;
      String bNamedParameter = bNamedParameters.head;
      int result = aNamedParameter.compareTo(bNamedParameter);
      if (result == 0) {
        namedParameters.addLast(aNamedParameter);
        namedParameterTypes.addLast(computeLeastUpperBound(
            aNamedParameterTypes.head, bNamedParameterTypes.head));
      }
      if (result <= 0) {
        aNamedParameters = aNamedParameters.tail;
        aNamedParameterTypes = aNamedParameterTypes.tail;
      }
      if (result >= 0) {
        bNamedParameters = bNamedParameters.tail;
        bNamedParameterTypes = bNamedParameterTypes.tail;
      }
    }
    return new FunctionType(compiler.functionClass,
        returnType,
        parameterTypes, optionalParameterTypes,
        namedParameters.toLink(), namedParameterTypes.toLink());
  }

  /// Computes the least upper bound of two types of which at least one is a
  /// type variable. The least upper bound of a type variable is defined in
  /// terms of its bound, but to ensure reflexivity we need to check for common
  /// bounds transitively.
  DartType computeLeastUpperBoundTypeVariableTypes(DartType a,
                                                   DartType b) {
    Set<DartType> typeVariableBounds = new Set<DartType>();
    while (a.kind == TypeKind.TYPE_VARIABLE) {
      if (a == b) return a;
      typeVariableBounds.add(a);
      TypeVariableElement element = a.element;
      a = element.bound;
    }
    while (b.kind == TypeKind.TYPE_VARIABLE) {
      if (typeVariableBounds.contains(b)) return b;
      TypeVariableElement element = b.element;
      b = element.bound;
    }
    return computeLeastUpperBound(a, b);
  }

  /// Computes the least upper bound for [a] and [b].
  DartType computeLeastUpperBound(DartType a, DartType b) {
    if (a == b) return a;

    if (a.kind == TypeKind.TYPE_VARIABLE ||
           b.kind == TypeKind.TYPE_VARIABLE) {
      return computeLeastUpperBoundTypeVariableTypes(a, b);
    }

    a = a.unalias(compiler);
    b = b.unalias(compiler);

    if (a.treatAsDynamic || b.treatAsDynamic) return dynamicType;
    if (a.isVoid || b.isVoid) return voidType;

    if (a.kind == TypeKind.FUNCTION && b.kind == TypeKind.FUNCTION) {
      return computeLeastUpperBoundFunctionTypes(a, b);
    }

    if (a.kind == TypeKind.FUNCTION) {
      a = compiler.functionClass.rawType;
    }
    if (b.kind == TypeKind.FUNCTION) {
      b = compiler.functionClass.rawType;
    }

    if (a.kind == TypeKind.INTERFACE && b.kind == TypeKind.INTERFACE) {
      return computeLeastUpperBoundInterfaces(a, b);
    }
    return dynamicType;
  }
}

/**
 * Type visitor that determines one type could a subtype of another given the
 * right type variable substitution. The computation is approximate and returns
 * [:false:] only if we are sure no such substitution exists.
 */
class PotentialSubtypeVisitor extends SubtypeVisitor {
  PotentialSubtypeVisitor(Compiler compiler,
                          DynamicType dynamicType,
                          VoidType voidType)
      : super(compiler, dynamicType, voidType);


  bool isSubtype(DartType t, DartType s) {
    if (t is TypeVariableType || s is TypeVariableType) {
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
class MoreSpecificSubtypeVisitor extends DartTypeVisitor<bool, DartType> {
  final Compiler compiler;
  Map<TypeVariableType, DartType> constraintMap;

  MoreSpecificSubtypeVisitor(Compiler this.compiler);

  /// Compute an instance of [element] which is more specific than [supertype].
  /// If no instance is found, `null` is returned.
  ///
  /// Note that this computation is a heuristic. It does not find a suggestion
  /// in all possible cases.
  InterfaceType computeMoreSpecific(ClassElement element,
                                    InterfaceType supertype) {
    InterfaceType supertypeInstance =
        element.thisType.asInstanceOf(supertype.element);
    if (supertypeInstance == null) return null;

    constraintMap = new Map<TypeVariableType, DartType>();
    element.typeVariables.forEach((TypeVariableType typeVariable) {
      constraintMap[typeVariable] = compiler.types.dynamicType;
    });
    if (supertypeInstance.accept(this, supertype)) {
      LinkBuilder<DartType> typeArguments = new LinkBuilder<DartType>();
      element.typeVariables.forEach((TypeVariableType typeVariable) {
        typeArguments.addLast(constraintMap[typeVariable]);
      });
      return element.thisType.createInstantiation(typeArguments.toLink());
    }
    return null;
  }

  bool visitType(DartType type, DartType argument) {
    return compiler.types.isMoreSpecific(type, argument);
  }

  bool visitTypes(Link<DartType> a, Link<DartType> b) {
    while (!a.isEmpty && !b.isEmpty) {
      if (!a.head.accept(this, b.head)) return false;
      a = a.tail;
      b = b.tail;
    }
    return a.isEmpty && b.isEmpty;
  }

  bool visitTypeVariableType(TypeVariableType type, DartType argument) {
    DartType constraint =
        compiler.types.getMostSpecific(constraintMap[type], argument);
    constraintMap[type] = constraint;
    return constraint != null;
  }

  bool visitFunctionType(FunctionType type, DartType argument) {
    if (argument is FunctionType) {
      if (type.parameterTypes.slowLength() !=
          argument.parameterTypes.slowLength()) {
        return false;
      }
      if (type.optionalParameterTypes.slowLength() !=
          argument.optionalParameterTypes.slowLength()) {
        return false;
      }
      if (type.namedParameters != argument.namedParameters) {
        return false;
      }

      if (!type.returnType.accept(this, argument.returnType)) return false;
      if (visitTypes(type.parameterTypes, argument.parameterTypes)) {
        return false;
      }
      if (visitTypes(type.optionalParameterTypes,
                     argument.optionalParameterTypes)) {
        return false;
      }
      return visitTypes(type.namedParameterTypes, argument.namedParameterTypes);
    }
    return false;
  }

  bool visitGenericType(GenericType type, DartType argument) {
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
class TypeDeclarationFormatter extends DartTypeVisitor<dynamic, String> {
  Set<String> usedNames;
  StringBuffer sb;

  /// Creates textual representation of [type] as if a member by the [name] were
  /// declared. For instance 'String foo' for `format(String, 'foo')`.
  String format(DartType type, String name) {
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

  void visit(DartType type) {
    type.accept(this, null);
  }

  void visitTypes(Link<DartType> types, String prefix) {
    bool needsComma = false;
    for (Link<DartType> link = types;
        !link.isEmpty;
        link = link.tail) {
      if (needsComma) {
        sb.write(', ');
      }
      link.head.accept(this, prefix);
      needsComma = true;
    }  }

  void visitType(DartType type, String name) {
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

  void visitFunctionType(FunctionType type, String name) {
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
      Link<String> namedParameter = type.namedParameters;
      Link<DartType> namedParameterType = type.namedParameterTypes;
      needsComma = false;
      while (!namedParameter.isEmpty && !namedParameterType.isEmpty) {
        if (needsComma) {
          sb.write(', ');
        }
        namedParameterType.head.accept(this, namedParameter.head);
        namedParameter = namedParameter.tail;
        namedParameterType = namedParameterType.tail;
        needsComma = true;
      }
      sb.write('}');
    }
    sb.write(')');
  }
}

