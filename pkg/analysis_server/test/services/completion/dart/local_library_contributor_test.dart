// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests written in a deprecated way. Please do not add any
/// tests to this file. Instead, add tests to the files in `declaration`,
/// `location`, or `relevance`.
library;

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalLibraryContributorTest);
  });
}

@reflectiveTest
class LocalLibraryContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return LocalLibraryContributor(request, builder);
  }

  Future<void> test_partFile_Constructor() async {
    // SimpleIdentifier  NamedType  ConstructorName
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    newFile('$testPackageLibPath/a.dart', '''
        library libA;
        import "b.dart";
        part "test.dart";
        class A { }
        var m;''');
    addTestSource('''
        part of libA;
        class B { B.bar(int x); }
        void f() {new ^}''');
    await resolveFile('$testPackageLibPath/a.dart');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestConstructor('A');
    // Suggested by LocalConstructorContributor
    assertNotSuggested('B.bar');
    // Suggested by ImportedReferenceContributor
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_partFile_Constructor2() async {
    // SimpleIdentifier  NamedType  ConstructorName
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    newFile('$testPackageLibPath/a.dart', '''
        part of libA;
        class B { }''');
    addTestSource('''
        library libA;
        import "b.dart";
        part "a.dart";
        class A { A({String boo: 'hoo'}) { } }
        void f() {new ^}
        var m;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestConstructor('B');
    // Suggested by ConstructorContributor
    assertNotSuggested('A');
    // Suggested by ImportedReferenceContributor
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_partFile_extension() async {
    newFile('$testPackageLibPath/a.dart', '''
part of libA;
extension E on int {}
''');
    addTestSource('''
library libA;
part "a.dart";
void f() {^}
''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('E');
  }

  Future<void> test_partFile_extension_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
part of libA;
extension on int {}
''');
    addTestSource('''
library libA;
part "a.dart";
void f() {^}
''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('');
  }

  Future<void>
      test_partFile_InstanceCreationExpression_assignment_filter() async {
    // ConstructorName  InstanceCreationExpression  VariableDeclarationList
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    newFile('$testPackageLibPath/a.dart', '''
        part of libA;
        class A {} class B extends A {} class C implements A {} class D {}
        ''');
    addTestSource('''
        library libA;
        import "b.dart";
        part "a.dart";
        class Local { }
        void f() {
          A a;
          // FAIL:
          a = new ^
        }
        var m;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // A is suggested with a higher relevance
    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
    // D has the default relevance
    assertSuggestConstructor('D', elemOffset: -1);

    // Suggested by ConstructorContributor
    assertNotSuggested('Local');

    // Suggested by ImportedReferenceContributor
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void>
      test_partFile_InstanceCreationExpression_variable_declaration_filter() async {
    // ConstructorName  InstanceCreationExpression  VariableDeclarationList
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    newFile('$testPackageLibPath/a.dart', '''
        part of libA;
        class A {} class B extends A {} class C implements A {} class D {}
        ''');
    addTestSource('''
        library libA;
        import "b.dart";
        part "a.dart";
        class Local { }
        void f() {
          A a = new ^
        }
        var m;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // A is suggested with a higher relevance
    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
    // D has the default relevance
    assertSuggestConstructor('D', elemOffset: -1);

    // Suggested by ConstructorContributor
    assertNotSuggested('Local');

    // Suggested by ImportedReferenceContributor
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_partFile_TypeName() async {
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    newFile('$testPackageLibPath/a.dart', '''
        library libA;
        import "b.dart";
        part "test.dart";
        class A { var a1; a2(){}}
        var m;
        typedef t1(int blue);
        typedef t2 = void Function(int blue);
        typedef t3 = List<int>;
        int af() {return 0;}''');
    addTestSource('''
        part of libA;
        class B { B.bar(int x); }
        void f() {^}''');
    await resolveFile('$testPackageLibPath/a.dart');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    if (suggestConstructorsWithoutNew) {
      assertSuggestConstructor('A');
    }
    assertSuggestFunction('af', 'int');
    assertSuggestTopLevelVar('m', null);
    assertSuggestTypeAlias('t1',
        aliasedType: 'dynamic Function(int)', returnType: 'dynamic');
    assertSuggestTypeAlias('t2',
        aliasedType: 'void Function(int)', returnType: 'void');
    assertSuggestTypeAlias('t3', aliasedType: 'List<int>');
    assertNotSuggested('a1');
    assertNotSuggested('a2');
    // Suggested by LocalConstructorContributor
    assertNotSuggested('B.bar');
    // Suggested by ImportedReferenceContributor
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
  }

  Future<void> test_partFile_TypeName2() async {
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    newFile('$testPackageLibPath/a.dart', '''
        part of libA;
        class B { var b1; b2(){}}
        int bf() => 0;
        typedef t1(int blue);
        var n;''');
    addTestSource('''
        library libA;
        import "b.dart";
        part "a.dart";
        class A { A({String boo: 'hoo'}) { } }
        void f() {^}
        var m;''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('B');
    if (suggestConstructorsWithoutNew) {
      assertSuggestConstructor('B');
    }
    assertSuggestFunction('bf', 'int');
    assertSuggestTopLevelVar('n', null);
    assertSuggestTypeAlias('t1',
        aliasedType: 'dynamic Function(int)', returnType: 'dynamic');
    assertNotSuggested('b1');
    assertNotSuggested('b2');
    // Suggested by ConstructorContributor
    assertNotSuggested('A');
    // Suggested by ImportedReferenceContributor
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }
}
