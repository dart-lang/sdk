// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'various_2_lib.dart' as lib;

typedef F1<T> = T Function(T);
typedef F2 = T Function<T>(T);

const objectTypeLiteral = Object;
const int Function(int) partialInstantiation = lib.id1;
const instance = const lib.Class<int>(0);
const instance2 = const lib.Class<dynamic>([42]);

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

const objectTypeLiteralIdentical =
    identical(objectTypeLiteral, lib.objectTypeLiteral);
const partialInstantiationIdentical =
    identical(partialInstantiation, lib.partialInstantiation);
const instanceIdentical = identical(instance, lib.instance);
const instance2Identical = identical(instance2, lib.instance2);
const functionTypeLiteralIdentical =
    identical(functionTypeLiteral, lib.functionTypeLiteral);
const genericFunctionTypeLiteralIdentical =
    identical(genericFunctionTypeLiteral, lib.genericFunctionTypeLiteral);
const listLiteralIdentical = identical(listLiteral, lib.listLiteral);
const listLiteral2Identical = identical(listLiteral2, lib.listLiteral2);
const setLiteralIdentical = identical(setLiteral, lib.setLiteral);
const setLiteral2Identical = identical(setLiteral2, lib.setLiteral2);
const mapLiteralIdentical = identical(mapLiteral, lib.mapLiteral);
const mapLiteral2Identical = identical(mapLiteral2, lib.mapLiteral2);
const listConcatenationIdentical =
    identical(listConcatenation, lib.listConcatenation);
const setConcatenationIdentical =
    identical(setConcatenation, lib.setConcatenation);
const mapConcatenationIdentical =
    identical(mapConcatenation, lib.mapConcatenation);

main() {
  test(objectTypeLiteral, lib.objectTypeLiteral);
  test(partialInstantiation, lib.partialInstantiation);
  test(instance, lib.instance);
  test(functionTypeLiteral, lib.functionTypeLiteral);
  test(genericFunctionTypeLiteral, lib.genericFunctionTypeLiteral);
  test(listLiteral, lib.listLiteral);
  test(setLiteral, lib.setLiteral);
  test(mapLiteral, lib.mapLiteral);
  test(listConcatenation, lib.listConcatenation);
  test(setConcatenation, lib.setConcatenation);
  test(mapConcatenation, lib.mapConcatenation);

  test(true, objectTypeLiteralIdentical);
  test(true, partialInstantiationIdentical);
  test(true, instanceIdentical);
  test(true, functionTypeLiteralIdentical);
  test(true, genericFunctionTypeLiteralIdentical);
  test(true, listLiteralIdentical);
  test(true, setLiteralIdentical);
  test(true, mapLiteralIdentical);
  test(true, listConcatenationIdentical);
  test(true, setConcatenationIdentical);
  test(true, mapConcatenationIdentical);
}

test(expected, actual) {
  print('test($expected, $actual)');
  if (!identical(expected, actual)) {
    throw 'Expected $expected, actual $actual';
  }
}
