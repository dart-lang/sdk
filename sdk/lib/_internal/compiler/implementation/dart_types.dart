// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_types;

import 'dart2jslib.dart' show Compiler, invariant, Script, Message;
import 'elements/modelx.dart'
    show VoidElementX, LibraryElementX, BaseClassElementX;
import 'elements/elements.dart';
import 'util/util.dart' show Link, LinkBuilder;

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
  final Link<DartType> typeArguments;

  GenericType(Link<DartType> this.typeArguments);

  TypeDeclarationElement get element;

  /// Creates a new instance of this type using the provided type arguments.
  GenericType _createType(Link<DartType> newTypeArguments);

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
      return _createType(newTypeArguments);
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
  final ClassElement element;

  InterfaceType(this.element,
                [Link<DartType> typeArguments = const Link<DartType>()])
      : super(typeArguments) {
    assert(invariant(element, element.isDeclaration));
    assert(invariant(element, element.thisType == null ||
        typeArguments.slowLength() == element.typeVariables.slowLength(),
        message: () => 'Invalid type argument count on ${element.thisType}. '
                       'Provided type arguments: $typeArguments.'));
  }

  InterfaceType.forUserProvidedBadType(this.element,
                                       [Link<DartType> typeArguments =
                                           const Link<DartType>()])
      : super(typeArguments);

  TypeKind get kind => TypeKind.INTERFACE;

  String get name => element.name;

  InterfaceType _createType(Link<DartType> newTypeArguments) {
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

  /**
   * Finds the method, field or property named [name] declared or inherited
   * on this interface type.
   */
  Member lookupMember(String name, {bool isSetter: false}) {
    // Abstract field returned when setter was needed but only a getter was
    // present and vice-versa.
    Member fallbackAbstractField;

    Member createMember(ClassElement classElement,
                        InterfaceType receiver, InterfaceType declarer) {
      Element member = classElement.implementation.lookupLocalMember(name);
      if (member == null) return null;
      if (member.isConstructor() || member.isPrefix()) return null;
      assert(member.isFunction() ||
             member.isAbstractField() ||
             member.isField());

      if (member.isAbstractField()) {
        AbstractFieldElement abstractFieldElement = member;
        if (fallbackAbstractField == null) {
          fallbackAbstractField =
              new Member(receiver, declarer, member, isSetter: isSetter);
        }
        if (isSetter && abstractFieldElement.setter == null) {
          // Keep searching further up the hierarchy.
          member = null;
        } else if (!isSetter && abstractFieldElement.getter == null) {
          // Keep searching further up the hierarchy.
          member = null;
        }
      }
      return member != null
          ? new Member(receiver, declarer, member, isSetter: isSetter) : null;
    }

    ClassElement classElement = element;
    InterfaceType receiver = this;
    InterfaceType declarer = receiver;
    // TODO(johnniwinther): Lookup and callers should handle private members and
    // injected members.
    Member member = createMember(classElement, receiver, declarer);
    if (member != null) return member;

    assert(invariant(element, classElement.allSupertypes != null,
        message: 'Supertypes not computed for $classElement'));
    for (InterfaceType supertype in classElement.allSupertypes) {
      // Skip mixin applications since their supertypes are also in the list of
      // [allSupertypes].
      if (supertype.element.isMixinApplication) continue;
      declarer = supertype;
      ClassElement lookupTarget = declarer.element;
      Member member = createMember(lookupTarget, receiver, declarer);
      if (member != null) return member;
    }

    return fallbackAbstractField;
  }

  int get hashCode => super.hashCode;

  InterfaceType asRaw() => super.asRaw();

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitInterfaceType(this, argument);
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
               Link<DartType> this.parameterTypes,
               Link<DartType> this.optionalParameterTypes,
               Link<String> this.namedParameters,
               Link<DartType> this.namedParameterTypes) {
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
  final TypedefElement element;

  // TODO(johnniwinther): Assert that the number of arguments and parameters
  // match, like for [InterfaceType].
  TypedefType(this.element,
              [Link<DartType> typeArguments = const Link<DartType>()])
      : super(typeArguments);

  TypedefType _createType(Link<DartType> newTypeArguments) {
    return new TypedefType(element, newTypeArguments);
  }

  TypedefType.forUserProvidedBadType(this.element,
                                     [Link<DartType> typeArguments =
                                         const Link<DartType>()])
      : super(typeArguments);

  TypeKind get kind => TypeKind.TYPEDEF;

  String get name => element.name;

  DartType unalias(Compiler compiler) {
    // TODO(ahe): This should be [ensureResolved].
    compiler.resolveTypedef(element);
    element.checkCyclicReference(compiler);
    DartType definition = element.alias.unalias(compiler);
    TypedefType declaration = element.computeType(compiler);
    return definition.subst(typeArguments, declaration.typeArguments);
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
 * Member encapsulates a member (method, field, property) with the types of the
 * declarer and receiver in order to do substitution on the member type.
 *
 * Consider for instance these classes and the variable [: B<String> b :]:
 *
 *     class A<E> {
 *       E field;
 *     }
 *     class B<F> extends A<F> {}
 *
 * In a [Member] for [: b.field :] the [receiver] is the type [: B<String> :]
 * and the declarer is the type [: A<F> :], which is the supertype of [: B<F> :]
 * from which [: field :] has been inherited. To compute the type of
 * [: b.field :] we must first substitute [: E :] by [: F :] using the relation
 * between [: A<E> :] and [: A<F> :], and then [: F :] by [: String :] using the
 * relation between [: B<F> :] and [: B<String> :].
 */
// TODO(johnniwinther): Add [isReadable] and [isWritable] predicates.
class Member {
  final InterfaceType receiver;
  final InterfaceType declarer;
  final Element element;
  DartType cachedType;
  final bool isSetter;

  Member(this.receiver, this.declarer, this.element,
         {bool this.isSetter: false}) {
    assert(invariant(element, element.isAbstractField() ||
                              element.isField() ||
                              element.isFunction(),
                     message: "Unsupported Member element: $element"));
  }

  DartType computeType(Compiler compiler) {
    if (cachedType == null) {
      DartType type;
      if (element.isAbstractField()) {
        AbstractFieldElement abstractFieldElement = element;
        // Use setter if present and required or if no getter is available.
        if ((isSetter && abstractFieldElement.setter != null) ||
            abstractFieldElement.getter == null) {
          // TODO(johnniwinther): Add check of read of field with no getter.
          FunctionType functionType =
              abstractFieldElement.setter.computeType(
                  compiler);
          type = functionType.parameterTypes.head;
          if (type == null) {
            type = compiler.types.dynamicType;
          }
        } else {
          // TODO(johnniwinther): Add check of assignment to field with no
          // setter.
          FunctionType functionType =
              abstractFieldElement.getter.computeType(compiler);
          type = functionType.returnType;
        }
      } else {
        type = element.computeType(compiler);
      }
      if (!declarer.element.typeVariables.isEmpty) {
        type = type.subst(declarer.typeArguments,
                          declarer.element.typeVariables);
        type = type.subst(receiver.typeArguments,
                          receiver.element.typeVariables);
      }
      cachedType = type;
    }
    return cachedType;
  }

  String toString() {
    return '$receiver.${element.name}';
  }
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

    lookupCall(type) => type.lookupMember(Compiler.CALL_OPERATOR_NAME);

    if (s is InterfaceType &&
        s.element == compiler.functionClass &&
        lookupCall(t) != null) {
      return true;
    } else if (s is FunctionType) {
      Member call = lookupCall(t);
      if (call == null) return false;
      return isSubtype(call.computeType(compiler), s);
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
    LibraryElement library = new LibraryElementX(new Script(null, null));
    VoidType voidType = new VoidType(new VoidElementX(library));
    DynamicType dynamicType = new DynamicType(dynamicElement);
    dynamicElement.rawTypeCache = dynamicElement.thisType = dynamicType;
    MoreSpecificVisitor moreSpecificVisitor =
        new MoreSpecificVisitor(compiler, dynamicType, voidType);
    SubtypeVisitor subtypeVisitor =
        new SubtypeVisitor(compiler, dynamicType, voidType);
    PotentialSubtypeVisitor potentialSubtypeVisitor =
        new PotentialSubtypeVisitor(compiler, dynamicType, voidType);

    return new Types.internal(compiler, voidType, dynamicType,
        moreSpecificVisitor, subtypeVisitor, potentialSubtypeVisitor);
  }

  Types.internal(this.compiler, this.voidType, this.dynamicType,
                 this.moreSpecificVisitor, this.subtypeVisitor,
                 this.potentialSubtypeVisitor);

  /** Returns true if t is more specific than s */
  bool isMoreSpecific(DartType t, DartType s) {
    return moreSpecificVisitor.isMoreSpecific(t, s);
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
      DartType bound = typeVariable.element.bound.subst(
          type.typeArguments, element.typeVariables);
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
