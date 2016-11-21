// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchTest);
  });
}

class ExpectedResult {
  final List<String> enclosingComponents;
  final SearchResultKind kind;
  final int offset;
  final int length;
  final bool isResolved;
  final bool isQualified;

  ExpectedResult(this.enclosingComponents, this.kind, this.offset, this.length,
      {this.isResolved: true, this.isQualified: false});

  bool operator ==(Object result) {
    return result is SearchResult &&
        result.kind == this.kind &&
        result.isResolved == this.isResolved &&
        result.isQualified == this.isQualified &&
        result.offset == this.offset &&
        hasExpectedComponents(result.enclosingElement);
  }

  bool hasExpectedComponents(Element element) {
    for (int i = enclosingComponents.length - 1; i >= 0; i--) {
      if (element == null) {
        return false;
      }
      if (element is CompilationUnitElement) {
        if (element.source.uri.toString() != enclosingComponents[0]) {
          return false;
        }
      } else if (element.name != enclosingComponents[i]) {
        return false;
      }
      element = element.enclosingElement;
    }
    return true;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("ExpectedResult(kind=");
    buffer.write(kind);
    buffer.write(", enclosingComponents=");
    buffer.write(enclosingComponents);
    buffer.write(", offset=");
    buffer.write(offset);
    buffer.write(", length=");
    buffer.write(length);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }
}

@reflectiveTest
class SearchTest extends BaseAnalysisDriverTest {
  static const testUri = 'package:test/test.dart';

  test_searchReferences_Label() async {
    addTestFile('''
main() {
label:
  while (true) {
    if (true) {
      break label; // 1
    }
    break label; // 2
  }
}
''');
    int offset = findOffset('label:');
    List<String> main = [testUri, 'main'];
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 1'),
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 2')
    ];
    await _verifyReferences(offset, expected);
  }

  test_searchReferences_localVariable() async {
    addTestFile(r'''
main() {
  var v;
  v = 1;
  v += 2;
  print(v);
  v();
}
''');
    int offset = findOffset('v;');
    List<String> main = [testUri, 'main'];
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(offset, expected);
  }

  test_searchReferences_localVariable_inForEachLoop() async {
    addTestFile('''
main() {
  for (var v in []) {
    v = 1;
    v += 2;
    print(v);
    v();
  }
}
''');
    int offset = findOffset('v in []');
    List<String> main = [testUri, 'main'];
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(offset, expected);
  }

  ExpectedResult _expectId(
      List<String> enclosingComponents, SearchResultKind kind, String search,
      {int length, bool isResolved: true, bool isQualified: false}) {
    int offset = findOffset(search);
    if (length == null) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedResult(enclosingComponents, kind, offset, length,
        isResolved: isResolved, isQualified: isQualified);
  }

  Future _verifyReferences(
      int offset, List<ExpectedResult> expectedMatches) async {
    List<SearchResult> results =
        await driver.search.references(testFile, offset);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  static void _assertResults(
      List<SearchResult> matches, List<ExpectedResult> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}
