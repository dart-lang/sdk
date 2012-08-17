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
interface MirrorSystem {
  /**
   * An immutable map from from library names to mirrors for all
   * libraries known to this mirror system.
   */
  final Map<String, LibraryMirror> libraries;

  /**
   * A mirror on the isolate associated with this [MirrorSystem].
   * This may be null if this mirror system is not running.
   */
  final IsolateMirror isolate;

  /**
   * A mirror on the [:Dynamic:] type.
   */
  final TypeMirror dynamicType;

  /**
   * A mirror on the [:void:] type.
   */
  final TypeMirror voidType;
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
interface Mirror extends Hashable {
  /**
   * The [MirrorSystem] that contains this mirror.
   */
  final MirrorSystem mirrors;
}

/**
 * An [IsolateMirror] reflects an isolate.
 */
interface IsolateMirror extends Mirror {
  /**
   * A unique name used to refer to an isolate in debugging messages.
   */
  final String debugName;

  /**
   * Does this mirror reflect the currently running isolate?
   */
  final bool isCurrent;

  /**
   * A mirror on the root library for this isolate.
   */
  final LibraryMirror rootLibrary;
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
interface ObjectMirror extends Mirror {
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
interface InstanceMirror extends ObjectMirror {
  /**
   * A mirror on the type of the reflectee.
   */
  final ClassMirror type;

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
  final bool hasReflectee;

  /**
   * If the [InstanceMirror] reflects an instance it is meaningful to
   * have a local reference to, we provide access to the actual
   * instance here.
   *
   * If you access [reflectee] when [hasReflectee] is false, an
   * exception is thrown.
   */
  final reflectee;
}

/**
 * A [ClosureMirror] reflects a closure.
 *
 * A [ClosureMirror] provides access to its captured variables and
 * provides the ability to execute its reflectee.
 */
interface ClosureMirror extends InstanceMirror {
  /**
   * A mirror on the function associated with this closure.
   */
  final MethodMirror function;

  /**
   * The source code for this closure, if available.  Otherwise null.
   *
   * TODO(turnidge): Would this just be available in function?
   */
  final String source;

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
 * A [TypeMirror] reflects a Dart language class, interface, typedef
 * or type variable.
 */
interface TypeMirror extends Mirror {
  /**
   * The library in which this interface is declared.
   */
  final LibraryMirror library;
}

/**
 * A [ClassMirror] reflects a Dart language class or interface.
 */
interface ClassMirror extends TypeMirror, ObjectMirror {
  /**
   * The name of this interface.
   */
  final String simpleName;

  /**
   * Does this mirror represent a class?
   */
  final bool isClass;

  /**
   * Returns a mirror on the superclass on the reflectee.
   *
   * For interfaces, the superclass is Object.
   */
  final ClassMirror superclass;

  /**
   * Returns a list of mirrors on the superinterfaces for the reflectee.
   */
  final List<ClassMirror> superinterfaces;

  /**
   * Returns a mirror on the default factory class or null if there is
   * none.
   */
  final ClassMirror defaultFactory;

  /**
   * An immutable map from from names to mirrors for all members of
   * this type.
   *
   * The members of an interface are its constructors, methods,
   * fields, getters, and setters.
   *
   * This does not include inherited members.
   */
  final Map<String, Mirror> members;

  /**
   * An immutable map from names to mirrors for all method,
   * constructor, getter, and setter declarations in this library.
   */
  final Map<String, MethodMirror> methods;

  /**
   * An immutable map from names to mirrors for all variable
   * declarations in this library.
   */
  final Map<String, VariableMirror> variables;

  /**
   * Invokes the named constructor and returns a mirror on the result.
   *
   * TODO(turnidge): Properly document.
   */
  Future<InstanceMirror> newInstance(String constructorName,
                                List<Object> positionalArguments,
                                [Map<String,Object> namedArguments]);
}

/**
 * A [LibraryMirror] reflects a Dart language library, providing
 * access to the variables, functions, classes, and interfaces of the
 * library.
 */
interface LibraryMirror extends ObjectMirror {
  /**
   * The name of this library, as provided in the [#library] declaration.
   */
  final String simpleName;

  /**
   * The url of the library.
   *
   * TODO(turnidge): Document where this url comes from.  Will this
   * value be sensible?
   */
  final String url;

  /**
   * An immutable map from from names to mirrors for all members in
   * this library.
   *
   * The members of a library are its top-level classes, interfaces,
   * functions, variables, getters, and setters.
   */
  final Map<String, Mirror> members;

  /**
   * An immutable map from names to mirrors for all class and
   * interface declarations in this library.
   */
  final Map<String, ClassMirror> classes;

  /**
   * An immutable map from names to mirrors for all function
   * declarations in this library.
   */
  final Map<String, MethodMirror> functions;

  /**
   * An immutable map from names to mirrors for all variable
   * declarations in this library.
   */
  final Map<String, VariableMirror> variables;
}

/**
 * A [MethodMirror] reflects a Dart language function, method,
 * constructor, getter, or setter.
 */
interface MethodMirror {
  /**
   * The name of this function.
   */
  final String simpleName;

  /**
   * A mirror on the owner of this function.  This is the declaration
   * immediately surrounding the reflectee.
   *
   * For top-level functions, this will be a [LibraryMirror] and for
   * methods, constructors, getters, and setters, this will be an
   * [ClassMirror].
   */
  final Mirror owner;

  /**
   * Returns the list of parameters for this method.
   */
  final List<ParameterMirror> parameters;

  // Ownership

  /**
   * Does this mirror reflect a top-level function?
   */
  final bool isTopLevel;

  /**
   * Does this mirror reflect a static method?
   *
   * For the purposes of the mirrors library, a top-level function is
   * considered static.
   */
  final bool isStatic;

  // Method kind

  /**
   * Does this mirror reflect a regular function or method?
   *
   * A method is regular if it is not a getter, setter, or constructor.
   */
  final bool isMethod;

  /**
   * Does this mirror reflect an abstract method?
   */
  final bool isAbstract;

  /**
   * Does this mirror reflect a getter?
   */
  final bool isGetter;

  /**
   * Does this mirror reflect a setter?
   */
  final bool isSetter;

  /**
   * Does this mirror reflect a constructor?
   */
  final bool isConstructor;

  // Constructor kind

  /**
   * Does this mirror reflect a const constructor?
   */
  final bool isConstConstructor;

  /**
   * Does this mirror reflect a generative constructor?
   */
  final bool isGenerativeConstructor;

  /**
   * Does this mirror reflect a redirecting constructor?
   */
  final bool isRedirectingConstructor;

  /**
   * Does this mirror reflect a factory constructor?
   */
  final bool isFactoryConstructor;
}

/**
 * A [ParameterMirror] reflects a Dart formal parameter declaration.
 */
interface ParameterMirror extends VariableMirror {
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
}

/**
 * A [VariableMirror] reflects a Dart language variable declaration.
 */
interface VariableMirror {
  /**
   * The name of this variable
   */
  final String simpleName;

  /**
   * A mirror on the owner of this method.  The owner is the
   * declaration immediately surrounding the reflectee.
   *
   * For top-level variables, this will be a [LibraryMirror] and for
   * class and interface variables, this will be a [ClassMirror].
   */
  final Mirror owner;

  /**
   * Does this mirror reflect a top-level variable?
   */
  final bool isTopLevel;

  /**
   * Does this mirror reflect a static variable?
   *
   * For the purposes of the mirror library, top-level variables are
   * implicitly declared static.
   */
  final bool isStatic;

  /**
   * Does this mirror reflect a final variable?
   */
  final bool isFinal;
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
