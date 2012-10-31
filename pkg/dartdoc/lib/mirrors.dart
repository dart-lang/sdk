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
abstract class Compilation {
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
  Future<String> compileToJavaScript();
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
   * Returns the mirror system which contains this mirror.
   */
  MirrorSystem get system;
}

abstract class DeclarationMirror implements Mirror {
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
   * The source location of this Dart language entity.
   */
  SourceLocation get location;

  /**
   * A mirror on the owner of this function. This is the declaration immediately
   * surrounding the reflectee.
   *
   * Note that for libraries, the owner will be [:null:].
   */
  DeclarationMirror get owner;

  /**
   * Is this declaration private?
   *
   * Note that for libraries, this will be [:false:].
   */
  bool get isPrivate;

  /**
   * Is this declaration top-level?
   *
   * This is defined to be equivalent to:
   *    [:mirror.owner != null && mirror.owner is LibraryMirror:]
   */
  bool get isTopLevel;
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
abstract class LibraryMirror implements ObjectMirror, DeclarationMirror {
  /**
   * An immutable map from from names to mirrors for all members in
   * this library.
   *
   * The members of a library are its top-level classes,
   * functions, variables, getters, and setters.
   */
  Map<String, Mirror> get members;

  /**
   * An immutable map from names to mirrors for all class
   * declarations in this library.
   */
  Map<String, ClassMirror> get classes;

  /**
   * An immutable map from names to mirrors for all function, getter,
   * and setter declarations in this library.
   */
  Map<String, MethodMirror> get functions;

  /**
   * An immutable map from names to mirrors for all getter
   * declarations in this library.
   */
  Map<String, MethodMirror> get getters;

  /**
   * An immutable map from names to mirrors for all setter
   * declarations in this library.
   */
  Map<String, MethodMirror> get setters;

  /**
   * An immutable map from names to mirrors for all variable
   * declarations in this library.
   */
  Map<String, VariableMirror> get variables;

  /**
   * Returns the canonical URI for this library.
   */
  Uri get uri;
}

/**
 * Common interface for classes, interfaces, typedefs and type variables.
 */
abstract class TypeMirror implements DeclarationMirror {
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
abstract class ClassMirror implements TypeMirror, ObjectMirror {
  /**
   * A mirror on the original declaration of this type.
   *
   * For most classes, they are their own original declaration.  For
   * generic classes, however, there is a distinction between the
   * original class declaration, which has unbound type variables, and
   * the instantiations of generic classes, which have bound type
   * variables.
   */
  ClassMirror get originalDeclaration;

  /**
   * Returns the super class of this type, or null if this type is [Object] or a
   * typedef.
   */
  ClassMirror get superclass;

  /**
   * Returns a list of the interfaces directly implemented by this type.
   */
  List<ClassMirror> get superinterfaces;

  /**
   * Is [:true:] iff this type is a class.
   */
  bool get isClass;

  /**
   * Is [:true:] iff this type is an interface.
   */
  bool get isInterface;

  /**
   * Is this the original declaration of this type?
   *
   * For most classes, they are their own original declaration.  For
   * generic classes, however, there is a distinction between the
   * original class declaration, which has unbound type variables, and
   * the instantiations of generic classes, which have bound type
   * variables.
   */
  bool get isOriginalDeclaration;

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
   * An immutable map from from names to mirrors for all members of
   * this type.
   *
   * The members of a type are its methods, fields, getters, and
   * setters.  Note that constructors and type variables are not
   * considered to be members of a type.
   *
   * This does not include inherited members.
   */
  Map<String, Mirror> get members;

  /**
   * An immutable map from names to mirrors for all method,
   * declarations for this type.  This does not include getters and
   * setters.
   */
  Map<String, MethodMirror> get methods;

  /**
   * An immutable map from names to mirrors for all getter
   * declarations for this type.
   */
  Map<String, MethodMirror> get getters;

  /**
   * An immutable map from names to mirrors for all setter
   * declarations for this type.
   */
  Map<String, MethodMirror> get setters;

  /**
   * An immutable map from names to mirrors for all variable
   * declarations for this type.
   */
  Map<String, VariableMirror> get variables;

  /**
   * An immutable map from names to mirrors for all constructor
   * declarations for this type.
   */
  Map<String, MethodMirror> get constructors;

  /**
   * Returns the default type for this interface.
   */
  ClassMirror get defaultFactory;
}

/**
 * A type parameter as declared on a generic type.
 */
abstract class TypeVariableMirror implements TypeMirror {
  /**
   * Returns the bound of the type parameter.
   */
  TypeMirror get upperBound;
}

/**
 * A function type.
 */
abstract class FunctionTypeMirror implements ClassMirror {
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
abstract class TypedefMirror implements ClassMirror {
  /**
   * The defining type for this typedef.
   *
   * For instance [:void f(int):] for a [:typedef void f(int):].
   */
  TypeMirror get value;
}

/**
 * A member of a type, i.e. a field, method or constructor.
 */
abstract class MemberMirror implements DeclarationMirror {
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
   * Returns true if this member is static.
   */
  bool get isStatic;
}

/**
 * A field.
 */
abstract class VariableMirror implements MemberMirror {

  /**
   * Returns true if this field is final.
   */
  bool get isFinal;

  /**
   * Returns true if this field is const.
   */
  bool get isConst;

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
  VariableMirror get initializedField;
}

/**
 * A [SourceLocation] describes the span of an entity in Dart source code.
 * A [SourceLocation] should be the minimum span that encloses the declaration
 * of the mirrored entity.
 */
abstract class SourceLocation {
  /**
   * The character position where the location begins.
   */
  int get start;

  /**
   * The character position where the location ends.
   */
  int get end;

  /**
   * Returns the [Source] in which this [SourceLocation] indexes.
   * If [:loc:] is a location, [:loc.source().text()[loc.start]:] is where it
   * starts, and [:loc.source().text()[loc.end]:] is where it ends.
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
