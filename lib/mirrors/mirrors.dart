// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// #library("mirrors");

// The dart:mirrors library provides reflective access for Dart program.
//
// TODO(turnidge): Finish implementing this api.

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
  final Map<String, LibraryMirror> libraries;
}


/**
 * An [ObjectMirror] is a common superinterface of [InstanceMirror],
 * [InterfaceMirror], and [LibraryMirror] that represents their shared
 * functionality.
 *
 * For the purposes of the mirrors api, these types are all
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
   * If the [InstanceMirror] refers to a simple type, we provide
   * access to the actual value here.  Simple types are...
   *
   * TODO(turnidge): Properly document.
   *
   * TODO(turnidge): How best to represent a null simple value versus
   * the absence of a simple value?
   */
  final simpleValue;
}

/**
 * An [InterfaceMirror] reflects a Dart language class or interface.
 */
interface InterfaceMirror extends ObjectMirror {
}

/**
 * A [LibraryMirror] reflects a Dart language library, providing
 * access to the variables, functions, classes, and interfaces of the
 * library.
 */
interface LibraryMirror extends ObjectMirror {
  /**
   * The name of the library, as provided in the [#library] declaration.
   */
  final String simpleName;

  /**
   * The url of the library.
   *
   * TODO(turnidge): Document where this url comes from.  Will this
   * value be sensible?
   */
  final String url;
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
