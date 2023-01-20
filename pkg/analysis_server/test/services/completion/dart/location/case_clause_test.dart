// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseClauseTest1);
    defineReflectiveTests(CaseClauseTest2);
  });
}

@reflectiveTest
class CaseClauseTest1 extends AbstractCompletionDriverTest
    with CaseClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class CaseClauseTest2 extends AbstractCompletionDriverTest
    with CaseClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin CaseClauseTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    // TODO(brianwilkerson) Include more than keywords in these tests.
    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        return suggestion.kind == CompletionSuggestionKind.KEYWORD;
      },
    );
  }

  Future<void> test_afterCase_inIfElement() async {
    await computeSuggestions('''
var v = [ if (o case ^) ];
''');
    // TODO(brianwilkerson) We should be suggesting type names here.
    assertResponse('''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterCase_inIfStatement() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case ^) {}
}
''');
    // TODO(brianwilkerson) We should be suggesting type names here.
    assertResponse('''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
  }
}
