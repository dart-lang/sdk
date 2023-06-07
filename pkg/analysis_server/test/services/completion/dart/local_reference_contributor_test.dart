// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests written in a deprecated way. Please do not add any
/// tests to this file. Instead, add tests to the files in `declaration`,
/// `location`, or `relevance`.
library;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalReferenceContributorTest);
  });
}

@reflectiveTest
class LocalReferenceContributorTest extends DartCompletionContributorTest {
  @override
  bool get isNullExpectedReturnTypeConsideredDynamic => false;

  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return LocalReferenceContributor(request, builder);
  }

  Future<void> test_doc_classMember() async {
    var docLines = r'''
  /// My documentation.
  /// Short description.
  ///
  /// Longer description.
''';
    void assertDoc(CompletionSuggestion suggestion) {
      expect(suggestion.docSummary, 'My documentation.\nShort description.');
      expect(suggestion.docComplete,
          'My documentation.\nShort description.\n\nLonger description.');
    }

    addTestSource('''
class C {
$docLines
  int myField;

$docLines
  myMethod() {}

$docLines
  int get myGetter => 0;

  void f() {^}
}''');
    await computeSuggestions();
    {
      var suggestion = assertSuggestField('myField', 'int');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestMethod('myMethod', 'C', null);
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestGetter('myGetter', 'int');
      assertDoc(suggestion);
    }
  }

  Future<void> test_doc_macro() async {
    dartdocInfo.addTemplateNamesAndValues([
      'template_name'
    ], [
      '''
Macro contents on
multiple lines.
'''
    ]);
    addTestSource('''
/// {@macro template_name}
///
/// With an additional line.
int x = 0;

void f() {^}
''');
    await computeSuggestions();
    var suggestion = assertSuggestTopLevelVar('x', 'int');
    expect(suggestion.docSummary, 'Macro contents on\nmultiple lines.');
    expect(suggestion.docComplete,
        'Macro contents on\nmultiple lines.\n\n\nWith an additional line.');
  }

  Future<void> test_doc_topLevel() async {
    var docLines = r'''
/// My documentation.
/// Short description.
///
/// Longer description.
''';
    void assertDoc(CompletionSuggestion suggestion) {
      expect(suggestion.docSummary, 'My documentation.\nShort description.');
      expect(suggestion.docComplete,
          'My documentation.\nShort description.\n\nLonger description.');
    }

    addTestSource('''
$docLines
class MyClass {}

$docLines
class MyMixinApplication = Object with MyClass;

$docLines
enum MyEnum {A, B, C}

$docLines
void myFunction() {}

$docLines
int myVariable;

void f() {^}
''');
    await computeSuggestions();
    {
      var suggestion = assertSuggestClass('MyClass');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestClass('MyMixinApplication');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestEnum('MyEnum');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestFunction('myFunction', 'void');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestTopLevelVar('myVariable', 'int');
      assertDoc(suggestion);
    }
  }
}
