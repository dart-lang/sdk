// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternTest1);
    defineReflectiveTests(CastPatternTest2);
  });
}

@reflectiveTest
class CastPatternTest1 extends AbstractCompletionDriverTest
    with CastPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class CastPatternTest2 extends AbstractCompletionDriverTest
    with CastPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin CastPatternTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        final completion = suggestion.completion;
        return suggestion.kind == CompletionSuggestionKind.KEYWORD ||
            ['A0', 'B0'].any(completion.startsWith);
      },
    );
  }

  Future<void> test_partialType() async {
    await computeSuggestions('''
void f(Object x) {
  switch (x) {
    case i as A^
  }
}
class A01 {}
class A02 {}
class B01 {}
''');
    if (isProtocolVersion2) {
      assertResponse('''
replacement
  left: 1
suggestions
  A01
    kind: class
  A02
    kind: class
''');
    } else {
      assertResponse('''
replacement
  left: 1
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
''');
    }
  }
}
