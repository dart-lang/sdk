// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.parser_test;

import 'dart:json' as json;
import 'package:unittest/unittest.dart';
import 'package:source_maps/source_maps.dart';
import 'common.dart';

main() {
  test('parse', () {
    var mapping = parseJson(EXPECTED_MAP);
    check(outputVar1, mapping, inputVar1, false);
    check(outputVar2, mapping, inputVar2, false);
    check(outputFunction, mapping, inputFunction, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('parse + json', () {
    var mapping = parse(json.stringify(EXPECTED_MAP));
    check(outputVar1, mapping, inputVar1, false);
    check(outputVar2, mapping, inputVar2, false);
    check(outputFunction, mapping, inputFunction, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('parse with file', () {
    var mapping = parseJson(EXPECTED_MAP);
    check(outputVar1, mapping, inputVar1, true);
    check(outputVar2, mapping, inputVar2, true);
    check(outputFunction, mapping, inputFunction, true);
    check(outputExpr, mapping, inputExpr, true);
  });
}
