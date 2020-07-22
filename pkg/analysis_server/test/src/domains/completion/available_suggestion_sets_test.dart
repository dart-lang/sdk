// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvailableSuggestionSetsTest);
  });
}

@reflectiveTest
class AvailableSuggestionSetsTest extends AvailableSuggestionsBase {
  Future<void> test_notifications_whenFileChanges() async {
    var path = convertPath('/home/test/lib/a.dart');
    var uriStr = 'package:test/a.dart';

    // No file initially, so no set.
    expect(uriToSetMap.keys, isNot(contains(uriStr)));

    // Create the file, should get the set.
    {
      newFile(path, content: r'''
class A {}
''');
      var set = await waitForSetWithUri(uriStr);
      expect(set.items.map((d) => d.label), contains('A'));
    }

    // Update the file, should get the updated set.
    {
      newFile(path, content: r'''
class B {}
''');
      removeSet(uriStr);
      var set = await waitForSetWithUri(uriStr);
      expect(set.items.map((d) => d.label), contains('B'));
    }

    // Delete the file, the set should be removed.
    deleteFile(path);
    waitForSetWithUriRemoved(uriStr);
  }

  Future<void> test_suggestion_class() async {
    var path = convertPath('/home/test/lib/a.dart');
    var uriStr = 'package:test/a.dart';

    newFile(path, content: r'''
class A {
  A.a();
}
''');

    var set = await waitForSetWithUri(uriStr);
    assertJsonText(_getSuggestion(set, 'A'), '''
{
  "label": "A",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "CLASS",
    "name": "A",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 6,
      "length": 0,
      "startLine": 1,
      "startColumn": 7
    },
    "flags": 0
  },
  "relevanceTags": [
    "ElementKind.CLASS",
    "package:test/a.dart::A",
    "A"
  ]
}
''');
    assertJsonText(_getSuggestion(set, 'A.a'), '''
{
  "label": "A.a",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "CONSTRUCTOR",
    "name": "a",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 14,
      "length": 0,
      "startLine": 2,
      "startColumn": 5
    },
    "flags": 0,
    "parameters": "()",
    "returnType": "A"
  },
  "parameterNames": [],
  "parameterTypes": [],
  "relevanceTags": [
    "ElementKind.CONSTRUCTOR",
    "package:test/a.dart::A",
    "a"
  ],
  "requiredParameterCount": 0
}
''');
  }

  Future<void> test_suggestion_enum() async {
    var path = convertPath('/home/test/lib/a.dart');
    var uriStr = 'package:test/a.dart';

    newFile(path, content: r'''
enum MyEnum {
  aaa,
  bbb,
}
''');

    var set = await waitForSetWithUri(uriStr);
    assertJsonText(_getSuggestion(set, 'MyEnum'), '''
{
  "label": "MyEnum",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "ENUM",
    "name": "MyEnum",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 5,
      "length": 0,
      "startLine": 1,
      "startColumn": 6
    },
    "flags": 0
  },
  "relevanceTags": [
    "ElementKind.ENUM",
    "package:test/a.dart::MyEnum",
    "MyEnum"
  ]
}
''');
    assertJsonText(_getSuggestion(set, 'MyEnum.aaa'), '''
{
  "label": "MyEnum.aaa",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "ENUM_CONSTANT",
    "name": "aaa",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 16,
      "length": 0,
      "startLine": 2,
      "startColumn": 3
    },
    "flags": 0
  },
  "relevanceTags": [
    "ElementKind.ENUM_CONSTANT",
    "ElementKind.ENUM_CONSTANT+const",
    "package:test/a.dart::MyEnum",
    "aaa"
  ]
}
''');
    assertJsonText(_getSuggestion(set, 'MyEnum.bbb'), '''
{
  "label": "MyEnum.bbb",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "ENUM_CONSTANT",
    "name": "bbb",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 23,
      "length": 0,
      "startLine": 3,
      "startColumn": 3
    },
    "flags": 0
  },
  "relevanceTags": [
    "ElementKind.ENUM_CONSTANT",
    "ElementKind.ENUM_CONSTANT+const",
    "package:test/a.dart::MyEnum",
    "bbb"
  ]
}
''');
  }

  Future<void> test_suggestion_topLevelVariable() async {
    var path = convertPath('/home/test/lib/a.dart');
    var uriStr = 'package:test/a.dart';

    newFile(path, content: r'''
var boolV = false;
var intV = 0;
var doubleV = 0.1;
var stringV = 'hi';
''');

    var set = await waitForSetWithUri(uriStr);
    assertJsonText(_getSuggestion(set, 'boolV'), '''
{
  "label": "boolV",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "TOP_LEVEL_VARIABLE",
    "name": "boolV",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 4,
      "length": 0,
      "startLine": 1,
      "startColumn": 5
    },
    "flags": 0,
    "returnType": ""
  },
  "relevanceTags": [
    "ElementKind.TOP_LEVEL_VARIABLE",
    "dart:core::bool",
    "boolV"
  ]
}
''');
    assertJsonText(_getSuggestion(set, 'intV'), '''
{
  "label": "intV",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "TOP_LEVEL_VARIABLE",
    "name": "intV",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 23,
      "length": 0,
      "startLine": 2,
      "startColumn": 5
    },
    "flags": 0,
    "returnType": ""
  },
  "relevanceTags": [
    "ElementKind.TOP_LEVEL_VARIABLE",
    "dart:core::int",
    "intV"
  ]
}
''');
    assertJsonText(_getSuggestion(set, 'doubleV'), '''
{
  "label": "doubleV",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "TOP_LEVEL_VARIABLE",
    "name": "doubleV",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 37,
      "length": 0,
      "startLine": 3,
      "startColumn": 5
    },
    "flags": 0,
    "returnType": ""
  },
  "relevanceTags": [
    "ElementKind.TOP_LEVEL_VARIABLE",
    "dart:core::double",
    "doubleV"
  ]
}
''');
    assertJsonText(_getSuggestion(set, 'stringV'), '''
{
  "label": "stringV",
  "declaringLibraryUri": "package:test/a.dart",
  "element": {
    "kind": "TOP_LEVEL_VARIABLE",
    "name": "stringV",
    "location": {
      "file": ${jsonOfPath(path)},
      "offset": 56,
      "length": 0,
      "startLine": 4,
      "startColumn": 5
    },
    "flags": 0,
    "returnType": ""
  },
  "relevanceTags": [
    "ElementKind.TOP_LEVEL_VARIABLE",
    "dart:core::String",
    "stringV"
  ]
}
''');
  }

  static AvailableSuggestion _getSuggestion(
      AvailableSuggestionSet set, String label) {
    return set.items.singleWhere((s) => s.label == label);
  }
}
