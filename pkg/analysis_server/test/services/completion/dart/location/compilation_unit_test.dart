// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitTest1);
    defineReflectiveTests(CompilationUnitTest2);
  });
}

@reflectiveTest
class CompilationUnitTest1 extends AbstractCompletionDriverTest
    with CompilationUnitTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class CompilationUnitTest2 extends AbstractCompletionDriverTest
    with CompilationUnitTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin CompilationUnitTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        if (isProtocolVersion2) {
          return suggestion.kind == CompletionSuggestionKind.KEYWORD;
        } else {
          final completion = suggestion.completion;
          return const {'import', 'export', 'part'}.any(completion.contains);
        }
      },
    );
  }

  Future<void> test_definingUnit_export() async {
    await computeSuggestions('''
exp^
''');

    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  export '';
    kind: keyword
    selection: 8
''');
    } else {
      // TODO(scheglov) This is wrong, should filter.
      _protocol1Directives();
    }
  }

  Future<void> test_definingUnit_import() async {
    await computeSuggestions('''
imp^
''');

    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  import '';
    kind: keyword
    selection: 8
''');
    } else {
      // TODO(scheglov) This is wrong, should filter.
      _protocol1Directives();
    }
  }

  Future<void> test_definingUnit_part() async {
    await computeSuggestions('''
par^
''');

    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  part '';
    kind: keyword
    selection: 6
''');
    } else {
      // TODO(scheglov) This is wrong, should filter.
      _protocol1Directives();
    }
  }

  void _protocol1Directives() {
    assertResponse(r'''
replacement
  left: 3
suggestions
  export '';
    kind: keyword
    selection: 8
  import '';
    kind: keyword
    selection: 8
  part '';
    kind: keyword
    selection: 6
''');
  }
}
