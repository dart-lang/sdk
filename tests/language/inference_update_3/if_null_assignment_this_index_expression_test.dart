// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is an index expression whose target is
// `this`.

// SharedOptions=--enable-experiment=inference-update-3

import '../static_type_helper.dart';

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

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

// - An if-null assignment `E` of the form `lvalue ??= e` with context type `K`
//   is analyzed as follows:
//
//   - Let `T1` be the read type of the lvalue.
//   - Let `T2` be the type of `e` inferred with context type `J`, where:
//     - If the lvalue is a local variable, `J` is the promoted type of the
//       variable.
//     - Otherwise, `J` is the write type of the lvalue.
//
// Check the context type of `e`.
class Test1 extends Indexable<String, Object?> {
  Test1() : super('');
  test() {
    // ignore: dead_null_aware_expression
    this[0] ??= contextType('')..expectStaticType<Exactly<Object?>>();
  }
}

class Test2 extends Indexable<String?, String?> {
  Test2() : super(null);
  test() {
    this[0] ??= contextType('')..expectStaticType<Exactly<String?>>();
  }
}

//   - Let `T` be `UP(NonNull(T1), T2)`.
//   - Let `S` be the greatest closure of `K`.
//   - If `T <: S`, then the type of `E` is `T`.
class Test3 extends Indexable<int?, Object?> {
  Test3() : super(null);
  test() {
    // K=Object, T1=int?, and T2=double, therefore T=num and S=Object, so T <:
    // S, and hence the type of E is num.
    var d = 2.0;
    context<Object>((this[0] ??= d)..expectStaticType<Exactly<num>>());
  }
}

class Test4 extends Indexable<Iterable<int>?, Object?> {
  Test4() : super(null);
  test() {
    // K=Iterable<_>, T1=Iterable<int>?, and T2=Iterable<double>, therefore
    // T=Iterable<num> and S=Iterable<Object?>, so T <: S, and hence the type of
    // E is Iterable<num>.
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((this[0] ??= iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }
}

//   - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of `E` is
//     `S`.
class Test5 extends Indexable<C1<int>?, Object?> {
  Test5() : super(null);
  test() {
    // K=B1<_>, T1=C1<int>?, and T2=C2<double>, therefore T=A and S=B1<Object?>,
    // so T is not <: S, but NonNull(T1) <: S and T2 <: S, hence the type of E
    // is B1<Object?>.
    var c2Double = C2<double>();
    contextB1((this[0] ??= c2Double)..expectStaticType<Exactly<B1<Object?>>>());
  }
}

class Test6 extends Indexable<C1<int>?, Object?> {
  Test6() : super(null);
  test() {
    // K=B1<Object>, T1=C1<int>?, and T2=C2<double>, therefore T=A and
    // S=B1<Object>, so T is not <: S, but NonNull(T1) <: S and T2 <: S, hence
    // the type of E is B1<Object>.
    var c2Double = C2<double>();
    contextB1<Object>(
        (this[0] ??= c2Double)..expectStaticType<Exactly<B1<Object>>>());
  }
}

class Test7 extends Indexable<Iterable<int>?, Object?> {
  Test7() : super(null);
  test() {
    // K=Iterable<num>, T1=Iterable<int>?, and T2=List<num>, therefore T=Object
    // and S=Iterable<num>, so T is not <: S, but NonNull(T1) <: S and T2 <: S,
    // hence the type of E is Iterable<num>.
    var listNum = <num>[];
    context<Iterable<num>>(
        (this[0] ??= listNum)..expectStaticType<Exactly<Iterable<num>>>());
  }
}

//   - Otherwise, the type of `E` is `T`.
class Test8 extends Indexable<int?, Object?> {
  Test8() : super(null);
  test() {
    var d = 2.0;
    var o = 0 as Object?;
    if (o is int?) {
      // K=int?, T1=int?, and T2=double, therefore T=num and S=int?, so T is not
      // <: S. NonNull(T1) <: S, but T2 is not <: S. Hence the type of E is num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (this[0] ??= d)..expectStaticType<Exactly<num>>();
    }
  }
}

class Test9 extends Indexable<double?, Object?> {
  Test9() : super(null);
  test() {
    var intQuestion = null as int?;
    var o = 0 as Object?;
    if (o is int?) {
      // K=int?, T1=double?, and T2=int?, therefore T=num? and S=int?, so T is
      // not <: S. T2 <: S, but NonNull(T1) is not <: S. Hence the type of E is
      // num?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (this[0] ??= intQuestion)..expectStaticType<Exactly<num?>>();
    }
  }
}

class Test10 extends Indexable<int?, Object?> {
  Test10() : super(null);
  test() {
    var d = 2.0;
    var o = '' as Object?;
    if (o is String?) {
      // K=String?, T1=int?, and T2=double, therefore T=num and S=String?, so
      // none of T, NonNull(T1), nor T2 are <: S. Hence the type of E is num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (this[0] ??= d)..expectStaticType<Exactly<num>>();
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
}
