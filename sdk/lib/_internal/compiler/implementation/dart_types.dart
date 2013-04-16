// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_types;

import 'dart2jslib.dart' show Compiler, invariant, Script, Message;
import 'elements/modelx.dart'
    show VoidElementX, LibraryElementX, BaseClassElementX;
import 'elements/elements.dart';
import 'scanner/scannerlib.dart' show SourceString;
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
  SourceString get name;

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
   * Finds the method, field or property named [name] declared or inherited
   * on this type.
   */
  // TODO(johnniwinther): Implement this for [TypeVariableType], [FunctionType],
  // and [TypedefType].
  Member lookupMember(SourceString name) => null;

  /**
   * A type is malformed if it is itself a malformed type or contains a
   * malformed type.
   */
  bool get isMalformed => false;

  /**
   * Calls [f] with each [MalformedType] within this type.
   *
   * If [f] returns [: false :], the traversal stops prematurely.
   *
   * [forEachMalformedType] returns [: false :] if the traversal was stopped
   * prematurely.
   */
  bool forEachMalformedType(bool f(MalformedType type)) => true;

  bool operator ==(other);

  /**
   * Is [: true :] if this type has no explict type arguments.
   */
  bool get isRaw => true;

  DartType asRaw() => this;

  /**
   * Is [: true :] if this type is the dynamic type.
   */
  bool get isDynamic => false;

  /**
   * Is [: true :] if this type is the void type.
   */
  bool get isVoid => false;

  /**
   * Returns an occurrence of a type variable within this type, if any.
   */
  TypeVariableType get typeVariableOccurrence => null;

  TypeVariableType _findTypeVariableOccurrence(Link<DartType> types) {
    for (Link<DartType> link = types; !link.isEmpty ; link = link.tail) {
      TypeVariableType typeVariable = link.head.typeVariableOccurrence;
      if (typeVariable != null) {
        return typeVariable;
      }
    }
    return null;
  }

  /**
   * Is [: true :] if this type contains any type variables.
   */
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

  SourceString get name => element.name;

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

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitTypeVariableType(this, argument);
  }

  int get hashCode => 17 * element.hashCode;

  bool operator ==(other) {
    if (other is !TypeVariableType) return false;
    return identical(other.element, element);
  }

  String toString() => name.slowToString();
}

/**
 * A statement type tracks whether a statement returns or may return.
 */
class StatementType extends DartType {
  final String stringName;

  Element get element => null;

  TypeKind get kind => TypeKind.STATEMENT;

  SourceString get name => new SourceString(stringName);

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

  SourceString get name => element.name;

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

  String toString() => name.slowToString();
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

  MalformedType(this.element, this.userProvidedBadType,
                [this.typeArguments = null]);

  TypeKind get kind => TypeKind.MALFORMED_TYPE;

  SourceString get name => element.name;

  DartType subst(Link<DartType> arguments, Link<DartType> parameters) {
    // Malformed types are not substitutable.
    return this;
  }

  bool get isMalformed => true;

  bool forEachMalformedType(bool f(MalformedType type)) => f(this);

  DartType unalias(Compiler compiler) => this;

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitMalformedType(this, argument);
  }

  String toString() {
    var sb = new StringBuffer();
    if (typeArguments != null) {
      if (userProvidedBadType != null) {
        sb.write(userProvidedBadType.name.slowToString());
      } else {
        sb.write(element.name.slowToString());
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

bool hasMalformed(Link<DartType> types) {
  for (DartType typeArgument in types) {
    if (typeArgument.isMalformed) {
      return true;
    }
  }
  return false;
}

abstract class GenericType extends DartType {
  final Link<DartType> typeArguments;
  final bool isMalformed;

  GenericType(Link<DartType> this.typeArguments, bool this.isMalformed);

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

  bool forEachMalformedType(bool f(MalformedType type)) {
    for (DartType typeArgument in typeArguments) {
      if (!typeArgument.forEachMalformedType(f)) {
        return false;
      }
    }
    return true;
  }

  TypeVariableType get typeVariableOccurrence {
    return _findTypeVariableOccurrence(typeArguments);
  }

  void visitChildren(DartTypeVisitor visitor, var argument) {
    DartType.visitList(typeArguments, visitor, argument);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(name.slowToString());
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
    if (!identical(element, other.element)) return false;
    return typeArguments == other.typeArguments;
  }

  bool get isRaw => typeArguments.isEmpty || identical(this, element.rawType);

  GenericType asRaw() => element.rawType;
}

// TODO(johnniwinther): Add common supertype for InterfaceType and TypedefType.
class InterfaceType extends GenericType {
  final ClassElement element;

  InterfaceType(this.element,
                [Link<DartType> typeArguments = const Link<DartType>()])
      : super(typeArguments, hasMalformed(typeArguments)) {
    assert(invariant(element, element.isDeclaration));
    assert(invariant(element, element.thisType == null ||
        typeArguments.slowLength() == element.typeVariables.slowLength(),
        message: () => 'Invalid type argument count on ${element.thisType}. '
                       'Provided type arguments: $typeArguments.'));
  }

  InterfaceType.userProvidedBadType(this.element,
                                    [Link<DartType> typeArguments =
                                        const Link<DartType>()])
      : super(typeArguments, true);

  TypeKind get kind => TypeKind.INTERFACE;

  SourceString get name => element.name;

  InterfaceType _createType(Link<DartType> newTypeArguments) {
    return new InterfaceType(element, newTypeArguments);
  }

  /**
   * Returns the type as an instance of class [other], if possible, null
   * otherwise.
   */
  DartType asInstanceOf(ClassElement other) {
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
  Member lookupMember(SourceString name) {

    Member createMember(InterfaceType receiver, InterfaceType declarer,
                        Element member) {
      if (member.kind == ElementKind.FUNCTION ||
          member.kind == ElementKind.ABSTRACT_FIELD ||
          member.kind == ElementKind.FIELD) {
        return new Member(receiver, declarer, member);
      }
      return null;
    }

    ClassElement classElement = element;
    InterfaceType receiver = this;
    InterfaceType declarer = receiver;
    Element member = classElement.lookupLocalMember(name);
    if (member != null) {
      return createMember(receiver, declarer, member);
    }
    for (DartType supertype in classElement.allSupertypes) {
      declarer = supertype;
      ClassElement lookupTarget = declarer.element;
      member = lookupTarget.lookupLocalMember(name);
      if (member != null) {
        return createMember(receiver, declarer, member);
      }
    }
    return null;
  }

  bool operator ==(other) {
    if (other is !InterfaceType) return false;
    return super == other;
  }

  InterfaceType asRaw() => super.asRaw();

  accept(DartTypeVisitor visitor, var argument) {
    return visitor.visitInterfaceType(this, argument);
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
  final Link<SourceString> namedParameters;

  /**
   * The types of the named parameters in the order corresponding to the
   * [namedParameters].
   */
  final Link<DartType> namedParameterTypes;
  final bool isMalformed;

  factory FunctionType(Element element,
                       DartType returnType,
                       Link<DartType> parameterTypes,
                       Link<DartType> optionalParameterTypes,
                       Link<SourceString> namedParameters,
                       Link<DartType> namedParameterTypes) {
    // Compute [isMalformed] eagerly since it is faster than a lazy computation
    // and since [isMalformed] most likely will be accessed in [Types.isSubtype]
    // anyway.
    bool isMalformed = returnType != null &&
                       returnType.isMalformed ||
                       hasMalformed(parameterTypes) ||
                       hasMalformed(optionalParameterTypes) ||
                       hasMalformed(namedParameterTypes);
    return new FunctionType.internal(element,
                                     returnType,
                                     parameterTypes,
                                     optionalParameterTypes,
                                     namedParameters,
                                     namedParameterTypes,
                                     isMalformed);
  }

  FunctionType.internal(Element this.element,
                        DartType this.returnType,
                        Link<DartType> this.parameterTypes,
                        Link<DartType> this.optionalParameterTypes,
                        Link<SourceString> this.namedParameters,
                        Link<DartType> this.namedParameterTypes,
                        bool this.isMalformed) {
    assert(invariant(element, element.isDeclaration));
    // Assert that optional and named parameters are not used at the same time.
    assert(optionalParameterTypes.isEmpty || namedParameterTypes.isEmpty);
    assert(namedParameters.slowLength() == namedParameterTypes.slowLength());
  }

  TypeKind get kind => TypeKind.FUNCTION;

  DartType getNamedParameterType(SourceString name) {
    Link<SourceString> namedParameter = namedParameters;
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

  bool forEachMalformedType(bool f(MalformedType type)) {
    if (!returnType.forEachMalformedType(f)) {
      return false;
    }
    for (DartType parameterType in parameterTypes) {
      if (!parameterType.forEachMalformedType(f)) {
        return false;
      }
    }
    for (DartType parameterType in optionalParameterTypes) {
      if (!parameterType.forEachMalformedType(f)) {
        return false;
      }
    }
    for (DartType parameterType in namedParameterTypes) {
      if (!parameterType.forEachMalformedType(f)) {
        return false;
      }
    }
    return true;
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
      Link<SourceString> namedParameter = namedParameters;
      Link<DartType> namedParameterType = namedParameterTypes;
      first = true;
      while (!namedParameter.isEmpty && !namedParameterType.isEmpty) {
        if (!first) {
          sb.write(', ');
        }
        sb.write(namedParameterType.head);
        sb.write(' ');
          sb.write(namedParameter.head.slowToString());
        namedParameter = namedParameter.tail;
        namedParameterType = namedParameterType.tail;
        first = false;
      }
      sb.write('}');
    }
    sb.write(') -> ${returnType}');
    return sb.toString();
  }

  SourceString get name => const SourceString('Function');

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
    for (SourceString name  in namedParameters) {
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
      : super(typeArguments, hasMalformed(typeArguments));

  TypedefType _createType(Link<DartType> newTypeArguments) {
    return new TypedefType(element, newTypeArguments);
  }

  TypedefType.userProvidedBadType(this.element,
                                  [Link<DartType> typeArguments =
                                      const Link<DartType>()])
      : super(typeArguments, true);

  TypeKind get kind => TypeKind.TYPEDEF;

  SourceString get name => element.name;

  DartType unalias(Compiler compiler) {
    // TODO(ahe): This should be [ensureResolved].
    compiler.resolveTypedef(element);
    DartType definition = element.alias.unalias(compiler);
    TypedefType declaration = element.computeType(compiler);
    return definition.subst(typeArguments, declaration.typeArguments);
  }

  bool operator ==(other) {
    if (other is !TypedefType) return false;
    return super == other;
  }

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

  SourceString get name => const SourceString('dynamic');

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
class Member {
  final InterfaceType receiver;
  final InterfaceType declarer;
  final Element element;
  DartType cachedType;

  Member(this.receiver, this.declarer, this.element) {
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
        if (abstractFieldElement.getter != null) {
          FunctionType functionType =
              abstractFieldElement.getter.computeType(compiler);
          type = functionType.returnType;
        } else {
          FunctionType functionType =
              abstractFieldElement.setter.computeType(
                  compiler);
          type = functionType.parameterTypes.head;
          if (type == null) {
            type = compiler.types.dynamicType;
          }
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
    return '$receiver.${element.name.slowToString()}';
  }
}

abstract class DartTypeVisitor<R, A> {
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

class SubtypeVisitor extends DartTypeVisitor<bool, DartType> {
  final Compiler compiler;
  final DynamicType dynamicType;
  final VoidType voidType;

  SubtypeVisitor(Compiler this.compiler,
                 DynamicType this.dynamicType,
                 VoidType this.voidType);

  bool isSubtype(DartType t, DartType s) {
    if (identical(t, s) ||
        identical(t, dynamicType) ||
        identical(s, dynamicType) ||
        t.isMalformed ||
        s.isMalformed ||
        identical(s.element, compiler.objectClass) ||
        identical(t.element, compiler.nullClass)) {
      return true;
    }
    t = t.unalias(compiler);
    s = s.unalias(compiler);

    return t.accept(this, s);
  }

  bool isAssignable(DartType t, DartType s) {
    return isSubtype(t, s) || isSubtype(s, t);
  }

  bool visitType(DartType t, DartType s) {
    throw 'internal error: unknown type kind ${t.kind}';
  }

  bool visitVoidType(VoidType t, DartType s) {
    assert(s is! VoidType);
    return false;
  }

  bool visitInterfaceType(InterfaceType t, DartType s) {

    bool checkTypeArguments(InterfaceType instance, InterfaceType other) {
      Link<DartType> tTypeArgs = instance.typeArguments;
      Link<DartType> sTypeArgs = other.typeArguments;
      while (!tTypeArgs.isEmpty) {
        assert(!sTypeArgs.isEmpty);
        if (!isSubtype(tTypeArgs.head, sTypeArgs.head)) {
          return false;
        }
        tTypeArgs = tTypeArgs.tail;
        sTypeArgs = sTypeArgs.tail;
      }
      assert(sTypeArgs.isEmpty);
      return true;
    }

    lookupCall(type) => type.lookupMember(Compiler.CALL_OPERATOR_NAME);

    // TODO(johnniwinther): Currently needed since literal types like int,
    // double, bool etc. might not have been resolved yet.
    t.element.ensureResolved(compiler);

    if (s is InterfaceType) {
      if (s.element == compiler.functionClass && lookupCall(t) != null) {
        return true;
      }
      InterfaceType instance = t.asInstanceOf(s.element);
      return instance != null && checkTypeArguments(instance, s);
    } else if (s is FunctionType) {
      Member call = lookupCall(t);
      if (call == null) return false;
      return isSubtype(call.computeType(compiler), s);
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
    Link<DartType> tps = tf.parameterTypes;
    Link<DartType> sps = sf.parameterTypes;
    while (!tps.isEmpty && !sps.isEmpty) {
      if (!isAssignable(tps.head, sps.head)) return false;
      tps = tps.tail;
      sps = sps.tail;
    }
    if (!tps.isEmpty || !sps.isEmpty) return false;
    if (!identical(sf.returnType, voidType) &&
        !isAssignable(tf.returnType, sf.returnType)) {
      return false;
    }
    if (!sf.namedParameters.isEmpty) {
      // Since named parameters are globally ordered we can determine the
      // subset relation with a linear search for [:sf.NamedParameters:]
      // within [:tf.NamedParameters:].
      Link<SourceString> tNames = tf.namedParameters;
      Link<DartType> tTypes = tf.namedParameterTypes;
      Link<SourceString> sNames = sf.namedParameters;
      Link<DartType> sTypes = sf.namedParameterTypes;
      while (!tNames.isEmpty && !sNames.isEmpty) {
        if (sNames.head == tNames.head) {
          if (!isAssignable(tTypes.head, sTypes.head)) return false;

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
    }
    if (!sf.optionalParameterTypes.isEmpty) {
      Link<DartType> tOptionalParameterType = tf.optionalParameterTypes;
      Link<DartType> sOptionalParameterType = sf.optionalParameterTypes;
      while (!tOptionalParameterType.isEmpty &&
             !sOptionalParameterType.isEmpty) {
        if (!isAssignable(tOptionalParameterType.head,
                          sOptionalParameterType.head)) {
          return false;
        }
        sOptionalParameterType = sOptionalParameterType.tail;
        tOptionalParameterType = tOptionalParameterType.tail;
      }
      if (!sOptionalParameterType.isEmpty) {
        // We didn't find enough optional parameters.
        return false;
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
    return isSubtype(bound, s);
  }
}

class Types {
  final Compiler compiler;
  // TODO(karlklose): should we have a class Void?
  final VoidType voidType;
  final DynamicType dynamicType;
  final SubtypeVisitor subtypeVisitor;

  factory Types(Compiler compiler, BaseClassElementX dynamicElement) {
    LibraryElement library = new LibraryElementX(new Script(null, null));
    VoidType voidType = new VoidType(new VoidElementX(library));
    DynamicType dynamicType = new DynamicType(dynamicElement);
    dynamicElement.rawTypeCache = dynamicElement.thisType = dynamicType;
    SubtypeVisitor subtypeVisitor =
        new SubtypeVisitor(compiler, dynamicType, voidType);
    return new Types.internal(compiler, voidType, dynamicType, subtypeVisitor);
  }

  Types.internal(this.compiler, this.voidType, this.dynamicType,
                 this.subtypeVisitor);

  /** Returns true if t is a subtype of s */
  bool isSubtype(DartType t, DartType s) {
    return subtypeVisitor.isSubtype(t, s);
  }

  bool isAssignable(DartType r, DartType s) {
    return subtypeVisitor.isAssignable(r, s);
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
   * Combine error messages in a malformed type to a single message string.
   */
  static String fetchReasonsFromMalformedType(DartType type) {
    // TODO(johnniwinther): Figure out how to produce good error message in face
    // of multiple errors, and how to ensure non-localized error messages.
    var reasons = new List<String>();
    type.forEachMalformedType((MalformedType malformedType) {
      ErroneousElement error = malformedType.element;
      Message message = error.messageKind.message(error.messageArguments);
      reasons.add(message.toString());
      return true;
    });
    return reasons.join(', ');
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
}
