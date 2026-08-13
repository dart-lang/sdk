// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {}

class A {}

class B extends A {}

class C extends B {}

class D extends C {}

class G<T extends A> {}

class GB extends G<B> {}

class GC extends G<C> {}

class GD extends G<D> {}

class X implements A {}

class Y extends X {}

class Z implements Y {}

class W implements Z {}

class GX implements G<A> {}

class GY extends X implements GB {}

class GZ implements Y, GC {}

class GW implements Z, GD {}

class GU extends GW {}

class GV extends GU implements GW {}

class ARO<S> {}

class ARQ<T> extends Object implements ARO<T> {}

class ARN extends ARQ<A> {}
