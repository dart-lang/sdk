// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// #library("mirrors");

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
//
// TODO(turnidge): Finish implementing this api.

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
   * A mirror on the root library of the mirror system.
   */
  final LibraryMirror rootLibrary;

  /**
   * An immutable map from from library names to mirrors for all
   * libraries known to this mirror system.
  */
  Map<String, LibraryMirror> libraries();

  /**
   * A mirror on the isolate associated with this [MirrorSystem].
   * This may be null if this mirror system is not running.
   */
  IsolateMirror isolate;

  /**
   * Returns an [InstanceMirror] for some Dart language object.
   *
   * This only works if this mirror system is associated with the
   * current running isolate.
   */
  InstanceMirror mirrorOf(Object reflectee);
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
 * A [Mirror] reflects some Dart language entity.
 *
 * Every [Mirror] originates from some [MirrorSystem].
 */
interface Mirror {
  /**
   * The originating [MirrorSystem] for this mirror.
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
}


/**
 * An [ObjectMirror] is a common superinterface of [InstanceMirror],
 * [InterfaceMirror], and [LibraryMirror] that represents their shared
 * functionality.
 *
 * For the purposes of the mirrors library, these types are all
 * object-like, in that they support method invocation and field
 * access.  Real Dart objects are represented by the [InstanceMirror]
 * type.
 *
 * See [InstanceMirror], [InterfaceMirror], and [LibraryMirror].
 */
interface ObjectMirror extends Mirror {
  /**
   * Invokes the named function and returns a mirror on the result.
   *
   * TODO(turnidge): Properly document.
   */
  Future<InstanceMirror> invoke(String memberName,
                                List<Object> positionalArguments,
                                [Map<String,Object> namedArguments]);
}

/**
 * An [InstanceMirror] reflects an instance of a Dart language object.
 */
interface InstanceMirror extends ObjectMirror {
  /**
   * Returns a mirror on the class of the reflectee.
   */
  InterfaceMirror getClass();

  /**
   * Does [reflectee] contain the instance reflected by this mirror? This will
   * always be true in the local case (reflecting instances in the same 
   * isolate), but only true in the remote case if this mirror reflects a 
   * simple value.
   *
   * A value is simple if one of the following holds:
   *  - the value is null
   *  - the value is of type [num]
   *  - the value is of type [bool]
   *  - the value is of type [String]
   */
  final bool hasReflectee;

  /**
   * If the [InstanceMirror] reflects an instance it is meaningful to have a
   * local reference to, we provide access to the actual instance here.
   *
   * If you access [reflectee] when [hasReflectee] is false, an
   * exception is thrown.
   */
  final reflectee;
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
 * An [InterfaceMirror] reflects a Dart language class or interface.
 */
interface InterfaceMirror extends TypeMirror, ObjectMirror {
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
  InterfaceMirror superclass();

  /**
   * Returns a list of mirrors on the superinterfaces for the reflectee.
   */
  List<InterfaceMirror> superinterfaces();

  /**
   * Returns a mirror on the default factory class or null if there is
   * none.
   */
  InterfaceMirror defaultFactory();

  /**
   * An immutable map from from names to mirrors for all members of
   * this type.
   *
   * The members of an interface are its constructors, methods,
   * fields, getters, and setters.
   *
   * This does not include inherited members.
   */
  Map<String, Mirror> members();

  /**
   * An immutable map from names to mirrors for all method,
   * constructor, getter, and setter declarations in this library.
   */
  Map<String, MethodMirror> methods();

  /**
   * An immutable map from names to mirrors for all variable
   * declarations in this library.
   */
  Map<String, VariableMirror> variables();
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
  Map<String, Mirror> members();

  /**
   * An immutable map from names to mirrors for all class and
   * interface declarations in this library.
   */
  Map<String, InterfaceMirror> classes();

  /**
   * An immutable map from names to mirrors for all function
   * declarations in this library.
   */
  Map<String, MethodMirror> functions();

  /**
   * An immutable map from names to mirrors for all variable
   * declarations in this library.
   */
  Map<String, VariableMirror> variables();
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
   * [InterfaceMirror].
   */
  Mirror owner;

  // Ownership

  /**
   * Does this mirror reflect a top-level function?
   */
  bool isTopLevel;

  /**
   * Does this mirror reflect a static method?
   *
   * For the purposes of the mirrors library, a top-level function is
   * considered static.
   */
  bool isStatic;

  // Method kind

  /**
   * Does this mirror reflect a regular function or method?
   *
   * A method is regular if it is not a getter, setter, or constructor.
   */
  bool isMethod;

  /**
   * Does this mirror reflect an abstract method?
   */
  bool isAbstract;

  /**
   * Does this mirror reflect a getter?
   */
  bool isGetter;

  /**
   * Does this mirror reflect a setter?
   */
  bool isSetter;

  /**
   * Does this mirror reflect a constructor?
   */
  bool isConstructor;

  // Constructor kind

  /**
   * Does this mirror reflect a const constructor?
   */
  bool isConstConstructor;

  /**
   * Does this mirror reflect a generative constructor?
   */
  bool isGenerativeConstructor;

  /**
   * Does this mirror reflect a redirecting constructor?
   */
  bool isRedirectingConstructor;

  /**
   * Does this mirror reflect a factory constructor?
   */
  bool isFactoryConstructor;
}


/**
 * A [VariableMirror] reflects a Dart language variable.
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
   * class and interface variables, this will be an [InterfaceMirror].
   */
  Mirror owner;

  /**
   * Does this mirror reflect a top-level variable?
   */
  bool isTopLevel;

  /**
   * Does this mirror reflect a static variable?
   *
   * For the purposes of the mirror library, top-level variables are
   * implicitly declared static.
   */
  bool isStatic;

  /**
   * Does this mirror reflect a final variable?
   */
  bool isFinal;
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
