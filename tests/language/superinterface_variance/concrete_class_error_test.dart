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

class B<X> extends A<F1<X>> {} //# 01: compile-time error

class B<X> extends A<F2<X>> {} //# 02: compile-time error

class B<X> extends A<F3<X>> {} //# 03: compile-time error

class B<X> extends A<F4<X>> {} //# 04: compile-time error

class B<X, Y> extends A<F5<X, Y>> {} //# 05: compile-time error

class B<X, Y> extends A<F6<X, Y>> {} //# 06: compile-time error

class B<X> extends Object with A<F1<X>> {} //# 07: compile-time error

class B<X> extends Object with A<F2<X>> {} //# 08: compile-time error

class B<X> extends Object with A<F3<X>> {} //# 09: compile-time error

class B<X> extends Object with A<F4<X>> {} //# 10: compile-time error

class B<X, Y> extends Object with A<F5<X, Y>> {} //# 11: compile-time error

class B<X, Y> extends Object with A<F6<X, Y>> {} //# 12: compile-time error

class B<X> implements A<F1<X>> {} //# 13: compile-time error

class B<X> implements A<F2<X>> {} //# 14: compile-time error

class B<X> implements A<F3<X>> {} //# 15: compile-time error

class B<X> implements A<F4<X>> {} //# 16: compile-time error

class B<X, Y> implements A<F5<X, Y>> {} //# 17: compile-time error

class B<X, Y> implements A<F6<X, Y>> {} //# 18: compile-time error

class B<X> extends A<void Function(X)> {} //# 19: compile-time error

class B<X> extends A<X Function(X)> {} //# 20: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
class B<X> extends A<void Function<Y extends X>()> {} //# 21: compile-time error

class B<X> extends A<X Function(X Function(void))> {} //# 22: compile-time error

class B<X, Y> extends A<Y Function(X)> {} //# 23: compile-time error

class B<X, Y> extends A<X Function(Y)> {} //# 24: compile-time error

class B<X> extends Object with A<void Function(X)> {} //# 25: compile-time error

class B<X> extends Object with A<X Function(X)> {} //# 26: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
class B<X> extends Object //# 27: compile-time error
    with //# 27: continued
        A<void Function<Y extends X>()> {} //# 27: continued

class B<X> extends Object //# 28: compile-time error
    with //# 28: continued
        A<X Function(X Function(void))> {} //# 28: continued

class B<X, Y> extends Object with A<Y Function(X)> {} //# 29: compile-time error

class B<X, Y> extends Object with A<X Function(Y)> {} //# 30: compile-time error

class B<X> implements A<void Function(X)> {} //# 31: compile-time error

class B<X> implements A<X Function(X)> {} //# 32: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
class B<X> //# 33: compile-time error
    implements //# 33: continued
        A<void Function<Y extends X>()> {} //# 33: continued

class B<X> //# 34: compile-time error
    implements //# 34: continued
        A<X Function(X Function(void))> {} //# 34: continued

class B<X, Y> implements A<Y Function(X)> {} //# 35: compile-time error

class B<X, Y> implements A<X Function(Y)> {} //# 36: compile-time error

main() {
  A();
}
