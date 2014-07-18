// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
 * Basic reflection in Dart,
 * with support for introspection and dynamic evaluation.
 *
 * *Introspection* is that subset of reflection by which a running
 * program can examine its own structure. For example, a function
 * that prints out the names of all the members of an arbitrary object.
 *
 * *Dynamic evaluation* refers the ability to evaluate code that
 * has not been literally specified at compile time, such as calling a method
 * whose name is provided as an argument (because it is looked up
 * in a database, or provided interactively by the user).
 *
 * ## How to interpret this library's documentation
 *
 * As a rule, the names of Dart declarations are represented using
 * instances of class [Symbol]. Whenever the doc speaks of an object *s*
 * of class [Symbol] denoting a name, it means the string that
 * was used to construct *s*.
 *
 * The documentation frequently abuses notation with
 * Dart pseudo-code such as [:o.x(a):], where
 * o and a are defined to be objects; what is actually meant in these
 * cases is [:o'.x(a'):] where *o'* and *a'* are Dart variables
 * bound to *o* and *a* respectively. Furthermore, *o'* and *a'*
 * are assumed to be fresh variables (meaning that they are
 * distinct from any other variables in the program).
 *
 * Sometimes the documentation refers to *serializable* objects.
 * An object is serializable across isolates if and only if it is an instance of
 * num, bool, String, a list of objects that are serializable
 * across isolates, or a map with keys and values that are all serializable across
 * isolates.
 *
 * ## Status: Unstable
 *
 * The dart:mirrors library is unstable and its API might change slightly as a
 * result of user feedback. This library is platform dependent and therefore it
 * has implementations for both dart2js and the Dart VM. Both are under
 * development and may not support all operations yet.
 */
library dart.mirrors;

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
   * Returns an immutable map from URIs to mirrors for all
   * libraries known to this mirror system.
   */
  Map<Uri, LibraryMirror> get libraries;

  /**
   * Returns the unique library named [libraryName] if it exists.
   *
   * If no unique library exists, an error is thrown.
   */
  LibraryMirror findLibrary(Symbol libraryName) {
    return libraries.values.singleWhere(
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

  /**
   * Returns a symbol for [name]. If [library] is not a [LibraryMirror] or if
   * [name] is a private identifier and [library] is [:null:], throws an
   * [ArgumentError]. If [name] is a private identifier, the symbol returned is
   * with respect to [library].
   *
   * The following text is non-normative:
   *
   * Using this method may result in larger output.  If possible, use
   * the const constructor of Symbol or symbol literals.
   */
  external static Symbol getSymbol(String name, [LibraryMirror library]);
}

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
external MirrorSystem currentMirrorSystem();

/**
 * Reflects an instance.
 * Returns an [InstanceMirror] reflecting [reflectee].
 * If [reflectee] is a function or an instance of a class
 * that has a [:call:] method, the returned instance mirror
 * will be a [ClosureMirror].
 *
 * Note that since one cannot obtain an object from
 * another isolate, this function can only be used to
 * obtain  mirrors on objects of the current isolate.
 */
external InstanceMirror reflect(Object reflectee);

/**
 * Reflects a class declaration.
 * Let *C* be the original class declaration of the class
 * represented by [key].
 * This function returns a [ClassMirror] reflecting *C*.
 *
 * If [key] is not an instance of [Type] then this function
 * throws an [ArgumentError]. If [key] is the Type for dynamic
 * or a function typedef, throws an [ArgumentError].
 *
 * Note that since one cannot obtain a [Type] object from
 * another isolate, this function can only be used to
 * obtain class mirrors on classes of the current isolate.
 */
external ClassMirror reflectClass(Type key);

/**
 * This function returns a [TypeMirror] reflecting the type
 * represented by [key].
 *
 * If [key] is not an instance of [Type] then this function
 * throws an [ArgumentError].
 *
 * Note that since one cannot obtain a [Type] object from
 * another isolate, this function can only be used to
 * obtain type mirrors on types of the current isolate.
 */
external TypeMirror reflectType(Type key);

/**
 * A [Mirror] reflects some Dart language entity.
 *
 * Every [Mirror] originates from some [MirrorSystem].
 */
abstract class Mirror {}

/**
 * An [IsolateMirror] reflects an isolate.
 */
abstract class IsolateMirror implements Mirror {
  /**
   * Returns a unique name used to refer to an isolate
   * in debugging messages.
   */
  String get debugName;

  /**
   * Returns [:true:] if and only if this mirror reflects
   * the currently running isolate. Otherwise returns
   * [:false:].
   */
  bool get isCurrent;

  /**
   * Returns a [LibraryMirror] on the root library for this
   * isolate.
   */
  LibraryMirror get rootLibrary;

  /**
   * Returns [:true:] if this mirror is equal to [other].
   * Otherwise returns [:false:].
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2) the isolate being reflected by this mirror is the same
   * isolate being reflected by [other].
   */
  bool operator == (other);
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
   * 'mylibrary' for a [:library 'mylibrary';:] declaration.
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
   *
   * Because an isolate can contain more than one library with the same name (at
   * different URIs), a fully-qualified name does not uniquely identify any
   * language entity.
   */
  Symbol get qualifiedName;

  /**
   * A mirror on the owner of this Dart language entity. This is the declaration
   * immediately surrounding the reflectee.
   *
   * For a library, the owner is [:null:].
   * For a class declaration, typedef or top level function
   * or variable, the owner is the enclosing library.
   * For a mixin application *S with M*, the owner is the owner
   * of *M*.
   * For a constructor, the owner is the immediately enclosing class.
   * For a method, instance variable or
   * a static variable, the owner is the immediately enclosing class,
   * unless the class is a mixin application *S with M*, in which case
   * the owner is *M*. Note that *M* may be an invocation of a generic.
   * For a parameter, local variable or local function the owner is the
   * immediately enclosing function.
   */
  DeclarationMirror get owner;

  /**
   * Returns [:true:] if this declaration is considered private
   * according to the Dart language specification.
   * Always returns [: false :] if this declaration
   * is a library.
   * Otherwise return [:false:].
   *
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
   *
   * This operation is optional and may return [:null:].
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
   *
   * If evaluating any of *c1, ..., cn* would cause a
   * compilation error
   * the effect is the same as if a non-reflective compilation error
   * had been encountered.
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
   * If the invocation causes a compilation error
   * the effect is the same as if a non-reflective compilation error
   * had been encountered.
   * If the invocation throws an exception *e* (that it does not catch)
   * this method throws *e*.
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
   *
   * If this mirror is an [InstanceMirror], and [fieldName] denotes an instance
   * method on its reflectee, the result of the invocation is an instance
   * mirror on a closure corresponding to that method.
   *
   * If this mirror is a [LibraryMirror], and [fieldName] denotes a top-level
   * method in the corresponding library, the result of the invocation is an
   * instance mirror on a closure corresponding to that method.
   *
   * If this mirror is a [ClassMirror], and [fieldName] denotes a static method
   * in the corresponding class, the result of the invocation is an instance
   * mirror on a closure corresponding to that method.
   *
   * If the invocation returns a result *r*, this method returns
   * the result of calling [reflect](*r*).
   * If the invocation causes a compilation error
   * the effect is the same as if a non-reflective compilation error
   * had been encountered.
   * If the invocation throws an exception *e* (that it does not catch)
   * this method throws *e*.
   */
  // TODO(ahe): Remove stuff about scope and private members. [fieldName] is a
  // capability giving access to private members.
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
   * If the invocation causes a compilation error
   * the effect is the same as if a non-reflective compilation error
   * had been encountered.
   * If the invocation throws an exception *e* (that it does not catch)
   * this method throws *e*.
   */
  /* TODO(turnidge): Handle ambiguous names.*/
  InstanceMirror setField(Symbol fieldName, Object value);
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
   *  - the value is [:null:]
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
   * Returns true if this mirror is equal to [other].
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2) either
   * (a) [hasReflectee] is true and so is
   * [:identical(reflectee, other.reflectee):]
   * or
   * (b) the remote objects reflected by this mirror and
   * by [other] are identical.
   */
  bool operator == (other);

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
   *
   * The function associated with an implicit closure of a function is that
   * function.
   *
   * The function associated with an instance of a class that has a [:call:]
   * method is that [:call:] method.
   */
  MethodMirror get function;

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
   * If the invocation causes a compilation error
   * the effect is the same as if a non-reflective compilation error
   * had been encountered.
   * If the invocation throws an exception *e* (that it does not catch)
   * this method throws *e*.
   */
  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]);
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
   * Returns an immutable map of the declarations actually given in the library.
   *
   * This map includes all regular methods, getters, setters, fields, classes
   * and typedefs actually declared in the library. The map is keyed by the
   * simple names of the declarations.
   */
  Map<Symbol, DeclarationMirror> get declarations;

  /**
   * Returns [:true:] if this mirror is equal to [other].
   * Otherwise returns [:false:].
   *
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2)  The library being reflected by this mirror
   * and the library being reflected by [other]
   * are
   * the same library in the same isolate.
   */
   bool operator ==(other);

  /**
   * Returns a list of the imports and exports in this library;
   */
  List<LibraryDependencyMirror> get libraryDependencies;
}

/// A mirror on an import or export declaration.
abstract class LibraryDependencyMirror implements Mirror {
  /// Is `true` if this dependency is an import.
  bool get isImport;

  /// Is `true` if this dependency is an export.
  bool get isExport;

  /// Returns the library mirror of the library that imports or exports the
  /// [targetLibrary].
  LibraryMirror get sourceLibrary;

  /// Returns the library mirror of the library that is imported or exported.
  LibraryMirror get targetLibrary;

  /// Returns the prefix if this is a prefixed import and `null` otherwise.
  Symbol get prefix;

  /// Returns the list of show/hide combinators on the import/export
  /// declaration.
  List<CombinatorMirror> get combinators;

  /// Returns the source location for this import/export declaration.
  SourceLocation get location;

  List<InstanceMirror> get metadata;
}

/// A mirror on a show/hide combinator declared on a library dependency.
abstract class CombinatorMirror implements Mirror {
  /// The list of identifiers on the combinator.
  List<Symbol> get identifiers;

  /// Is `true` if this is a 'show' combinator.
  bool get isShow;

  /// Is `true` if this is a 'hide' combinator.
  bool get isHide;
}

/**
 * A [TypeMirror] reflects a Dart language class, typedef,
 * function type or type variable.
 */
abstract class TypeMirror implements DeclarationMirror {
  /**
   * Returns true if this mirror reflects dynamic, a non-generic class or
   * typedef, or an instantiated generic class or typedef in the current
   * isolate. Otherwise, returns false.
   */
  bool get hasReflectedType;

  /**
   * If [:hasReflectedType:] returns true, returns the corresponding [Type].
   * Otherwise, an [UnsupportedError] is thrown.
   */
  Type get reflectedType;

  /**
   * An immutable list with mirrors for all type variables for this type.
   *
   * If this type is a generic declaration or an invocation of a generic
   * declaration, the returned list contains mirrors on the type variables
   * declared in the original declaration.
   * Otherwise, the returned list is empty.
   *
   * This list preserves the order of declaration of the type variables.
   */
  List<TypeVariableMirror> get typeVariables;

  /**
   * An immutable list with mirrors for all type arguments for
   * this type.
   *
   * If the reflectee is an invocation of a generic class,
   * the type arguments are the bindings of its type parameters.
   * If the reflectee is the original declaration of a generic,
   * it has no type arguments and this method returns an empty list.
   * If the reflectee is not generic, then
   * it has no type arguments and this method returns an empty list.
   *
   * This list preserves the order of declaration of the type variables.
   */
  List<TypeMirror> get typeArguments;

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
  TypeMirror get originalDeclaration;


  /**
   * Checks the subtype relationship, denoted by [:<::] in the language
   * specification. This is the type relationship used in [:is:] test checks.
   */
  bool isSubtypeOf(TypeMirror other);

  /**
   * Checks the assignability relationship, denoted by [:<=>:] in the language
   * specification. This is the type relationship tested on assignment in
   * checked mode.
   */
  bool isAssignableTo(TypeMirror other);
}

/**
 * A [ClassMirror] reflects a Dart language class.
 */
abstract class ClassMirror implements TypeMirror, ObjectMirror {
  /**
   * A mirror on the superclass on the reflectee.
   *
   * If this type is [:Object:], the superclass will be null.
   */
  ClassMirror get superclass;

  /**
   * A list of mirrors on the superinterfaces of the reflectee.
   */
  List<ClassMirror> get superinterfaces;

  /**
   * Is the reflectee abstract?
   */
  bool get isAbstract;

  /**
   * Returns an immutable map of the declarations actually given in the class
   * declaration.
   *
   * This map includes all regular methods, getters, setters, fields,
   * constructors and type variables actually declared in the class. Both
   * static and instance members are included, but no inherited members are
   * included. The map is keyed by the simple names of the declarations.
   *
   * This does not include inherited members.
   */
  Map<Symbol, DeclarationMirror> get declarations;

  /**
   * Returns a map of the methods, getters and setters of an instance of the
   * class.
   *
   * The intent is to capture those members that constitute the API of an
   * instance. Hence fields are not included, but the getters and setters
   * implicitly introduced by fields are included. The map includes methods,
   * getters and setters that are inherited as well as those introduced by the
   * class itself.
   *
   * The map is keyed by the simple names of the members.
   */
  Map<Symbol, MethodMirror> get instanceMembers;

  /**
   * Returns a map of the static methods, getters and setters of the class.
   *
   * The intent is to capture those members that constitute the API of a class.
   * Hence fields are not included, but the getters and setters implicitly
   * introduced by fields are included.
   *
   * The map is keyed by the simple names of the members.
   */
  Map<Symbol, MethodMirror> get staticMembers;


  /**
   * The mixin of this class.
   * If this class is the result of a mixin application of the
   * form S with M, returns a class mirror on M.
   * Otherwise returns a class mirror on [reflectee].
   */
  ClassMirror get mixin;

  // TODO(ahe): What about:
  // /// Finds the instance member named [name] declared or inherited in the
  // /// reflected class.
  // DeclarationMirror instanceLookup(Symbol name);

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
   * If evaluating the expression causes a compilation error
   * the effect is the same as if a non-reflective compilation error
   * had been encountered.
   * If evaluating the expression throws an exception *e*
   * (that it does not catch)
   * this method throws *e*.
   */
  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol,dynamic> namedArguments]);

  /**
   * Returns [:true:] if this mirror is equal to [other].
   * Otherwise returns [:false:].
   *
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2) This mirror and [other] reflect the same class.
   *
   * Note that if the reflected class is an invocation of
   * a generic class,(2) implies that the reflected class
   * and [other] have equal type arguments.
   */
   bool operator == (other);

  /**
   * Returns whether the class denoted by the receiver is a subclass of the
   * class denoted by the argument.
   *
   * Note that the subclass relationship is reflexive.
   */
  bool isSubclassOf(ClassMirror other);
}

/**
 * A [FunctionTypeMirror] represents the type of a function in the
 * Dart language.
 */
abstract class FunctionTypeMirror implements ClassMirror {
  /**
   * Returns the return type of the reflectee.
   */
  TypeMirror get returnType;

  /**
   * Returns a list of the parameter types of the reflectee.
   */
  List<ParameterMirror> get parameters;

  /**
   * A mirror on the [:call:] method for the reflectee.
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

  /**
   * Is the reflectee static?
   *
   * For the purposes of the mirrors library, type variables are considered
   * non-static.
   */
  bool get isStatic;

  /**
   * Returns [:true:] if this mirror is equal to [other].
   * Otherwise returns [:false:].
   *
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2)  [:simpleName == other.simpleName:] and
   * [:owner == other.owner:].
   */
   bool operator == (other);
}

/**
 * A [TypedefMirror] represents a typedef in a Dart language program.
 */
abstract class TypedefMirror implements TypeMirror {
  /**
   * The defining type for this typedef.
   * If the the type referred to by the reflectee is a function type 
   * *F*, the result will be [:FunctionTypeMirror:] reflecting *F*
   * which is abstract and has an abstract method [:call:] whose 
   * signature corresponds to *F*.
   *
   * For instance [:void f(int):] is the referent for [:typedef void f(int):].
   */
  FunctionTypeMirror get referent;
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
   * The source code for the reflectee, if available. Otherwise null.
   */
  String get source;

  /**
   * A list of mirrors on the parameters for the reflectee.
   */
  List<ParameterMirror> get parameters;

  /**
   * A function is considered non-static iff it is permited to refer to 'this'.
   *
   * Note that generative constructors are considered non-static, whereas
   * factory constructors are considered static.
   */
  bool get isStatic;

  /**
   * Is the reflectee abstract?
   */
  bool get isAbstract;

  /**
   * Returns true if the reflectee is synthetic, and returns false otherwise.
   *
   * A reflectee is synthetic if it is a getter or setter implicitly introduced
   * for a field or Type, or if it is a constructor that was implicitly
   * introduced as a default constructor or as part of a mixin application.
   */
  bool get isSynthetic;

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

  /**
   * Returns true if this mirror is equal to [other].
   *
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2) [:simpleName == other.simpleName:] and
   * [:owner == other.owner:].
   */
   bool operator == (other);
}

/**
 * A [VariableMirror] reflects a Dart language variable declaration.
 */
abstract class VariableMirror implements DeclarationMirror {
  /**
   * Returns a mirror on the type of the reflectee.
   */
  TypeMirror get type;

  /**
   * Returns [:true:] if the reflectee is a static variable.
   * Otherwise returns [:false:].
   *
   * For the purposes of the mirror library, top-level variables are
   * implicitly declared static.
   */
  bool get isStatic;

  /**
   * Returns [:true:] if the reflectee is a final variable.
   * Otherwise returns [:false:].
   */
  bool get isFinal;

  /**
   * Returns [:true:] if the reflectee is declared [:const:].
   * Otherwise returns [:false:].
   */
  bool get isConst;

  /**
   * Returns true if this mirror is equal to [other].
   *
   * The equality holds if and only if
   * (1) [other] is a mirror of the same kind
   * and
   * (2)  [:simpleName == other.simpleName:] and
   * [:owner == other.owner:].
   */
   bool operator == (other);
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
   * Returns [:true:] if the reflectee is an optional parameter.
   * Otherwise returns [:false:].
   */
  bool get isOptional;

  /**
   * Returns [:true:] if the reflectee is a named parameter.
   * Otherwise returns [:false:].
   */
  bool get isNamed;

  /**
   * Returns [:true:] if the reflectee has explicitly declared a default value.
   * Otherwise returns [:false:].
   */
  bool get hasDefaultValue;

  /**
   * If this is a required parameter, returns [:null:]. Otherwise returns a
   * mirror on the default value for this parameter. If no default is declared
   * for an optional parameter, the default is [:null:] and a mirror on [:null:]
   * is returned.
   */
  InstanceMirror get defaultValue;
}

/**
 * A [SourceLocation] describes the span of an entity in Dart source code.
 */
abstract class SourceLocation {
  /**
   * The 1-based line number for this source location.
   *
   * A value of 0 means that the line number is unknown.
   */
  int get line;

  /**
   * The 1-based column number for this source location.
   *
   * A value of 0 means that the column number is unknown.
   */
  int get column;

  /**
   * Returns the URI where the source originated.
   */
  Uri get sourceUri;
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
 * Annotation describing how "dart:mirrors" is used (EXPERIMENTAL).
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
 *     @MirrorsUsed(symbols: 'foo', override: '*')
 *     import 'dart:mirrors';
 *
 *     class Foo {
 *       noSuchMethod(Invocation invocation) {
 *         print(MirrorSystem.getName(invocation.memberName));
 *       }
 *     }
 *
 *     main() {
 *       new Foo().foo(); // Prints "foo".
 *       new Foo().bar(); // Might print an arbitrary (mangled) name, "bar".
 *     }
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
   * Combined with the names of [targets], [metaTargets] and their members,
   * this forms the complete list of strings passed to new [Symbol], and
   * symbols that might be passed to [MirrorSystem.getName] by the library to
   * which this metadata applies.
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
