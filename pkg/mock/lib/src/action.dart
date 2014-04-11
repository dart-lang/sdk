// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.action;

/** The ways in which a call to a mock method can be handled. */
class Action {
  /** Do nothing (void method) */
  static const IGNORE = const Action._('IGNORE');

  /** Return a supplied value. */
  static const RETURN = const Action._('RETURN');

  /** Throw a supplied value. */
  static const THROW = const Action._('THROW');

  /** Call a supplied function. */
  static const PROXY = const Action._('PROXY');

  const Action._(this.name);

  final String name;

  String toString() => 'Action: $name';
}
