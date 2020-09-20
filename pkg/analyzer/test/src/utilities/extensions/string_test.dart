// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListOfStringExtensionTest);
  });
}

@reflectiveTest
class ListOfStringExtensionTest {
  void test_commaSeparatedWithAnd_five() {
    expect(<String>['a', 'b', 'c', 'd', 'e'].commaSeparatedWithAnd,
        'a, b, c, d, and e');
  }

  void test_commaSeparatedWithAnd_one() {
    expect(<String>['a'].commaSeparatedWithAnd, 'a');
  }

  void test_commaSeparatedWithAnd_three() {
    expect(<String>['a', 'b', 'c'].commaSeparatedWithAnd, 'a, b, and c');
  }

  void test_commaSeparatedWithAnd_two() {
    expect(<String>['a', 'b'].commaSeparatedWithAnd, 'a and b');
  }

  void test_commaSeparatedWithAnd_zero() {
    expect(<String>[].commaSeparatedWithOr, isEmpty);
  }

  void test_commaSeparatedWithOr_five() {
    expect(<String>['a', 'b', 'c', 'd', 'e'].commaSeparatedWithOr,
        'a, b, c, d, or e');
  }

  void test_commaSeparatedWithOr_one() {
    expect(<String>['a'].commaSeparatedWithOr, 'a');
  }

  void test_commaSeparatedWithOr_three() {
    expect(<String>['a', 'b', 'c'].commaSeparatedWithOr, 'a, b, or c');
  }

  void test_commaSeparatedWithOr_two() {
    expect(<String>['a', 'b'].commaSeparatedWithOr, 'a or b');
  }

  void test_commaSeparatedWithOr_zero() {
    expect(<String>[].commaSeparatedWithOr, isEmpty);
  }
}
