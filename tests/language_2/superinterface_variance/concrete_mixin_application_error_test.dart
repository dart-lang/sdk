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

mixin B {}

class C0 = Object with B;

class C<X> = A<F1<X>> with B; //# 01: compile-time error

class C<X> = A<F2<X>> with B; //# 02: compile-time error

class C<X> = A<F3<X>> with B; //# 03: compile-time error

class C<X> = A<F4<X>> with B; //# 04: compile-time error

class C<X, Y> = A<F5<X, Y>> with B; //# 05: compile-time error

class C<X, Y> = A<F6<X, Y>> with B; //# 06: compile-time error

class C<X> = Object with A<F1<X>>; //# 07: compile-time error

class C<X> = Object with A<F2<X>>; //# 08: compile-time error

class C<X> = Object with A<F3<X>>; //# 09: compile-time error

class C<X> = Object with A<F4<X>>; //# 10: compile-time error

class C<X, Y> = Object with A<F5<X, Y>>; //# 11: compile-time error

class C<X, Y> = Object with A<F6<X, Y>>; //# 12: compile-time error

class C<X> = Object with B implements A<F1<X>>; //# 13: compile-time error

class C<X> = Object with B implements A<F2<X>>; //# 14: compile-time error

class C<X> = Object with B implements A<F3<X>>; //# 15: compile-time error

class C<X> = Object with B implements A<F4<X>>; //# 16: compile-time error

class C<X, Y> = Object with B implements A<F5<X, Y>>; //# 17: compile-time error

class C<X, Y> = Object with B implements A<F6<X, Y>>; //# 18: compile-time error

class C<X> = A<void Function(X)> with B; //# 19: compile-time error

class C<X> = A<X Function(X)> with B; //# 20: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
class C<X> = A<void Function<Y extends X>()> with B; //# 21: compile-time error

class C<X> = A<X Function(X Function(void))> with B; //# 22: compile-time error

class C<X, Y> = A<Y Function(X)> with B; //# 23: compile-time error

class C<X, Y> = A<X Function(Y)> with B; //# 24: compile-time error

class C<X> = Object with A<void Function(X)>; //# 25: compile-time error

class C<X> = Object with A<X Function(X)>; //# 26: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
class C<X> = Object //# 27: compile-time error
    with //# 27: continued
        A<void Function<Y extends X>()>; //# 27: continued

class C<X> = Object //# 28: compile-time error
    with //# 28: continued
        A<X Function(X Function(void))>; //# 28: continued

class C<X, Y> = Object with A<Y Function(X)>; //# 29: compile-time error

class C<X, Y> = Object with A<X Function(Y)>; //# 30: compile-time error

class C<X> = Object //# 31: compile-time error
    with //# 31: continued
        B //# 31: continued
    implements //# 31: continued
        A<void Function(X)>; //# 31: continued

class C<X> = Object //# 32: compile-time error
    with //# 32: continued
        B //# 32: continued
    implements //# 32: continued
        A<X Function(X)>; //# 32: continued

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
class C<X> = Object //# 33: compile-time error
    with //# 33: continued
        B //# 33: continued
    implements //# 33: continued
        A<void Function<Y extends X>()>; //# 33: continued

class C<X> = Object //# 34: compile-time error
    with //# 34: continued
        B //# 34: continued
    implements //# 34: continued
        A<X Function(X Function(void))>; //# 34: continued

class C<X, Y> = Object //# 35: compile-time error
    with //# 35: continued
        B //# 35: continued
    implements //# 35: continued
        A<Y Function(X)>; //# 35: continued

class C<X, Y> = Object //# 36: compile-time error
    with //# 36: continued
        B //# 36: continued
    implements //# 36: continued
        A<X Function(Y)>; //# 36: continued

main() {
  A();
  C0();
}
