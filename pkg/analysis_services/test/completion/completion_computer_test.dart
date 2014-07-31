// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.suggestion;

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/src/completion/top_level_computer.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionComputerTest);
}

@ReflectiveTestCase()
class CompletionComputerTest extends AbstractSingleUnitTest {

  test_topLevel() {
    CompletionComputer.create(null).then((computers) {
      assertContainsType(computers, TopLevelComputer);
      expect(computers, hasLength(1));
    });
  }

  /// Assert that the list contains exactly one of the given type
  void assertContainsType(List computers, Type type) {
    int count = 0;
    computers.forEach((c) {
      if (c.runtimeType == type) {
        ++count;
      }
    });
    if (count != 1) {
      var msg = new StringBuffer();
      msg.writeln('Expected $type, but found:');
      computers.forEach((c) {
        msg.writeln('  ${c.runtimeType}');
      });
      fail(msg.toString());
    }
  }
}
