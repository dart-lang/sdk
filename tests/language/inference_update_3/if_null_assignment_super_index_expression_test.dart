// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is an index expression whose target is
// `super`.

import 'package:expect/static_type_helper.dart';

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

class CallableClass<T> {
  T call() => throw '';
}

/// Ensures a context type of `B1<T>` for the operand, or `B1<_>` if no type
/// argument is supplied.
Object? contextB1<T>(B1<T> x) => x;

/// Class that can be the target of `[]` and `[]=` operations. [ReadType] and
/// [WriteType] are the read and write types of the `[]` and `[]=` operators,
/// respectively.
class Indexable<ReadType, WriteType> {
  final ReadType _value;

  Indexable(this._value);

  ReadType operator [](int index) => _value;

  operator []=(int index, WriteType value) {}
}

// - An if-null assignment `e` of the form `e1 ??= e2` with context type K is
//   analyzed as follows:
//
//   - Let T1 be the read type of `e1`. This is the static type that `e1` would
//     have as an expression with a context type schema of `_`.
//   - Let T2 be the type of `e2` inferred with context type J, where:
//     - If the lvalue is a local variable, J is the current (possibly promoted)
//       type of the variable.
//     - Otherwise, J is the write type `e1`. This is the type schema that the
//       setter associated with `e1` imposes on its single argument (or, for the
//       case of indexed assignment, the type schema that `operator[]=` imposes
//       on its second argument).
//
// Check the context type of `e`.
class Test1 extends Indexable<String, Object?> {
  Test1() : super('');
  test() {
    // ignore: dead_null_aware_expression
    super[0] ??= contextType('')..expectStaticType<Exactly<Object?>>();
  }
}

class Test2 extends Indexable<String?, String?> {
  Test2() : super(null);
  test() {
    super[0] ??= contextType('')..expectStaticType<Exactly<String?>>();
  }
}

//   - Let J' be the unpromoted write type of `e1`, defined as follows:
//     - If `e1` is a local variable, J' is the declared (unpromoted) type of
//       `e1`.
//     - Otherwise J' = J.
//   - Let T2' be the coerced type of `e2`, defined as follows:
//     - If T2 is a subtype of J', then T2' = T2 (no coercion is needed).
//     - Otherwise, if T2 can be coerced to a some other type which *is* a
//       subtype of J', then apply that coercion and let T2' be the type
//       resulting from the coercion.
//     - Otherwise, it is a compile-time error.
//   - Let T be UP(NonNull(T1), T2').
//   - Let S be the greatest closure of K.
//   - If T <: S, then the type of `e` is T.
//     (Testing this case here. Otherwise continued below.)
class Test3 extends Indexable<int?, Object?> {
  Test3() : super(null);
  test() {
    // This example has:
    // - K = Object
    // - T1 = int?
    // - T2' = double
    // Which implies:
    // - T = num
    // - S = Object
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = num.
    var d = 2.0;
    context<Object>((super[0] ??= d)..expectStaticType<Exactly<num>>());
  }
}

class Test4 extends Indexable<Iterable<int>?, Object?> {
  Test4() : super(null);
  test() {
    // This example has:
    // - K = Iterable<_>
    // - T1 = Iterable<int>?
    // - T2' = Iterable<double>
    // Which implies:
    // - T = Iterable<num>
    // - S = Iterable<Object?>
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Iterable<num>.
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((super[0] ??= iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }
}

class Test5 extends Indexable<Function?, Function?> {
  Test5() : super(null);
  test() {
    // This example has:
    // - K = Function
    // - T1 = Function?
    // - T2' = int Function()
    //    (coerced from T2=CallableClass<int>)
    // Which implies:
    // - T = Function
    // - S = Function
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Function.
    var callableClassInt = CallableClass<int>();
    context<Function>(
        (super[0] ??= callableClassInt)..expectStaticType<Exactly<Function>>());
  }
}

//   - Otherwise, if NonNull(T1) <: S and T2' <: S, then the type of `e` is S.
class Test6 extends Indexable<C1<int>?, Object?> {
  Test6() : super(null);
  test() {
    // This example has:
    // - K = B1<_>
    // - T1 = C1<int>?
    // - T2' = C2<double>
    // Which implies:
    // - T = A
    // - S = B1<Object?>
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2' <: S
    // Therefore the type of `e` is S = B1<Object?>.
    var c2Double = C2<double>();
    contextB1(
        (super[0] ??= c2Double)..expectStaticType<Exactly<B1<Object?>>>());
  }
}

class Test7 extends Indexable<C1<int>?, Object?> {
  Test7() : super(null);
  test() {
    // This example has:
    // - K = B1<Object>
    // - T1 = C1<int>?
    // - T2' = C2<double>
    // Which implies:
    // - T = A
    // - S = B1<Object>
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2' <: S
    // Therefore the type of `e` is S = B1<Object>.
    var c2Double = C2<double>();
    contextB1<Object>(
        (super[0] ??= c2Double)..expectStaticType<Exactly<B1<Object>>>());
  }
}

class Test8 extends Indexable<Iterable<int>?, Object?> {
  Test8() : super(null);
  test() {
    // This example has:
    // - K = Iterable<num>
    // - T1 = Iterable<int>?
    // - T2' = List<num>
    // Which implies:
    // - T = Object
    // - S = Iterable<num>
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2' <: S
    // Therefore the type of `e` is S = Iterable<num>.
    var listNum = <num>[];
    context<Iterable<num>>(
        (super[0] ??= listNum)..expectStaticType<Exactly<Iterable<num>>>());
  }
}

class Test9 extends Indexable<C1<int> Function()?, Function?> {
  Test9() : super(null);
  test() {
    // This example has:
    // - K = B1<int> Function()
    // - T1 = C1<int> Function()?
    // - T2' = C2<int> Function()
    //    (coerced from T2=CallableClass<C2<int>>)
    // Which implies:
    // - T = A Function()
    // - S = B1<int> Function()
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2' <: S
    // Therefore the type of `e` is S = B1<int> Function().
    var callableClassC2Int = CallableClass<C2<int>>();
    context<B1<int> Function()>((super[0] ??= callableClassC2Int)
      ..expectStaticType<Exactly<B1<int> Function()>>());
  }
}

//   - Otherwise, the type of `e` is T.
class Test10 extends Indexable<int?, Object?> {
  Test10() : super(null);
  test() {
    var d = 2.0;
    Object? o;
    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = int?
      // - T2' = double
      // Which implies:
      // - T = num
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <!: S
      // The fact that T2' <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (super[0] ??= d)..expectStaticType<Exactly<num>>();
    }
  }
}

class Test11 extends Indexable<double?, Object?> {
  Test11() : super(null);
  test() {
    var intQuestion = null as int?;
    Object? o;
    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = double?
      // - T2' = int?
      // Which implies:
      // - T = num?
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (super[0] ??= intQuestion)..expectStaticType<Exactly<num?>>();
    }
  }
}

class Test12 extends Indexable<int?, Object?> {
  Test12() : super(null);
  test() {
    var d = 2.0;
    Object? o;
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int?
      // - T2' = double
      // Which implies:
      // - T = num
      // - S = String?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <!: S
      // The fact that NonNull(T1) <!: S and T2' <!: S precludes using S as
      // static type.
      // Therefore the type of `e` is T = num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (super[0] ??= d)..expectStaticType<Exactly<num>>();
    }
  }
}

class Test13 extends Indexable<C1<int> Function()?, Function?> {
  Test13() : super(null);
  test() {
    var callableClassC2Int = CallableClass<C2<int>>();
    Object? o;
    o = (() => C1<int>()) as Object?;
    if (o is C1<int> Function()) {
      // This example has:
      // - K = C1<int> Function()
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = C1<int> Function()
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <!: S
      // The fact that T2' <!: S precludes using S as static type.
      // Therefore the type of `e` is T = A Function().
      // We avoid having a compile-time error because `o` can be demoted.
      o = (super[0] ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }
  }
}

class Test14 extends Indexable<C1<int> Function()?, Function?> {
  Test14() : super(null);
  test() {
    var callableClassC2Int = CallableClass<C2<int>>();
    Object? o;
    o = (() => C2<int>()) as Object?;
    if (o is C2<int> Function()) {
      // This example has:
      // - K = C2<int> Function()
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = C2<int> Function()
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = A Function().
      // We avoid having a compile-time error because `o` can be demoted.
      o = (super[0] ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }
  }
}

class Test15 extends Indexable<C1<int> Function()?, Function?> {
  Test15() : super(null);
  test() {
    var callableClassC2Int = CallableClass<C2<int>>();
    Object? o;
    o = 0 as Object?;
    if (o is int) {
      // This example has:
      // - K = int
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = int
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = A Function().
      // We avoid having a compile-time error because `o` can be demoted.
      o = (super[0] ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }
  }
}

main() {
  Test1().test();
  Test2().test();
  Test3().test();
  Test4().test();
  Test5().test();
  Test6().test();
  Test7().test();
  Test8().test();
  Test9().test();
  Test10().test();
  Test11().test();
  Test12().test();
  Test13().test();
  Test14().test();
  Test15().test();
}
