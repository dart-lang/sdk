// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interner;

import 'dart:collection';

/**
 * The interface `Interner` defines the behavior of objects that can intern
 * strings.
 */
abstract class Interner {
  /**
   * Return a string that is identical to all of the other strings that have
   * been interned that are equal to the given [string].
   */
  String intern(String string);
}

/**
 * The class `MappedInterner` implements an interner that uses a map to manage
 * the strings that have been interned.
 */
class MappedInterner implements Interner {
  /**
   * A table mapping strings to themselves.
   */
  Map<String, String> _table = new HashMap<String, String>();

  @override
  String intern(String string) {
    String original = _table[string];
    if (original == null) {
      _table[string] = string;
      return string;
    }
    return original;
  }
}

/**
 * The class `NullInterner` implements an interner that does nothing (does not
 * actually intern any strings).
 */
class NullInterner implements Interner {
  @override
  String intern(String string) => string;
}
