// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalLibraryContributorTest);
  });
}

@reflectiveTest
class LocalLibraryContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new LocalLibraryContributor();
  }

  test_partFile_Constructor() async {
    // SimpleIdentifier  TypeName  ConstructorName
    addSource(
        '/testB.dart',
        '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
        library libA;
        import "/testB.dart";
        part "$testFile";
        class A { }
        var m;''');
    addTestSource('''
        part of libA;
        class B { factory B.bar(int x) => null; }
        main() {new ^}''');
    await computeLibrariesContaining();
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

  test_partFile_Constructor2() async {
    // SimpleIdentifier  TypeName  ConstructorName
    addSource(
        '/testB.dart',
        '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
        part of libA;
        class B { }''');
    addTestSource('''
        library libA;
        import "/testB.dart";
        part "/testA.dart";
        class A { A({String boo: 'hoo'}) { } }
        main() {new ^}
        var m;''');
    await computeLibrariesContaining();
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

  test_partFile_InstanceCreationExpression_assignment_filter() async {
    // ConstructorName  InstanceCreationExpression  VariableDeclarationList
    addSource(
        '/testB.dart',
        '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
        part of libA;
        class A {} class B extends A {} class C implements A {} class D {}
        ''');
    addTestSource('''
        library libA;
        import "/testB.dart";
        part "/testA.dart";
        class Local { }
        main() {
          A a;
          // FAIL:
          a = new ^
        }
        var m;''');
    await computeLibrariesContaining();
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // A is suggested with a higher relevance
    assertSuggestConstructor('A',
        elemOffset: -1,
        relevance: DART_RELEVANCE_DEFAULT + DART_RELEVANCE_INCREMENT);
    assertSuggestConstructor('B',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertSuggestConstructor('C',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    // D is sorted out
    assertNotSuggested('D');

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

  test_partFile_InstanceCreationExpression_variable_declaration_filter() async {
    // ConstructorName  InstanceCreationExpression  VariableDeclarationList
    addSource(
        '/testB.dart',
        '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
        part of libA;
        class A {} class B extends A {} class C implements A {} class D {}
        ''');
    addTestSource('''
        library libA;
        import "/testB.dart";
        part "/testA.dart";
        class Local { }
        main() {
          A a = new ^
        }
        var m;''');
    await computeLibrariesContaining();
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // A is suggested with a higher relevance
    assertSuggestConstructor('A',
        elemOffset: -1,
        relevance: DART_RELEVANCE_DEFAULT + DART_RELEVANCE_INCREMENT);
    assertSuggestConstructor('B',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertSuggestConstructor('C',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    // D is sorted out
    assertNotSuggested('D');

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

  test_partFile_TypeName() async {
    addSource(
        '/testB.dart',
        '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
        library libA;
        import "/testB.dart";
        part "$testFile";
        class A { var a1; a2(){}}
        var m;
        typedef t1(int blue);
        int af() {return 0;}''');
    addTestSource('''
        part of libA;
        class B { factory B.bar(int x) => null; }
        main() {^}''');
    await computeLibrariesContaining();
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertSuggestFunction('af', 'int',
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
    assertSuggestTopLevelVar('m', null,
        relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    assertSuggestFunctionTypeAlias('t1', null,
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
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

  test_partFile_TypeName2() async {
    addSource(
        '/testB.dart',
        '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
        part of libA;
        class B { var b1; b2(){}}
        int bf() => 0;
        typedef t1(int blue);
        var n;''');
    addTestSource('''
        library libA;
        import "/testB.dart";
        part "/testA.dart";
        class A { A({String boo: 'hoo'}) { } }
        main() {^}
        var m;''');
    await computeLibrariesContaining();
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('B');
    assertSuggestFunction('bf', 'int',
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
    assertSuggestTopLevelVar('n', null,
        relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    assertSuggestFunctionTypeAlias('t1', null,
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
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
