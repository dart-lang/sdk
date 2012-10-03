// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mirrors');

#import('dart:io');
#import('dart:uri');

// TODO(rnystrom): Use "package:" URL (#4968).
#import('src/mirrors/dart2js_mirror.dart');

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
abstract class MirrorSystem {
  /**
   * Returns an unmodifiable map of all libraries in this mirror system.
   */
  Map<String, LibraryMirror> get libraries;
}


/**
 * An entity in the mirror system.
 */
abstract class Mirror {
  static const String UNARY_MINUS = 'unary-';

  /**
   * The simple name of the entity. The simple name is unique within the
   * scope of the entity declaration.
   *
   * The simple name is in most cases the declared single identifier name of
   * the entity, such as 'method' for a method [:void method() {...}:]. For an
   * unnamed constructor for [:class Foo:] the simple name is 'Foo'. For a
   * constructor for [:class Foo:] named 'named' the simple name is 'Foo.named'.
   * For a property [:foo:] the simple name of the getter method is 'foo' and
   * the simple name of the setter is 'foo='. For operators the simple name is
   * the operator itself, for example '+' for [:operator +:].
   *
   * The simple name for the unary minus operator is [UNARY_MINUS].
   */
  String get simpleName;

  /**
   * The display name is the normal representation of the entity name. In most
   * cases the display name is the simple name, but for a setter 'foo=' the
   * display name is simply 'foo' and for the unary minus operator the display
   * name is 'operator -'. The display name is not unique.
   */
  String get displayName;

  /**
   * Returns the name of this entity qualified by is enclosing context. For
   * instance, the qualified name of a method 'method' in class 'Class' in
   * library 'library' is 'library.Class.method'.
   */
  String get qualifiedName;

  /**
   * Returns the mirror system which contains this mirror.
   */
  MirrorSystem get system;
}

/**
 * Common interface for interface types and libraries.
 */
abstract class ObjectMirror implements Mirror {

  /**
   * Returns an unmodifiable map of the members of declared in this type or
   * library.
   */
  Map<String, MemberMirror> get declaredMembers;
}

/**
 * A library.
 */
abstract class LibraryMirror extends ObjectMirror {
  /**
   * The name of the library, as given in #library().
   */
  String get simpleName;

  /**
   * Returns an iterable over all types in the library.
   */
  Map<String, InterfaceMirror> get types;

  /**
   * Returns the source location for this library.
   */
  Location get location;
}

/**
 * Common interface for classes, interfaces, typedefs and type variables.
 */
abstract class TypeMirror implements Mirror {
  /**
   * Returns the source location for this type.
   */
  Location get location;

  /**
   * Returns the library in which this member resides.
   */
  LibraryMirror get library;

  /**
   * Is [:true:] iff this type is the [:Object:] type.
   */
  bool get isObject;

  /**
   * Is [:true:] iff this type is the [:Dynamic:] type.
   */
  bool get isDynamic;

  /**
   * Is [:true:] iff this type is the void type.
   */
  bool get isVoid;

  /**
   * Is [:true:] iff this type is a type variable.
   */
  bool get isTypeVariable;

  /**
   * Is [:true:] iff this type is a typedef.
   */
  bool get isTypedef;

  /**
   * Is [:true:] iff this type is a function type.
   */
  bool get isFunction;
}

/**
 * A class or interface type.
 */
abstract class InterfaceMirror implements TypeMirror, ObjectMirror {
  /**
   * Returns the defining type, i.e. declaration of a type.
   */
  InterfaceMirror get declaration;

  /**
   * Returns the super class of this type, or null if this type is [Object] or a
   * typedef.
   */
  InterfaceMirror get superclass;

  /**
   * Returns a list of the interfaces directly implemented by this type.
   */
  List<InterfaceMirror> get interfaces;

  /**
   * Is [:true:] iff this type is a class.
   */
  bool get isClass;

  /**
   * Is [:true:] iff this type is an interface.
   */
  bool get isInterface;

  /**
   * Is [:true:] if this type is private.
   */
  bool get isPrivate;

  /**
   * Is [:true:] if this type is the declaration of a type.
   */
  bool get isDeclaration;

  /**
   * Is [:true:] if this class is declared abstract.
   */
  bool get isAbstract;

  /**
   * Returns a list of the type arguments for this type.
   */
  List<TypeMirror> get typeArguments;

  /**
   * Returns the list of type variables for this type.
   */
  List<TypeVariableMirror> get typeVariables;

  /**
   * Returns an immutable map of the constructors in this interface.
   */
  Map<String, MethodMirror> get constructors;

  /**
   * Returns the default type for this interface.
   */
  InterfaceMirror get defaultType;
}

/**
 * A type parameter as declared on a generic type.
 */
abstract class TypeVariableMirror implements TypeMirror {
  /**
   * Return a mirror on the class, interface, or typedef that declared the
   * type variable.
   */
  // Should not be called [declaration] as we then would have two [TypeMirror]
  // subtypes ([InterfaceMirror] and [TypeVariableMirror]) which have
  // [declaration()] methods but with different semantics.
  InterfaceMirror get declarer;

  /**
   * Returns the bound of the type parameter.
   */
  TypeMirror get bound;
}

/**
 * A function type.
 */
abstract class FunctionTypeMirror implements InterfaceMirror {
  /**
   * Returns the return type of this function type.
   */
  TypeMirror get returnType;

  /**
   * Returns the parameters for this function type.
   */
  List<ParameterMirror> get parameters;

  /**
   * Returns the call method for this function type.
   */
  MethodMirror get callMethod;
}

/**
 * A typedef.
 */
abstract class TypedefMirror implements InterfaceMirror {
  /**
   * Returns the defining type for this typedef. For instance [:void f(int):]
   * for a [:typedef void f(int):].
   */
  TypeMirror get definition;
}

/**
 * A member of a type, i.e. a field, method or constructor.
 */
abstract class MemberMirror implements Mirror {
  /**
   * Returns the source location for this member.
   */
  Location get location;

  /**
   * Returns a mirror on the declaration immediately surrounding the reflectee.
   * This could be a class, interface, library or another method or function.
   */
  ObjectMirror get surroundingDeclaration;

  /**
   * Returns true if this is a top level member, i.e. a member not within a
   * type.
   */
  bool get isTopLevel;

  /**
   * Returns true if this member is a constructor.
   */
  bool get isConstructor;

  /**
   * Returns true if this member is a field.
   */
  bool get isField;

  /**
   * Returns true if this member is a method.
   */
  bool get isMethod;

  /**
   * Returns true if this member is private.
   */
  bool get isPrivate;

  /**
   * Returns true if this member is static.
   */
  bool get isStatic;
}

/**
 * A field.
 */
abstract class FieldMirror implements MemberMirror {

  /**
   * Returns true if this field is final.
   */
  bool get isFinal;

  /**
   * Returns the type of this field.
   */
  TypeMirror get type;
}

/**
 * Common interface constructors and methods, including factories, getters and
 * setters.
 */
abstract class MethodMirror implements MemberMirror {
  /**
   * Returns the list of parameters for this method.
   */
  List<ParameterMirror> get parameters;

  /**
   * Returns the return type of this method.
   */
  TypeMirror get returnType;

  /**
   * Is [:true:] if this method is declared abstract.
   */
  bool get isAbstract;

  /**
   * Is [:true:] if this method is a constant constructor.
   */
  bool get isConst;

  /**
   * Is [:true:] if this method is a factory method.
   */
  bool get isFactory;

  /**
   * Returns the constructor name for named constructors and factory methods,
   * e.g. [:'bar':] for constructor [:Foo.bar:] of type [:Foo:].
   */
  String get constructorName;

  /**
   * Is [:true:] if this method is a getter method.
   */
  bool get isGetter;

  /**
   * Is [:true:] if this method is a setter method.
   */
  bool get isSetter;

  /**
   * Is [:true:] if this method is an operator method.
   */
  bool get isOperator;

  /**
   * Returns the operator name for operator methods, e.g. [:'<':] for
   * [:operator <:]
   */
  String get operatorName;
}

/**
 * A formal parameter.
 */
abstract class ParameterMirror implements Mirror {
  /**
   * Returns the type of this parameter.
   */
  TypeMirror get type;

  /**
   * Returns the default value for this parameter.
   */
  String get defaultValue;

  /**
   * Returns true if this parameter has a default value.
   */
  bool get hasDefaultValue;

  /**
   * Returns true if this parameter is optional.
   */
  bool get isOptional;

  /**
   * Returns [:true:] iff this parameter is an initializing formal of a
   * constructor. That is, if it is of the form [:this.x:] where [:x:] is a
   * field.
   */
  bool get isInitializingFormal;

  /**
   * Returns the initialized field, if this parameter is an initializing formal.
   */
  FieldMirror get initializedField;
}

/**
 * A [Location] describes the span of an entity in Dart source code.
 * A [Location] should be the minimum span that encloses the declaration of the
 * mirrored entity.
 */
abstract class Location {
  /**
   * The character position where the location begins.
   */
  int get start;

  /**
   * The character position where the location ends.
   */
  int get end;

  /**
   * Returns the [Source] in which this [Location] indexes.
   * If [:loc:] is a location, [:loc.source().text()[loc.start()] is where it
   * starts, and [:loc.source().text()[loc.end()] is where it ends.
   */
  Source get source;

  /**
   * The text of the location span.
   */
  String get text;
}

/**
 * A [Source] describes the source code of a compilation unit in Dart source
 * code.
 */
abstract class Source {
  /**
   * Returns the URI where the source originated.
   */
  Uri get uri;

  /**
   * Returns the text of this source.
   */
  String get text;
}
