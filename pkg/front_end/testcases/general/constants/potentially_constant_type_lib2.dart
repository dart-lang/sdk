// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;

typedef F<X, Y> = Class<X>;
typedef G<X> = Class<int>;

class Class<T> {
  final field1;
  final field2;
  final field3;
  final field4;
  final field5;
  final field6;
  final field7;
  final field8;
  final field9;
  final field10;
  final field11;
  final field12;
  final field13;
  final field14;
  final field15;
  final field16;

  const Class(o)
      // Potentially constant context:
      : field1 = T,
        field2 = Class<T>,
        field3 = id<T>,
        field4 = (id)<T>,
        field5 = <T>[],
        field6 = <T>{},
        field7 = <T, T>{},
        field8 = o is T,
        field9 = o is Class<T>,
        field10 = o as T,
        field11 = o as Class<T>,
        field12 = Class<T>.new,
        field13 = F<T, T>.new,
        field14 = id<Class<T>>,
        field15 = <Class<T>>[],
        field16 = G<T>.new;

  void method() {
    const o = null;

    // Required constant context:
    const local1 = T;
    const local2 = Class<T>;
    const local3 = id<T>;
    const local4 = (id)<T>;
    const local5 = <T>[];
    const local6 = <T>{};
    const local7 = <T, T>{};
    const local8 = o is T;
    const local9 = o is Class<T>;
    const local10 = o as T;
    const local11 = o as Class<T>;
    const local12 = Class<T>.new;
    const local13 = F<T, T>.new;
    const local14 = id<Class<T>>;
    const local15 = <Class<T>>[];
    const local16 = G<T>.new;
    const List<T> listOfNever = []; // ok

    print(local1);
    print(local2);
    print(local3);
    print(local4);
    print(local5);
    print(local6);
    print(local7);
    print(local8);
    print(local9);
    print(local10);
    print(local11);
    print(local12);
    print(local13);
    print(local14);
    print(local15);
    print(local16);
    print(listOfNever);

    // Inferred constant context:
    print(const [T]);
    print(const [Class<T>]);
    print(const [id<T>]);
    print(const [(id)<T>]);
    print(const [<T>[]]);
    print(const [<T>{}]);
    print(const [<T, T>{}]);
    print(const [o is T]);
    print(const [o is Class<T>]);
    print(const [o as T]);
    print(const [o as Class<T>]);
    print(const [Class<T>.new]);
    print(const [F<T, T>.new]);
    print(const [id<Class<T>>]);
    print(const [<Class<T>>[]]);
    print(const [G<T>.new]);
  }
}

main() {}
