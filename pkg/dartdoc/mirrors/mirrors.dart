// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mirrors');

#import('dart:io');
#import('dart:uri');
#import('dart2js_mirror.dart');

/**
 * [Compilation] encapsulates the compilation of a program.
 */
class Compilation {
  /**
   * Creates a new compilation which has [script] as its entry point.
   */
  factory Compilation(Path script,
                      Path libraryRoot,
                      [Path packageRoot,
                       List<String> opts = const <String>[]]) {
    return new Dart2JsCompilation(script, libraryRoot, packageRoot, opts);
  }

  /**
   * Creates a new compilation which consists of a set of libraries, but which
   * has no entry point. This compilation cannot generate output but can only
   * be used for static inspection of the source code.
   */
  factory Compilation.library(List<Path> libraries,
                              Path libraryRoot,
                              [Path packageRoot,
                               List<String> opts = const []]) {
    return new Dart2JsCompilation.library(libraries, libraryRoot,
                                          packageRoot, opts);
  }

  /**
   * Returns the mirror system for this compilation.
   */
  final MirrorSystem mirrors;

  /**
   * Returns a future for the compiled JavaScript code.
   */
  abstract Future<String> compileToJavaScript();
}

/**
 * The main interface for the whole mirror system.
 */
interface MirrorSystem {
  /**
   * Returns an unmodifiable map of all libraries in this mirror system.
   */
  final Map<Object, LibraryMirror> libraries;
}


/**
 * An entity in the mirror system.
 */
interface Mirror extends Hashable {
  /**
   * The simple name of the entity. The simple name is in most cases the
   * the declared single identifier name of the entity, such as 'method' for
   * a method [:void method() {...}:].
   */
  final String simpleName;

  /**
   * Returns the name of this entity qualified by is enclosing context. For
   * instance, the qualified name of a method 'method' in class 'Class' in
   * library 'library' is 'library.Class.method'.
   */
  final String qualifiedName;

  /**
   * Returns the mirror system which contains this mirror.
   */
  final MirrorSystem system;
}

/**
 * Common interface for interface types and libraries.
 */
interface ObjectMirror extends Mirror {

  /**
   * Returns an unmodifiable map of the members of declared in this type or
   * library.
   */
  final Map<Object, MemberMirror> declaredMembers;
}

/**
 * A library.
 */
interface LibraryMirror extends ObjectMirror {
  /**
   * The name of the library, as given in #library().
   */
  final String simpleName;

  /**
   * Returns an iterable over all types in the library.
   */
  final Map<Object, InterfaceMirror> types;

  /**
   * Returns the source location for this library.
   */
  final Location location;
}

/**
 * Common interface for classes, interfaces, typedefs and type variables.
 */
interface TypeMirror extends Mirror {
  /**
   * Returns the source location for this type.
   */
  final Location location;

  /**
   * Returns the library in which this member resides.
   */
  final LibraryMirror library;

  /**
   * Is [:true:] iff this type is the [:Object:] type.
   */
  final bool isObject;

  /**
   * Is [:true:] iff this type is the [:Dynamic:] type.
   */
  final bool isDynamic;

  /**
   * Is [:true:] iff this type is the void type.
   */
  final bool isVoid;

  /**
   * Is [:true:] iff this type is a type variable.
   */
  final bool isTypeVariable;

  /**
   * Is [:true:] iff this type is a typedef.
   */
  final bool isTypedef;

  /**
   * Is [:true:] iff this type is a function type.
   */
  final bool isFunction;
}

/**
 * A class or interface type.
 */
interface InterfaceMirror extends TypeMirror, ObjectMirror {
  /**
   * Returns the defining type, i.e. declaration of a type.
   */
  final InterfaceMirror declaration;

  /**
   * Returns the super class of this type, or null if this type is [Object] or a
   * typedef.
   */
  final InterfaceMirror superclass;

  /**
   * Returns an iterable over the interfaces directly implemented by this type.
   */
  final Map<Object, InterfaceMirror> interfaces;

  /**
   * Is [:true:] iff this type is a class.
   */
  final bool isClass;

  /**
   * Is [:true:] iff this type is an interface.
   */
  final bool isInterface;

  /**
   * Is [:true:] if this type is private.
   */
  final bool isPrivate;

  /**
   * Is [:true:] if this type is the declaration of a type.
   */
  final bool isDeclaration;

  /**
   * Returns a list of the type arguments for this type.
   */
  final List<TypeMirror> typeArguments;

  /**
   * Returns the list of type variables for this type.
   */
  final List<TypeVariableMirror> typeVariables;

  /**
   * Returns an immutable map of the constructors in this interface.
   */
  final Map<Object, MethodMirror> constructors;

  /**
   * Returns the default type for this interface.
   */
  final InterfaceMirror defaultType;
}

/**
 * A type parameter as declared on a generic type.
 */
interface TypeVariableMirror extends TypeMirror {
  /**
   * Return a mirror on the class, interface, or typedef that declared the
   * type variable.
   */
  // Should not be called [declaration] as we then would have two [TypeMirror]
  // subtypes ([InterfaceMirror] and [TypeVariableMirror]) which have
  // [declaration()] methods but with different semantics.
  final InterfaceMirror declarer;

  /**
   * Returns the bound of the type parameter.
   */
  final TypeMirror bound;
}

/**
 * A function type.
 */
interface FunctionTypeMirror extends InterfaceMirror {
  /**
   * Returns the return type of this function type.
   */
  final TypeMirror returnType;

  /**
   * Returns the parameters for this function type.
   */
  final List<ParameterMirror> parameters;

  /**
   * Returns the call method for this function type.
   */
  final MethodMirror callMethod;
}

/**
 * A typedef.
 */
interface TypedefMirror extends InterfaceMirror {
  /**
   * Returns the defining type for this typedef. For instance [:void f(int):]
   * for a [:typedef void f(int):].
   */
  final TypeMirror definition;
}

/**
 * A member of a type, i.e. a field, method or constructor.
 */
interface MemberMirror extends Mirror {
  /**
   * Returns the source location for this member.
   */
  final Location location;

  /**
   * Returns a mirror on the declaration immediately surrounding the reflectee.
   * This could be a class, interface, library or another method or function.
   */
  final ObjectMirror surroundingDeclaration;

  /**
   * Returns true if this is a top level member, i.e. a member not within a
   * type.
   */
  final bool isTopLevel;

  /**
   * Returns true if this member is a constructor.
   */
  final bool isConstructor;

  /**
   * Returns true if this member is a field.
   */
  final bool isField;

  /**
   * Returns true if this member is a method.
   */
  final bool isMethod;

  /**
   * Returns true if this member is private.
   */
  final bool isPrivate;

  /**
   * Returns true if this member is static.
   */
  final bool isStatic;
}

/**
 * A field.
 */
interface FieldMirror extends MemberMirror {

  /**
   * Returns true if this field is final.
   */
  final bool isFinal;

  /**
   * Returns the type of this field.
   */
  final TypeMirror type;
}

/**
 * Common interface constructors and methods, including factories, getters and
 * setters.
 */
interface MethodMirror extends MemberMirror {
  /**
   * Returns the list of parameters for this method.
   */
  final List<ParameterMirror> parameters;

  /**
   * Returns the return type of this method.
   */
  final TypeMirror returnType;

  /**
   * Is [:true:] if this method is a constant constructor.
   */
  final bool isConst;

  /**
   * Is [:true:] if this method is a factory method.
   */
  final bool isFactory;

  /**
   * Returns the constructor name for named constructors and factory methods,
   * e.g. [:'bar':] for constructor [:Foo.bar:] of type [:Foo:].
   */
  final String constructorName;

  /**
   * Is [:true:] if this method is a getter method.
   */
  final bool isGetter;

  /**
   * Is [:true:] if this method is a setter method.
   */
  final bool isSetter;

  /**
   * Is [:true:] if this method is an operator method.
   */
  final bool isOperator;

  /**
   * Returns the operator name for operator methods, e.g. [:'<':] for
   * [:operator <:]
   */
  final String operatorName;
}

/**
 * A formal parameter.
 */
interface ParameterMirror extends Mirror {
  /**
   * Returns the type of this parameter.
   */
  final TypeMirror type;

  /**
   * Returns the default value for this parameter.
   */
  final String defaultValue;

  /**
   * Returns true if this parameter has a default value.
   */
  final bool hasDefaultValue;

  /**
   * Returns true if this parameter is optional.
   */
  final bool isOptional;

  /**
   * Returns [:true:] iff this parameter is an initializing formal of a
   * constructor. That is, if it is of the form [:this.x:] where [:x:] is a
   * field.
   */
  final bool isInitializingFormal;

  /**
   * Returns the initialized field, if this parameter is an initializing formal.
   */
  final FieldMirror initializedField;
}

/**
 * A [Location] describes the span of an entity in Dart source code.
 * A [Location] should be the minimum span that encloses the declaration of the
 * mirrored entity.
 */
interface Location {
  /**
   * The character position where the location begins.
   */
  final int start;

  /**
   * The character position where the location ends.
   */
  final int end;

  /**
   * Returns the [Source] in which this [Location] indexes.
   * If [:loc:] is a location, [:loc.source().text()[loc.start()] is where it
   * starts, and [:loc.source().text()[loc.end()] is where it ends.
   */
  final Source source;

  /**
   * The text of the location span.
   */
  final String text;
}

/**
 * A [Source] describes the source code of a compilation unit in Dart source
 * code.
 */
interface Source {
  /**
   * Returns the URI where the source originated.
   */
  final Uri uri;

  /**
   * Returns the text of this source.
   */
  final String text;
}
