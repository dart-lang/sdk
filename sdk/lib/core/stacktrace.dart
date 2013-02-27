// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An interface implemented by all stack trace objects.
 *
 * A [StackTrace] is intended to convey information to the user about the call
 * sequence that triggered an exception.
 *
 * These objects are created by the runtime, it is not possible to create
 * them programmatically.
 */
abstract class StackTrace {
  // Returns a String object that contains the full stack trace starting from
  // the point where an exception has ocurred to the entry function which is
  // typically 'main'.
  // 'toString()' on a stack trace object essentially invokes this getter.
  external String get fullStackTrace;

  // Returns a String object that contains a stack trace starting from the
  // point where an exception has ocurred to the point where the exception
  // is caught.
  external String get stackTrace;
}

