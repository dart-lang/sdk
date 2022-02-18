// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/source_range.dart';
import 'package:test/test.dart';

int offsetFromMarker(String code) {
  final offset = withoutRangeMarkers(code).indexOf('^');
  expect(offset, isNot(-1));
  return offset;
}

SourceRange rangeFromMarkers(String code) {
  code = _withoutPositionMarker(code);
  final start = code.indexOf('[[');
  final end = code.indexOf(']]');
  expect(start, isNot(-1));
  expect(end, isNot(-1));
  final endAdjusted = end - 2; // Account for the [[ before this marker
  return SourceRange(start, endAdjusted - start);
}

String withoutMarkers(String code) =>
    withoutRangeMarkers(_withoutPositionMarker(code));

String withoutRangeMarkers(String code) =>
    code.replaceAll('[[', '').replaceAll(']]', '');

String _withoutPositionMarker(String code) => code.replaceAll('^', '');
