// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestionAvailableTest);
  });
}

@reflectiveTest
class GetSuggestionAvailableTest extends AvailableSuggestionsBase {
  test_dart() async {
    addTestFile('');
    var mathSet = await waitForSetWithUri('dart:math');
    var asyncSet = await waitForSetWithUri('dart:async');

    var results = await _getSuggestions(testFile, 0);
    expect(results.includedSuggestionKinds, isNotEmpty);

    var includedIdSet = results.includedSuggestionSets.map((set) => set.id);
    expect(includedIdSet, contains(mathSet.id));
    expect(includedIdSet, contains(asyncSet.id));
  }

  test_inHtml() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');

    var path = convertPath('/home/test/doc/a.html');
    newFile(path, content: '<html></html>');

    await waitResponse(
      CompletionGetSuggestionsParams(path, 0).toRequest('0'),
    );
    expect(serverErrors, isEmpty);
  }

  test_relevanceTags_argumentList_named() async {
    addTestFile(r'''
void foo({int a, String b}) {}

main() {
  foo(b: ); // ref
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf('); // ref'),
    );

    assertJsonText(results.includedSuggestionRelevanceTags, r'''
[
  {
    "tag": "dart:core::String",
    "relevanceBoost": 10
  }
]
''');
  }

  test_relevanceTags_argumentList_positional() async {
    addTestFile(r'''
void foo(double a) {}

main() {
  foo(); // ref
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf('); // ref'),
    );

    assertJsonText(results.includedSuggestionRelevanceTags, r'''
[
  {
    "tag": "dart:core::double",
    "relevanceBoost": 10
  }
]
''');
  }

  test_relevanceTags_assignment() async {
    addTestFile(r'''
main() {
  int v;
  v = // ref;
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf(' // ref'),
    );

    assertJsonText(results.includedSuggestionRelevanceTags, r'''
[
  {
    "tag": "dart:core::int",
    "relevanceBoost": 10
  }
]
''');
  }

  test_relevanceTags_listLiteral() async {
    addTestFile(r'''
main() {
  var v = [0, ]; // ref
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf(']; // ref'),
    );

    assertJsonText(results.includedSuggestionRelevanceTags, r'''
[
  {
    "tag": "dart:core::int",
    "relevanceBoost": 10
  }
]
''');
  }

  Future<CompletionResultsParams> _getSuggestions(
    String path,
    int offset,
  ) async {
    var response = CompletionGetSuggestionsResult.fromResponse(
      await waitResponse(
        CompletionGetSuggestionsParams(path, offset).toRequest('0'),
      ),
    );
    return await waitForGetSuggestions(response.id);
  }
}
