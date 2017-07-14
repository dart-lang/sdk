// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/named_constructor_contributor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedConstructorContributorTest);
  });
}

@reflectiveTest
class NamedConstructorContributorTest extends DartCompletionContributorTest {
  CompletionSuggestion assertSuggestNamedConstructor(
      String name, String returnType,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    CompletionSuggestion cs =
        assertSuggest(name, csKind: kind, relevance: relevance);
    Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.CONSTRUCTOR));
    expect(element.name, equals(name));
    String param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, equals(returnType));
    assertHasParameterInfo(cs);
    return cs;
  }

  @override
  DartCompletionContributor createContributor() {
    return new NamedConstructorContributor();
  }

  test_ConstructorName_importedClass() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/testB.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
        import "/testB.dart";
        var m;
        main() {new X.^}''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor('c', 'X');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  test_ConstructorName_importedClass_unresolved() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/testB.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
        import "/testB.dart";
        var m;
        main() {new X.^}''');
    // Assume that imported libraries are NOT resolved
    //await resolveLibraryUnit(libSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor('c', 'X');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  test_ConstructorName_importedFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/testB.dart', '''
        lib B;
        int T1;
        F1() { }
        class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
        import "/testB.dart";
        var m;
        main() {new X.^}''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor('c', 'X');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  test_ConstructorName_importedFactory2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        main() {new String.fr^omCharCodes([]);}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 13);
    assertSuggestNamedConstructor('fromCharCodes', 'String');
    assertNotSuggested('isEmpty');
    assertNotSuggested('isNotEmpty');
    assertNotSuggested('length');
    assertNotSuggested('Object');
    assertNotSuggested('String');
  }

  test_ConstructorName_localClass() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        int T1;
        F1() { }
        class X {X.c(); X._d(); z() {}}
        main() {new X.^}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor('c', 'X');
    assertSuggestNamedConstructor('_d', 'X');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  test_ConstructorName_localFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        int T1;
        F1() { }
        class X {factory X.c(); factory X._d(); z() {}}
        main() {new X.^}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestNamedConstructor('c', 'X');
    assertSuggestNamedConstructor('_d', 'X');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }
}
