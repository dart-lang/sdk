// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'summary_common.dart';
import 'test_strategies.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrelinkerTest);
  });
}

/// Tests for the pre-linker which exercise it using the old (two-phase) summary
/// generation strategy.
///
/// TODO(paulberry): eliminate these tests once we have transitioned over to
/// one-step summary generation.
@reflectiveTest
class PrelinkerTest extends SummaryBlackBoxTestStrategyPrelink
    with SummaryTestCases {}
