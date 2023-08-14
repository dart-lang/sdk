// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  (int, int) record1 = (1, 2);
  print(record1);

  (int x, int y) record1Named = (1, 2);
  print(record1Named);

  (
    int,
    int,
  ) record2 = (1, 2);
  print(record2);

  (
    int x,
    int y,
  ) record2Named = (1, 2);
  print(record2Named);

  (int, int, {int a, int b}) record3 = (1, 2, a: 3, b: 4);
  print(record3);

  (int x, int y, {int a, int b}) record3Named = (1, 2, a: 3, b: 4);
  print(record3Named);

  (
    int,
    int, {
    int a,
    int b,
  }) record4 = (1, 2, a: 3, b: 4);
  print(record4);

  (
    int x,
    int y, {
    int a,
    int b,
  }) record4Named = (1, 2, a: 3, b: 4);
  print(record4Named);

  print(foo((42, b: true), 42));

  Bar b = new Bar();
  print(b.foo(42));
  (int, int) Function((int, int) a) z1 = ((int, int) a) {
    return (42, 42);
  };

  final (int x, int y) finalRecordType = (42, 42);

  List<(int, int)> listOfRecords = [];

  var listOfRecords2 = <(int, int)>[];

  (int,) oneElementRecord = (1,);
  print(oneElementRecord);

  ({int ok}) oneElementNamedRecord = (ok: 1);
  print(oneElementNamedRecord);
}

(int, T) f1<T>(T t) {
  return (42, t);
}

(int, T) f2<T>(T t) => (42, t);

(int a, String b) get topLevelGetterType => throw '';

(int, int) foo((int, {bool b}) inputRecord, int x) {
  if (inputRecord.b) return (42, 42);
  return (
    1,
    1,
  );
}

class Bar {
  (int, int) foo(int x) => (42, 42);

  static (int x, int y) staticRecordType = (42, 42);

  (int a, String b) get instanceGetterType => throw '';

  static (int a, String b) get staticGetterType => throw '';

  (int, T) f1<T>(T t) {
    return (42, t);
  }

  (int, T) f2<T>(T t) => (42, t);
}
