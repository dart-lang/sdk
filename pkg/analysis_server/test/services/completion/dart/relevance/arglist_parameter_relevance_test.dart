// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArglistParameterRelevanceTest);
  });
}

@reflectiveTest
class ArglistParameterRelevanceTest extends DartCompletionManagerTest {
  Future<void> test_closureParam() async {
    addTestSource(r'''
void f({void Function(int a, {int b, int c}) closure}) {}

void main() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, {b, c}) => ,',
      // todo (pq): replace w/ a test of relative relevance
      relevance: DART_RELEVANCE_HIGH,
      selectionOffset: 15,
    );
  }
}
