// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditDartfixDomainHandlerTest);
  });
}

@reflectiveTest
class EditDartfixDomainHandlerTest extends AbstractAnalysisTest {
  int requestId = 30;

  String get nextRequestId => (++requestId).toString();

  void expectEdits(List<SourceFileEdit> fileEdits, String expectedSource) {
    expect(fileEdits, hasLength(1));
    expect(fileEdits[0].file, testFile);
    expectFileEdits(testCode, fileEdits[0], expectedSource);
  }

  void expectFileEdits(
      String originalSource, SourceFileEdit fileEdit, String expectedSource) {
    var source = SourceEdit.applySequence(originalSource, fileEdit.edits);
    expect(source, expectedSource);
  }

  void expectSuggestion(DartFixSuggestion suggestion, String partialText,
      [int offset, int length]) {
    expect(suggestion.description, contains(partialText));
    if (offset == null) {
      expect(suggestion.location, isNull);
    } else {
      expect(suggestion.location.offset, offset);
      expect(suggestion.location.length, length);
    }
  }

  Future<EditDartfixResult> performFix(
      {List<String> includedFixes, bool pedantic}) async {
    var response =
        await performFixRaw(includedFixes: includedFixes, pedantic: pedantic);
    expect(response.error, isNull);
    return EditDartfixResult.fromResponse(response);
  }

  Future<Response> performFixRaw(
      {List<String> includedFixes,
      List<String> excludedFixes,
      bool pedantic}) async {
    final id = nextRequestId;
    final params = EditDartfixParams([projectPath]);
    params.includedFixes = includedFixes;
    params.excludedFixes = excludedFixes;
    params.includePedanticFixes = pedantic;
    final request = Request(id, 'edit.dartfix', params.toJson());

    var fix = EditDartFix(server, request);
    final response = await fix.compute();
    expect(response.id, id);
    return response;
  }

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    testFile = resourceProvider.convertPath('/project/lib/fileToBeFixed.dart');
  }

  Future<void> test_collection_if_elements() async {
    addTestFile('''
f(bool b) {
  return ['a', b ? 'c' : 'd', 'e'];
}
''');
    createProject();
    var result = await performFix(
        includedFixes: ['prefer_if_elements_to_conditional_expressions']);
    expect(result.suggestions.length, greaterThanOrEqualTo(1));
    expect(result.hasErrors, isFalse);
    expectEdits(result.edits, '''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }

  Future<void> test_excludedFix_invalid() async {
    addTestFile('''
const double myDouble = 42.0;
    ''');
    createProject();

    final result = await performFixRaw(excludedFixes: ['not_a_fix']);
    expect(result.error, isNotNull);
  }

  Future<void> test_excludedSource() async {
    // Add analysis options to exclude the lib directory then reanalyze
    newFile('/project/analysis_options.yaml', content: '''
analyzer:
  exclude:
    - lib/**
''');

    addTestFile('''
const double myDouble = 42.0;
    ''');
    createProject();

    // Assert no suggestions now that source has been excluded
    final result = await performFix(includedFixes: ['prefer_int_literals']);
    expect(result.suggestions, hasLength(0));
    expect(result.edits, hasLength(0));
  }

  Future<void> test_fixNamedConstructorTypeArgs() async {
    addTestFile('''
class A<T> {
  A.from(Object obj);
}
main() {
  print(A.from<String>([]));
}
    ''');
    createProject();
    var result = await performFix(
        includedFixes: ['wrong_number_of_type_arguments_constructor']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'type arguments', 60, 8);
    expectEdits(result.edits, '''
class A<T> {
  A.from(Object obj);
}
main() {
  print(A<String>.from([]));
}
    ''');
  }

  Future<void> test_includedFix_invalid() async {
    addTestFile('''
const double myDouble = 42.0;
    ''');
    createProject();

    final result = await performFixRaw(includedFixes: ['not_a_fix']);
    expect(result.error, isNotNull);
  }

  Future<void> test_partFile() async {
    newFile('/project/lib/lib.dart', content: '''
library lib2;
part 'fileToBeFixed.dart';
    ''');
    addTestFile('''
part of lib2;
const double myDouble = 42.0;
    ''');
    createProject();

    // Assert dartfix suggestions
    var result = await performFix(includedFixes: ['prefer_int_literals']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 38, 4);
    expectEdits(result.edits, '''
part of lib2;
const double myDouble = 42;
    ''');
  }

  Future<void> test_partFile_loose() async {
    addTestFile('''
part of lib2;
const double myDouble = 42.0;
    ''');
    createProject();

    // Assert dartfix suggestions
    var result = await performFix(includedFixes: ['prefer_int_literals']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 38, 4);
    expectEdits(result.edits, '''
part of lib2;
const double myDouble = 42;
    ''');
  }

  Future<void> test_pedantic() async {
    addTestFile('main(List args) { if (args.length == 0) { } }');
    createProject();
    var result = await performFix(pedantic: true);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], "Replace with 'isEmpty'", 22, 16);
    expect(result.hasErrors, isFalse);
    expectEdits(result.edits, 'main(List args) { if (args.isEmpty) { } }');
  }

  Future<void> test_preferEqualForDefaultValues() async {
    // Add analysis options to enable ui as code
    addTestFile('f({a: 1}) { }');
    createProject();
    var result =
        await performFix(includedFixes: ['prefer_equal_for_default_values']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], "Replace ':' with '='", 4, 1);
    expect(result.hasErrors, isFalse);
    expectEdits(result.edits, 'f({a = 1}) { }');
  }

  Future<void> test_preferForElementsToMapFromIterable() async {
    addTestFile('''
var m =
  Map<int, int>.fromIterable([1, 2, 3], key: (i) => i, value: (i) => i * 2);
    ''');
    createProject();
    var result = await performFix(
        includedFixes: ['prefer_for_elements_to_map_fromIterable']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(
        result.suggestions[0], "Convert to a 'for' element", 10, 73);
    expectEdits(result.edits, '''
var m =
  { for (var i in [1, 2, 3]) i : i * 2 };
    ''');
  }

  Future<void> test_preferIfElementsToConditionalExpressions() async {
    addTestFile('''
f(bool b) => ['a', b ? 'c' : 'd', 'e'];
    ''');
    createProject();
    var result = await performFix(
        includedFixes: ['prefer_if_elements_to_conditional_expressions']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(
        result.suggestions[0], "Convert to an 'if' element", 19, 13);
    expectEdits(result.edits, '''
f(bool b) => ['a', if (b) 'c' else 'd', 'e'];
    ''');
  }

  Future<void> test_preferIntLiterals() async {
    addTestFile('''
const double myDouble = 42.0;
    ''');
    createProject();
    var result = await performFix(includedFixes: ['prefer_int_literals']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 24, 4);
    expectEdits(result.edits, '''
const double myDouble = 42;
    ''');
  }

  Future<void> test_preferIsEmpty() async {
    addTestFile('main(List<String> args) { if (args.length == 0) { } }');
    createProject();
    var result = await performFix(includedFixes: ['prefer_is_empty']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], "Replace with 'isEmpty'", 30, 16);
    expect(result.hasErrors, isFalse);
    expectEdits(
        result.edits, 'main(List<String> args) { if (args.isEmpty) { } }');
  }

  Future<void> test_preferMixin() async {
    addTestFile('''
class A {}
class B extends A {}
class C with B {}
    ''');
    createProject();
    var result = await performFix(includedFixes: ['convert_class_to_mixin']);
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'mixin', 17, 1);
    expectEdits(result.edits, '''
class A {}
mixin B implements A {}
class C with B {}
    ''');
  }

  Future<void> test_preferSingleQuotes() async {
    addTestFile('''
var l = [
  "abc",
  'def',
  "'g'",
  """hij""",
  \'''klm\''',
];
''');
    createProject();
    var result = await performFix(includedFixes: ['prefer_single_quotes']);
    expect(result.suggestions, hasLength(2));
    expectSuggestion(
        result.suggestions[0], 'Convert to single quoted string', 12, 5);
    expectSuggestion(
        result.suggestions[1], 'Convert to single quoted string', 39, 9);
    expect(result.hasErrors, isFalse);
    expectEdits(result.edits, '''
var l = [
  'abc',
  'def',
  "'g'",
  \'''hij\''',
  \'''klm\''',
];
''');
  }

  Future<void> test_preferSpreadCollections() async {
    addTestFile('''
var l1 = ['b'];
var l2 = ['a']..addAll(l1);
''');
    createProject();
    var result = await performFix(includedFixes: ['prefer_spread_collections']);
    expect(result.suggestions.length, greaterThanOrEqualTo(1));
    expect(result.hasErrors, isFalse);
    expectEdits(result.edits, '''
var l1 = ['b'];
var l2 = ['a', ...l1];
''');
  }
}
