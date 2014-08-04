// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.suggestion;

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';
import 'dart:async';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionManagerTest);
  runReflectiveTests(DartCompletionManagerTest);
}

@ReflectiveTestCase()
class CompletionManagerTest extends AbstractCompletionTest {

  test_dart() {
    Source source = addSource('/does/not/exist.dart', '');
    var manager = CompletionManager.create(source, 0, null);
    expect(manager.runtimeType, DartCompletionManager);
  }

  test_html() {
    Source source = addSource('/does/not/exist.html', '');
    var manager = CompletionManager.create(source, 0, null);
    expect(manager.runtimeType, NoOpCompletionManager);
  }

  test_other() {
    Source source = addSource('/does/not/exist.foo', '');
    var manager = CompletionManager.create(source, 0, null);
    expect(manager.runtimeType, NoOpCompletionManager);
  }
}

@ReflectiveTestCase()
class DartCompletionManagerTest extends AbstractCompletionTest {

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

  test_topLevel() {
    Source source = addSource('/does/not/exist.dart', '');
    var manager = new DartCompletionManager(source, 0, searchEngine);
    bool anyResult;
    manager.results().forEach((_) {
      anyResult = true;
    });
    return new Future.delayed(Duration.ZERO, () {
      expect(anyResult, isTrue);
    });
  }
}
