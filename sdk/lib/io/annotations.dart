// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * The annotation `@Experimental('message')` marks a feature as experimental.
 *
 * The annotation `@experimental` is shorthand that uses the default message
 * "This feature is experimental and not intended for general use".
 *
 * The intent of the `@Experimental` annotation is to inform users that a
 * feature has one ore more of the following issues:
 * - It is not yet stable,
 * - It may not work as documented,
 * - It should only be used by experts,
 * - It is not available in all environments.
 *
 * The documentation for an experimental feature should explain which of these
 * apply, and ideally give a reasonably safe example usage.
 *
 * A tool that processes Dart source code may give reports when experimental
 * features are used similarly to how they give reports for features marked
 * with the [Deprecated] annotation.
 */
class Experimental {
  /**
   * A brief message describing how or why the feature is experimental.
   */
  final String message;

  const Experimental({String message}) : this.message = message;

  @override
  String toString() {
    if (message == null) {
      return "This feature is experimental, and not intended for general use.";
    } else {
      return "This feature is experimental: $message";
    }
  }
}

/**
 * Marks a feature as experimental with the message, "Not intended for
 * general use".
 */
const Experimental experimental = const Experimental();
