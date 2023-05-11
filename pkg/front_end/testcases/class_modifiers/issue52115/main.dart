// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "main_lib.dart";

// Implementing a legacy class that implements a core library base class.
abstract base class LegacyImplementBase<E extends LinkedListEntry<E>>
    implements LegacyImplementBaseCore<E> {}

// Implementing a legacy class that implements a core library final class.
final class LegacyImplementFinal implements LegacyImplementFinalCore {
  int get key => 0;
  int get value => 1;
  String toString() => "Bad";
}

// Implementing a legacy class that implements a core library base class.
abstract class LegacyImplementBaseNoModifier<E extends LinkedListEntry<E>>
    implements LegacyImplementBaseCore<E> {}

// Implementing a legacy class that implements a core library final class.
class LegacyImplementFinalNoModifier implements LegacyImplementFinalCore {
  int get key => 0;
  int get value => 1;
  String toString() => "Bad";
}
