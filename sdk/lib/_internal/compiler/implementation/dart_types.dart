// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_types;

import 'dart2jslib.dart' show Compiler, invariant, Script, Message;
import 'elements/modelx.dart' show VoidElementX, LibraryElementX;
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

  String toString() {
    var sb = new StringBuffer();
    if (typeArguments != null) {
      if (userProvidedBadType != null) {
        sb.add(userProvidedBadType.name.slowToString());
      } else {
        sb.add(element.name.slowToString());
      }
      if (!typeArguments.isEmpty) {
        sb.add('<');
        typeArguments.printOn(sb, ', ');
        sb.add('>');
      }
    } else {
      sb.add(userProvidedBadType.toString());
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

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add(name.slowToString());
    if (!isRaw) {
      sb.add('<');
      typeArguments.printOn(sb, ', ');
      sb.add('>');
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
  }

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

  bool operator ==(other) {
    if (other is !InterfaceType) return false;
    return super == other;
  }

  InterfaceType asRaw() => super.asRaw();
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
    assert(element == null || invariant(element, element.isDeclaration));
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

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add('(');
    parameterTypes.printOn(sb, ', ');
    bool first = parameterTypes.isEmpty;
    if (!optionalParameterTypes.isEmpty) {
      if (!first) {
        sb.add(', ');
      }
      sb.add('[');
      optionalParameterTypes.printOn(sb, ', ');
      sb.add(']');
      first = false;
    }
    if (!namedParameterTypes.isEmpty) {
      if (!first) {
        sb.add(', ');
      }
      sb.add('{');
      Link<SourceString> namedParameter = namedParameters;
      Link<DartType> namedParameterType = namedParameterTypes;
      first = true;
      while (!namedParameter.isEmpty && !namedParameterType.isEmpty) {
        if (!first) {
          sb.add(', ');
        }
        sb.add(namedParameterType.head);
        sb.add(' ');
          sb.add(namedParameter.head.slowToString());
        namedParameter = namedParameter.tail;
        namedParameterType = namedParameterType.tail;
        first = false;
      }
      sb.add('}');
    }
    sb.add(') -> ${returnType}');
    return sb.toString();
  }

  SourceString get name => const SourceString('Function');

  int computeArity() {
    int arity = 0;
    parameterTypes.forEach((_) { arity++; });
    return arity;
  }

  int get hashCode {
    int hash = 17 * element.hashCode + 3 * returnType.hashCode;
    for (DartType parameter  in parameterTypes) {
      hash = 17 * hash + 3 * parameter.hashCode;
    }
    for (DartType parameter  in optionalParameterTypes) {
      hash = 17 * hash + 3 * parameter.hashCode;
    }
    for (SourceString name  in namedParameters) {
      hash = 17 * hash + 3 * name.hashCode;
    }
    for (DartType parameter  in namedParameterTypes) {
      hash = 17 * hash + 3 * parameter.hashCode;
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

  TypedefType(this.element,
              [Link<DartType> typeArguments = const Link<DartType>()])
      : super(typeArguments, hasMalformed(typeArguments));

  TypedefType _createType(Link<DartType> newTypeArguments) {
    return new TypedefType(element, newTypeArguments);
  }

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
}

/**
 * Special type to hold the [dynamic] type. Used for correctly returning
 * 'dynamic' on [toString].
 */
class DynamicType extends InterfaceType {
  DynamicType(ClassElement element) : super(element);

  SourceString get name => const SourceString('dynamic');
}

class Types {
  final Compiler compiler;
  // TODO(karlklose): should we have a class Void?
  final VoidType voidType;
  final DynamicType dynamicType;

  factory Types(Compiler compiler, ClassElement dynamicElement) {
    LibraryElement library = new LibraryElementX(new Script(null, null));
    VoidType voidType = new VoidType(new VoidElementX(library));
    DynamicType dynamicType = new DynamicType(dynamicElement);
    dynamicElement.rawType = dynamicElement.thisType = dynamicType;
    return new Types.internal(compiler, voidType, dynamicType);
  }

  Types.internal(this.compiler, this.voidType, this.dynamicType);

  /** Returns true if t is a subtype of s */
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

    if (t is VoidType) {
      return false;
    } else if (t is InterfaceType) {
      if (s is !InterfaceType) return false;
      ClassElement tc = t.element;
      if (identical(tc, s.element)) return true;
      for (Link<DartType> supertypes = tc.allSupertypes;
           supertypes != null && !supertypes.isEmpty;
           supertypes = supertypes.tail) {
        DartType supertype = supertypes.head;
        if (identical(supertype.element, s.element)) return true;
      }
      return false;
    } else if (t is FunctionType) {
      if (identical(s.element, compiler.functionClass)) return true;
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
      if (!isAssignable(sf.returnType, tf.returnType)) return false;
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
    } else if (t is TypeVariableType) {
      if (s is !TypeVariableType) return false;
      return (identical(t.element, s.element));
    } else {
      throw 'internal error: unknown type kind';
    }
  }

  bool isAssignable(DartType r, DartType s) {
    return isSubtype(r, s) || isSubtype(s, r);
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
    return Strings.join(reasons, ', ');
  }
}
