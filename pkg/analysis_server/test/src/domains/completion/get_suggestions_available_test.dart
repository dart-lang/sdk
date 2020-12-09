// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExistingImportsNotification);
    defineReflectiveTests(GetSuggestionAvailableTest);
  });
}

@reflectiveTest
class ExistingImportsNotification extends GetSuggestionsBase {
  Future<void> test_dart() async {
    addTestFile(r'''
import 'dart:math';
''');
    await _getSuggestions(testFile, 0);
    _assertHasImport('dart:math', 'dart:math', 'Random');
  }

  Future<void> test_invalidUri() async {
    addTestFile(r'''
import 'ht:';
''');
    await _getSuggestions(testFile, 0);
    // We should not get 'server.error' notification.
  }

  void _assertHasImport(String exportingUri, String declaringUri, String name) {
    var existingImports = fileToExistingImports[testFile];
    expect(existingImports, isNotNull);

    var existingImport = existingImports.imports.singleWhere((import) =>
        existingImports.elements.strings[import.uri] == exportingUri);

    var elements = existingImport.elements.map((index) {
      var uriIndex = existingImports.elements.uris[index];
      var nameIndex = existingImports.elements.names[index];
      var uri = existingImports.elements.strings[uriIndex];
      var name = existingImports.elements.strings[nameIndex];
      return '$uri::$name';
    }).toList();

    expect(elements, contains('$declaringUri::$name'));
  }
}

@reflectiveTest
class GetSuggestionAvailableTest extends GetSuggestionsBase {
  Future<void> test_dart() async {
    addTestFile('');
    var mathSet = await waitForSetWithUri('dart:math');
    var asyncSet = await waitForSetWithUri('dart:async');

    var results = await _getSuggestions(testFile, 0);
    expect(results.includedElementKinds, isNotEmpty);

    var includedIdSet = results.includedSuggestionSets.map((set) => set.id);
    expect(includedIdSet, contains(mathSet.id));
    expect(includedIdSet, contains(asyncSet.id));
  }

  Future<void> test_dart_instanceCreationExpression() async {
    addTestFile(r'''
main() {
  new ; // ref
}
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var asyncSet = await waitForSetWithUri('dart:async');

    var results = await _getSuggestions(testFile, findOffset('; // ref'));
    expect(
      results.includedElementKinds,
      unorderedEquals([ElementKind.CONSTRUCTOR]),
    );

    var includedIdSet = results.includedSuggestionSets.map((set) => set.id);
    expect(includedIdSet, contains(mathSet.id));
    expect(includedIdSet, contains(asyncSet.id));
  }

  Future<void> test_defaultArgumentListString() async {
    newFile('/home/test/lib/a.dart', content: r'''
void fff(int aaa, int bbb) {}

void ggg({int aaa, @required int bbb, @required int ccc}) {}
''');

    var aSet = await waitForSetWithUri('package:test/a.dart');

    var fff = aSet.items.singleWhere((e) => e.label == 'fff');
    expect(fff.defaultArgumentListString, 'aaa, bbb');
    expect(fff.defaultArgumentListTextRanges, [0, 3, 5, 3]);

    var ggg = aSet.items.singleWhere((e) => e.label == 'ggg');
    expect(ggg.defaultArgumentListString, 'bbb: bbb, ccc: ccc');
    expect(ggg.defaultArgumentListTextRanges, [5, 3, 15, 3]);
  }

  Future<void> test_displayUri_file() async {
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

  Future<void> test_displayUri_package() async {
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

  Future<void> test_includedElementKinds_type() async {
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

  Future<void> test_includedElementKinds_value() async {
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
        ElementKind.CONSTRUCTOR,
        ElementKind.ENUM,
        ElementKind.ENUM_CONSTANT,
        ElementKind.EXTENSION,
        ElementKind.FIELD,
        ElementKind.FUNCTION,
        ElementKind.FUNCTION_TYPE_ALIAS,
        ElementKind.GETTER,
        ElementKind.MIXIN,
        ElementKind.SETTER,
        ElementKind.TOP_LEVEL_VARIABLE,
      ]),
    );
  }

  Future<void> test_inHtml() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');

    var path = convertPath('/home/test/doc/a.html');
    newFile(path, content: '<html></html>');

    await waitResponse(
      CompletionGetSuggestionsParams(path, 0).toRequest('0'),
    );
  }

  Future<void> test_relevanceTags_constructorBeforeClass() async {
    addTestFile(r'''
void foo(List<int> a) {}

main() {
  foo(); // ref
}
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf('); // ref'),
    );

    var includedTags = results.includedSuggestionRelevanceTags;
    int findBoost(String tag) {
      for (var includedTag in includedTags) {
        if (includedTag.tag == tag) {
          return includedTag.relevanceBoost;
        }
      }
      fail('Missing relevance boost for tag $tag');
    }

    var classBoost = findBoost('ElementKind.CLASS');
    var constructorBoost = findBoost('ElementKind.CONSTRUCTOR');
    expect(constructorBoost, greaterThan(classBoost));
  }

  Future<void> test_relevanceTags_enum() async {
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
    "tag": "ElementKind.PREFIX",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.TOP_LEVEL_VARIABLE",
    "relevanceBoost": 1
  },
  {
    "tag": "ElementKind.FUNCTION",
    "relevanceBoost": 2
  },
  {
    "tag": "ElementKind.METHOD",
    "relevanceBoost": 4
  },
  {
    "tag": "ElementKind.ENUM",
    "relevanceBoost": 9
  },
  {
    "tag": "ElementKind.CLASS",
    "relevanceBoost": 28
  },
  {
    "tag": "ElementKind.LOCAL_VARIABLE",
    "relevanceBoost": 40
  },
  {
    "tag": "ElementKind.CONSTRUCTOR",
    "relevanceBoost": 53
  },
  {
    "tag": "ElementKind.FIELD",
    "relevanceBoost": 68
  },
  {
    "tag": "ElementKind.PARAMETER",
    "relevanceBoost": 100
  },
  {
    "tag": "package:test/a.dart::MyEnum",
    "relevanceBoost": 250
  }
]
''');
  }

  Future<void> test_relevanceTags_location_argumentList_named() async {
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
    "tag": "ElementKind.PREFIX",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.FUNCTION",
    "relevanceBoost": 1
  },
  {
    "tag": "ElementKind.METHOD",
    "relevanceBoost": 1
  },
  {
    "tag": "ElementKind.TOP_LEVEL_VARIABLE",
    "relevanceBoost": 3
  },
  {
    "tag": "ElementKind.ENUM",
    "relevanceBoost": 5
  },
  {
    "tag": "ElementKind.CLASS",
    "relevanceBoost": 20
  },
  {
    "tag": "ElementKind.LOCAL_VARIABLE",
    "relevanceBoost": 30
  },
  {
    "tag": "ElementKind.FIELD",
    "relevanceBoost": 41
  },
  {
    "tag": "ElementKind.PARAMETER",
    "relevanceBoost": 56
  },
  {
    "tag": "ElementKind.CONSTRUCTOR",
    "relevanceBoost": 100
  },
  {
    "tag": "dart:core::String",
    "relevanceBoost": 10
  }
]
''');
  }

  Future<void> test_relevanceTags_location_argumentList_positional() async {
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
    "tag": "ElementKind.MIXIN",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.TYPE_PARAMETER",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.PREFIX",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.ENUM",
    "relevanceBoost": 3
  },
  {
    "tag": "ElementKind.METHOD",
    "relevanceBoost": 4
  },
  {
    "tag": "ElementKind.FUNCTION",
    "relevanceBoost": 9
  },
  {
    "tag": "ElementKind.CLASS",
    "relevanceBoost": 13
  },
  {
    "tag": "ElementKind.TOP_LEVEL_VARIABLE",
    "relevanceBoost": 18
  },
  {
    "tag": "ElementKind.CONSTRUCTOR",
    "relevanceBoost": 27
  },
  {
    "tag": "ElementKind.FIELD",
    "relevanceBoost": 42
  },
  {
    "tag": "ElementKind.LOCAL_VARIABLE",
    "relevanceBoost": 60
  },
  {
    "tag": "ElementKind.PARAMETER",
    "relevanceBoost": 100
  },
  {
    "tag": "dart:core::double",
    "relevanceBoost": 10
  }
]
''');
  }

  Future<void> test_relevanceTags_location_assignment() async {
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
    "tag": "ElementKind.PREFIX",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.TOP_LEVEL_VARIABLE",
    "relevanceBoost": 1
  },
  {
    "tag": "ElementKind.FUNCTION",
    "relevanceBoost": 2
  },
  {
    "tag": "ElementKind.METHOD",
    "relevanceBoost": 4
  },
  {
    "tag": "ElementKind.ENUM",
    "relevanceBoost": 9
  },
  {
    "tag": "ElementKind.CLASS",
    "relevanceBoost": 28
  },
  {
    "tag": "ElementKind.LOCAL_VARIABLE",
    "relevanceBoost": 40
  },
  {
    "tag": "ElementKind.CONSTRUCTOR",
    "relevanceBoost": 53
  },
  {
    "tag": "ElementKind.FIELD",
    "relevanceBoost": 68
  },
  {
    "tag": "ElementKind.PARAMETER",
    "relevanceBoost": 100
  },
  {
    "tag": "dart:core::int",
    "relevanceBoost": 10
  }
]
''');
  }

  Future<void> test_relevanceTags_location_initializer() async {
    addTestFile(r'''
int v = // ref;
''');

    var results = await _getSuggestions(
      testFile,
      testCode.indexOf(' // ref'),
    );

    assertJsonText(results.includedSuggestionRelevanceTags, r'''
[
  {
    "tag": "ElementKind.MIXIN",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.TYPE_PARAMETER",
    "relevanceBoost": 0
  },
  {
    "tag": "ElementKind.PREFIX",
    "relevanceBoost": 1
  },
  {
    "tag": "ElementKind.ENUM",
    "relevanceBoost": 1
  },
  {
    "tag": "ElementKind.METHOD",
    "relevanceBoost": 4
  },
  {
    "tag": "ElementKind.TOP_LEVEL_VARIABLE",
    "relevanceBoost": 6
  },
  {
    "tag": "ElementKind.FUNCTION",
    "relevanceBoost": 16
  },
  {
    "tag": "ElementKind.PARAMETER",
    "relevanceBoost": 26
  },
  {
    "tag": "ElementKind.FIELD",
    "relevanceBoost": 35
  },
  {
    "tag": "ElementKind.CLASS",
    "relevanceBoost": 56
  },
  {
    "tag": "ElementKind.LOCAL_VARIABLE",
    "relevanceBoost": 68
  },
  {
    "tag": "ElementKind.CONSTRUCTOR",
    "relevanceBoost": 100
  },
  {
    "tag": "dart:core::int",
    "relevanceBoost": 10
  }
]
''');
  }

  Future<void> test_relevanceTags_location_listLiteral() async {
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
}

abstract class GetSuggestionsBase extends AvailableSuggestionsBase {
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
