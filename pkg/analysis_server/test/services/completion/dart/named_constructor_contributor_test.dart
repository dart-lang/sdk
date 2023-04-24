// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests written in a deprecated way. Please do not add any
/// tests to this file. Instead, add tests to the files in `declaration`,
/// `location`, or `relevance`.
library;

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/named_constructor_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedConstructorContributorTest);
  });
}

@reflectiveTest
class NamedConstructorContributorTest extends DartCompletionContributorTest {
  CompletionSuggestion assertConstructorReference({
    required String elementName,
    required String name,
    required String returnType,
  }) {
    return assertSuggestNamedConstructor(
      elementName: elementName,
      kind: CompletionSuggestionKind.IDENTIFIER,
      name: name,
      returnType: returnType,
    );
  }

  CompletionSuggestion assertSuggestNamedConstructor({
    required String elementName,
    CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
    required String name,
    required String returnType,
  }) {
    var cs = assertSuggest(name, csKind: kind);
    var element = cs.element!;
    expect(element.kind, equals(ElementKind.CONSTRUCTOR));
    expect(element.name, equals(elementName));
    var param = element.parameters!;
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, equals(returnType));
    assertHasParameterInfo(cs);
    return cs;
  }

  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return NamedConstructorContributor(request, builder);
  }

  Future<void>
      test_className_period_identifier_functionTypeContext_matchingReturnType() async {
    addTestSource('''
class A {
  A();
  A.named();
}

void f() {
  A Function() v = A.na^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertConstructorReference(
      elementName: 'A',
      name: 'new',
      returnType: 'A',
    );
    assertConstructorReference(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A',
    );
  }

  Future<void> test_className_period_identifier_interfaceTypeContext() async {
    addTestSource('''
class A {
  A();
  A.named();
}

void f() {
  int v = A.na^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertSuggestNamedConstructor(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A',
    );
  }

  Future<void>
      test_className_period_nothing_functionTypeContext_matchingReturnType() async {
    addTestSource('''
class A {
  A();
  A.named();
}

void f() {
  A Function() v = A.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertConstructorReference(
      elementName: 'A',
      name: 'new',
      returnType: 'A',
    );
    assertConstructorReference(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A',
    );
  }

  Future<void> test_className_period_nothing_interfaceTypeContext() async {
    addTestSource('''
class A {
  A();
  A.named();
}

void f() {
  int v = A.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A',
    );
  }

  Future<void>
      test_className_typeArguments_period_identifier_functionTypeContext_matchingReturnType() async {
    addTestSource('''
class A<T> {
  A.named();
  A.new();
}

void f() {
  A<int> Function() v = A<int>.na^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertConstructorReference(
      elementName: 'A',
      name: 'new',
      returnType: 'A<T>',
    );
    assertConstructorReference(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A<T>',
    );
  }

  Future<void>
      test_className_typeArguments_period_nothing_functionTypeContext_matchingReturnType() async {
    addTestSource('''
class A<T> {
  A.named();
  A.new();
}

void f() {
  A<int> Function() v = A<int>.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertConstructorReference(
      elementName: 'A',
      name: 'new',
      returnType: 'A<T>',
    );
    assertConstructorReference(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A<T>',
    );
  }

  Future<void>
      test_className_typeArguments_period_nothing_functionTypeContext_matchingReturnType2() async {
    addTestSource('''
class A {}

class B<T> extends A {
  B.named();
  B.new();
}

void f() {
  A Function() v = B<int>.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertConstructorReference(
      elementName: 'B',
      name: 'new',
      returnType: 'B<T>',
    );
    assertConstructorReference(
      elementName: 'B.named',
      name: 'named',
      returnType: 'B<T>',
    );
  }

  Future<void>
      test_className_typeArguments_period_nothing_functionTypeContext_notMatchingReturnType() async {
    addTestSource('''
class A<T> {
  A.named();
}

void f() {
  List<int> Function() v = A<int>.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A<T>',
    );
  }

  Future<void>
      test_className_typeArguments_period_nothing_interfaceContextType() async {
    addTestSource('''
class A<T> {
  A.named();
}

void f() {
  A<int> v = A<int>.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A<T>',
    );
  }

  Future<void> test_ConstructorName_importedClass() async {
    // SimpleIdentifier  PrefixedIdentifier  NamedType  ConstructorName
    // InstanceCreationExpression
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
        import 'b.dart';
        var m;
        void f() {new X.^}''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'X.c',
      name: 'c',
      returnType: 'X',
    );
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_importedClass_unresolved() async {
    // SimpleIdentifier  PrefixedIdentifier  NamedType  ConstructorName
    // InstanceCreationExpression
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
        import 'b.dart';
        var m;
        void f() {new X.^}''');
    // Assume that imported libraries are NOT resolved
    //await resolveLibraryUnit(libSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'X.c',
      name: 'c',
      returnType: 'X',
    );
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_importedFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  NamedType  ConstructorName
    // InstanceCreationExpression
    newFile('$testPackageLibPath/b.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
        import 'b.dart';
        var m;
        void f() {new X.^}''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'X.c',
      name: 'c',
      returnType: 'X',
    );
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_importedFactory2() async {
    // SimpleIdentifier  PrefixedIdentifier  NamedType  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        void f() {new String.fr^omCharCodes([]);}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 13);
    assertSuggestNamedConstructor(
      elementName: 'String.fromCharCodes',
      name: 'fromCharCodes',
      returnType: 'String',
    );
    assertNotSuggested('isEmpty');
    assertNotSuggested('isNotEmpty');
    assertNotSuggested('length');
    assertNotSuggested('Object');
    assertNotSuggested('String');
  }

  Future<void> test_ConstructorName_localClass() async {
    // SimpleIdentifier  PrefixedIdentifier  NamedType  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}
        void f() {new X.^}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'X.c',
      name: 'c',
      returnType: 'X',
    );
    assertSuggestNamedConstructor(
      elementName: 'X._d',
      name: '_d',
      returnType: 'X',
    );
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_localFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  NamedType  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        int T1;
        F1() { }
        class X {factory X.c(); factory X._d(); z() {}}
        void f() {new X.^}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor(
      elementName: 'X.c',
      name: 'c',
      returnType: 'X',
    );
    assertSuggestNamedConstructor(
      elementName: 'X._d',
      name: '_d',
      returnType: 'X',
    );
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void>
      test_importPrefix_className_typeArguments_period_nothing_functionTypeContext_matchingReturnType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A<T> {
  A.named();
  A.new();
}
''');
    addTestSource('''
import 'a.dart' as prefix;

void f() {
  A<int> Function() v = prefix.A<int>.^;
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertConstructorReference(
      elementName: 'A',
      name: 'new',
      returnType: 'A<T>',
    );
    assertConstructorReference(
      elementName: 'A.named',
      name: 'named',
      returnType: 'A<T>',
    );
  }
}
