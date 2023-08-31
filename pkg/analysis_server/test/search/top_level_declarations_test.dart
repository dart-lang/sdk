// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelDeclarationsTest);
  });
}

@reflectiveTest
class TopLevelDeclarationsTest extends AbstractSearchDomainTest {
  void assertHasDeclaration(ElementKind kind, String name) {
    var result = findTopLevelResult(kind, name);
    if (result == null) {
      fail('Not found: kind=$kind name="$name"\nin\n${results.join('\n')}');
    }
    this.result = result;
  }

  void assertNoDeclaration(ElementKind kind, String name) {
    var result = findTopLevelResult(kind, name);
    if (result != null) {
      fail('Unexpected: kind=$kind name="$name"\nin\n${results.join('\n')}');
    }
  }

  Future<dynamic /*RequestError?|void*/ > findTopLevelDeclarations(
      String pattern) async {
    await waitForTasksFinished();
    var request = SearchFindTopLevelDeclarationsParams(pattern).toRequest('0');
    var response = await handleRequest(request);
    if (response.error != null) {
      return response.error;
    }
    searchId = SearchFindTopLevelDeclarationsResult.fromResponse(response).id;
    return waitForSearchResults();
  }

  SearchResult? findTopLevelResult(ElementKind kind, String name) {
    for (var result in results) {
      var element = result.path[0];
      if (element.kind == kind && element.name == name) {
        return result;
      }
    }
    return null;
  }

  Future<void> test_enum_startEndPattern() async {
    addTestFile('''
enum A {
  v
}

enum A2 {
  v
}

enum B {
  v
}

enum D {
  v
}
''');
    await findTopLevelDeclarations('^[A-C]\$');
    assertHasDeclaration(ElementKind.ENUM, 'A');
    assertHasDeclaration(ElementKind.ENUM, 'B');
    assertNoDeclaration(ElementKind.ENUM, 'A2');
    assertNoDeclaration(ElementKind.ENUM, 'D');
  }

  Future<void> test_extensionDeclaration() async {
    addTestFile('''
extension MyExtension on int {}
''');
    await findTopLevelDeclarations('My*');
    assertHasDeclaration(ElementKind.EXTENSION, 'MyExtension');
  }

  Future<void> test_extensionTypeDeclaration() async {
    addTestFile('''
extension type MyExtensionType(int it) {}
''');
    await findTopLevelDeclarations('My*');
    assertHasDeclaration(ElementKind.EXTENSION_TYPE, 'MyExtensionType');
  }

  Future<void> test_invalidRegex() async {
    var result = await findTopLevelDeclarations('[A');
    expect(result, const TypeMatcher<RequestError>());
  }

  Future<void> test_startEndPattern() async {
    addTestFile('''
class A {} // A
class B = Object with A;
typedef C();
typedef D();
E() {}
var F = null;
class ABC {}
''');
    await findTopLevelDeclarations('^[A-F]\$');
    assertHasDeclaration(ElementKind.CLASS, 'A');
    assertHasDeclaration(ElementKind.CLASS, 'B');
    assertHasDeclaration(ElementKind.TYPE_ALIAS, 'C');
    assertHasDeclaration(ElementKind.TYPE_ALIAS, 'D');
    assertHasDeclaration(ElementKind.FUNCTION, 'E');
    assertHasDeclaration(ElementKind.TOP_LEVEL_VARIABLE, 'F');
    assertNoDeclaration(ElementKind.CLASS, 'ABC');
  }
}
