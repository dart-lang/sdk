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
// TODO(turnidge): Implement getter/setter lookup.
//
// TODO(turnidge): Finish implementing this api.

/**
 * Returns an [IsolateMirror] for the current isolate.
 */
IsolateMirror currentIsolateMirror() {
  return _Mirrors.currentIsolateMirror();
}

/**
 * Returns an [InstanceMirror] for some Dart language object.
 */
InstanceMirror mirrorOf(Object reflectee) {
  return _Mirrors.mirrorOf(reflectee);
}

/**
 * Creates an [IsolateMirror] on the isolate which is listening on
 * the [SendPort].
 */
Future<IsolateMirror> isolateMirrorOf(SendPort port) {
  return _Mirrors.isolateMirrorOf(port);
}

/**
 * A [Mirror] reflects some Dart language entity.
 *
 * Every [Mirror] originates from some [IsolateMirror].
 */
interface Mirror {
  /**
   * The isolate of orgin for this [Mirror].
   */
  final IsolateMirror isolate;
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
   * A mirror on the root library of the reflectee.
   */
  final LibraryMirror rootLibrary;

  /**
   * An immutable map from from library names to mirrors for all
   * libraries loaded in the reflectee.
  */
  Map<String, LibraryMirror> libraries();
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
   *
   * TODO(turnidge): what to do if invoke causes the death of the reflectee?
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
   * Does [simpleValue] contain the value of the reflectee?
   */
  bool hasSimpleValue;

  /**
   * If the [InstanceMirror] refers to a simple value, we provide
   * access to the actual value here.
   *
   * A value is simple if:
   *  - it is null
   *  - it is of type [num]
   *  - it is of type [bool]
   *  - it is of type [String]
   *
   * If you access [simpleValue] when [hasSimpleValue] is false an
   * exception is thrown.
   */
  final simpleValue;

}

/**
 * An [InterfaceMirror] reflects a Dart language class or interface.
 */
interface InterfaceMirror extends ObjectMirror {
  /**
   * The name of this interface.
   */
  final String simpleName;

  /**
   * The library in which this interface is declared.
   */
  final LibraryMirror library;

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
   * this type, including inherited members.
   *
   * The members of an interface are its constructors, methods,
   * fields, getters, and setters.
   *
   * TODO(turnidge): Currently empty.
   */
  Map<String, Mirror> members();
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
   * An immutable map from from top-level names to mirrors for all
   * members in this library.
   *
   * The members of a library are its top-level classes, interfaces,
   * functions, variables, getters, and setters.
   *
   * TODO(turnidge): Currently only contains classes and interfaces.
   */
  Map<String, Mirror> members();
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
 *   isolate death, but this is yet to be implemented.
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
