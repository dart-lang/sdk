// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchEngineImplTest);
    defineReflectiveTests(SearchEngineImplWithNonFunctionTypeAliasesTest);
  });
}

/// TODO(scheglov) This class does not really belong here.
/// Consider merging it into [AbstractContextTest].
class PubPackageResolutionTest extends AbstractContextTest {
  late ResolvedUnitResult result;
  late FindNode findNode;
  late FindElement findElement;

  void addTestFile(String content) {
    newFile(testFile.path, content);
  }

  /// Resolve the [file] into [result].
  Future<void> resolveFile2(File file) async {
    result = await getResolvedUnit(file);

    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) {
    addTestFile(code);
    return resolveTestFile();
  }

  Future<void> resolveTestFile() {
    return resolveFile2(testFile);
  }
}

@reflectiveTest
class SearchEngineImplTest extends PubPackageResolutionTest {
  SearchEngineImpl get searchEngine {
    return SearchEngineImpl(allDrivers);
  }

  Future<void> test_membersOfSubtypes_classByClass_hasMembers() async {
    final a = newFile('$testPackageLibPath/a.dart', '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
class B extends A {
  void a() {}
}
''');

    newFile('$testPackageLibPath/c.dart', '''
import 'a.dart';
class C extends A {
  void b() {}
}
''');

    await resolveFile2(a);
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, unorderedEquals(['a', 'b']));
  }

  Future<void> test_membersOfSubtypes_enum_implements_hasMembers() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

enum E implements A {
  v;
  void foo() {}
}
''');

    var A = findElement.class_('A');
    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, unorderedEquals(['foo']));
  }

  Future<void> test_membersOfSubtypes_enum_with_hasMembers() async {
    await resolveTestCode('''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  void foo() {}
}
''');

    var M = findElement.mixin('M');
    var members = await searchEngine.membersOfSubtypes(M);
    expect(members, unorderedEquals(['foo']));
  }

  Future<void> test_membersOfSubtypes_noMembers() async {
    final a = newFile('$testPackageLibPath/a.dart', '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
class B extends A {}
''');

    await resolveFile2(a);
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, isEmpty);
  }

  Future<void> test_membersOfSubtypes_noSubtypes() async {
    final a = newFile('$testPackageLibPath/a.dart', '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
class B {
  void a() {}
}
''');

    await resolveFile2(a);
    var A = findElement.class_('A');

    var members = await searchEngine.membersOfSubtypes(A);
    expect(members, isNull);
  }

  Future<void> test_membersOfSubtypes_private() async {
    final a = newFile('$testPackageLibPath/a.dart', '''
class A {
  void a() {}
  void _b() {}
  void _c() {}
}
class B extends A {
  void _b() {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
class C extends A {
  void a() {}
  void _c() {}
}
class D extends B {
  void _c() {}
}
''');

    await resolveFile2(a);
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

    var subtypes = <InterfaceElement>{};
    await searchEngine.appendAllSubtypes(
        element, subtypes, OperationPerformanceImpl("<root>"));
    expect(subtypes, hasLength(3));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
  }

  Future<void> test_searchAllSubtypes_acrossDrivers() async {
    var aaaRootPath = _configureForPackage_aaa();

    final a = newFile('$aaaRootPath/lib/a.dart', '''
class T {}
class A extends T {}
''');

    newFile('$testPackageLibPath/b.dart', '''
import 'package:aaa/a.dart';
class B extends A {}
class C extends B {}
''');

    await resolveFile2(a);
    var element = findElement.class_('T');

    var subtypes = <InterfaceElement>{};
    await searchEngine.appendAllSubtypes(
        element, subtypes, OperationPerformanceImpl("<root>"));
    expect(subtypes, hasLength(3));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
  }

  Future<void> test_searchAllSubtypes_extensionType() async {
    await resolveTestCode('''
class A {}
extension type B(int it) implements A {}
extension type C(int it) implements A {}
''');

    var element = findElement.class_('A');

    var subtypes = <InterfaceElement>{};
    await searchEngine.appendAllSubtypes(
        element, subtypes, OperationPerformanceImpl("<root>"));
    expect(subtypes, hasLength(2));
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

    var subtypes = <InterfaceElement>{};
    await searchEngine.appendAllSubtypes(
        element, subtypes, OperationPerformanceImpl("<root>"));
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

    newFile('$testPackageLibPath/a.dart', codeA);
    newFile('$testPackageLibPath/b.dart', codeB);

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
    newFile('$testPackageLibPath/a.dart', '''
class A {
  int test;
}
foo(p) {
  p.test;
}
''');

    newFile('$testPackageLibPath/b.dart', '''
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

    newFile('$aaaRootPath/lib/a.dart', '''
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

    var a = newFile('$aaaRootPath/lib/a.dart', '''
int a;
''').path;

    var t = newFile('$testPackageLibPath/lib/t.dart', '''
import 'package:aaa/a.dart';
int t;
''').path;

    var coreLibResult = await driverFor(testFile).getLibraryByUri('dart:core')
        as LibraryElementResult;
    var intElement = coreLibResult.element.getClass('int')!;

    var matches = await searchEngine.searchReferences(intElement);

    void assertHasOne(String path, String name) {
      expect(matches.where((m) {
        var element = m.element;
        return element.name == name && element.source!.fullName == path;
      }), hasLength(1));
    }

    assertHasOne(t, 't');
    assertHasOne(a, 'a');
  }

  Future<void> test_searchReferences_enum_constructor_named() async {
    var code = '''
enum E {
  v.named(); // 1
  const E.named();
}
''';
    await resolveTestCode(code);

    var element = findElement.constructor('named');
    var matches = await searchEngine.searchReferences(element);
    expect(
      matches,
      unorderedEquals([
        predicate((SearchMatch m) {
          return m.kind == MatchKind.INVOCATION &&
              identical(m.element, findElement.field('v')) &&
              m.sourceRange.offset == code.indexOf('.named(); // 1') &&
              m.sourceRange.length == '.named'.length;
        }),
      ]),
    );
  }

  Future<void> test_searchReferences_enum_constructor_unnamed() async {
    var code = '''
enum E {
  v1, // 1
  v2(), // 2
  v3.new(), // 3
}
''';
    await resolveTestCode(code);

    var element = findElement.unnamedConstructor('E');
    var matches = await searchEngine.searchReferences(element);
    expect(
      matches,
      unorderedEquals([
        predicate((SearchMatch m) {
          return m.kind ==
                  MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS &&
              identical(m.element, findElement.field('v1')) &&
              m.sourceRange.offset == code.indexOf(', // 1') &&
              m.sourceRange.length == 0;
        }),
        predicate((SearchMatch m) {
          return m.kind == MatchKind.INVOCATION &&
              identical(m.element, findElement.field('v2')) &&
              m.sourceRange.offset == code.indexOf('(), // 2') &&
              m.sourceRange.length == 0;
        }),
        predicate((SearchMatch m) {
          return m.kind == MatchKind.INVOCATION &&
              identical(m.element, findElement.field('v3')) &&
              m.sourceRange.offset == code.indexOf('.new(), // 3') &&
              m.sourceRange.length == '.new'.length;
        }),
      ]),
    );
  }

  Future<void> test_searchReferences_extensionType() async {
    final code = '''
extension type A(int it) {}

void f(A a) {}
''';
    await resolveTestCode(code);

    final element = findElement.extensionType('A');
    final matches = await searchEngine.searchReferences(element);
    expect(
      matches,
      unorderedEquals([
        predicate((SearchMatch m) {
          return m.kind == MatchKind.REFERENCE &&
              identical(m.element, findElement.parameter('a')) &&
              m.sourceRange.offset == code.indexOf('A a) {}') &&
              m.sourceRange.length == 'A'.length;
        }),
      ]),
    );
  }

  Future<void>
      test_searchReferences_parameter_ofConstructor_super_named() async {
    var code = '''
class A {
  A({required int a});
}
class B extends A {
  B({required super.a}); // ref
}
''';
    await resolveTestCode(code);

    var element = findElement.unnamedConstructor('A').parameter('a');
    var matches = await searchEngine.searchReferences(element);
    expect(
      matches,
      unorderedEquals([
        predicate((SearchMatch m) {
          return m.kind == MatchKind.REFERENCE &&
              identical(
                m.element,
                findElement.unnamedConstructor('B').superFormalParameter('a'),
              ) &&
              m.sourceRange.offset == code.indexOf('a}); // ref') &&
              m.sourceRange.length == 1;
        }),
      ]),
    );
  }

  Future<void>
      test_searchReferences_topFunction_parameter_optionalNamed_anywhere() async {
    var code = '''
void foo(int a, int b, {int? test}) {}

void g() {
  foo(1, test: 0, 2);
}
''';
    await resolveTestCode(code);

    var element = findElement.parameter('test');
    var matches = await searchEngine.searchReferences(element);
    expect(
      matches,
      unorderedEquals([
        predicate((SearchMatch m) {
          return m.kind == MatchKind.REFERENCE &&
              identical(m.element, findElement.topFunction('g')) &&
              m.sourceRange.offset == code.indexOf('test: 0') &&
              m.sourceRange.length == 'test'.length;
        }),
      ]),
    );
  }

  Future<void> test_searchTopLevelDeclarations() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
int a;
''');

    newFile('$testPackageLibPath/b.dart', '''
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

    newFile('$aaaRootPath/lib/a.dart', '''
class A {}
''');

    // The `package:test` uses the class `A` from the `package:aaa`.
    // So it sees the declaration the element `A`.
    newFile(testFile.path, '''
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

    writePackageConfig(
      '$aaaRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: aaaRootPath),
    );

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    return aaaRootPath;
  }

  Future<void> _ensureContainedFilesKnown() async {
    for (var driver in allDrivers) {
      var contextRoot = driver.analysisContext!.contextRoot;
      for (var file in contextRoot.analyzedFiles()) {
        if (file.endsWith('.dart')) {
          await driver.getUnitElement(file);
        }
      }
    }
  }

  static void _assertContainsClass(
      Set<InterfaceElement> subtypes, String name) {
    expect(
      subtypes,
      contains(
        predicate((InterfaceElement e) => e.name == name),
      ),
    );
  }
}

@reflectiveTest
class SearchEngineImplWithNonFunctionTypeAliasesTest
    extends SearchEngineImplTest {
  Future<void> test_searchReferences_typeAlias_interfaceType() async {
    await resolveTestCode('''
typedef A<T> = Map<T, String>;

void f(A<int> a, A<double> b) {}
''');

    var element = findElement.typeAlias('A');
    var matches = await searchEngine.searchReferences(element);

    Matcher hasOne(Element element, String search) {
      return predicate((SearchMatch match) {
        return match.element == element &&
            match.sourceRange.offset == findNode.offset(search);
      });
    }

    expect(
      matches,
      unorderedMatches([
        hasOne(findElement.parameter('a'), 'A<int>'),
        hasOne(findElement.parameter('b'), 'A<double>'),
      ]),
    );
  }
}
