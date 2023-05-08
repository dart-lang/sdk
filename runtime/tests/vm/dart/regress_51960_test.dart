// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that VM doesn't time out on loading of highly recursive types.
// Regression test for https://github.com/dart-lang/sdk/issues/51960.

class A<A1 extends A<A1, B1, C1, D1>, B1 extends B<A1, B1, C1, D1>,
    C1 extends C<A1, B1, C1, D1>, D1 extends D<A1, B1, C1, D1>> {}

class B<A1 extends A<A1, B1, C1, D1>, B1 extends B<A1, B1, C1, D1>,
    C1 extends C<A1, B1, C1, D1>, D1 extends D<A1, B1, C1, D1>> {}

class C<A1 extends A<A1, B1, C1, D1>, B1 extends B<A1, B1, C1, D1>,
    C1 extends C<A1, B1, C1, D1>, D1 extends D<A1, B1, C1, D1>> {}

class D<A1 extends A<A1, B1, C1, D1>, B1 extends B<A1, B1, C1, D1>,
    C1 extends C<A1, B1, C1, D1>, D1 extends D<A1, B1, C1, D1>> {}

/* -= Mixins =- */

mixin MixinA<
        A1 extends MixinA<A1, B1, C1, D1>,
        B1 extends MixinB<A1, B1, C1, D1>,
        C1 extends MixinC<A1, B1, C1, D1>,
        D1 extends MixinD<A1, B1, C1, D1>>
    on A<MixinA<A1, B1, C1, D1>, MixinB<A1, B1, C1, D1>, MixinC<A1, B1, C1, D1>,
        MixinD<A1, B1, C1, D1>> {}

mixin MixinB<
        A1 extends MixinA<A1, B1, C1, D1>,
        B1 extends MixinB<A1, B1, C1, D1>,
        C1 extends MixinC<A1, B1, C1, D1>,
        D1 extends MixinD<A1, B1, C1, D1>>
    on B<MixinA<A1, B1, C1, D1>, MixinB<A1, B1, C1, D1>, MixinC<A1, B1, C1, D1>,
        MixinD<A1, B1, C1, D1>> {}

mixin MixinC<
        A1 extends MixinA<A1, B1, C1, D1>,
        B1 extends MixinB<A1, B1, C1, D1>,
        C1 extends MixinC<A1, B1, C1, D1>,
        D1 extends MixinD<A1, B1, C1, D1>>
    on C<MixinA<A1, B1, C1, D1>, MixinB<A1, B1, C1, D1>, MixinC<A1, B1, C1, D1>,
        MixinD<A1, B1, C1, D1>> {}

mixin MixinD<
        A1 extends MixinA<A1, B1, C1, D1>,
        B1 extends MixinB<A1, B1, C1, D1>,
        C1 extends MixinC<A1, B1, C1, D1>,
        D1 extends MixinD<A1, B1, C1, D1>>
    on D<MixinA<A1, B1, C1, D1>, MixinB<A1, B1, C1, D1>, MixinC<A1, B1, C1, D1>,
        MixinD<A1, B1, C1, D1>> {}

void main() {}
