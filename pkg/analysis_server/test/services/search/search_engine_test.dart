// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchEngineImplTest);
  });
}

/// TODO(scheglov) This class does not really belong here.
/// Consider merging it into [AbstractContextTest].
class PubPackageResolutionTest extends AbstractContextTest {
  ResolvedUnitResult result;
  FindNode findNode;
  FindElement findElement;

  String get testFilePath => '$testPackageLibPath/test.dart';

  void addTestFile(String content) {
    newFile(testFilePath, content: content);
  }

  /// Resolve the file with the [path] into [result].
  Future<void> resolveFile2(String path) async {
    path = convertPath(path);

    result = await resolveFile(path);
    expect(result.state, ResultState.VALID);

    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) {
    addTestFile(code);
    return resolveTestFile();
  }

  Future<void> resolveTestFile() {
    return resolveFile2(testFilePath);
  }
}

@reflectiveTest
class SearchEngineImplTest extends PubPackageResolutionTest {
  SearchEngineImpl get searchEngine {
    return SearchEngineImpl(allDrivers);
  }

  @override
  void setUp() {
    super.setUp();

    // TODO(scheglov) This is not ideal.
    // We write into the root because we choose the workspace root to
    // index `aaa/lib/a.dart`. But ideally we should use the context root
    // that contains it (i.e. `root/aaa`), or a context root where it is a
    // package (e.g. `root/test`).
    writePackageConfig(
      '$workspaceRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()
        ..add(name: 'test', rootPath: testPackageRootPath),
    );
  }

  Future<void> test_membersOfSubtypes_hasMembers() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
class B extends A {
  void a() {}
}
''');

    newFile('$testPackageLibPath/c.dart', content: '''
import 'a.dart';
class C extends A {
  void b() {}
}
''');

    await resolveFile2('$testPackageLibPath/a.dart');
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, unorderedEquals(['a', 'b']));
  }

  Future<void> test_membersOfSubtypes_noMembers() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
class B extends A {}
''');

    await resolveFile2('$testPackageLibPath/a.dart');
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, isEmpty);
  }

  Future<void> test_membersOfSubtypes_noSubtypes() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
class B {
  void a() {}
}
''');

    await resolveFile2('$testPackageLibPath/a.dart');
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, isNull);
  }

  Future<void> test_membersOfSubtypes_private() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  void a() {}
  void _b() {}
  void _c() {}
}
class B extends A {
  void _b() {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
class C extends A {
  void a() {}
  void _c() {}
}
class D extends B {
  void _c() {}
}
''');

    await resolveFile2('$testPackageLibPath/a.dart');
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, unorderedEquals(['a', '_b']));
  }

  Future<void> test_searchAllSubtypes() async {
    await resolveTestCode('''
class T {}
class A extends T {}
class B extends A {}
class C implements B {}
''');

    var element = findElement.class_('T');

    var subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
  }

  Future<void> test_searchAllSubtypes_acrossDrivers() async {
    var aaaRootPath = _configureForPackage_aaa();

    newFile('$aaaRootPath/lib/a.dart', content: '''
class T {}
class A extends T {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'package:aaa/a.dart';
class B extends A {}
class C extends B {}
''');

    await resolveFile2('$aaaRootPath/lib/a.dart');
    var element = findElement.class_('T');

    var subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
  }

  Future<void> test_searchAllSubtypes_mixin() async {
    await resolveTestCode('''
class T {}

mixin A on T {}
mixin B implements T {}

class C extends T {}

mixin D on C {}
mixin E implements C {}
''');

    var element = findElement.class_('T');

    var subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(5));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
    _assertContainsClass(subtypes, 'D');
    _assertContainsClass(subtypes, 'E');
  }

  Future<void> test_searchMemberDeclarations() async {
    var codeA = '''
class A {
  int test; // 1
  int testTwo;
}
''';
    var codeB = '''
class B {
  void test() {} // 2
  void testTwo() {}
}
int test;
''';

    newFile('$testPackageLibPath/a.dart', content: codeA);
    newFile('$testPackageLibPath/b.dart', content: codeB);

    var matches = await searchEngine.searchMemberDeclarations('test');
    expect(matches, hasLength(2));

    void assertHasElement(String name, int nameOffset) {
      expect(
          matches,
          contains(predicate((SearchMatch m) =>
              m.kind == MatchKind.DECLARATION &&
              m.element.name == name &&
              m.element.nameOffset == nameOffset)));
    }

    assertHasElement('test', codeA.indexOf('test; // 1'));
    assertHasElement('test', codeB.indexOf('test() {} // 2'));
  }

  Future<void> test_searchMemberReferences() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  int test;
}
foo(p) {
  p.test;
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
bar(p) {
  p.test = 1;
}
''');

    var matches = await searchEngine.searchMemberReferences('test');
    expect(matches, hasLength(2));
    expect(
        matches,
        contains(predicate((SearchMatch m) =>
            m.element.name == 'foo' || m.kind == MatchKind.READ)));
    expect(
        matches,
        contains(predicate((SearchMatch m) =>
            m.element.name == 'bar' || m.kind == MatchKind.WRITE)));
  }

  Future<void> test_searchReferences() async {
    var aaaRootPath = _configureForPackage_aaa();

    newFile('$aaaRootPath/lib/a.dart', content: '''
class T {}
T a;
''');

    await resolveTestCode('''
import 'package:aaa/a.dart';
T b;
''');

    var element = findElement.importFind('package:aaa/a.dart').class_('T');
    var matches = await searchEngine.searchReferences(element);
    expect(matches, hasLength(2));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'a')));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'b')));
  }

  Future<void> test_searchReferences_discover_owned() async {
    var aaaRootPath = _configureForPackage_aaa();

    var a = newFile('$aaaRootPath/lib/a.dart', content: '''
int a;
''').path;

    var t = newFile('$testPackageLibPath/lib/t.dart', content: '''
import 'package:aaa/a.dart';
int t;
''').path;

    var coreLib = await driverFor(testFilePath).getLibraryByUri('dart:core');
    var intElement = coreLib.getType('int');

    var matches = await searchEngine.searchReferences(intElement);

    void assertHasOne(String path, String name) {
      expect(matches.where((m) {
        var element = m.element;
        return element.name == name && element.source.fullName == path;
      }), hasLength(1));
    }

    assertHasOne(t, 't');
    assertHasOne(a, 'a');
  }

  Future<void> test_searchTopLevelDeclarations() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {}
int a;
''');

    newFile('$testPackageLibPath/b.dart', content: '''
class B {}
get b => 42;
''');

    await _ensureContainedFilesKnown();

    var matches = await searchEngine.searchTopLevelDeclarations('.*');
    matches.removeWhere((match) => match.libraryElement.isInSdk);
    expect(matches, hasLength(4));

    void assertHasOneElement(String name) {
      var nameMatches = matches.where((SearchMatch m) =>
          m.kind == MatchKind.DECLARATION && m.element.name == name);
      expect(nameMatches, hasLength(1));
    }

    assertHasOneElement('A');
    assertHasOneElement('a');
    assertHasOneElement('B');
    assertHasOneElement('b');
  }

  Future<void> test_searchTopLevelDeclarations_dependentPackage() async {
    var aaaRootPath = _configureForPackage_aaa();

    newFile('$aaaRootPath/lib/a.dart', content: '''
class A {}
''');

    // The `package:test` uses the class `A` from the `package:aaa`.
    // So it sees the declaration the element `A`.
    newFile('$testFilePath', content: '''
import 'package:aaa/a.dart';
class B extends A {}
''');

    await _ensureContainedFilesKnown();

    var matches = await searchEngine.searchTopLevelDeclarations('.*');
    matches.removeWhere((match) => match.libraryElement.isInSdk);

    // We get exactly two items: `A` and `B`.
    // Specifically, we get exactly one `A`.
    expect(matches, hasLength(2));

    void assertHasOneElement(String name) {
      var nameMatches = matches.where((SearchMatch m) =>
          m.kind == MatchKind.DECLARATION && m.element.name == name);
      expect(nameMatches, hasLength(1));
    }

    assertHasOneElement('A');
    assertHasOneElement('B');
  }

  String _configureForPackage_aaa() {
    var aaaRootPath = '$workspaceRootPath/aaa';

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    // TODO(scheglov) This is not ideal.
    // We write into the root because we choose the workspace root to
    // index `aaa/lib/a.dart`. But ideally we should use the context root
    // that contains it (i.e. `root/aaa`), or a context root where it is a
    // package (e.g. `root/test`).
    writePackageConfig(
      '$workspaceRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath)
        ..add(name: 'test', rootPath: testPackageRootPath),
    );
    return aaaRootPath;
  }

  Future _ensureContainedFilesKnown() async {
    for (var driver in allDrivers) {
      var contextRoot = driver.analysisContext.contextRoot;
      for (var file in contextRoot.analyzedFiles()) {
        await driver.getUnitElement(file);
      }
    }
  }

  static void _assertContainsClass(Set<ClassElement> subtypes, String name) {
    expect(subtypes, contains(predicate((ClassElement e) => e.name == name)));
  }
}
