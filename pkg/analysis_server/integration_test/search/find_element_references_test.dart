// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FindElementReferencesTest);
  });
}

@reflectiveTest
class FindElementReferencesTest extends AbstractAnalysisServerIntegrationTest {
  late String pathname;

  Future<void> test_badTarget() async {
    var text = r'''
void f() {
  if /* target */ (true) {
    print('Hello');
  }
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = await _findElementReferences(text);
    expect(results, isNull);
  }

  Future<void> test_findReferences() async {
    var text = r'''
void f() {
  foo /* target */ ('Hello');
}

foo(String str) {}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.INVOCATION.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_dotShorthand_invocation_class() async {
    var text = r'''
class A {
  A.foo /* target */();
}

void f() {
  A a = .foo();
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.INVOCATION.name);
    expect(result.path.first.name, 'f');
  }

  Future<void>
  test_findReferences_dotShorthand_invocation_extensionType() async {
    var text = r'''
extension type A(int x) {
  static A foo /* target */() => A(1);
}

void f() {
  A a = .foo();
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.INVOCATION.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_dotShorthand_read_class() async {
    var text = r'''
class A {
  static A get getter /* target */ => A();
}

void f() {
  A a = .getter;
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_dotShorthand_read_enum() async {
    var text = r'''
enum A { a /* target */ }

void f() {
  A a = .a;
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_dotShorthand_read_extensionType() async {
    var text = r'''
extension type A(int x) {
  static A get getter /* target */ => A(1);
}

void f() {
  A a = .getter;
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_inNullAware_listElement() async {
    var text = r'''
List<int> f(int? foo) {
  return [?foo /* target */];
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_inNullAware_mapKey() async {
    var text = r'''
Map<int, String> f(int? foo) {
  return {?foo /* target */: "value"};
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_inNullAware_mapKeyValue() async {
    var text = r'''
Map<int, String> f(int? key, String? value) {
  return {?key: ?value /* target */};
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_inNullAware_mapValue() async {
    var text = r'''
Map<String, int> f(int? foo) {
  return {"key": ?foo /* target */};
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<void> test_findReferences_inNullAware_setElement() async {
    var text = r'''
Set<int> f(int? foo) {
  return {?foo /* target */};
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    var results = (await _findElementReferences(text))!;
    expect(results, hasLength(1));
    var result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.READ.name);
    expect(result.path.first.name, 'f');
  }

  Future<List<SearchResult>?> _findElementReferences(String text) async {
    var offset = text.indexOf(' /* target */') - 1;
    var result = await sendSearchFindElementReferences(pathname, offset, false);
    if (result.id == null) return null;
    var searchParams = await onSearchResults.first;
    expect(searchParams.id, result.id);
    expect(searchParams.isLast, isTrue);
    return searchParams.results;
  }
}
