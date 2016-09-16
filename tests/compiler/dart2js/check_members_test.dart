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
  'language/check_method_override_test.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_more_parameters_t01.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_more_parameters_t02.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_fewer_parameters_t01.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_fewer_parameters_t02.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_named_parameters_t01.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_named_parameters_t02.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_named_parameters_t03.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_named_parameters_t04.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_named_parameters_t05.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_named_parameters_t06.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_subtype_t01.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_subtype_t02.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_subtype_t03.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_subtype_t04.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_subtype_t05.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'override_subtype_t06.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t01.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t02.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t04.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t05.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t06.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t07.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t08.dart': null,
  'co19/src/Language/Classes/Instance_Methods/'
      'same_name_static_member_in_superclass_t09.dart': null,

  // Getters.
  'co19/src/Language/Classes/Getters/override_t01.dart': null,
  'co19/src/Language/Classes/Getters/override_t02.dart': null,
  'co19/src/Language/Classes/Getters/override_t03.dart': null,
  'co19/src/Language/Classes/Getters/override_t04.dart': null,
};

void main() {
  checkWarnings(TESTS);
}
