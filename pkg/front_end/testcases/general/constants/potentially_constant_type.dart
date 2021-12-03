// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Pre-nnbd language version
// @dart=2.9

import 'potentially_constant_type_lib1.dart';
import 'potentially_constant_type_lib2.dart';

T id<T>(T t) => t;

class Class<T> {
  final field1;
  final field5;
  final field6;
  final field7;
  final field8;
  final field9;
  final field10;
  final field11;
  final field15;

  const Class(o)
      // Potentially constant context:
      : field1 = T,
        field5 = <T>[],
        field6 = <T>{},
        field7 = <T, T>{},
        field8 = o is T,
        field9 = o is Class<T>,
        field10 = o as T,
        field11 = o as Class<T>,
        field15 = <Class<T>>[];

  void method() {
    const o = null;

    // Required constant context:
    const local1 = T;
    const local5 = <T>[];
    const local6 = <T>{};
    const local7 = <T, T>{};
    const local8 = o is T;
    const local9 = o is Class<T>;
    const local10 = o as T;
    const local11 = o as Class<T>;
    const local15 = <Class<T>>[];
    const List<T> listOfNever = []; // ok

    print(local1);
    print(local5);
    print(local6);
    print(local7);
    print(local8);
    print(local9);
    print(local10);
    print(local11);
    print(local15);
    print(listOfNever);

    // Inferred constant context:
    print(const [T]);
    print(const [<T>[]]);
    print(const [<T>{}]);
    print(const [<T, T>{}]);
    print(const [o is T]);
    print(const [o is Class<T>]);
    print(const [o as T]);
    print(const [o as Class<T>]);
    print(const [<Class<T>>[]]);
  }
}

main() {}
