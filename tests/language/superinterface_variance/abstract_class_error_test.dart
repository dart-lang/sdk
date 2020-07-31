// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F1<X> = void Function(X);
typedef F2<X> = X Function(X);
typedef F3<X> = void Function<Y extends X>();
typedef F4<X> = X Function(X Function(void));
typedef F5<X, Y> = Y Function(X);
typedef F6<X, Y> = X Function(Y);

class A<X> {}

abstract class B<X> extends A<A<F1<X>>> {} //# 01: compile-time error

abstract class B<X> extends A<A<F2<X>>> {} //# 02: compile-time error

abstract class B<X> extends A<A<F3<X>>> {} //# 03: compile-time error

abstract class B<X> extends A<A<F4<X>>> {} //# 04: compile-time error

abstract class B<X, Y> extends A<A<F5<X, Y>>> {} //# 05: compile-time error

abstract class B<X, Y> extends A<A<F6<X, Y>>> {} //# 06: compile-time error

abstract class B<X> extends Object //# 07: compile-time error
    with //# 07: continued
        A<A<F1<X>>> {} //# 07: continued

abstract class B<X> extends Object //# 08: compile-time error
    with //# 08: continued
        A<A<F2<X>>> {} //# 08: continued

abstract class B<X> extends Object //# 09: compile-time error
    with //# 09: continued
        A<A<F3<X>>> {} //# 09: continued

abstract class B<X> extends Object //# 10: compile-time error
    with //# 10: continued
        A<A<F4<X>>> {} //# 10: continued

abstract class B<X, Y> extends Object //# 11: compile-time error
    with //# 11: continued
        A<A<F5<X, Y>>> {} //# 11: continued

abstract class B<X, Y> extends Object //# 12: compile-time error
    with //# 12: continued
        A<A<F6<X, Y>>> {} //# 12: continued

abstract class B<X> implements A<A<F1<X>>> {} //# 13: compile-time error

abstract class B<X> implements A<A<F2<X>>> {} //# 14: compile-time error

abstract class B<X> implements A<A<F3<X>>> {} //# 15: compile-time error

abstract class B<X> implements A<A<F4<X>>> {} //# 16: compile-time error

abstract class B<X, Y> implements A<A<F5<X, Y>>> {} //# 17: compile-time error

abstract class B<X, Y> implements A<A<F6<X, Y>>> {} //# 18: compile-time error

abstract class B<X> extends A<A<void Function(X)>> {} //# 19: compile-time error

abstract class B<X> extends A<A<X Function(X)>> {} //# 20: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
abstract class B<X> extends //# 21: compile-time error
    A<A<void Function<Y extends X>()>> {} //# 21: continued

abstract class B<X> extends //# 22: compile-time error
    A<A<X Function(X Function(void))>> {} //# 22: continued

abstract class B<X, Y> extends A<A<Y Function(X)>> {} //# 23: compile-time error

abstract class B<X, Y> extends A<A<X Function(Y)>> {} //# 24: compile-time error

abstract class B<X> extends Object //# 25: compile-time error
    with //# 25: continued
        A<A<void Function(X)>> {} //# 25: continued

abstract class B<X> extends Object //# 26: compile-time error
    with //# 26: continued
        A<A<X Function(X)>> {} //# 26: continued

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
abstract class B<X> extends Object //# 27: compile-time error
    with //# 27: continued
        A<A<void Function<Y extends X>()>> {} //# 27: continued

abstract class B<X> extends Object //# 28: compile-time error
    with //# 28: continued
        A<A<X Function(X Function(void))>> {} //# 28: continued

abstract class B<X, Y> extends Object //# 29: compile-time error
    with //# 29: continued
        A<A<Y Function(X)>> {} //# 29: continued

abstract class B<X, Y> extends Object //# 30: compile-time error
    with //# 30: continued
        A<A<X Function(Y)>> {} //# 30: continued

abstract class B<X> //# 31: compile-time error
    implements //# 31: continued
        A<A<void Function(X)>> {} //# 31: continued

abstract class B<X> //# 32: compile-time error
    implements //# 32: continued
        A<A<X Function(X)>> {} //# 32: continued

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
abstract class B<X> //# 33: compile-time error
    implements //# 33: continued
        A<A<void Function<Y extends X>()>> {} //# 33: continued

abstract class B<X> //# 34: compile-time error
    implements //# 34: continued
        A<A<X Function(X Function(void))>> {} //# 34: continued

abstract class B<X, Y> //# 35: compile-time error
    implements //# 35: continued
        A<A<Y Function(X)>> {} //# 35: continued

abstract class B<X, Y> //# 36: compile-time error
    implements //# 36: continued
        A<A<X Function(Y)>> {} //# 36: continued

main() {
  A();
}
