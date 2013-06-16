// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// For the purposes of the mirrors library, we adopt a naming
// convention with respect to getters and setters.  Specifically, for
// some variable or field...
//
//   var myField;
//
// ...the getter is named 'myField' and the setter is named
// 'myField='.  This allows us to assign unique names to getters and
// setters for the purposes of member lookup.

/**
 * The mirrors library provides basic reflection support for Dart.
 * Reflection here is limited to introspection and dynamic
 * evaluation.
 *
 * Introspection is that subset of reflection by which a running
 * program can examine its own structure. For example, a function
 * that prints out the names of all the members of an arbitrary object.
 *
 * Dynamic evaluation refers the ability to evaluate code that
 * has not been literally specified at compile time, such as calling a method
 * whose name is provided as an argument (because it is looked up
 * in a database, or provided interactively by the user).
 *
 * How to Interpret the Dartdoc specifications below
 *
 * As a rule, the names of Dart declarations are represented using
 * instances of class [Symbol]. Whenever we speak of an object *s*
 * of class [Symbol] denoting a name, we mean the string that
 * was used to construct *s*.
 *
 * We will also frequently abuse notation and write
 * Dart pseudo-code such as [:o.x(a):], where we have defined
 * o and a to be objects; what is actually meant in these
 * cases is [:o'.x(a'):] where *o'* and *a'* are Dart variables
 * bound to *o* and *a* respectively. Furthermore, *o'* and *a'*
 * are assumed to be fresh variables (meaning that they are
 * distinct from any other variables in the program).
 *
 * An object is serializable across isolates if and only if it is an instance of
 * either num, bool, String, a list of objects that are serializable
 * across isolates or a map whose keys and values are all serializable across
 * isolates.
 */
library dart.mirrors;

import 'dart:async';
import 'dart:isolate';

/**
 * A [MirrorSystem] is the main interface used to reflect on a set of
 * associated libraries.
 *
 * At runtime each running isolate has a distinct [MirrorSystem].
 *
 * It is also possible to have a [MirrorSystem] which represents a set
 * of libraries which are not running -- perhaps at compile-time.  In
 * this case, all available reflective functionality would be
 * supported, but runtime functionality (such as invoking a function
 * or inspecting the contents of a variable) would fail dynamically.
 */
abstract class MirrorSystem {
  /**
   * An immutable map from from library names to mirrors for all
   * libraries known to this mirror system.
   */
  Map<Uri, LibraryMirror> get libraries;

  /**
   * Returns an iterable of all libraries in the mirror system whose library
   * name is [libraryName].
   */
  Iterable<LibraryMirror> findLibrary(Symbol libraryName) {
    return libraries.values.where(
        (library) => library.simpleName == libraryName);
  }

  /**
   * A mirror on the isolate associated with this [MirrorSystem].
   * This may be null if this mirror system is not running.
   */
  IsolateMirror get isolate;

  /**
   * A mirror on the [:dynamic:] type.
   */
  TypeMirror get dynamicType;

  /**
   * A mirror on the [:void:] type.
   */
  TypeMirror get voidType;

  /**
   * Returns the name of [symbol].
   *
   * The following text is non-normative:
   *
   * Using this method may result in larger output.  If possible, use
   * [MirrorsUsed] to specify which symbols must be retained in clear text.
   */
  external static String getName(Symbol symbol);
}

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
external MirrorSystem currentMirrorSystem();

/**
 * Creates a [MirrorSystem] for the isolate which is listening on
 * the [SendPort].
 */
external Future<MirrorSystem> mirrorSystemOf(SendPort port);

/**
 * Returns an [InstanceMirror] for some Dart language object.
 *
 * This only works with objects local to the current isolate.
 */
external InstanceMirror reflect(Object reflectee);

/**
 * Returns a [ClassMirror] for the class represented by a Dart
 * Type object.
 *
 * This only works with objects local to the current isolate.
 */
external ClassMirror reflectClass(Type key);

/**
 * A [Mirror] reflects some Dart language entity.
 *
 * Every [Mirror] originates from some [MirrorSystem].
 */
abstract class Mirror {
  /**
   * The [MirrorSystem] that contains this mirror.
   */
  MirrorSystem get mirrors;
}

/**
 * An [IsolateMirror] reflects an isolate.
 */
abstract class IsolateMirror implements Mirror {
  /**
   * A unique name used to refer to an isolate in debugging messages.
   */
  String get debugName;

  /**
   * Does this mirror reflect the currently running isolate?
   */
  bool get isCurrent;

  /**
   * A mirror on the root library for this isolate.
   */
  LibraryMirror get rootLibrary;
}

/**
 * A [DeclarationMirror] reflects some entity declared in a Dart program.
 */
abstract class DeclarationMirror implements Mirror {
  /**
   * The simple name for this Dart language entity.
   *
   * The simple name is in most cases the the identifier name of the
   * entity, such as 'method' for a method [:void method() {...}:] or
   * 'mylibrary' for a [:#library('mylibrary');:] declaration.
   */
  Symbol get simpleName;

  /**
   * The fully-qualified name for this Dart language entity.
   *
   * This name is qualified by the name of the owner. For instance,
   * the qualified name of a method 'method' in class 'Class' in
   * library 'library' is 'library.Class.method'.
   *
   * Returns a [Symbol] constructed from a string representing the
   * fully qualified name of the reflectee.
   * Let *o* be the [owner] of this mirror, let *r* be the reflectee of
   * this mirror, let *p* be the fully qualified
   * name of the reflectee of *o*, and let *s* be the simple name of *r*
   * computed by [simpleName].
   * The fully qualified name of *r* is the
   * concatenation of *p*, '.', and *s*.
   */
  Symbol get qualifiedName;

  /**
   * A mirror on the owner of this function.  This is the declaration
   * immediately surrounding the reflectee.
   *
   * For a library, the owner is [:null:].
   * For a class, typedef or top level function or variable, the owner is
   * the enclosing library. For a method, instance variable or
   * a static variable, the owner is the immediately enclosing class.
   * For a parameter, local variable or local function the owner is the
   * immediately enclosing function.
   */
  DeclarationMirror get owner;

  /**
   * Is this declaration private?
   *
   * A declaration is private if and only if it is considered private
   * according to the Dart language specification.
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

  /**
   * The source location of this Dart language entity.
   */
  SourceLocation get location;

  /**
   * A list of the metadata associated with this declaration.
   *
   * Let *D* be the declaration this mirror reflects.
   * If *D* is decorated with annotations *A1, ..., An*
   * where *n > 0*, then for each annotation *Ai* associated 
   * with *D, 1 <= i <= n*, let *ci* be the constant object 
   * specified by *Ai*. Then this method returns a list whose 
   * members are instance mirrors on *c1, ..., cn*.
   * If no annotations are associated with *D*, then 
   * an empty list is returned.
   */
  List<InstanceMirror> get metadata;
}

/**
 * An [ObjectMirror] is a common superinterface of [InstanceMirror],
 * [ClassMirror], and [LibraryMirror] that represents their shared
 * functionality.
 *
 * For the purposes of the mirrors library, these types are all
 * object-like, in that they support method invocation and field
 * access.  Real Dart objects are represented by the [InstanceMirror]
 * type.
 *
 * See [InstanceMirror], [ClassMirror], and [LibraryMirror].
 */
abstract class ObjectMirror implements Mirror {

  /**
   * Invokes the named function and returns a mirror on the result.
   *
   * Let *o* be the object reflected by this mirror, let
   * *f* be the simple name of the member denoted by [memberName],
   * let *a1, ..., an* be the elements of [positionalArguments]
   * let *k1, ..., km* be the identifiers denoted by the elements of
   * [namedArguments.keys]
   * and let *v1, ..., vm* be the elements of [namedArguments.values].
   * Then this method will perform the method invocation
   *  *o.f(a1, ..., an, k1: v1, ..., km: vm)*
   * in a scope that has access to the private members
   * of *o* (if *o* is a class or library) or the private members of the
   * class of *o* (otherwise).
   * If the invocation returns a result *r*, this method returns
   * the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * the the result is a [MirrorError] wrapping *e*.
   */
  /*
   * TODO(turnidge): Handle ambiguous names.
   * TODO(turnidge): Handle optional & named arguments.
   */
  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]);

  /**
   * Invokes a getter and returns a mirror on the result. The getter
   * can be the implicit getter for a field or a user-defined getter
   * method.
   *
   * Let *o* be the object reflected by this mirror, let
   * *f* be the simple name of the getter denoted by [fieldName],
   * Then this method will perform the getter invocation
   *  *o.f*
   * in a scope that has access to the private members
   * of *o* (if *o* is a class or library) or the private members of the
   * class of *o* (otherwise).
   * If the invocation returns a result *r*, this method returns
   * the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * the the result is a [MirrorError] wrapping *e*.
   */
  /* TODO(turnidge): Handle ambiguous names.*/
  InstanceMirror getField(Symbol fieldName);

  /**
   * Invokes a setter and returns a mirror on the result. The setter
   * may be either the implicit setter for a non-final field or a
   * user-defined setter method.
   *
   * Let *o* be the object reflected by this mirror, let
   * *f* be the simple name of the getter denoted by [fieldName],
   * and let *a* be the object bound to [value].
   * Then this method will perform the setter invocation
   * *o.f = a*
   * in a scope that has access to the private members
   * of *o* (if *o* is a class or library) or the private members of the
   * class of *o* (otherwise).
   * If the invocation returns a result *r*, this method returns
   * the result of calling [reflect]([value]).
   * If the invocation throws an exception *e* (that it does not catch)
   * the the result is a [MirrorError] wrapping *e*.
   */
  /* TODO(turnidge): Handle ambiguous names.*/
  InstanceMirror setField(Symbol fieldName, Object value);

  /**
   * Invokes the named function and returns a mirror on the result.
   * The arguments must be instances of [InstanceMirror], or of
   * a type that is serializable across isolates (currently [num],
   * [String], or [bool]).
   *
   * Let *o* be the object reflected by this mirror, let
   * *f* be the simple name of the member denoted by [memberName],
   * let *a1, ..., an* be the elements of [positionalArguments]
   * let *k1, ..., km* be the identifiers denoted by the elements of
   * [namedArguments.keys]
   * and let *v1, ..., vm* be the elements of [namedArguments.values].
   * For each *ai*, if *ai* is an instance of [InstanceMirror], let *pi*
   * be the object reflected by *ai*; otherwise let *pi = ai,  i in 1 ...n*.
   * Likewise, for each *vj*, if *vj* is an instance of [InstanceMirror], let *qj*
   * be the object reflected by *vj*; otherwise let *qj = vj,  j in 1 ...m*.
   * If any of the *pi, qj* is not an instance of [InstanceMirror] and
   * is not serializable across isolates, an exception is thrown.
   * Then this method will perform the method invocation
   *  *o.f(p1, ..., pn, k1: q1, ..., km: qm)*
   * in a scope that has access to the private members
   * of *o* (if *o* is a class or library) or the private members of the
   * class of *o*(otherwise).
   * The method returns a future *k*.
   * If the invocation returns a result *r*, *k* will be completed
   * with the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * then *k* is completed with a [MirrorError] wrapping *e*.
   */
  /*
   * TODO(turnidge): Handle ambiguous names.
   * TODO(turnidge): Handle optional & named arguments.
   */
  Future<InstanceMirror> invokeAsync(Symbol memberName,
                                     List positionalArguments,
                                     [Map<Symbol, dynamic> namedArguments]);

  /**
   * Invokes a getter and returns a mirror on the result. The getter
   * can be the implicit getter for a field or a user-defined getter
   * method.
   *
   * Let *o* be the object reflected by this mirror, let
   * *f* be the simple name of the getter denoted by [fieldName],
   * Then this method will perform the getter invocation
   *  *o.f*
   * in a scope that has access to the private members
   * of *o* (if *o* is a class or library) or the private members of the
   * class of *o*(otherwise).
   * The method returns a future *k*.
   * If the invocation returns a result *r*, *k* will be completed
   * with the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * then *k* is completed with a [MirrorError] wrapping *e*.
   */
  /* TODO(turnidge): Handle ambiguous names.*/
  Future<InstanceMirror> getFieldAsync(Symbol fieldName);

  /**
   * Invokes a setter and returns a mirror on the result. The setter
   * may be either the implicit setter for a non-final field or a
   * user-defined setter method.
   * The second argument must be an instance of [InstanceMirror], or of
   * a type that is serializable across isolates (currently [num],
   * [String], or [bool]).
   *
   * Let *o* be the object reflected by this mirror, let
   * *f* be the simple name of the getter denoted by [fieldName],
   * and let a be the object bound to [value]. If *a* is an instance of
   * [InstanceMirror]  let *p* be the object
   * reflected by *a*, otherwise let *p =a*.
   * If *p* is not an instance of [InstanceMirror], *p* must be
   * serializable across isolates or an exception is thrown.
   * Then this method will perform the setter invocation
   *  *o.f = a*
   * in a scope that has access to the private members
   * of *o* (if *o* is a class or library) or the private members of the
   * class of *o*(otherwise).
   * The method returns a future *k*.
   * If the invocation returns a result *r*, *k* will be completed
   * with the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * then *k* is completed with a [MirrorError} wrapping *e*.
   */
  /* TODO(turnidge): Handle ambiguous names.*/
  Future<InstanceMirror> setFieldAsync(Symbol fieldName, Object value);
}

/**
 * An [InstanceMirror] reflects an instance of a Dart language object.
 */
abstract class InstanceMirror implements ObjectMirror {
  /**
   * A mirror on the type of the reflectee.
   *
   * Returns a mirror on the actual class of the reflectee.
   * The class of the reflectee may differ from
   * the object returned by invoking [runtimeType] on
   * the reflectee.
   */
  ClassMirror get type;

  /**
   * Does [reflectee] contain the instance reflected by this mirror?
   * This will always be true in the local case (reflecting instances
   * in the same isolate), but only true in the remote case if this
   * mirror reflects a simple value.
   *
   * A value is simple if one of the following holds:
   *  - the value is null
   *  - the value is of type [num]
   *  - the value is of type [bool]
   *  - the value is of type [String]
   */
  bool get hasReflectee;

  /**
   * If the [InstanceMirror] reflects an instance it is meaningful to
   * have a local reference to, we provide access to the actual
   * instance here.
   *
   * If you access [reflectee] when [hasReflectee] is false, an
   * exception is thrown.
   */
  get reflectee;

  /**
   * Perform [invocation] on [reflectee].
   * Equivalent to
   *
   * this.invoke(invocation.memberName,
   *             invocation.positionalArguments,
   *             invocation.namedArguments);
   */
  delegate(Invocation invocation);
}

/**
 * A [ClosureMirror] reflects a closure.
 *
 * A [ClosureMirror] provides access to its captured variables and
 * provides the ability to execute its reflectee.
 */
abstract class ClosureMirror implements InstanceMirror {
  /**
   * A mirror on the function associated with this closure.
   */
  MethodMirror get function;

  /**
   * The source code for this closure, if available.  Otherwise null.
   *
   * TODO(turnidge): Would this just be available in function?
   */
  String get source;

  /**
   * Executes the closure and returns a mirror on the result.
   * Let *f* be the closure reflected by this mirror,
   * let *a1, ..., an* be the elements of [positionalArguments]
   * let *k1, ..., km* be the identifiers denoted by the elements of
   * [namedArguments.keys]
   * and let *v1, ..., vm* be the elements of [namedArguments.values].
   * Then this method will perform the method invocation
   *  *f(a1, ..., an, k1: v1, ..., km: vm)*
   * If the invocation returns a result *r*, this method returns
   * the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * the the result is a [MirrorError] wrapping *e*.
   */
  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]);

  /**
   * Executes the closure and returns a mirror on the result.
   *
   * Let *f* be the closure reflected by this mirror,
   * let *a1, ..., an* be the elements of [positionalArguments]
   * let *k1, ..., km* be the identifiers denoted by the elements of
   * [namedArguments.keys]
   * and let *v1, ..., vm* be the elements of [namedArguments.values].
   * For each *ai*, if *ai* is an instance of [InstanceMirror], let *pi*
   * be the object reflected by *ai*; otherwise let *pi = ai,  i in 1 ...n*.
   * Likewise, for each *vj*, if *vj* is an instance of [InstanceMirror], let
   * *qj*
   * be the object reflected by *vj*; otherwise let *qj = vj,  j in 1 ...m*.
   * If any of the *pi, qj* is not an instance of [InstanceMirror] and
   * is not serializable across isolates, an exception is thrown.
   * Then this method will perform the function invocation
   *  *f(p1, ..., pn, k1: q1, ..., km: qm)*
   * The method returns a future *k*.
   * If the invocation returns a result *r*, *k* will be completed
   * with the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * then *k* is completed with a [MirrorError] wrapping *e*.
   *
   * The arguments must be instances of [InstanceMirror], or of
   * a type that is serializable across isolates (currently [num],
   * [String], or [bool]).
   */
  Future<InstanceMirror> applyAsync(List positionalArguments,
                                    [Map<Symbol, dynamic> namedArguments]);

  /**
   * Looks up the value of a name in the scope of the closure. The
   * result is a mirror on that value.
   *
   * Let *s* be the contents of the string used to construct the symbol [name].
   *
   * If the expression *s* occurs within the source code of the reflectee,
   * and that any such occurrence refers to a declaration outside the reflectee,
   * then let *v* be the result of evaluating the expression *s* at such
   * an occurrence.
   * If *s = this*, and the reflectee was defined within the instance scope of
   * an object *o*, then let *v* be *o*.
   *
   * The returned value is the result of invoking the method [reflect] on
   * *v*.
   */
  Future<InstanceMirror> findInContext(Symbol name);
}

/**
 * A [LibraryMirror] reflects a Dart language library, providing
 * access to the variables, functions, and classes of the
 * library.
 */
abstract class LibraryMirror implements DeclarationMirror, ObjectMirror {
  /**
   * The absolute uri of the library.
   */
  Uri get uri;

  /**
   * An immutable map from from names to mirrors for all members in
   * this library.
   *
   * The members of a library are its top-level classes,
   * functions, variables, getters, and setters.
   */
  Map<Symbol, Mirror> get members;

  /**
   * An immutable map from names to mirrors for all class
   * declarations in this library.
   */
  Map<Symbol, ClassMirror> get classes;

  /**
   * An immutable map from names to mirrors for all function, getter,
   * and setter declarations in this library.
   */
  Map<Symbol, MethodMirror> get functions;

  /**
   * An immutable map from names to mirrors for all getter
   * declarations in this library.
   */
  Map<Symbol, MethodMirror> get getters;

  /**
   * An immutable map from names to mirrors for all setter
   * declarations in this library.
   */
  Map<Symbol, MethodMirror> get setters;

  /**
   * An immutable map from names to mirrors for all variable
   * declarations in this library.
   */
  Map<Symbol, VariableMirror> get variables;
}

/**
 * A [TypeMirror] reflects a Dart language class, typedef,
 * or type variable.
 */
abstract class TypeMirror implements DeclarationMirror {
}

/**
 * A [ClassMirror] reflects a Dart language class.
 */
abstract class ClassMirror implements TypeMirror, ObjectMirror {
  /**
   * A mirror on the superclass on the reflectee.
   *
   * If this type is [:Object:] or a typedef, the superClass will be
   * null.
   */
  ClassMirror get superclass;

  /**
   * A list of mirrors on the superinterfaces of the reflectee.
   */
  List<ClassMirror> get superinterfaces;

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
  Map<Symbol, Mirror> get members;

  /**
   * An immutable map from names to mirrors for all method,
   * declarations for this type.  This does not include getters and
   * setters.
   */
  Map<Symbol, MethodMirror> get methods;

  /**
   * An immutable map from names to mirrors for all getter
   * declarations for this type.
   */
  Map<Symbol, MethodMirror> get getters;

  /**
   * An immutable map from names to mirrors for all setter
   * declarations for this type.
   */
  Map<Symbol, MethodMirror> get setters;

  /**
   * An immutable map from names to mirrors for all variable
   * declarations for this type.
   */
  Map<Symbol, VariableMirror> get variables;

  /**
   * An immutable map from names to mirrors for all constructor
   * declarations for this type.
   */
   Map<Symbol, MethodMirror> get constructors;

  /**
   * An immutable map from names to mirrors for all type variables for
   * this type.
   *
   * This map preserves the order of declaration of the type variables.
   */
   Map<Symbol, TypeVariableMirror> get typeVariables;

  /**
   * An immutable map from names to mirrors for all type arguments for
   * this type.
   *
   * This map preserves the order of declaration of the type variables.
   */
  Map<Symbol, TypeMirror> get typeArguments;

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
   * Invokes the named constructor and returns a mirror on the result.
   *
   * Let *c* be the class reflected by this mirror
   * let *a1, ..., an* be the elements of [positionalArguments]
   * let *k1, ..., km* be the identifiers denoted by the elements of
   * [namedArguments.keys]
   * and let *v1, ..., vm* be the elements of [namedArguments.values].
   * If [constructorName] was created from the empty string
   * Then this method will execute the instance creation expression
   * *new c(a1, ..., an, k1: v1, ..., km: vm)*
   * in a scope that has access to the private members
   * of *c*. Otherwise, let
   * *f* be the simple name of the constructor denoted by [constructorName]
   * Then this method will execute the instance creation expression
   *  *new c.f(a1, ..., an, k1: v1, ..., km: vm)*
   * in a scope that has access to the private members
   * of *c*.
   * In either case:
   * If the expression evaluates to a result *r*, this method returns
   * the result of calling [reflect](*r*).
   * If evaluating the expression throws an exception *e* (that it does not
   * catch)
   * the the result is a [MirrorError] wrapping *e*.
   */
  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol,dynamic> namedArguments]);

 /**
   * Invokes the named function and returns a mirror on the result.
   * The arguments must be instances of [InstanceMirror], or of
   * a type that is serializable across isolates (currently [num],
   * [String], or [bool]).
   *
   * Let *c* be the class reflected by this mirror,
   * let *a1, ..., an* be the elements of [positionalArguments]
   * let *k1, ..., km* be the identifiers denoted by the elements of
   * [namedArguments.keys]
   * and let *v1, ..., vm* be the elements of [namedArguments.values].
   * For each *ai*, if *ai* is an instance of [InstanceMirror], let *pi*
   * be the object reflected by *ai*; otherwise let *pi = ai,  i in 1 ...n*.
   * Likewise, for each *vj*, if *vj* is an instance of [InstanceMirror], let
   * *qj*
   * be the object reflected by *vj*; otherwise let *qj = vj,  j in 1 ...m*.
   * If any of the *pi, qj* is not an instance of [InstanceMirror] and
   * is not serializable across isolates, an exception is thrown.
   * If [constructorName] was created from the empty string
   * Then this method will execute the instance creation expression
   * *new c(a1, ..., an, k1: v1, ..., km: vm)*
   * in a scope that has access to the private members
   * of *c*. Otherwise, let
   * *f* be the simple name of the constructor denoted by [constructorName]
   * Then this method will execute the instance creation expression
   *  *new c.f(a1, ..., an, k1: v1, ..., km: vm)*
   * in a scope that has access to the private members
   * of *c*.
   * In either case:
   * The method returns a future *k*.
   * If the invocation returns a result *r*, *k* will be completed
   * with the result of calling [reflect](*r*).
   * If the invocation throws an exception *e* (that it does not catch)
   * then *k* is completed with a [MirrorError] wrapping *e*.
*/
  Future<InstanceMirror> newInstanceAsync(Symbol constructorName,
                                          List positionalArguments,
                                          [Map<Symbol, dynamic> namedArguments]);

  /**
   * Does this mirror represent a class?
   *
   * TODO(turnidge): This functions goes away after the
   * class/interface changes.
   */
  bool get isClass;

  /**
   * A mirror on the default factory class or null if there is none.
   *
   * TODO(turnidge): This functions goes away after the
   * class/interface changes.
   */
  ClassMirror get defaultFactory;
}

/**
 * A [FunctionTypeMirror] represents the type of a function in the
 * Dart language.
 */
abstract class FunctionTypeMirror implements ClassMirror {
  /**
   * The return type of the reflectee.
   */
  TypeMirror get returnType;

  /**
   * A list of the parameter types of the reflectee.
   */
  List<ParameterMirror> get parameters;

  /**
   * A mirror on the [:call:] method for the reflectee.
   *
   * TODO(turnidge): What is this and what is it for?
   */
  MethodMirror get callMethod;
}

/**
 * A [TypeVariableMirror] represents a type parameter of a generic
 * type.
 */
abstract class TypeVariableMirror extends TypeMirror {
  /**
   * A mirror on the type that is the upper bound of this type variable.
   */
  TypeMirror get upperBound;
}

/**
 * A [TypedefMirror] represents a typedef in a Dart language program.
 */
abstract class TypedefMirror implements ClassMirror {
  /**
   * The defining type for this typedef.
   *
   * For instance [:void f(int):] is the value for [:typedef void f(int):].
   */
  TypeMirror get value;
}

/**
 * A [MethodMirror] reflects a Dart language function, method,
 * constructor, getter, or setter.
 */
abstract class MethodMirror implements DeclarationMirror {
  /**
   * A mirror on the return type for the reflectee.
   */
  TypeMirror get returnType;

  /**
   * A list of mirrors on the parameters for the reflectee.
   */
  List<ParameterMirror> get parameters;

  /**
   * Is the reflectee static?
   *
   * For the purposes of the mirrors library, a top-level function is
   * considered static.
   */
  bool get isStatic;

  /**
   * Is the reflectee abstract?
   */
  bool get isAbstract;

  /**
   * Is the reflectee a regular function or method?
   *
   * A function or method is regular if it is not a getter, setter, or
   * constructor.  Note that operators, by this definition, are
   * regular methods.
   */
  bool get isRegularMethod;

  /**
   * Is the reflectee an operator?
   */
  bool get isOperator;

  /**
   * Is the reflectee a getter?
   */
  bool get isGetter;

  /**
   * Is the reflectee a setter?
   */
  bool get isSetter;

  /**
   * Is the reflectee a constructor?
   */
  bool get isConstructor;

  /**
   * The constructor name for named constructors and factory methods.
   *
   * For unnamed constructors, this is the empty string.  For
   * non-constructors, this is the empty string.
   *
   * For example, [:'bar':] is the constructor name for constructor
   * [:Foo.bar:] of type [:Foo:].
   */
  Symbol get constructorName;

  /**
   * Is the reflectee a const constructor?
   */
  bool get isConstConstructor;

  /**
   * Is the reflectee a generative constructor?
   */
  bool get isGenerativeConstructor;

  /**
   * Is the reflectee a redirecting constructor?
   */
  bool get isRedirectingConstructor;

  /**
   * Is the reflectee a factory constructor?
   */
  bool get isFactoryConstructor;
}

/**
 * A [VariableMirror] reflects a Dart language variable declaration.
 */
abstract class VariableMirror implements DeclarationMirror {
  /**
   * A mirror on the type of the reflectee.
   */
  TypeMirror get type;

  /**
   * Is the reflectee a static variable?
   *
   * For the purposes of the mirror library, top-level variables are
   * implicitly declared static.
   */
  bool get isStatic;

  /**
   * Is the reflectee a final variable?
   */
  bool get isFinal;
}

/**
 * A [ParameterMirror] reflects a Dart formal parameter declaration.
 */
abstract class ParameterMirror implements VariableMirror {
  /**
   * A mirror on the type of this parameter.
   */
  TypeMirror get type;

  /**
   * Is this parameter optional?
   */
  bool get isOptional;

  /**
   * Is this parameter named?
   */
  bool get isNamed;

  /**
   * Does this parameter have a default value?
   */
  bool get hasDefaultValue;

  /**
   * A mirror on the default value for this parameter, if it exists.
   */
  // TODO(ahe): This should return an InstanceMirror.
  String get defaultValue;
}

/**
 * A [SourceLocation] describes the span of an entity in Dart source code.
 */
abstract class SourceLocation {
}

/**
 * When an error occurs during the mirrored execution of code, a
 * [MirroredError] is thrown.
 *
 * In general, there are three main classes of failure that can happen
 * during mirrored execution of code in some isolate:
 *
 * - An exception is thrown but not caught.  This is caught by the
 *   mirrors framework and a [MirroredUncaughtExceptionError] is
 *   created and thrown.
 *
 * - A compile-time error occurs, such as a syntax error.  This is
 *   suppressed by the mirrors framework and a
 *   [MirroredCompilationError] is created and thrown.
 *
 * - A truly fatal error occurs, causing the isolate to be exited.  If
 *   the reflector and reflectee share the same isolate, then they
 *   will both suffer.  If the reflector and reflectee are in distinct
 *   isolates, then we hope to provide some information about the
 *   isolate death, but this has yet to be implemented.
 *
 * TODO(turnidge): Specify the behavior for remote fatal errors.
 */
abstract class MirroredError implements Exception {
}

/**
 * When an uncaught exception occurs during the mirrored execution
 * of code, a [MirroredUncaughtExceptionError] is thrown.
 *
 * This exception contains a mirror on the original exception object.
 * It also contains an object which can be used to recover the
 * stacktrace.
 */
class MirroredUncaughtExceptionError extends MirroredError {
  MirroredUncaughtExceptionError(this.exception_mirror,
                                 this.exception_string,
                                 this.stacktrace) {}

  /** A mirror on the exception object. */
  final InstanceMirror exception_mirror;

  /** The result of toString() for the exception object. */
  final String exception_string;

  /** A stacktrace object for the uncaught exception. */
  final Object stacktrace;

  String toString() {
    return
        "Uncaught exception during mirrored execution: <${exception_string}>";
  }
}

/**
 * When a compile-time error occurs during the mirrored execution
 * of code, a [MirroredCompilationError] is thrown.
 *
 * This exception includes the compile-time error message that would
 * have been displayed to the user, if the function had not been
 * invoked via mirror.
 */
class MirroredCompilationError extends MirroredError {
  MirroredCompilationError(this.message) {}

  final String message;

  String toString() {
    return "Compile-time error during mirrored execution: <$message>";
  }
}

/**
 * A [MirrorException] is used to indicate errors within the mirrors
 * framework.
 */
class MirrorException implements Exception {
  const MirrorException(String this._message);
  String toString() => "MirrorException: '$_message'";
  final String _message;
}

/**
 * Class used for encoding comments as metadata annotations.
 */
class Comment {
  /**
   * The comment text as written in the source text.
   */
  final String text;

  /**
   * The comment text without the start, end, and padding text.
   *
   * For example, if [text] is [: /** Comment text. */ :] then the [trimmedText]
   * is [: Comment text. :].
   */
  final String trimmedText;

  /**
   * Is [:true:] if this comment is a documentation comment.
   *
   * That is, that the comment is either enclosed in [: /** ... */ :] or starts
   * with [: /// :].
   */
  final bool isDocComment;

  const Comment(this.text, this.trimmedText, this.isDocComment);
}

/**
 * EXPERIMENTAL API: Description of how "dart:mirrors" is used.
 *
 * When used as metadata on an import of "dart:mirrors" in library *L*, this
 * class describes how "dart:mirrors" is used by library *L* unless overridden.
 * See [override].
 *
 * The following text is non-normative:
 *
 * In some scenarios, for example, when minifying Dart code, or when generating
 * JavaScript code from a Dart program, the size and performance of the output
 * can suffer from use of reflection.  In those cases, telling the compiler
 * what is used, can have a significant impact.
 *
 * Example usage:
 *
 * [:
 * @MirrorsUsed(symbols: 'foo', override: '*')
 * import 'dart:mirrors';
 *
 * class Foo {
 *   noSuchMethod(Invocation invocation) {
 *     print(Mirrors.getName(invocation.memberName));
 *   }
 * }
 *
 * main() {
 *   new Foo().foo(); // Prints "foo".
 *   new Foo().bar(); // Might print an arbitrary (mangled) name, "bar".
 * }
 * :]
 */
// TODO(ahe): Remove ", override: '*'" when it isn't necessary anymore.
class MirrorsUsed {
  // Note: the fields of this class are untyped.  This is because the most
  // convenient way to specify to specify symbols today is using a single
  // string. In some cases, a const list of classes might be convenient. Some
  // might prefer to use a const list of symbols.

  /**
   * The list of strings passed to new [Symbol], and symbols that might be
   * passed to [MirrorSystem.getName].
   *
   * Combined with the names of [reflectiveTarget], [metaTargets] and their
   * members, this forms the complete list of strings passed to new [Symbol],
   * and symbols that might be passed to [MirrorSystem.getName] by the library
   * to which this metadata applies.
   *
   * The following text is non-normative:
   *
   * Specifying this option turns off the following warnings emitted by
   * dart2js:
   *
   * * Using "MirrorSystem.getName" may result in larger output.
   * * Using "new #{name}" may result in larger output.
   *
   * Use symbols = "*" to turn off the warnings mentioned above.
   *
   * For example, if using [noSuchMethod] to interact with a database, extract
   * all the possible column names and include them in this list.  Similarly,
   * if using [noSuchMethod] to interact with another language (JavaScript, for
   * example) extract all the identifiers from API used and include them in
   * this list.
   */
  final symbols;

  /**
   * A list of reflective targets.
   *
   * Combined with [metaTargets], this provides the complete list of reflective
   * targets used by the library to which this metadata applies.
   *
   * The following text is non-normative:
   *
   * For now, there is no formal description of what a reflective target is.
   * Informally, it is a list of things that are expected to have fully
   * functional mirrors.
   */
  final targets;

  /**
   * A list of classes that when used as metadata indicates a reflective
   * target.
   *
   * See [targets].
   */
  final metaTargets;

  /**
   * A list of library names or "*".
   *
   * When used as metadata on an import of "dart:mirrors", this metadata does
   * not apply to the library in which the annotation is used, but instead
   * applies to the other libraries (all libraries if "*" is used).
   */
  final override;

  const MirrorsUsed(
      {this.symbols, this.targets, this.metaTargets, this.override});
}
