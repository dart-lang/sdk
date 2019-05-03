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

mixin B<X> on A<F1<X>> {} //# 01: compile-time error

mixin B<X> on A<F2<X>> {} //# 02: compile-time error

mixin B<X> on A<F3<X>> {} //# 03: compile-time error

mixin B<X> on A<F4<X>> {} //# 04: compile-time error

mixin B<X, Y> on A<F5<X, Y>> {} //# 05: compile-time error

mixin B<X, Y> on A<F6<X, Y>> {} //# 06: compile-time error

mixin B<X> on Object, A<F1<X>> {} //# 07: compile-time error

mixin B<X> on Object, A<F2<X>> {} //# 08: compile-time error

mixin B<X> on Object, A<F3<X>> {} //# 09: compile-time error

mixin B<X> on Object, A<F4<X>> {} //# 10: compile-time error

mixin B<X, Y> on Object, A<F5<X, Y>> {} //# 11: compile-time error

mixin B<X, Y> on Object, A<F6<X, Y>> {} //# 12: compile-time error

mixin B<X> implements A<F1<X>> {} //# 13: compile-time error

mixin B<X> implements A<F2<X>> {} //# 14: compile-time error

mixin B<X> implements A<F3<X>> {} //# 15: compile-time error

mixin B<X> implements A<F4<X>> {} //# 16: compile-time error

mixin B<X, Y> implements A<F5<X, Y>> {} //# 17: compile-time error

mixin B<X, Y> implements A<F6<X, Y>> {} //# 18: compile-time error

mixin B<X> on A<void Function(X)> {} //# 19: compile-time error

mixin B<X> on A<X Function(X)> {} //# 20: compile-time error

// Two errors here: Invariance in `on` clause and
// generic function type used as actual type argument.
mixin B<X> on A<void Function<Y extends X>()> {} //# 21: compile-time error

mixin B<X> on A<X Function(X Function(void))> {} //# 22: compile-time error

mixin B<X, Y> on A<Y Function(X)> {} //# 23: compile-time error

mixin B<X, Y> on A<X Function(Y)> {} //# 24: compile-time error

mixin B<X> on Object, A<void Function(X)> {} //# 25: compile-time error

mixin B<X> on Object, A<X Function(X)> {} //# 26: compile-time error

// Two errors here: Invariance in `on` clause and
// generic function type used as actual type argument.
mixin B<X> //# 27: compile-time error
    on //# 27: continued
        Object, //# 27: continued
        A<void Function<Y extends X>()> {} //# 27: continued

mixin B<X> //# 28: compile-time error
    on //# 28: continued
        Object, //# 28: continued
        A<X Function(X Function(void))> {} //# 28: continued

mixin B<X, Y> on Object, A<Y Function(X)> {} //# 29: compile-time error

mixin B<X, Y> on Object, A<X Function(Y)> {} //# 30: compile-time error

mixin B<X> implements A<void Function(X)> {} //# 31: compile-time error

mixin B<X> implements A<X Function(X)> {} //# 32: compile-time error

// Two errors here: Invariance in superinterface and
// generic function type used as actual type argument.
mixin B<X> //# 33: compile-time error
    implements //# 33: continued
        A<void Function<Y extends X>()> {} //# 33: continued

mixin B<X> //# 34: compile-time error
    implements //# 34: continued
        A<X Function(X Function(void))> {} //# 34: continued

mixin B<X, Y> implements A<Y Function(X)> {} //# 35: compile-time error

mixin B<X, Y> implements A<X Function(Y)> {} //# 36: compile-time error

// A superinterface variance error can arise for an inferred type. For
// instance, mixin inference and instantiation to bound transforms `B` to
// `B<X, F1<X>>` in subtest 37.

class C<X> extends A<X> with B {} //# 37: compile-time error

mixin B<X, Y extends F1<X>> on A<X> {} //# 37: continued

class C<X> extends A<X> with B {} //# 38: compile-time error

mixin B<X, Y extends F2<X>> on A<X> {} //# 38: continued

class C<X> extends A<X> with B {} //# 39: compile-time error

mixin B<X, Y extends F3<X>> on A<X> {} //# 39: continued

class C<X> extends A<X> with B {} //# 40: compile-time error

mixin B<X, Y extends F4<X>> on A<X> {} //# 40: continued

class C<X> extends A<X> with B {} //# 41: compile-time error

mixin B<X, Y extends F5<X, Y>> on A<X> {} //# 41: continued

// Different kind of error here: I2b binds `Y` to `Null` which yields the
// correct super-bounded type `B<X, F6<X, Null>>`. But it is still an error
// for `C`, because a superinterface cannot be a super-bounded type.
class C<X> extends A<X> with B {} //# 42: compile-time error

mixin B<X, Y extends F6<X, Y>> on A<X> {} //# 42: continued

class C<X> extends A<X> with B {} //# 43: compile-time error

mixin B<X, Y extends void Function(X)> on A<X> {} //# 43: continued

class C<X> extends A<X> with B {} //# 44: compile-time error

mixin B<X, Y extends X Function(X)> on A<X> {} //# 44: continued

// Two errors here: Invariance in inferred superinterface of `C` and
// generic function type used as bound.
class C<X> extends A<X> with B {} //# 45: compile-time error

mixin B<X, Y extends void Function<Z extends X>()> on A<X> {} //# 45: continued

class C<X> extends A<X> with B {} //# 46: compile-time error

mixin B<X, Y extends X Function(X Function(void))> on A<X> {} //# 46: continued

class C<X> extends A<X> with B {} //# 47: compile-time error

mixin B<X, Y extends Y Function(X)> on A<X> {} //# 47: continued

// Similar to subtest 42.
class C<X> extends A<X> with B {} //# 48: compile-time error

mixin B<X, Y extends X Function(Y)> on A<X> {} //# 48: continued

main() {
  A();
}
