// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'impl/assert_in_declarations_phase_macro.dart';
import 'impl/assert_in_definitions_phase_macro.dart';
import 'impl/assert_in_types_phase_macro.dart';

// If any of the "assert" macros is broken then tests that use them might
// pass with a false positive. This test should start failing at the same time.

@AssertInTypesPhase(
// [error line 13, column 1, length 218]
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  targetLibrary: 'dart:core',
  targetName: 'int',
  resolveIdentifier: '<intentional mismatch and failure>',
)
@AssertInDefinitionsPhase(
// [error line 20, column 1, length 191]
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  targetName: 'A',
  constructorsOf: ['<intentional mismatch and failure>'],
)
@AssertInDeclarationsPhase(
// [error line 26, column 1, length 191]
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  targetName: 'A',
  constructorsOf: ['<intentional mismatch and failure'],
)
class A {}

// TODO(davidmorgan): add CFE error coverage.
