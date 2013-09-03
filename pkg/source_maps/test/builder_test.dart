// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source_maps_test;

import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:source_maps/source_maps.dart';
import 'common.dart';

main() {
  test('builder - with span', () {
    var map = (new SourceMapBuilder()
        ..addSpan(inputVar1, outputVar1)
        ..addSpan(inputFunction, outputFunction)
        ..addSpan(inputVar2, outputVar2)
        ..addSpan(inputExpr, outputExpr))
        .build(output.url);
    expect(map, equals(EXPECTED_MAP));
  });

  test('builder - with location', () {
    var str = (new SourceMapBuilder()
        ..addLocation(inputVar1.start, outputVar1.start, 'longVar1')
        ..addLocation(inputFunction.start, outputFunction.start, 'longName')
        ..addLocation(inputVar2.start, outputVar2.start, 'longVar2')
        ..addLocation(inputExpr.start, outputExpr.start, null))
        .toJson(output.url);
    expect(str, JSON.encode(EXPECTED_MAP));
  });
}
