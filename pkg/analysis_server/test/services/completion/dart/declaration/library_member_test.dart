// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryMemberWithPrefixTest1);
    defineReflectiveTests(LibraryMemberWithPrefixTest2);
    defineReflectiveTests(LibraryMemberWithoutPrefixTest1);
    defineReflectiveTests(LibraryMemberWithoutPrefixTest2);
  });
}

mixin LibraryMemberImportedWithoutPrefixTestCases
    on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_PrefixedIdentifier_partial() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  static int bar = 10;
}
_B() {}
f() {
  _B();
}
''');
    await computeSuggestions('''
import "a.dart";
class X {
  foo() {
    A0^.bar
  }
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
  }
}

mixin LibraryMemberImportedWithPrefixTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_afterCascade() async {
    allowedIdentifiers = {'min'};
    await computeSuggestions('''
import "dart:math" as math;
void f() {
  math..^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterCascade_partial() async {
    allowedIdentifiers = {'abs'};
    await computeSuggestions('''
import "dart:math" as math;
void f() {
  math..^a
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  Future<void> test_beforeRightBrace() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var T1;
class X0 {}
class Y0 {}
''');
    await computeSuggestions('''
import "b.dart" as b0;
var T1;
class A0 {}
void f() {
  b0.^
}
''');
    assertResponse(r'''
suggestions
  T1
    kind: topLevelVariable
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_beforeRightBrace_async() async {
    allowedIdentifiers = {'Future', 'loadLibrary'};
    await computeSuggestions('''
import "dart:async" as bar;
foo() {
  bar.^
}
''');
    // Part of the purpose of this test is to ensure that `loadLibrary` isn't
    // suggested when the import isn't deferred.
    assertResponse(r'''
suggestions
  Future
    kind: class
''');
  }

  Future<void> test_beforeRightBrace_deferred() async {
    allowedIdentifiers = {'Future', 'loadLibrary'};
    await computeSuggestions('''
import "dart:async" deferred as bar;
foo() {
  bar.^
}
''');
    assertResponse(r'''
suggestions
  Future
    kind: class
  loadLibrary
    kind: functionInvocation
''');
  }

  Future<void> test_beforeRightBrace_deferred_inPart() async {
    allowedIdentifiers = {'Future', 'loadLibrary'};
    newFile('$testPackageLibPath/a.dart', '''
library testA;
import "dart:async" deferred as bar;
part "test.dart";
''');
    await computeSuggestions('''
part of testA;
f0() {
  bar.^
}
''');
    assertResponse(r'''
suggestions
  Future
    kind: class
  loadLibrary
    kind: functionInvocation
''');
  }

  Future<void> test_beforeRightBrace_fromExport() async {
    newFile('$testPackageLibPath/a.dart', '''
library libA;
class A0 {}
''');
    newFile('$testPackageLibPath/b.dart', '''
library libB;
export "a.dart";
class B0 {}
@deprecated class B1 {}
''');
    await computeSuggestions('''
import "b.dart" as foo;
void f() {
  foo.^
}
class C0 {}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  B1
    kind: class
    deprecated: true
''');
  }

  Future<void> test_beforeRightBrace_fromExportWithShow() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
class B0 {}
''');
    newFile('$testPackageLibPath/b.dart', '''
export 'a.dart' show A0;
''');
    await computeSuggestions('''
import 'b.dart' as p;
void f() {
  p.^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_beforeRightBrace_fromImportWithShow() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
class B0 {}
''');
    await computeSuggestions('''
import 'a.dart' as p show A0;
void f() {
  p.^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_beforeRightBrace_inPart() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var T1;
class X0 {}
class Y0 {}
''');
    newFile('$testPackageLibPath/a.dart', '''
library testA;
import "b.dart" as b0;
part "test.dart";
var T2;
class A0 {}
''');
    await computeSuggestions('''
part of testA;
void f() {
  b0.^
}
''');
    assertResponse(r'''
suggestions
  T1
    kind: topLevelVariable
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_beforeRightBrace_typesOnly_withoutParameterName() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var T1;
class X0 {}
class Y0 {}
''');
    await computeSuggestions('''
import "b.dart" as b0;
var T1;
class A0 { }
foo(b0.^) {}
''');
    assertResponse(r'''
suggestions
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_beforeRightBrace_typesOnly_withParameterName() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var V0;
class X0 {}
class Y0 {}
typedef void T0();
typedef T1 = void Function();
typedef T2 = List<int>;
''');
    await computeSuggestions('''
import "b.dart" as b0;
var V1;
class A0 {}
foo(b0.^ f) {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeAlias
  T1
    kind: typeAlias
  T2
    kind: typeAlias
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_beforeStatement() async {
    allowedIdentifiers = {'Future', 'loadLibrary'};
    await computeSuggestions('''
import "dart:async" as bar;
foo() {
  bar.^
  print("f");
}
''');
    assertResponse(r'''
suggestions
  Future
    kind: class
''');
  }

  Future<void> test_betweenPeriodsInCascade() async {
    allowedIdentifiers = {'min'};
    await computeSuggestions('''
import "dart:math" as math;
void f() {
  math.^.
}
''');
    assertResponse(r'''
suggestions
  min
    kind: functionInvocation
''');
  }

  Future<void> test_betweenPeriodsInCascade_partial() async {
    allowedIdentifiers = {'min'};
    await computeSuggestions('''
import "dart:math" as math;
void f() {
  math.^.a
}
''');
    assertResponse(r'''
suggestions
  min
    kind: functionInvocation
''');
  }

  Future<void> test_extension() async {
    newFile('$testPackageLibPath/b.dart', '''
extension E0 on int {}
''');
    await computeSuggestions('''
import "b.dart" as b;
void f() {
  b.^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: extensionInvocation
''');
  }

  Future<void> test_inInstanceCreation_partial() async {
    allowedIdentifiers = {'Future', 'loadLibrary', 'Future.delayed'};
    await computeSuggestions('''
import "dart:async" as bar;
foo() {
  new bar.F^
  print("f");
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Future
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Future
    kind: constructorInvocation
  Future.delayed
    kind: constructorInvocation
  Future.microtask
    kind: constructorInvocation
  Future.value
    kind: constructorInvocation
''');
    }
  }
}

@reflectiveTest
class LibraryMemberWithoutPrefixTest1 extends AbstractCompletionDriverTest
    with LibraryMemberImportedWithoutPrefixTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LibraryMemberWithoutPrefixTest2 extends AbstractCompletionDriverTest
    with LibraryMemberImportedWithoutPrefixTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

@reflectiveTest
class LibraryMemberWithPrefixTest1 extends AbstractCompletionDriverTest
    with LibraryMemberImportedWithPrefixTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LibraryMemberWithPrefixTest2 extends AbstractCompletionDriverTest
    with LibraryMemberImportedWithPrefixTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}
