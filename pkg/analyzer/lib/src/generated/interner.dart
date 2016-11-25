// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.interner;

import 'dart:collection';

import 'package:front_end/src/scanner/interner.dart';

export 'package:front_end/src/scanner/interner.dart'
    show Interner, NullInterner;

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
