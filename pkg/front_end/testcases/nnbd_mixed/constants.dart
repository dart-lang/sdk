// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'constants_lib.dart' as lib;

const int Function(int) partialInstantiation = lib.id;
const instance = const lib.Class<int>(0);
const listLiteral = <int>[0];
const setLiteral = <int>{0};
const mapLiteral = <int, String>{0: 'foo'};
const listConcatenation = <int>[...listLiteral];
const setConcatenation = <int>{...setLiteral};
const mapConcatenation = <int, String>{...mapLiteral};

const partialInstantiationIdentical =
    identical(partialInstantiation, lib.partialInstantiation);
const instanceIdentical = identical(instance, lib.instance);
const listLiteralIdentical = identical(listLiteral, lib.listLiteral);
const setLiteralIdentical = identical(setLiteral, lib.setLiteral);
const mapLiteralIdentical = identical(mapLiteral, lib.mapLiteral);
const listConcatenationIdentical =
    identical(listConcatenation, lib.listConcatenation);
const setConcatenationIdentical =
    identical(setConcatenation, lib.setConcatenation);
const mapConcatenationIdentical =
    identical(mapConcatenation, lib.mapConcatenation);

main() {
  test(partialInstantiation, lib.partialInstantiation);
  test(instance, lib.instance);
  test(listLiteral, lib.listLiteral);
  test(setLiteral, lib.setLiteral);
  test(mapLiteral, lib.mapLiteral);
  test(listConcatenation, lib.listConcatenation);
  test(setConcatenation, lib.setConcatenation);
  test(mapConcatenation, lib.mapConcatenation);

  test(true, partialInstantiationIdentical);
  test(true, instanceIdentical);
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
