// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*@testedFeatures=checks*/

class C<T> {
  C(this.field1)
      : field2 = (() => field1),
        field3 = ((T t) {}),
        field4 = ((T t) => t),
        field5 = (() => () => field1),
        field6 = ((T Function() f) {}),
        field7 = ((T Function() f) => field1),
        field8 = ((void Function(T) f) {}),
        field9 = ((void Function(T) f) => field1),
        field10 = ((T Function(T) f) {}),
        field11 = ((T Function(T) f) => field1),
        field12 = <S extends T>() => null,
        field13 = <S extends T>(S s) {},
        field14 = <S extends T>(S s) => s,
        field15 = ((S Function<S extends T>() f) {});

  T field1;
  T Function() field2;
  void Function(/*contravariant*/ T) field3;
  T Function(/*contravariant*/ T) field4;
  T Function() Function() field5;
  void Function(/*contravariant*/ T Function()) field6;
  T Function(/*contravariant*/ T Function()) field7;
  void Function(void Function(T)) field8;
  T Function(void Function(T)) field9;
  void Function(/*contravariant*/ T Function(T)) field10;
  T Function(/*contravariant*/ T Function(T)) field11;

  S Function<S extends /*invariant*/ T>() field12;
  void Function<S extends /*invariant*/ T>(S) field13;
  S Function<S extends /*invariant*/ T>(S) field14;
  void Function(S Function<S extends /*invariant*/ T>()) field15;

  T get getter1 => field1;
  T Function() get getter2 => field2;
  void Function(/*contravariant*/ T) get getter3 => field3;
  T Function(/*contravariant*/ T) get getter4 => field4;
  T Function() Function() get getter5 => field5;
  void Function(/*contravariant*/ T Function()) get getter6 => field6;
  T Function(/*contravariant*/ T Function()) get getter7 => field7;
  void Function(void Function(T)) get getter8 => field8;
  T Function(void Function(T)) get getter9 => field9;
  void Function(/*contravariant*/ T Function(T)) get getter10 => field10;
  T Function(/*contravariant*/ T Function(T)) get getter11 => field11;

  S Function<S extends /*invariant*/ T>() get getter12 => field12;
  void Function<S extends /*invariant*/ T>(S) get getter13 => field13;
  S Function<S extends /*invariant*/ T>(S) get getter14 => field14;
  void Function(S Function<S extends /*invariant*/ T>()) get getter15 =>
      field15;

  void set setter1(/*covariant*/ T value) {
    field1 = value;
  }

  void set setter2(/*covariant*/ T Function() value) {
    field2 = value;
  }

  void set setter3(void Function(T) value) {
    field3 = value;
  }

  void set setter4(/*covariant*/ T Function(T) value) {
    field4 = value;
  }

  void set setter5(/*covariant*/ T Function() Function() value) {
    field5 = value;
  }

  void set setter6(void Function(T Function()) value) {
    field6 = value;
  }

  void set setter7(/*covariant*/ T Function(T Function()) value) {
    field7 = value;
  }

  void set setter8(void Function(void Function(/*covariant*/ T)) value) {
    field8 = value;
  }

  void set setter9(
      /*covariant*/ T Function(void Function(/*covariant*/ T)) value) {
    field9 = value;
  }

  void set setter10(void Function(T Function(/*covariant*/ T)) value) {
    field10 = value;
  }

  void set setter11(
      /*covariant*/ T Function(T Function(/*covariant*/ T)) value) {
    field11 = value;
  }

  void set setter12(S Function<S extends /*invariant*/ T>() value) {
    field12 = value;
  }

  void set setter13(void Function<S extends /*invariant*/ T>(S) value) {
    field13 = value;
  }

  void set setter14(S Function<S extends /*invariant*/ T>(S) value) {
    field14 = value;
  }

  void set setter15(
      void Function(S Function<S extends /*invariant*/ T>()) value) {
    field15 = value;
  }

  void method1(/*covariant*/ T value) {
    field1 = value;
  }

  void method2(/*covariant*/ T Function() value) {
    field2 = value;
  }

  void method3(void Function(T) value) {
    field3 = value;
  }

  void method4(/*covariant*/ T Function(T) value) {
    field4 = value;
  }

  void method5(/*covariant*/ T Function() Function() value) {
    field5 = value;
  }

  void method6(void Function(T Function()) value) {
    field6 = value;
  }

  void method7(/*covariant*/ T Function(T Function()) value) {
    field7 = value;
  }

  void method8(void Function(void Function(/*covariant*/ T)) value) {
    field8 = value;
  }

  void method9(/*covariant*/ T Function(void Function(/*covariant*/ T)) value) {
    field9 = value;
  }

  void method10(void Function(T Function(/*covariant*/ T)) value) {
    field10 = value;
  }

  void method11(/*covariant*/ T Function(T Function(/*covariant*/ T)) value) {
    field11 = value;
  }

  void method12(S Function<S extends /*invariant*/ T>() value) {
    field12 = value;
  }

  void method13(void Function<S extends /*invariant*/ T>(S) value) {
    field13 = value;
  }

  void method14(S Function<S extends /*invariant*/ T>(S) value) {
    field14 = value;
  }

  void method15(void Function(S Function<S extends /*invariant*/ T>()) value) {
    field15 = value;
  }
}

main() {
  C<num> c = new C<int>(0);
  c.field1;
  c.field2;
  try {
    c. /*@ checkReturn=(num*) ->* void */ field3;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=(num*) ->* num* */ field4;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.field5;
  try {
    c. /*@ checkReturn=(() ->* num*) ->* void */ field6;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=(() ->* num*) ->* num* */ field7;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.field8;
  c.field9;
  try {
    c. /*@ checkReturn=((num*) ->* num*) ->* void */ field10;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=((num*) ->* num*) ->* num* */ field11;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=<S extends num* = dynamic>() ->* S* */ field12;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=<S extends num* = dynamic>(S*) ->* void */ field13;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=<S extends num* = dynamic>(S*) ->* S* */ field14;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=(<S extends num* = dynamic>() ->* S*) ->* void */ field15;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }

  c.getter1;
  c.getter2;
  try {
    c. /*@ checkReturn=(num*) ->* void */ getter3;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=(num*) ->* num* */ getter4;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.getter5;
  try {
    c. /*@ checkReturn=(() ->* num*) ->* void */ getter6;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=(() ->* num*) ->* num* */ getter7;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.getter8;
  c.getter9;
  try {
    c. /*@ checkReturn=((num*) ->* num*) ->* void */ getter10;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=((num*) ->* num*) ->* num* */ getter11;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=<S extends num* = dynamic>() ->* S* */ getter12;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=<S extends num* = dynamic>(S*) ->* void */ getter13;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=<S extends num* = dynamic>(S*) ->* S* */ getter14;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c. /*@ checkReturn=(<S extends num* = dynamic>() ->* S*) ->* void */ getter15;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }

  try {
    c.setter1 = 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter2 = () => 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.setter3 = (num n) {};
  try {
    c.setter4 = (num n) => 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter5 = () => () => 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.setter6 = (num Function() f) {};
  try {
    c.setter7 = (num Function() f) => 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter8 = (void Function(double) f) {};
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter9 = (void Function(double) f) => 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter10 = (num Function(double) f) {};
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter11 = (num Function(double) f) => 0.5;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter12 = <S extends num>() => null;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter13 = <S extends num>(S s) {};
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter14 = <S extends num>(S s) => s;
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.setter15 = (S Function<S extends num>() f) {};
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }

  try {
    c.method1(0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method2(() => 0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.method3((num n) {});
  try {
    c.method4((num n) => 0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method5(() => () => 0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  c.method6((num Function() f) {});
  try {
    c.method7((num Function() f) => 0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method8((void Function(double) f) {});
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method9((void Function(double) f) => 0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method10((num Function(double) f) {});
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method11((num Function(double) f) => 0.5);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method12(<S extends num>() => null);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method13(<S extends num>(S s) {});
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method14(<S extends num>(S s) => s);
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    c.method15((S Function<S extends num>() f) {});
    throw 'TypeError expected';
  } on TypeError catch (e) {
    print(e);
  }
}
