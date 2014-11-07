// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.manager;

import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import '../../abstract_context.dart';
import '../../reflective_tests.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionManagerTest);
}

@ReflectiveTestCase()
class CompletionManagerTest extends AbstractContextTest {
  var perf = new CompletionPerformance();

  test_dart() {
    Source source = addSource('/does/not/exist.dart', '');
    var manager = CompletionManager.create(context, source, 0, null, perf);
    expect(manager.runtimeType, DartCompletionManager);
  }

  test_html() {
    Source source = addSource('/does/not/exist.html', '');
    var manager = CompletionManager.create(context, source, 0, null, perf);
    expect(manager.runtimeType, NoOpCompletionManager);
  }

  test_null_context() {
    Source source = addSource('/does/not/exist.dart', '');
    var manager = CompletionManager.create(null, source, 0, null, perf);
    expect(manager.runtimeType, NoOpCompletionManager);
  }

  test_other() {
    Source source = addSource('/does/not/exist.foo', '');
    var manager = CompletionManager.create(context, source, 0, null, perf);
    expect(manager.runtimeType, NoOpCompletionManager);
  }
}
