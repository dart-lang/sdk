// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDirectiveTest1);
    defineReflectiveTests(ImportDirectiveTest2);
  });
}

@reflectiveTest
class ImportDirectiveTest1 extends AbstractCompletionDriverTest
    with ImportDirectiveTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ImportDirectiveTest2 extends AbstractCompletionDriverTest
    with ImportDirectiveTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ImportDirectiveTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterDeferred_beforeSemicolon() async {
    await computeSuggestions('''
import "foo" deferred ^;
''');
    assertResponse(r'''
suggestions
  as
    kind: keyword
''');
  }

  Future<void> test_afterDeferred_beforeSemicolon_partial() async {
    await computeSuggestions('''
import "foo" deferred a^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  as
    kind: keyword
''');
  }

  Future<void> test_afterLeftQuote_beforeRightQuote() async {
    await computeSuggestions('''
import "^"
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
''');
  }

  Future<void> test_afterPrefix_beforeSemicolon() async {
    await computeSuggestions('''
import "foo" as foo ^;
''');
    assertResponse(r'''
suggestions
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterPrefix_beforeSemicolon_deferred() async {
    await computeSuggestions('''
import "foo" deferred as foo ^;
''');
    assertResponse(r'''
suggestions
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeAs() async {
    await computeSuggestions('''
import "foo" ^ as foo;
''');
    assertResponse(r'''
suggestions
  deferred
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeAs_partial_d() async {
    await computeSuggestions('''
import "foo" d^ as foo;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  deferred
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeAs_partial_def() async {
    await computeSuggestions('''
import "package:foo/foo.dart" def^ as foo;
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  deferred
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeEnd() async {
    await computeSuggestions('''
import "foo" ^
''');
    assertResponse(r'''
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeEnd_partial() async {
    await computeSuggestions('''
import "foo" d^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  deferred as
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
  hide
    kind: keyword
  show
    kind: keyword
''');
    }
  }

  Future<void> test_afterUri_beforeHide_partial() async {
    await computeSuggestions('''
import "foo" d^ hide foo;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeImport_partial_d() async {
    await computeSuggestions('''
import "foo" d^ import
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  deferred as
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
  hide
    kind: keyword
  show
    kind: keyword
''');
    }
  }

  Future<void> test_afterUri_beforeImport_partial_sh() async {
    await computeSuggestions('''
import "foo" sh^ import "bar"; import "baz";
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  show
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
  hide
    kind: keyword
  show
    kind: keyword
''');
    }
  }

  Future<void> test_afterUri_beforeSemicolon() async {
    await computeSuggestions('''
import "foo" ^;
''');
    assertResponse(r'''
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeSemicolon_partial() async {
    await computeSuggestions('''
import "foo" d^;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  deferred as
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
  hide
    kind: keyword
  show
    kind: keyword
''');
    }
  }

  Future<void> test_afterUri_beforeShow_partial() async {
    await computeSuggestions('''
import "foo" d^ show foo;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  as
    kind: keyword
  deferred as
    kind: keyword
''');
  }
}
