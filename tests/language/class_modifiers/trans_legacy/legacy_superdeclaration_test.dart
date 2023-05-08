// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

import "legacy_lib.dart";

// Can extend any class in legacy library.

abstract base class ExtendsLegacyImplementsFinal
    extends LegacyImplementsFinal {}

abstract base class ExtendsLegacyImplementsFinal2 = LegacyImplementsFinal
    with _AnyMixin;

abstract base class ExtendsLegacyExtendsFinal extends LegacyExtendsFinal {}

abstract base class ExtendsLegacyExtendsFinal2 = LegacyExtendsFinal2
    with _AnyMixin;

abstract base class ExtendsLegacyMixesInFinal extends LegacyMixesInFinal {}

abstract base class ExtendsLegacyMixesInFinal2 = LegacyMixesInFinal2
    with _AnyMixin;

abstract base class ExtendsLegacyImplementsBase extends LegacyImplementsBase {}

abstract base class ExtendsLegacyImplementsBase2 = LegacyImplementsBase
    with _AnyMixin;

abstract class ExtendsLegacyExtendsInterface extends LegacyExtendsInterface {}

abstract class ExtendsLegacyExtendsInterface2 = LegacyExtendsInterface
    with _AnyMixin;

abstract class ExtendsLegacyMixesInInterface extends LegacyMixesInInterface {}

abstract class ExtendsLegacyMixesInInterface2 = LegacyMixesInInterface
    with _AnyMixin;

// Can mix-in any class in legacy library with `Object` superclass and
// no constructor.

abstract base class MixesInLegacyImplementsFinal with LegacyImplementsFinal {}

abstract base class MixesInLegacyImplementsFinal2 = Object
    with LegacyImplementsFinal;

abstract base class MixesInLegacyMixesInFinal with LegacyMixesInFinal2 {}

abstract base class MixesInLegacyMixesInFinal2 = Object
    with LegacyMixesInFinal2;

abstract base class MixesInLegacyImplementsBase with LegacyImplementsBase {}

abstract base class MixesInLegacyImplementsBase2 = Object
    with LegacyImplementsBase;

abstract class MixesInLegacyMixesInInterface with LegacyMixesInInterface2 {}

abstract class MixesInLegacyMixesInInterface2 = Object
    with LegacyMixesInInterface2;

// Or which are mixins.
abstract base class MixesInLegacyMixinOnFinal extends LegacyImplementsFinal
    with LegacyMixinOnFinal {}

abstract base class MixesInLegacyMixinOnFinal2 = LegacyImplementsFinal
    with LegacyMixinOnFinal;

abstract base class MixesInLegacyMixinOnBase extends LegacyMixinOnBaseSuper
    with LegacyMixinOnBase {}

abstract base class MixesInLegacyMixinOnBase2 = LegacyMixinOnBaseSuper
    with LegacyMixinOnBase;

abstract base class MixesInLegacyMixesInNonMixin extends Object
    with LegacyMixesInNonMixin2 {}

abstract base class MixesInLegacyMixesInNonMixin2 = Object
    with LegacyMixesInNonMixin2;

abstract base class MixesInLegacyMixinImplementsFinal
    with LegacyMixinImplementsFinal {}

abstract base class MixesInLegacyMixinImplementsBase
    with LegacyMixinImplementsBase {}

// Can implement any legacy class which does not have `base`/`final`
// superdeclaration.

abstract class ImplementsLegacyExtendsInterface
    implements LegacyExtendsInterface {}

// Helpers
mixin _AnyMixin {}

void main() {}