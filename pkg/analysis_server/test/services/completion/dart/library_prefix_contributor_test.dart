// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/library_prefix_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrefixContributorTest);
  });
}

@reflectiveTest
class LibraryPrefixContributorTest extends DartCompletionContributorTest {
  void assertSuggestLibraryPrefixes(List<String> expectedPrefixes) {
    for (var prefix in expectedPrefixes) {
      var cs =
          assertSuggest(prefix, csKind: CompletionSuggestionKind.IDENTIFIER);
      var element = cs.element;
      expect(element, isNotNull);
      expect(element.kind, equals(ElementKind.LIBRARY));
      expect(element.parameters, isNull);
      expect(element.returnType, isNull);
      assertHasNoParameterInfo(cs);
    }
    if (suggestions.length != expectedPrefixes.length) {
      failedCompletion('expected only ${expectedPrefixes.length} suggestions');
    }
  }

  @override
  DartCompletionContributor createContributor() {
    return LibraryPrefixContributor();
  }

  Future<void> test_Block() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    var f;
    localF(int arg1) { }
    {var x;}
    ^ var r;
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['g']);
  }

  Future<void> test_Block_final_final() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/testAB.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/testCD.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/testEEF.dart', '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource('/testH.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show EE;
import "testG.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    final ^
    final var f;
    localF(int arg1) { }
    {var x;}
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['g']);
  }

  Future<void> test_Block_final_var() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/testAB.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/testCD.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/testEEF.dart', '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource('/testH.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show EE;
import "testG.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    final ^
    var f;
    localF(int arg1) { }
    {var x;}
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['g']);
  }

  Future<void> test_ClassDeclaration_body() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
@deprecated class A {^}
class _B {}
A T;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['x']);
  }

  Future<void> test_ClassDeclaration_body_final() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^}
class _B {}
A T;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['x']);
  }

  Future<void> test_ClassDeclaration_body_final_field() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^ A(){}}
class _B {}
A T;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['x']);
  }

  Future<void> test_ClassDeclaration_body_final_field2() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as Soo;
class A {final S^ A();}
class _B {}
A Sew;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLibraryPrefixes(['Soo']);
  }

  Future<void> test_ClassDeclaration_body_final_final() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^ final foo;}
class _B {}
A T;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['x']);
  }

  Future<void> test_ClassDeclaration_body_final_var() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^ var foo;}
class _B {}
A T;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibraryPrefixes(['x']);
  }

  Future<void> test_InstanceCreationExpression() async {
    addSource('/home/test/lib/a.dart', '''
class A {foo(){var f; {var x;}}}
class B {B(this.x, [String boo]) { } int x;}
class C {C.bar({boo: 'hoo', int z: 0}) { } }''');
    addTestSource('''
import "a.dart" as t;
import "dart:math" as math;
main() {new ^ String x = "hello";}''');
    await computeSuggestions();
    assertSuggestLibraryPrefixes(['math', 't']);
  }

  Future<void> test_InstanceCreationExpression2() async {
    addTestSource('import "dart:convert" as json;f() {var x=new js^}');
    await computeSuggestions();
    assertSuggestLibraryPrefixes(['json']);
  }

  Future<void> test_InstanceCreationExpression_inPart() async {
    addSource('/home/test/lib/a.dart', '''
class A {foo(){var f; {var x;}}}
class B {B(this.x, [String boo]) { } int x;}
class C {C.bar({boo: 'hoo', int z: 0}) { } }''');
    addSource('/home/test/lib/b.dart', '''
library testB;
import "a.dart" as t;
import "dart:math" as math;
part "test.dart";
main() {new ^ String x = "hello";}''');
    addTestSource('''
part of testB;
main() {new ^ String x = "hello";}''');
    await analyzeTestPackageFiles();
    await computeSuggestions();
    assertSuggestLibraryPrefixes(['math', 't']);
  }

  Future<void> test_InstanceCreationExpression_inPart_detached() async {
    addSource('/home/test/lib/a.dart', '''
class A {foo(){var f; {var x;}}}
class B {B(this.x, [String boo]) { } int x;}
class C {C.bar({boo: 'hoo', int z: 0}) { } }''');
    addSource('/home/test/lib/b.dart', '''
library testB;
import "a.dart" as t;
import "dart:math" as math;
//part "$testFile"
main() {new ^ String x = "hello";}''');
    addTestSource('''
//part of testB;
main() {new ^ String x = "hello";}''');
    await computeSuggestions();
    assertNoSuggestions();
  }
}
