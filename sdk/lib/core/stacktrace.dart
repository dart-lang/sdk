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
  /**
   * Returns a [String] representation of the stack trace.
   *
   * The string represents the full stack trace starting from
   * the point where a throw ocurred to the top of the current call sequence.
   *
   * The exact format of the string representation is not final.
   */
  String toString();
}

