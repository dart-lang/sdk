// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The dart:mirrors library provides reflective access for Dart program.
//
// For the purposes of the mirrors library, we adopt a naming
// convention with respect to getters and setters.  Specifically, for
// some variable or field...
//
//   var myField;
//
// ...the getter is named 'myField' and the setter is named
// 'myField='.  This allows us to assign unique names to getters and
// setters for the purposes of member lookup.

// #library("mirrors");

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
  Map<String, LibraryMirror> get libraries;

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
}

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
MirrorSystem currentMirrorSystem() {
  return _Mirrors.currentMirrorSystem();
}

/**
 * Creates a [MirrorSystem] for the isolate which is listening on
 * the [SendPort].
 */
Future<MirrorSystem> mirrorSystemOf(SendPort port) {
  return _Mirrors.mirrorSystemOf(port);
}

/**
 * Returns an [InstanceMirror] for some Dart language object.
 *
 * This only works if this mirror system is associated with the
 * current running isolate.
 */
InstanceMirror reflect(Object reflectee) {
  return _Mirrors.reflect(reflectee);
}

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
  String get simpleName;

  /**
   * The fully-qualified name for this Dart language entity.
   *
   * This name is qualified by the name of the owner. For instance,
   * the qualified name of a method 'method' in class 'Class' in
   * library 'library' is 'library.Class.method'.
   *
   * TODO(turnidge): Specify whether this name is unique.  Currently
   * this is a gray area due to lack of clarity over whether library
   * names are unique.
   */
  String get qualifiedName;

  /**
   * A mirror on the owner of this function.  This is the declaration
   * immediately surrounding the reflectee.
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

  /**
   * The source location of this Dart language entity.
   */
  SourceLocation get location;
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
   * TODO(turnidge): Properly document.
   * TODO(turnidge): Handle ambiguous names.
   * TODO(turnidge): Handle optional & named arguments.
   */
  Future<InstanceMirror> invoke(String memberName,
                                List<Object> positionalArguments,
                                [Map<String,Object> namedArguments]);

  /**
   * Invokes a getter and returns a mirror on the result. The getter
   * can be the implicit getter for a field or a user-defined getter
   * method.
   *
   * TODO(turnidge): Handle ambiguous names.
   */
  Future<InstanceMirror> getField(String fieldName);

  /**
   * Invokes a setter and returns a mirror on the result. The setter
   * may be either the implicit setter for a non-final field or a
   * user-defined setter method.
   *
   * TODO(turnidge): Handle ambiguous names.
   */
  Future<InstanceMirror> setField(String fieldName, Object value);
}

/**
 * An [InstanceMirror] reflects an instance of a Dart language object.
 */
abstract class InstanceMirror implements ObjectMirror {
  /**
   * A mirror on the type of the reflectee.
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
   * Executes the closure. The arguments given in the descriptor need to
   * be InstanceMirrors or simple values.
   *
   * A value is simple if one of the following holds:
   *  - the value is null
   *  - the value is of type [num]
   *  - the value is of type [bool]
   *  - the value is of type [String]
   */
  Future<InstanceMirror> apply(List<Object> positionalArguments,
                               [Map<String,Object> namedArguments]);

  /**
   * Looks up the value of a name in the scope of the closure. The
   * result is a mirror on that value.
   */
  Future<InstanceMirror> findInContext(String name);
}

/**
 * A [LibraryMirror] reflects a Dart language library, providing
 * access to the variables, functions, and classes of the
 * library.
 */
abstract class LibraryMirror implements DeclarationMirror, ObjectMirror {
  /**
   * The url of the library.
   *
   * TODO(turnidge): Document where this url comes from.  Will this
   * value be sensible?
   */
  String get url;

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
}

/**
 * A [TypeMirror] reflects a Dart language class, typedef
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
   * An immutable map from names to mirrors for all type variables for
   * this type.
   *
   * This map preserves the order of declaration of the type variables.
   */
   Map<String, TypeVariableMirror> get typeVariables;

  /**
   * An immutable map from names to mirrors for all type arguments for
   * this type.
   *
   * This map preserves the order of declaration of the type variables.
   */
  Map<String, TypeMirror> get typeArguments;

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
   * TODO(turnidge): Properly document.
   */
  Future<InstanceMirror> newInstance(String constructorName,
                                     List<Object> positionalArguments,
                                     [Map<String,Object> namedArguments]);

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
  String get constructorName;

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
   *
   * TODO(turnidge): String may not be a good representation of this
   * at runtime.
   */
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
