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
    expect(results.includedElementKinds, isNotEmpty);

    var includedIdSet = results.includedSuggestionSets.map((set) => set.id);
    expect(includedIdSet, contains(mathSet.id));
    expect(includedIdSet, contains(asyncSet.id));
  }

  test_displayUri_file() async {
    var aPath = '/home/test/test/a.dart';
    newFile(aPath, content: 'class A {}');

    var aSet = await waitForSetWithUri(toUriStr(aPath));

    var testPath = newFile('/home/test/test/sub/test.dart').path;
    var results = await _getSuggestions(testPath, 0);

    expect(
      results.includedSuggestionSets.singleWhere((set) {
        return set.id == aSet.id;
      }).displayUri,
      '../a.dart',
    );
  }

  test_displayUri_package() async {
    var aPath = '/home/test/lib/a.dart';
    newFile(aPath, content: 'class A {}');

    var aSet = await waitForSetWithUri('package:test/a.dart');
    var testPath = newFile('/home/test/lib/test.dart').path;

    var results = await _getSuggestions(testPath, 0);
    expect(
      results.includedSuggestionSets.singleWhere((set) {
        return set.id == aSet.id;
      }).displayUri,
      isNull,
    );
  }

  test_includedElementKinds_type() async {
    addTestFile(r'''
class X extends {} // ref
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf('{} // ref'),
    );

    expect(
      results.includedElementKinds,
      unorderedEquals([
        ElementKind.CLASS,
        ElementKind.CLASS_TYPE_ALIAS,
        ElementKind.ENUM,
        ElementKind.FUNCTION_TYPE_ALIAS,
        ElementKind.MIXIN,
      ]),
    );
  }

  test_includedElementKinds_value() async {
    addTestFile(r'''
main() {
  print(); // ref
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf('); // ref'),
    );

    expect(
      results.includedElementKinds,
      unorderedEquals([
        ElementKind.CLASS,
        ElementKind.CLASS_TYPE_ALIAS,
        ElementKind.ENUM,
        ElementKind.ENUM_CONSTANT,
        ElementKind.FUNCTION,
        ElementKind.FUNCTION_TYPE_ALIAS,
        ElementKind.MIXIN,
        ElementKind.TOP_LEVEL_VARIABLE,
      ]),
    );
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

  test_relevanceTags_enum() async {
    newFile('/home/test/lib/a.dart', content: r'''
enum MyEnum {
  aaa, bbb
}
''');
    addTestFile(r'''
import 'a.dart';

void f(MyEnum e) {
  e = // ref;
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf(' // ref'),
    );

    assertJsonText(results.includedSuggestionRelevanceTags, r'''
[
  {
    "tag": "package:test/a.dart::MyEnum",
    "relevanceBoost": 1100
  }
]
''');
  }

  test_relevanceTags_location_argumentList_named() async {
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

  test_relevanceTags_location_argumentList_positional() async {
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

  test_relevanceTags_location_assignment() async {
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

  test_relevanceTags_location_listLiteral() async {
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
