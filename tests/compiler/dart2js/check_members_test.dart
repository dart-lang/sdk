// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js produces the expected static type warnings for least upper
// bound language tests. This ensures that the analyzer and dart2js agrees
// on these tests.

import 'warnings_checker.dart';

/// Map from test files to a map of their expected status. If the status map is
/// `null` no warnings must be missing or unexpected, otherwise the status map
/// can contain a list of line numbers for keys 'missing' and 'unexpected' for
/// the warnings of each category.
const Map<String, dynamic> TESTS = const {
  // Instance methods.
    'co19/src/Language/07_Classes/1_Instance_Methods_A01_t01.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A01_t02.dart': null,

    'language/check_method_override_test.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A06_t01.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A06_t02.dart': null,

    'co19/src/Language/07_Classes/1_Instance_Methods_A02_t01.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A02_t02.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A02_t03.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A02_t04.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A02_t05.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A02_t06.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A03_t01.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A03_t02.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A03_t03.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A03_t04.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A03_t05.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A03_t06.dart': null,

    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t01.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t02.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t04.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t05.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t06.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t07.dart': null,
    'co19/src/Language/07_Classes/1_Instance_Methods_A05_t08.dart': null,
  // Getters.
    'co19/src/Language/07_Classes/2_Getters_A05_t01.dart': null,
    'co19/src/Language/07_Classes/2_Getters_A05_t02.dart': null,
    'co19/src/Language/07_Classes/2_Getters_A05_t03.dart': null,
    'co19/src/Language/07_Classes/2_Getters_A05_t04.dart': null,
};

void main() {
  checkWarnings(TESTS);
}
