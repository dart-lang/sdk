// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "main_lib.dart";

// Extending a legacy class that implements a core library base class.
abstract class LegacyExtendsBase<E extends LinkedListEntry<E>>
    extends LegacyImplementBaseCore<E> {}

// Extending a legacy class that implements a core library final class.
class LegacyExtendsFinal extends LegacyImplementFinalCore {}

// Mixing in a legacy class that implements a core library base class.
abstract class LegacyWithBase<E extends LinkedListEntry<E>>
    with LegacyImplementBaseCore<E> {}

// Mixing in a legacy class that implements a core library final class.
class LegacyWithFinal with LegacyImplementFinalCore {}

// Using a legacy class that implements a core library base class as a
// superclass constraint on a mixin.
mixin LegacyOnBase<E extends LinkedListEntry<E>>
    on LegacyImplementBaseCore<E> {}

// Using a legacy class that implements a core library final class as a
// superclass constraint on a mixin.
mixin LegacyOnFinal on LegacyImplementFinalCore {}
