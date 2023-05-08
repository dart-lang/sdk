// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19
// SharedOptions=--enable-experiment=class-modifiers

import "dart:async";
import "dart:collection";

// Pre-feature declarations which ignore platform library restrictions.
// Used to test that feature-enabled libraries behave correctly when
// going througn pre-feature super-declarations.

// Ignoring rule against extending, implementing, mixing in and `on`-typing
// a final declaration.

// Implements `final`.
abstract class LegacyImplementsFinal implements MapEntry<int, int> {}

mixin LegacyMixinImplementsFinal implements MapEntry<int, int> {}

enum LegacyEnumImplementsFinal implements MapEntry<int, int> {
  v;
  final int key = 0;
  final int value = 0;
}

// Extends `final`. `ListQueue` has public generative constructor.
abstract class LegacyExtendsFinal extends ListQueue<int> {}

abstract class LegacyExtendsFinal2 = ListQueue<int> with _AnyMixin;

// Mixes in `final`.
// BigInt is `final`, but has `Object` as superclass and declares only
// factory constructors, so should be allowed as a legacy mixin.
abstract class LegacyMixesInFinal with BigInt {}

abstract class LegacyMixesInFinal2 = Object with BigInt;

enum LegacyEnumMixesInFinal with BigInt {
  v;
  noSuchMethod(i) => super.noSuchMethod(i);
}

// Mixin on `final`.
mixin LegacyMixinOnFinal on MapEntry<int, int> {}

// Ignore `base` modifier.

// Implements `base`.
abstract class LegacyImplementsBase
    implements LinkedList<LinkedListEntry<Never>> {}

mixin LegacyMixinImplementsBase implements LinkedList<LinkedListEntry<Never>> {}

enum LegacyEnumImplementsBase implements LinkedList<LinkedListEntry<Never>> {
  v;
  noSuchMethod(i) => super.noSuchMethod(i);
}

// Mixin on `base`. Not prohibited otherwise, but the `base` should be
// visible through the legacy library.
mixin LegacyMixinOnBase on LinkedListEntry<Never> {}

// Valid class to mix in the above mixin on.
abstract class LegacyMixinOnBaseSuper extends LinkedListEntry<Never> {}

// Ignore `interface` modifier.

// Extends interface.
abstract class LegacyExtendsInterface extends Sink<int> {}

// Mixes in interface (*and* non-`mixin` class, necessarily).
abstract class LegacyMixesInInterface with Sink<int> {}

abstract class LegacyMixesInInterface2 = Object with Sink<int>;

enum LegacyEnumMixesInInterface with Sink<int> {
  v;
  noSuchMethod(i) => super.noSuchMethod(i);
}

// Ignore lack of `mixin`, with base or no modifier.
// (No `base` classes qualify. And `StreamConsumer` should have been an
// `abstract interface class`.)
abstract class LegacyMixesInNonMixin extends Object with StreamConsumer<int> {}

abstract class LegacyMixesInNonMixin2 = Object with StreamConsumer<int>;

enum LegacyEnumMixesInNonMixin with StreamConsumer<int> {
  v;
  noSuchMethod(i) => super.noSuchMethod(i);
}

// Helper
mixin _AnyMixin {}
