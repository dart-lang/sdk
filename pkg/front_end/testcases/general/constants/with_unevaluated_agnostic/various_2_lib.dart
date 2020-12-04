// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  final T field;

  const Class(this.field);
}

T id1<T>(T t) => t;
T id2<T>(T t) => t;

typedef F1<T> = T Function(T);
typedef F2 = T Function<T>(T);

const objectTypeLiteral = Object;
const c2 = identical;
const int Function(int) partialInstantiation =
    const bool.fromEnvironment("foo") ? id1 : id2;
const instance = const Class<int>(0);
const instance2 = const Class<dynamic>([42]);
const functionTypeLiteral = F1;
const genericFunctionTypeLiteral = F2;
const listLiteral = <int>[0];
const listLiteral2 = <dynamic>[
  <int>[42]
];
const setLiteral = <int>{0};
const setLiteral2 = <dynamic>{
  <int>[42]
};
const mapLiteral = <int, String>{0: 'foo'};
const mapLiteral2 = <dynamic, dynamic>{
  <int>[42]: 'foo',
  null: <int>[42]
};
const listConcatenation = <int>[...listLiteral];
const setConcatenation = <int>{...setLiteral};
const mapConcatenation = <int, String>{...mapLiteral};
