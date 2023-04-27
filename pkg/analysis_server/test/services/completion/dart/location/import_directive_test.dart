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

mixin HideClauseTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComma_beforeSemicolon() async {
    allowedIdentifiers = {'pi'};
    await computeSuggestions('''
import "dart:math" hide pi, ^;
''');
    // The purpose of this test is to ensure that `pi` is not suggested.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterHide_beforeSemicolon() async {
    newFile('$testPackageLibPath/ab.dart', '''
library libAB;
part "ab_part.dart";
class A0 {}
class B0 {}
''');
    newFile('$testPackageLibPath/ab_part.dart', '''
part of libAB;
var T1;
P0 F1() => new P0();
class P0 {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
class C0 {}
class D0 {}
''');
    await computeSuggestions('''
import "ab.dart" hide ^;
import "cd.dart";
class F0 {}
''');
    // Part of the purpose of this test is to ensure that we don't suggest names
    // from other imports ('C0' and 'D0') or locally defined names ('F0').
    // TODO(scheglov) It might be also interesting what happens when we have
    // just a getter, just a setter, a pair of a getter and a setter.
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  F1
    kind: function
  P0
    kind: class
  T1
    kind: topLevelVariable
''');
  }
}

@reflectiveTest
class ImportDirectiveTest1 extends AbstractCompletionDriverTest
    with HideClauseTestCases, ImportDirectiveTestCases, ShowClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ImportDirectiveTest2 extends AbstractCompletionDriverTest
    with HideClauseTestCases, ImportDirectiveTestCases, ShowClauseTestCases {
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

mixin ShowClauseTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComma_beforeSemicolon() async {
    await computeSuggestions('''
import "dart:math" show pi, ^;
''');
    // The purpose of this test is to ensure that `pi` is not suggested.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterShow_beforeSemicolon() async {
    newFile('$testPackageLibPath/ab.dart', '''
library libAB;
part "ab_part.dart";
class A0 {}
class B0 {}
class _A1 {}
void f(_A1 a) {}
''');
    newFile('$testPackageLibPath/ab_part.dart', '''
part of libAB;
var T1;
P1 F1() => new P1();
typedef P1 F2(int blat);
class C1 = Object with M;
class P1 {}
mixin M {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
class C0 {}
class D0 {}
''');
    await computeSuggestions('''
import "ab.dart" show ^;
import "cd.dart";
class G0 {}
''');
    // Part of the purpose of this test is to ensure that we don't suggest names
    // from other imports ('C0' and 'D0') or locally defined names ('G0').
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  C1
    kind: class
  F1
    kind: function
  F2
    kind: typeAlias
  P1
    kind: class
  T1
    kind: topLevelVariable
''');
  }

  Future<void> test_afterShow_beforeSemicolon_math() async {
    allowedIdentifiers = {'pi'};
    await computeSuggestions('''
import "dart:math" show ^;
''');
    assertResponse(r'''
suggestions
  pi
    kind: topLevelVariable
''');
  }

  Future<void> test_afterShow_beforeSemicolon_recursiveExport() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    newFile('$testPackageLibPath/b.dart', '''
export 'a.dart';
export 'b.dart';
class B0 {}
''');
    await computeSuggestions('''
import "b.dart" show ^;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
''');
  }

  Future<void> test_afterShow_beforeSemicolon_withRestrictedExport() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
class B0 {}
''');
    newFile('$testPackageLibPath/b.dart', '''
export 'a.dart' show A0;
''');
    await computeSuggestions('''
import 'b.dart' show ^;
''');
    // The purpose of this test is to ensure that `B0` is not suggested.
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }
}
