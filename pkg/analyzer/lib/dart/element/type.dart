// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the type model. The type model is part of the
 * [element model](element.dart) in that most types are defined by Dart code
 * (the types `dynamic` and `void` being the notable exceptions). All types are
 * represented by an instance of a subclass of [DartType].
 *
 * Other than `dynamic` and `void`, all of the types define either the interface
 * defined by a class (an instance of [InterfaceType]) or the type of a function
 * (an instance of [FunctionType]).
 *
 * We make a distinction between the declaration of a class (a [ClassElement])
 * and the type defined by that class (an [InterfaceType]). The biggest reason
 * for the distinction is to allow us to more cleanly represent the distinction
 * between type parameters and type arguments. For example, if we define a class
 * as `class Pair<K, V> {}`, the declarations of `K` and `V` represent type
 * parameters. But if we declare a variable as `Pair<String, int> pair;` the
 * references to `String` and `int` are type arguments.
 */
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart' show InterfaceTypeImpl;
import 'package:analyzer/src/generated/type_system.dart' show TypeSystem;

/**
 * The type associated with elements in the element model.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartType {
  /**
   * An empty list of types.
   */
  static const List<DartType> EMPTY_LIST = const <DartType>[];

  /**
   * Return the name of this type as it should appear when presented to users in
   * contexts such as error messages.
   */
  String get displayName;

  /**
   * Return the element representing the declaration of this type, or `null` if
   * the type has not, or cannot, be associated with an element. The former case
   * will occur if the element model is not yet complete; the latter case will
   * occur if this object represents an undefined type.
   */
  Element get element;

  /**
   * Return `true` if this type represents the bottom type.
   */
  bool get isBottom;

  /**
   * Return `true` if this type represents the type 'Future' defined in the
   * dart:async library.
   */
  bool get isDartAsyncFuture;

  /**
   * Return `true` if this type represents the type 'FutureOr<T>' defined in the
   * dart:async library.
   */
  bool get isDartAsyncFutureOr;

  /**
   * Return `true` if this type represents the type 'Function' defined in the
   * dart:core library.
   */
  bool get isDartCoreFunction;

  /**
   * Return `true` if this type represents the type 'Null' defined in the
   * dart:core library.
   */
  bool get isDartCoreNull;

  /**
   * Return `true` if this type represents the type 'dynamic'.
   */
  bool get isDynamic;

  /**
   * Return `true` if this type represents the type 'Object'.
   */
  bool get isObject;

  /**
   * Return `true` if this type represents a typename that couldn't be resolved.
   */
  bool get isUndefined;

  /**
   * Return `true` if this type represents the type 'void'.
   */
  bool get isVoid;

  /**
   * Return the name of this type, or `null` if the type does not have a name,
   * such as when the type represents the type of an unnamed function.
   */
  String get name;

  /**
   * Implements the function "flatten" defined in the spec, where T is this
   * type:
   *
   *     If T = Future<S> then flatten(T) = flatten(S).
   *
   *     Otherwise if T <: Future then let S be a type such that T << Future<S>
   *     and for all R, if T << Future<R> then S << R.  Then flatten(T) = S.
   *
   *     In any other circumstance, flatten(T) = T.
   */
  DartType flattenFutures(TypeSystem typeSystem);

  /**
   * Return `true` if this type is assignable to the given [type]. A type
   * <i>T</i> may be assigned to a type <i>S</i>, written <i>T</i> &hArr;
   * <i>S</i>, iff either <i>T</i> <: <i>S</i> or <i>S</i> <: <i>T</i>.
   */
  bool isAssignableTo(DartType type);

  /// Indicates whether `this` represents a type that is equivalent to `dest`.
  ///
  /// This is different from `operator==`.  Consider for example:
  ///
  ///     typedef void F<T>(); // T not used!
  ///
  /// `operator==` would consider F<int> and F<bool> to be different types;
  /// `isEquivalentTo` considers them to be equivalent.
  bool isEquivalentTo(DartType dest);

  /**
   * Return `true` if this type is more specific than the given [type].
   */
  bool isMoreSpecificThan(DartType type);

  /**
   * Return `true` if this type is a subtype of the given [type].
   */
  bool isSubtypeOf(DartType type);

  /**
   * Return `true` if this type is a supertype of the given [type]. A type
   * <i>S</i> is a supertype of <i>T</i>, written <i>S</i> :> <i>T</i>, iff
   * <i>T</i> is a subtype of <i>S</i>.
   */
  bool isSupertypeOf(DartType type);

  /**
   * If this type is a [TypeParameterType], returns its bound if it has one, or
   * [objectType] otherwise.
   *
   * For any other type, returns `this`. Applies recursively -- if the bound is
   * itself a type parameter, that is resolved too.
   */
  DartType resolveToBound(DartType objectType);

  /**
   * Return the type resulting from substituting the given [argumentTypes] for
   * the given [parameterTypes] in this type. The specification defines this
   * operation in section 2:
   * <blockquote>
   * The notation <i>[x<sub>1</sub>, ..., x<sub>n</sub>/y<sub>1</sub>, ...,
   * y<sub>n</sub>]E</i> denotes a copy of <i>E</i> in which all occurrences of
   * <i>y<sub>i</sub>, 1 <= i <= n</i> have been replaced with
   * <i>x<sub>i</sub></i>.
   * </blockquote>
   * Note that, contrary to the specification, this method will not create a
   * copy of this type if no substitutions were required, but will return this
   * type directly.
   *
   * Note too that the current implementation of this method is only guaranteed
   * to work when the parameter types are type variables.
   */
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes);
}

/**
 * The type of a function, method, constructor, getter, or setter. Function
 * types come in three variations:
 *
 * * The types of functions that only have required parameters. These have the
 *   general form <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i>.
 * * The types of functions with optional positional parameters. These have the
 *   general form <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>
 *   &hellip;, T<sub>n+k</sub>]) &rarr; T</i>.
 * * The types of functions with named parameters. These have the general form
 *   <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>x1</sub> x1, &hellip;,
 *   T<sub>xk</sub> xk}) &rarr; T</i>.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionType implements ParameterizedType {
  /**
   * Deprecated: use [typeFormals].
   */
  @deprecated
  List<TypeParameterElement> get boundTypeParameters;

  /**
   * Return a map from the names of named parameters to the types of the named
   * parameters of this type of function. The entries in the map will be
   * iterated in the same order as the order in which the named parameters were
   * defined. If there were no named parameters declared then the map will be
   * empty.
   */
  Map<String, DartType> get namedParameterTypes;

  /**
   * The names of the required positional parameters of this type of function,
   * in the order that the parameters appear.
   */
  List<String> get normalParameterNames;

  /**
   * Return a list containing the types of the normal parameters of this type of
   * function. The parameter types are in the same order as they appear in the
   * declaration of the function.
   */
  List<DartType> get normalParameterTypes;

  /**
   * The names of the optional positional parameters of this type of function,
   * in the order that the parameters appear.
   */
  List<String> get optionalParameterNames;

  /**
   * Return a map from the names of optional (positional) parameters to the
   * types of the optional parameters of this type of function. The entries in
   * the map will be iterated in the same order as the order in which the
   * optional parameters were defined. If there were no optional parameters
   * declared then the map will be empty.
   */
  List<DartType> get optionalParameterTypes;

  /**
   * Return a list containing the parameters elements of this type of function.
   * The parameter types are in the same order as they appear in the declaration
   * of the function.
   */
  List<ParameterElement> get parameters;

  /**
   * Return the type of object returned by this type of function.
   */
  DartType get returnType;

  /**
   * The formal type parameters of this generic function.
   * For example `<T> T -> T`.
   *
   * These are distinct from the [typeParameters] list, which contains type
   * parameters from surrounding contexts, and thus are free type variables from
   * the perspective of this function type.
   */
  List<TypeParameterElement> get typeFormals;

  @override
  FunctionType instantiate(List<DartType> argumentTypes);

  /**
   * Return `true` if this type is a subtype of the given [type].
   *
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i> is
   * a subtype of the function type <i>(S<sub>1</sub>, &hellip;, S<sub>n</sub>)
   * &rarr; S</i>, if all of the following conditions are met:
   *
   * * Either
   *   * <i>S</i> is void, or
   *   * <i>T &hArr; S</i>.
   *
   * * For all <i>i</i>, 1 <= <i>i</i> <= <i>n</i>, <i>T<sub>i</sub> &hArr;
   *   S<sub>i</sub></i>.
   *
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>,
   * [T<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>]) &rarr; T</i> is a subtype of
   * the function type <i>(S<sub>1</sub>, &hellip;, S<sub>n</sub>,
   * [S<sub>n+1</sub>, &hellip;, S<sub>n+m</sub>]) &rarr; S</i>, if all of the
   * following conditions are met:
   *
   * * Either
   *   * <i>S</i> is void, or
   *   * <i>T &hArr; S</i>.
   *
   * * <i>k</i> >= <i>m</i> and for all <i>i</i>, 1 <= <i>i</i> <= <i>n+m</i>,
   *   <i>T<sub>i</sub> &hArr; S<sub>i</sub></i>.
   *
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>,
   * {T<sub>x1</sub> x1, &hellip;, T<sub>xk</sub> xk}) &rarr; T</i> is a subtype
   * of the function type <i>(S<sub>1</sub>, &hellip;, S<sub>n</sub>,
   * {S<sub>y1</sub> y1, &hellip;, S<sub>ym</sub> ym}) &rarr; S</i>, if all of
   * the following conditions are met:
   * * Either
   *   * <i>S</i> is void,
   *   * or <i>T &hArr; S</i>.
   *
   * * For all <i>i</i>, 1 <= <i>i</i> <= <i>n</i>, <i>T<sub>i</sub> &hArr;
   *   S<sub>i</sub></i>.
   * * <i>k</i> >= <i>m</i> and <i>y<sub>i</sub></i> in <i>{x<sub>1</sub>,
   *   &hellip;, x<sub>k</sub>}</i>, 1 <= <i>i</i> <= <i>m</i>.
   * * For all <i>y<sub>i</sub></i> in <i>{y<sub>1</sub>, &hellip;,
   *   y<sub>m</sub>}</i>, <i>y<sub>i</sub> = x<sub>j</sub> => Tj &hArr; Si</i>.
   *
   * In addition, the following subtype rules apply:
   *
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, []) &rarr; T <: (T<sub>1</sub>,
   * &hellip;, T<sub>n</sub>) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T <: (T<sub>1</sub>,
   * &hellip;, T<sub>n</sub>, {}) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {}) &rarr; T <: (T<sub>1</sub>,
   * &hellip;, T<sub>n</sub>) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T <: (T<sub>1</sub>,
   * &hellip;, T<sub>n</sub>, []) &rarr; T.</i>
   *
   * All functions implement the class `Function`. However not all function
   * types are a subtype of `Function`. If an interface type <i>I</i> includes a
   * method named `call()`, and the type of `call()` is the function type
   * <i>F</i>, then <i>I</i> is considered to be a subtype of <i>F</i>.
   */
  @override
  bool isSubtypeOf(DartType type);

  @override
  FunctionType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes);

  /**
   * Return the type resulting from substituting the given [argumentTypes] for
   * this type's parameters. This is fully equivalent to
   * `substitute(argumentTypes, getTypeArguments())`.
   */
  @deprecated // use instantiate
  FunctionType substitute3(List<DartType> argumentTypes);
}

/**
 * The type introduced by either a class or an interface, or a reference to such
 * a type.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class InterfaceType implements ParameterizedType {
  /**
   * An empty list of types.
   */
  static const List<InterfaceType> EMPTY_LIST = const <InterfaceType>[];

  /**
   * Return a list containing all of the accessors (getters and setters)
   * declared in this type.
   */
  List<PropertyAccessorElement> get accessors;

  /**
   * Return a list containing all of the constructors declared in this type.
   */
  List<ConstructorElement> get constructors;

  @override
  ClassElement get element;

  /**
   * Return a list containing all of the interfaces that are implemented by this
   * interface. Note that this is <b>not</b>, in general, equivalent to getting
   * the interfaces from this type's element because the types returned by this
   * method will have had their type parameters replaced.
   */
  List<InterfaceType> get interfaces;

  /**
   * Return a list containing all of the methods declared in this type.
   */
  List<MethodElement> get methods;

  /**
   * Return a list containing all of the mixins that are applied to the class
   * being extended in order to derive the superclass of this class. Note that
   * this is <b>not</b>, in general, equivalent to getting the mixins from this
   * type's element because the types returned by this method will have had
   * their type parameters replaced.
   */
  List<InterfaceType> get mixins;

  /**
   * Return the type representing the superclass of this type, or null if this
   * type represents the class 'Object'. Note that this is <b>not</b>, in
   * general, equivalent to getting the superclass from this type's element
   * because the type returned by this method will have had it's type parameters
   * replaced.
   */
  InterfaceType get superclass;

  /**
   * Return the element representing the getter with the given [name] that is
   * declared in this class, or `null` if this class does not declare a getter
   * with the given name.
   */
  PropertyAccessorElement getGetter(String name);

  /**
   * Return the element representing the method with the given [name] that is
   * declared in this class, or `null` if this class does not declare a method
   * with the given name.
   */
  MethodElement getMethod(String name);

  /**
   * Return the element representing the setter with the given [name] that is
   * declared in this class, or `null` if this class does not declare a setter
   * with the given name.
   */
  PropertyAccessorElement getSetter(String name);

  @override
  InterfaceType instantiate(List<DartType> argumentTypes);

  /**
   * Return `true` if this type is a direct supertype of the given [type]. The
   * implicit interface of class <i>I</i> is a direct supertype of the implicit
   * interface of class <i>J</i> iff:
   *
   * * <i>I</i> is Object, and <i>J</i> has no extends clause.
   * * <i>I</i> is listed in the extends clause of <i>J</i>.
   * * <i>I</i> is listed in the implements clause of <i>J</i>.
   * * <i>I</i> is listed in the with clause of <i>J</i>.
   * * <i>J</i> is a mixin application of the mixin of <i>I</i>.
   */
  bool isDirectSupertypeOf(InterfaceType type);

  /**
   * Return `true` if this type is more specific than the given [type]. An
   * interface type <i>T</i> is more specific than an interface type <i>S</i>,
   * written <i>T &laquo; S</i>, if one of the following conditions is met:
   *
   * * Reflexivity: <i>T</i> is <i>S</i>.
   * * <i>T</i> is bottom.
   * * <i>S</i> is dynamic.
   * * Direct supertype: <i>S</i> is a direct supertype of <i>T</i>.
   * * <i>T</i> is a type parameter and <i>S</i> is the upper bound of <i>T</i>.
   * * Covariance: <i>T</i> is of the form <i>I&lt;T<sub>1</sub>, &hellip;,
   *   T<sub>n</sub>&gt;</i> and S</i> is of the form <i>I&lt;S<sub>1</sub>,
   *   &hellip;, S<sub>n</sub>&gt;</i> and <i>T<sub>i</sub> &laquo;
   *   S<sub>i</sub></i>, <i>1 <= i <= n</i>.
   * * Transitivity: <i>T &laquo; U</i> and <i>U &laquo; S</i>.
   */
  @override
  bool isMoreSpecificThan(DartType type);

  /**
   * Return `true` if this type is a subtype of the given [type]. An interface
   * type <i>T</i> is a subtype of an interface type <i>S</i>, written <i>T</i>
   * <: <i>S</i>, iff <i>[bottom/dynamic]T</i> &laquo; <i>S</i> (<i>T</i> is
   * more specific than <i>S</i>). If an interface type <i>I</i> includes a
   * method named <i>call()</i>, and the type of <i>call()</i> is the function
   * type <i>F</i>, then <i>I</i> is considered to be a subtype of <i>F</i>.
   */
  @override
  bool isSubtypeOf(DartType type);

  /**
   * Return the element representing the constructor that results from looking
   * up the constructor with the given [name] in this class with respect to the
   * given [library], or `null` if the look up fails. The behavior of this
   * method is defined by the Dart Language Specification in section 12.11.1:
   * <blockquote>
   * If <i>e</i> is of the form <b>new</b> <i>T.id()</i> then let <i>q<i> be the
   * constructor <i>T.id</i>, otherwise let <i>q<i> be the constructor <i>T<i>.
   * Otherwise, if <i>q</i> is not defined or not accessible, a
   * NoSuchMethodException is thrown.
   * </blockquote>
   */
  ConstructorElement lookUpConstructor(String name, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the
   * getter with the given [name] in this class with respect to the given
   * [library], or `null` if the look up fails. The behavior of this method is
   * defined by the Dart Language Specification in section 12.15.1:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   * * If <i>C</i> declares an instance getter (respectively setter) named
   *   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
   *   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
   *   superclass <i>S</i>, then the result of the lookup is the result of
   *   looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect
   *   to <i>L</i>. Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpGetter(String name, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the
   * getter with the given [name] in the superclass of this class with respect
   * to the given [library], or `null` if the look up fails. The behavior of
   * this method is defined by the Dart Language Specification in section
   * 12.15.1:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   * * If <i>C</i> declares an instance getter (respectively setter) named
   *   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
   *   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
   *   superclass <i>S</i>, then the result of the lookup is the result of
   *   looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect
   *   to <i>L</i>. Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpGetterInSuperclass(
      String name, LibraryElement library);

  /**
   * Look up the member with the given [name] in this type and all extended
   * and mixed in classes, and by default including [thisType]. If the search
   * fails, this will then search interfaces.
   *
   * Return the element representing the member that was found, or `null` if
   * there is no getter with the given name.
   *
   * The [library] determines if a private member name is visible, and does not
   * need to be supplied for public names.
   */
  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType: true});

  /**
   * Look up the member with the given [name] in this type and all extended
   * and mixed in classes, starting from this type. If the search fails,
   * search interfaces.
   *
   * Return the element representing the member that was found, or `null` if
   * there is no getter with the given name.
   *
   * The [library] determines if a private member name is visible, and does not
   * need to be supplied for public names.
   */
  ExecutableElement lookUpInheritedGetterOrMethod(String name,
      {LibraryElement library});

  /**
   * Look up the member with the given [name] in this type and all extended
   * and mixed in classes, and by default including [thisType]. If the search
   * fails, this will then search interfaces.
   *
   * Return the element representing the member that was found, or `null` if
   * there is no getter with the given name.
   *
   * The [library] determines if a private member name is visible, and does not
   * need to be supplied for public names.
   */
  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType: true});

  /**
   * Look up the member with the given [name] in this type and all extended
   * and mixed in classes, and by default including [thisType]. If the search
   * fails, this will then search interfaces.
   *
   * Return the element representing the member that was found, or `null` if
   * there is no getter with the given name.
   *
   * The [library] determines if a private member name is visible, and does not
   * need to be supplied for public names.
   */
  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType: true});

  /**
   * Return the element representing the method that results from looking up the
   * method with the given [name] in this class with respect to the given
   * [library], or `null` if the look up fails. The behavior of this method is
   * defined by the Dart Language Specification in section 12.15.1:
   * <blockquote>
   * The result of looking up method <i>m</i> in class <i>C</i> with respect to
   * library <i>L</i> is:
   * * If <i>C</i> declares an instance method named <i>m</i> that is accessible
   *   to <i>L</i>, then that method is the result of the lookup. Otherwise, if
   *   <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the
   *   result of looking up method <i>m</i> in <i>S</i> with respect to <i>L</i>
   *   Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  MethodElement lookUpMethod(String name, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the
   * method with the given [name] in the superclass of this class with respect
   * to the given [library], or `null` if the look up fails. The behavior of
   * this method is defined by the Dart Language Specification in section
   * 12.15.1:
   * <blockquote>
   * The result of looking up method <i>m</i> in class <i>C</i> with respect to
   * library <i>L</i> is:
   * * If <i>C</i> declares an instance method named <i>m</i> that is accessible
   *   to <i>L</i>, then that method is the result of the lookup. Otherwise, if
   * <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the
   * result of looking up method <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  MethodElement lookUpMethodInSuperclass(String name, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the
   * setter with the given [name] in this class with respect to the given
   * [library], or `null` if the look up fails. The behavior of this method is
   * defined by the Dart Language Specification in section 12.16:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   * * If <i>C</i> declares an instance getter (respectively setter) named
   *   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
   *   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
   *   superclass <i>S</i>, then the result of the lookup is the result of
   *   looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect
   *   to <i>L</i>. Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpSetter(String name, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the
   * setter with the given [name] in the superclass of this class with respect
   * to the given [library], or `null` if the look up fails. The behavior of
   * this method is defined by the Dart Language Specification in section 12.16:
   * <blockquote>
   * The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   * * If <i>C</i> declares an instance getter (respectively setter) named
   *   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
   *   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
   *   superclass <i>S</i>, then the result of the lookup is the result of
   *   looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect
   *   to <i>L</i>. Otherwise, we say that the lookup has failed.
   * </blockquote>
   */
  PropertyAccessorElement lookUpSetterInSuperclass(
      String name, LibraryElement library);

  @override
  InterfaceType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes);

  /**
   * Return the type resulting from substituting the given arguments for this
   * type's parameters. This is fully equivalent to `substitute2(argumentTypes,
   * getTypeArguments())`.
   */
  @deprecated // use instantiate
  InterfaceType substitute4(List<DartType> argumentTypes);

  /**
   * Returns a "smart" version of the "least upper bound" of the given types.
   *
   * If these types have the same element and differ only in terms of the type
   * arguments, attempts to find a compatible set of type arguments.
   *
   * Otherwise, returns the same result as [DartType.getLeastUpperBound].
   */
  // TODO(brianwilkerson) This needs to be deprecated and moved to TypeSystem.
  static InterfaceType getSmartLeastUpperBound(
          InterfaceType first, InterfaceType second) =>
      InterfaceTypeImpl.getSmartLeastUpperBound(first, second);
}

/**
 * A type that can track substituted type parameters, either for itself after
 * instantiation, or from a surrounding context.
 *
 * For example, given a class `Foo<T>`, after instantiation with S for T, it
 * will track the substitution `{S/T}`.
 *
 * This substitution will be propagated to its members. For example, say our
 * `Foo<T>` class has a field `T bar;`. When we look up this field, we will get
 * back a [FieldElement] that tracks the substituted type as `{S/T}T`, so when
 * we ask for the field type we will get `S`.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ParameterizedType implements DartType {
  /**
   * Return a list containing the actual types of the type arguments. If this
   * type's element does not have type parameters, then the array should be
   * empty (although it is possible for type arguments to be erroneously
   * declared). If the element has type parameters and the actual type does not
   * explicitly include argument values, then the type "dynamic" will be
   * automatically provided.
   */
  List<DartType> get typeArguments;

  /**
   * Return a list containing all of the type parameters declared for this type.
   */
  List<TypeParameterElement> get typeParameters;

  /**
   * Return the type resulting from instantiating (replacing) the given
   * [argumentTypes] for this type's bound type parameters.
   */
  ParameterizedType instantiate(List<DartType> argumentTypes);
}

/**
 * The type introduced by a type parameter.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeParameterType implements DartType {
  /**
   * An empty list of type parameter types.
   */
  static const List<TypeParameterType> EMPTY_LIST = const <TypeParameterType>[];

  /**
   * Return the type representing the bound associated with this parameter,
   * or `dynamic` if there was no explicit bound.
   */
  DartType get bound;

  /**
   * An object that can be used to identify this type parameter with `==`.
   *
   * Depending on the use, [bound] may also need to be taken into account.
   * A given type parameter, it may have different bounds in different scopes.
   * Always consult the bound if that could be relevant.
   */
  ElementLocation get definition;

  @override
  TypeParameterElement get element;
}
