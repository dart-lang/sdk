// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.levenshtein;

import 'package:analysis_services/src/correction/levenshtein.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  test('getLevenshteinDistance', () {
    expect(getLevenshteinDistance('test', 'test'), equals(0));
    expect(getLevenshteinDistance('String', 'Stirng'), equals(2));
    expect(getLevenshteinDistance('', ''), equals(0));
    expect(getLevenshteinDistance('kitten', 'sitting'), equals(3));
    expect(getLevenshteinDistance('Saturday', 'Sunday'), equals(3));
    expect(
        getLevenshteinDistance('Saturday', 'sunday', caseSensitive: false),
        equals(3));
    expect(
        getLevenshteinDistance('SaturDay', 'sunday', caseSensitive: false),
        equals(3));
    expect(getLevenshteinDistance('', 'fewfe'), equals(5));
    expect(getLevenshteinDistance('fewfe', ''), equals(5));
  });
}
