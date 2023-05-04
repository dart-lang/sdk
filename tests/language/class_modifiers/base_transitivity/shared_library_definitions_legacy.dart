// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// @dart=2.19

import 'dart:collection';

/// Legacy library which defines some classes and mixins to be used to test
/// behaviors across libraries.

abstract class LegacyImplementBaseCore<E extends LinkedListEntry<E>>
    implements LinkedList<E> {}

class LegacyImplementFinalCore implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
  String toString() => "Bad";
}
