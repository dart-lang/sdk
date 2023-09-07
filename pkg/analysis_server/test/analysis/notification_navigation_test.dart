// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationNavigationTest);
  });
}

class AbstractNavigationTest extends PubPackageAnalysisServerTest {
  late List<NavigationRegion> regions;
  late List<NavigationTarget> targets;
  late List<String> targetFiles;

  late NavigationRegion testRegion;
  late List<int> testTargetIndexes;
  late List<NavigationTarget> testTargets;
  late NavigationTarget testTarget;

  /// Validates that there is a target in [testTargets] with [file],
  /// at [offset] and with the given [length].
  void assertHasFileTarget(String file, int offset, int length) {
    for (var target in testTargets) {
      if (targetFiles[target.fileIndex] == file &&
          target.offset == offset &&
          target.length == length) {
        testTarget = target;
        return;
      }
    }
    fail(
        'Expected to find target (file=$file; offset=$offset; length=$length) in\n'
        '$testRegion in\n'
        '${testTargets.join('\n')}');
  }

  void assertHasOperatorRegion(String regionSearch, int regionLength,
      String targetSearch, int targetLength) {
    assertHasRegion(regionSearch, regionLength);
    assertHasTarget(targetSearch, targetLength);
  }

  /// Validates that there is a region at the offset of [search] in [testFile].
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertHasRegion(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    findRegion(offset, length, true);
  }

  /// Validates that there is a region at the offset of [search] in [testFile]
  /// with the given [length] or the length of [search].
  void assertHasRegionString(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = search.length;
    }
    findRegion(offset, length, true);
  }

  /// Validates that there is an identifier region at [regionSearch] with target
  /// at [targetSearch].
  void assertHasRegionTarget(String regionSearch, String targetSearch,
      {int regionLength = -1, int targetLength = -1}) {
    assertHasRegion(regionSearch, regionLength);
    assertHasTarget(targetSearch, targetLength);
  }

  /// Validates that there is a target in [testTargets]  with [testFile], at the
  /// offset of [search] in [testFile], and with the given [length] or the
  /// length of an leading identifier in [search].
  void assertHasTarget(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    assertHasFileTarget(testFile.path, offset, length);
  }

  /// TODO(scheglov) Improve target matching.
  void assertHasTargetInDartCore(String search) {
    var dartCoreFile = getFile('/sdk/lib/core/core.dart');
    var dartCoreContent = dartCoreFile.readAsStringSync();

    var offset = dartCoreContent.indexOf(search);
    expect(offset, isNot(-1));

    if (dartCoreContent.contains(search, offset + search.length)) {
      fail('Not unique');
    }

    var length = findIdentifierLength(search);
    assertHasFileTarget(dartCoreFile.path, offset, length);
  }

  /// Validates that there is a target in [testTargets]  with [testFile], at the
  /// offset of [str] in [testFile], and with the length of  [str].
  void assertHasTargetString(String str) {
    assertHasTarget(str, str.length);
  }

  /// Validates that there is not a region at [search] and with the given
  /// [length].
  void assertNoRegion(String search, int length) {
    var offset = findOffset(search);
    findRegion(offset, length, false);
  }

  /// Validates that there is not a region at [search] with any length.
  void assertNoRegionAt(String search) {
    var offset = findOffset(search);
    findRegion(offset, -1, false);
  }

  /// Validates that there is not a region for [search] string.
  void assertNoRegionString(String search) {
    var offset = findOffset(search);
    var length = search.length;
    findRegion(offset, length, false);
  }

  void assertRegionsSorted() {
    var lastEnd = -1;
    for (var region in regions) {
      var offset = region.offset;
      if (offset < lastEnd) {
        fail('$lastEnd was expected to be > $offset in\n${regions.join('\n')}');
      }
      lastEnd = offset + region.length;
    }
  }

  /// Finds the navigation region with the given [offset] and [length].
  /// If [length] is `-1`, then it is ignored.
  ///
  /// If [exists] is `true`, then fails if such region does not exist.
  /// Otherwise remembers it in [testRegion].
  /// Also fills [testTargets] with its targets.
  ///
  /// If [exists] is `false`, then fails if such region exists.
  void findRegion(int offset, int length, bool exists) {
    for (var region in regions) {
      if (region.offset == offset &&
          (length == -1 || region.length == length)) {
        if (exists == false) {
          fail('Not expected to find (offset=$offset; length=$length) in\n'
              '${regions.join('\n')}');
        }
        testRegion = region;
        testTargetIndexes = region.targets;
        testTargets = testTargetIndexes.map((i) => targets[i]).toList();
        return;
      }
    }
    if (exists == true) {
      fail('Expected to find (offset=$offset; length=$length) in\n'
          '${regions.join('\n')}');
    }
  }
}

@reflectiveTest
class AnalysisNotificationNavigationTest extends AbstractNavigationTest {
  final Completer<void> _resultsAvailable = Completer();

  Future<void> prepareNavigation() async {
    await handleSuccessfulRequest(
      AnalysisSetSubscriptionsParams({
        AnalysisService.NAVIGATION: [testFile.path],
      }).toRequest('0'),
    );

    await _resultsAvailable.future;
    assertRegionsSorted();
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
      var params = AnalysisNavigationParams.fromNotification(notification);
      if (params.file == testFile.path) {
        regions = params.regions;
        targets = params.targets;
        targetFiles = params.files;
        _resultsAvailable.complete();
      }
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('''
class AAA {}
AAA aaa;
''');
    await waitForTasksFinished();
    await prepareNavigation();
    assertHasRegionTarget('AAA aaa;', 'AAA {}');
  }

  Future<void> test_annotation_generic_typeArguments_class() async {
    addTestFile('''
class A<T> {
  const A();
}

@A<int>()
void f() {}
''');
    await prepareNavigation();
    assertHasRegion('int>()');
  }

  Future<void> test_annotationConstructor_generic_named() async {
    addTestFile('''
class A<T> {
  const A.named(_);
}

@A<int>.named(0)
void f() {}
''');
    await prepareNavigation();
    {
      assertHasRegion('A<int>.named(0)');
      assertHasTarget('named(_);');
    }
    {
      assertHasRegion('named(0)');
      assertHasTarget('named(_);');
    }
  }

  Future<void> test_annotationConstructor_generic_unnamed() async {
    addTestFile('''
class A<T> {
  const A(_);
}

@A<int>(0)
void f() {}
''');
    await prepareNavigation();
    assertHasRegionString('A<int>(0)', 'A'.length);
    assertHasTarget('A(_);');
  }

  Future<void> test_annotationConstructor_implicit() async {
    addTestFile('''
class A {
}
@A()
void f() {
}
''');
    await prepareNavigation();
    assertHasRegionString('A()', 'A'.length);
    assertHasTarget('A {');
  }

  Future<void> test_annotationConstructor_importPrefix() async {
    newFile('$testPackageLibPath/my_annotation.dart', r'''
library an;
class MyAnnotation {
  const MyAnnotation();
  const MyAnnotation.named();
}
''');
    addTestFile('''
import 'my_annotation.dart' as man;
@man.MyAnnotation()
@man.MyAnnotation.named()
void f() {
}
''');
    await prepareNavigation();
    assertHasRegion('MyAnnotation()');
    assertHasRegion('MyAnnotation.named()');
    assertHasRegion('named()');
    {
      assertHasRegion('man.MyAnnotation()');
      assertHasTarget('man;');
    }
    {
      assertHasRegion('man.MyAnnotation.named()');
      assertHasTarget('man;');
    }
  }

  Future<void> test_annotationConstructor_named() async {
    addTestFile('''
class A {
  const A.named(p);
}
@A.named(0)
void f() {
}
''');
    await prepareNavigation();
    {
      assertHasRegion('A.named(0)');
      assertHasTarget('named(p);');
    }
    {
      assertHasRegion('named(0)');
      assertHasTarget('named(p);');
    }
  }

  Future<void> test_annotationConstructor_unnamed() async {
    addTestFile('''
class A {
  const A();
}
@A()
void f() {
}
''');
    await prepareNavigation();
    assertHasRegionString('A()', 'A'.length);
    assertHasTarget('A();');
  }

  Future<void> test_annotationField() async {
    addTestFile('''
const myan = new Object();
@myan // ref
void f() {
}
''');
    await prepareNavigation();
    assertHasRegion('myan // ref');
    assertHasTarget('myan = new Object();');
  }

  Future<void> test_annotationField_importPrefix() async {
    newFile('$testPackageLibPath/mayn.dart', r'''
library an;
const myan = new Object();
''');
    addTestFile('''
import 'mayn.dart' as man;
@man.myan // ref
void f() {
}
''');
    await prepareNavigation();
    assertHasRegion('myan // ref');
  }

  Future<void> test_class_constructor_named() async {
    addTestFile('''
class A {
  A.named(BBB p) {}
}
class BBB {}
''');
    await prepareNavigation();
    // has no region for complete "A.named"
    assertNoRegion('A.named', 'A.named'.length);
    // has separate regions for "A" and "named"
    assertHasRegion('A.named(', 'A'.length);
    assertHasTarget('A {');
    assertHasRegion('named(', 'named'.length);
    assertHasTarget('named(BBB');
    // validate that we don't forget to resolve parameters
    assertHasRegionTarget('BBB p', 'BBB {}');
  }

  Future<void> test_class_constructor_unnamed() async {
    addTestFile('''
class A {
  A(BBB p) {}
}
class BBB {}
''');
    await prepareNavigation();
    // has region for complete "A.named"
    assertHasRegion('A(BBB');
    assertHasTarget('A(BBB');
    // validate that we don't forget to resolve parameters
    assertHasRegionTarget('BBB p', 'BBB {}');
  }

  Future<void> test_class_constructorReference_named() async {
    addTestFile('''
class A {}
class B<T> {
  B.named();
}
void f() {
  B<A>.named;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('B<A>.named;', 'B<T> {');
    assertHasRegionTarget('named;', 'named();');
    assertHasRegionTarget('A>', 'A {}');
  }

  Future<void> test_class_constructorReference_unnamed_declared() async {
    addTestFile('''
class A {
  A();
}
void f() {
  A.new;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('A.new;', 'A {');
    assertHasRegionTarget('new;', 'A();');
  }

  Future<void> test_class_constructorReference_unnamed_declared_new() async {
    addTestFile('''
class A {
  A.new();
}
void f() {
  A.new;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('A.new;', 'A {');
    assertHasRegionTarget('new;', 'new();');
  }

  Future<void> test_class_constructorReference_unnamed_default() async {
    addTestFile('''
class A {}
void f() {
  A.new;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('A.new;', 'A {}');
    assertHasRegionTarget('new;', 'A {}');
  }

  Future<void> test_class_factoryRedirectingConstructor_implicit() async {
    addTestFile('''
class A {
  factory A() = B;
}
class B {
}
''');
    await prepareNavigation();
    assertHasRegion('B;');
    assertHasTarget('B {');
  }

  Future<void>
      test_class_factoryRedirectingConstructor_implicit_withTypeArgument() async {
    addTestFile('''
class A {}
class B {
  factory B() = C<A>;
}
class C<T> {}
''');
    await prepareNavigation();
    {
      assertHasRegion('C<A>');
      assertHasTarget('C<T> {');
    }
    {
      assertHasRegion('A>;');
      assertHasTarget('A {');
    }
  }

  Future<void> test_class_factoryRedirectingConstructor_named() async {
    addTestFile('''
class A {
  factory A() = B.named;
}
class B {
  B.named();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('B.named;', 'B'.length);
      assertHasTarget('B {');
    }
    {
      assertHasRegionString('named;', 'named'.length);
      assertHasTarget('named();');
    }
  }

  Future<void>
      test_class_factoryRedirectingConstructor_named_withTypeArgument() async {
    addTestFile('''
class A {}
class B {
  factory B.named() = C<A>.named;
}
class C<T> {
  C.named() {}
}
''');
    await prepareNavigation();
    {
      assertHasRegion('C<A>');
      assertHasTarget('C<T> {');
    }
    {
      assertHasRegion('A>.named');
      assertHasTarget('A {');
    }
    {
      assertHasRegion('named;', 'named'.length);
      assertHasTarget('named() {}');
    }
  }

  Future<void> test_class_factoryRedirectingConstructor_unnamed() async {
    addTestFile('''
class A {
  factory A() = B;
}
class B {
  B() {}
}
''');
    await prepareNavigation();
    assertHasRegion('B;');
    assertHasTarget('B() {}');
  }

  Future<void>
      test_class_factoryRedirectingConstructor_unnamed_withTypeArgument() async {
    addTestFile('''
class A {}
class B {
  factory B() = C<A>;
}
class C<T> {
  C() {}
}
''');
    await prepareNavigation();
    {
      assertHasRegion('C<A>');
      assertHasTarget('C() {}');
    }
    {
      assertHasRegion('A>;');
      assertHasTarget('A {');
    }
  }

  Future<void> test_class_factoryRedirectingConstructor_unresolved() async {
    addTestFile('''
class A {
  factory A() = B;
}
''');
    await prepareNavigation();
    // don't check regions, but there should be no exceptions
  }

  Future<void> test_class_fieldFormalParameter_requiredNamed() async {
    addTestFile('''
class A {
  final int f;
  A({required this.f}) : assert(f > 0);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('this.f', 'f;');
    assertHasRegionTarget('f}) :', 'f;');
    assertHasRegionTarget('f > 0', 'f}) :');
  }

  Future<void> test_class_fieldFormalParameter_requiredPositional() async {
    addTestFile('''
class A {
  final int f;
  A(this.f) : assert(f > 0);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('this.f', 'f;');
    assertHasRegionTarget('f) :', 'f;');
    assertHasRegionTarget('f > 0', 'f) :');
  }

  Future<void>
      test_class_fieldFormalParameter_requiredPositional_functionTyped() async {
    addTestFile('''
class B {
  final Object f;
  B(int this.f<T>(T a)) : assert(f is Object);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('f<T>', 'f;');
    assertHasRegion('int ');
    assertHasRegionTarget('T>', 'T>');
    assertHasRegionTarget('T a', 'T>');
    assertHasRegionTarget('a))', 'a))');
    assertHasRegionTarget('f is', 'f<T>');
  }

  Future<void>
      test_class_fieldFormalParameter_requiredPositional_unresolved() async {
    addTestFile('''
class AAA {
  AAA(this.fff);
}
''');
    await prepareNavigation();
    assertNoRegion('fff);', 3);
  }

  Future<void> test_class_fromSDK() async {
    addTestFile('''
int V = 42;
''');
    await prepareNavigation();
    assertHasRegion('int V');
    var targetIndex = testTargetIndexes[0];
    var target = targets[targetIndex];
    expect(target.startLine, greaterThan(0));
    expect(target.startColumn, greaterThan(0));
  }

  Future<void> test_enum_constant() async {
    addTestFile('''
enum E { a, b }
void f() {
  E.a;
}
''');
    await prepareNavigation();
    assertHasRegion('a;');
    assertHasTarget('a,');
  }

  Future<void> test_enum_constructor_named() async {
    addTestFile('''
const a = 0;

enum E<T> {
  v<int>.named(a); // 1
  E.named(int _) {}
}
''');
    await prepareNavigation();

    assertHasRegionTarget('v<int', 'named(int');
    assertHasRegion('int>');
    assertHasRegionTarget('named(a); // 1', 'named(int');
    assertHasRegionTarget('a); // 1', 'a = 0');

    assertHasRegion('int _');
  }

  Future<void> test_enum_constructor_unnamed() async {
    addTestFile('''
enum E {
  v1,
  v2(),
  v3.new();
  const E();
}
''');
    await prepareNavigation();

    assertHasRegionTarget('v1', 'E();');
    assertHasRegionTarget('v2()', 'E();');
    assertHasRegionTarget('v3', 'E();');
    assertHasRegionTarget('new()', 'E();');
  }

  Future<void> test_enum_field() async {
    addTestFile('''
enum E {
  v;
  final int foo = 0;
  void bar() {
    foo;
    foo = 1;
  }
}
''');
    await prepareNavigation();

    assertHasRegion('int foo');
    assertHasRegionTarget('foo;', 'foo = 0;');
    assertHasRegionTarget('foo = 1;', 'foo = 0;');
  }

  Future<void> test_enum_getter() async {
    addTestFile('''
enum E {
  v;
  int get foo => 0;
  void bar() {
    foo;
  }
}
''');
    await prepareNavigation();

    assertHasRegion('int get');
    assertHasRegionTarget('foo;', 'foo =>');
  }

  Future<void> test_enum_implements() async {
    addTestFile('''
class A {}

enum E implements A { // ref
  v
}
''');
    await prepareNavigation();

    assertHasRegionTarget('A { // ref', 'A {}');
  }

  Future<void> test_enum_index() async {
    addTestFile('''
enum E { a, b }
void f() {
  E.a.index;
}
''');
    await prepareNavigation();
    assertHasRegion('index');
    assertHasTargetInDartCore('index; // Enum');
  }

  Future<void> test_enum_method() async {
    addTestFile('''
enum E {
  v;
  void foo(int a) {}
}
''');
    await prepareNavigation();

    assertHasRegion('int ');
  }

  Future<void> test_enum_setter() async {
    addTestFile('''
enum E {
  v;
  set foo(int _) {}
  void bar() {
    foo = 0;
  }
}
''');
    await prepareNavigation();

    assertHasRegion('int _');
    assertHasRegionTarget('foo = 0;', 'foo(');
  }

  Future<void> test_enum_typeParameter() async {
    addTestFile('''
enum E<T> {
  v(0);
  const E(T t);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('T t', 'T>');
  }

  Future<void> test_enum_values() async {
    addTestFile('''
enum E { a, b }
void f() {
  E.values;
}
''');
    await prepareNavigation();
    assertHasRegion('values');
    assertHasTarget('E');
  }

  Future<void> test_enum_with() async {
    addTestFile('''
mixin M {}

enum E with M { // ref
  v
}
''');
    await prepareNavigation();

    assertHasRegionTarget('M { // ref', 'M {}');
  }

  Future<void> test_extension_on() async {
    addTestFile('''
class C //1
{}
extension E on C //2
{}
''');
    await prepareNavigation();
    assertHasRegion('C //2');
    assertHasTarget('C //1');
  }

  Future<void> test_extensionType() async {
    addTestFile('''
extension type A(int it) {
  void foo() {
    it; // foo()
  }
  static void bar() {}
}
void f(A a) {
  A.it; // f()
  A(0);
  a.foo();
  A.bar();
}
''');
    await prepareNavigation();
    assertHasRegion('int it');
    assertHasRegionTarget('it; // foo()', 'it) {');
    assertHasRegionTarget('A a)', 'A(int');
    assertHasRegionTarget('it; // f()', 'it) {');
    assertHasRegionTarget('A(0);', 'A(int');
    assertHasRegionTarget('foo();', 'foo() {');
    assertHasRegionTarget('A.bar()', 'A(int');
    assertHasRegionTarget('bar();', 'bar() {}');
  }

  Future<void> test_extensionType_primaryConstructor_named() async {
    addTestFile('''
extension type A.named(int it) {
  A.other() : this.named(0);
}

void f() {
  A.named(1);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('A.named(int', 'A.named(int');
    assertHasRegionTarget('named(int', 'named(int');
    assertHasRegion('int it');
    assertHasRegionTarget('it) {', 'it) {');
    assertHasRegionTarget('this.named(0)', 'named(int');
    assertHasRegionTarget('named(0)', 'named(int');
    assertHasRegionTarget('A.named(1)', 'A.named(int');
    assertHasRegionTarget('named(1)', 'named(int');
  }

  Future<void> test_extensionType_primaryConstructor_unnamed() async {
    addTestFile('''
extension type A(int it) {
  A.other() : this(0);
}

void f() {
  A(1);
  A.new(2);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('A(int', 'A(int');
    assertHasRegion('int it');
    assertHasRegionTarget('it) {', 'it) {');
    assertHasRegionTarget('this(0)', 'A(int');
    assertHasRegionTarget('A(1)', 'A(int');
    assertHasRegionTarget('new(2)', 'A(int');
  }

  Future<void> test_extensionType_secondaryConstructor_named() async {
    addTestFile('''
extension type A(int it) {
  A.named() : this(0);
  A.other() : this.named(1);
}

void f() {
  A.named(2);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('A.named() :', 'A(int');
    assertHasRegionTarget('named() :', 'named() :');
    assertHasRegionTarget('this.named(1)', 'named() :');
    assertHasRegionTarget('named(1)', 'named() :');
    assertHasRegionTarget('A.named(2)', 'A(int');
    assertHasRegionTarget('named(2)', 'named() :');
  }

  Future<void> test_functionReference_className_staticMethod() async {
    addTestFile('''
class A {
  static void foo<T>() {}
}
void f() {
  A.foo<A>;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('foo<A>', 'foo<T>');
    assertHasRegionTarget('A>', 'A {');
  }

  Future<void> test_functionReference_function() async {
    addTestFile('''
class A {}
void foo<T>() {}
void f() {
  foo<A>;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('foo<A>', 'foo<T>');
    assertHasRegionTarget('A>', 'A {');
  }

  Future<void> test_functionReference_importPrefix_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo<T>() {}
''');
    addTestFile('''
import 'a.dart' as prefix;
class A {}
void f() {
  prefix.foo<A>;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('prefix.', 'prefix;');
    assertHasRegion('foo<A>');
    assertHasRegionTarget('A>', 'A {');
  }

  Future<void> test_functionReference_instance_method() async {
    addTestFile('''
class A {
  void foo<T>() {}
}
void f(A a) {
  a.foo<A>;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('foo<A>', 'foo<T>');
    assertHasRegionTarget('A>', 'A {');
  }

  Future<void> test_functionReference_method() async {
    addTestFile('''
class A {
  void foo<T>() {}
  void f() {
    foo<A>;
  }
}
''');
    await prepareNavigation();
    assertHasRegionTarget('foo<A>', 'foo<T>');
    assertHasRegionTarget('A>', 'A {');
  }

  Future<void> test_functionReference_staticMethod() async {
    addTestFile('''
class A {
  static void foo<T>() {}
  void f() {
    foo<A>;
  }
}
''');
    await prepareNavigation();
    assertHasRegionTarget('foo<A>', 'foo<T>');
    assertHasRegionTarget('A>', 'A {');
  }

  Future<void> test_identifier_resolved() async {
    addTestFile('''
class AAA {}
void f() {
  AAA aaa = null;
  print(aaa);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('AAA aaa', 'AAA {}');
    assertHasRegionTarget('aaa);', 'aaa = null');
    assertHasRegionTarget('f() {', 'f() {');
  }

  Future<void> test_identifier_unresolved() async {
    addTestFile('''
void f() {
  print(vvv);
}
''');
    await prepareNavigation();
    assertNoRegionString('vvv');
  }

  Future<void> test_identifier_whenStrayImportDirective() async {
    addTestFile('''
void f() {
  int aaa = 42;
  print(aaa);
}
import 'dart:math';
''');
    await prepareNavigation();
    assertHasRegionTarget('aaa);', 'aaa = 42');
  }

  Future<void> test_inComment() async {
    addTestFile('''
class FirstClass {}
class SecondClass {
  /**
   * Return a [FirstClass] object equivalent to this object in every other way.
   */
  convert() {
    return new FirstClass();
  }
}
''');
    await prepareNavigation();
    assertHasRegionTarget('FirstClass]', 'FirstClass {');
    assertHasRegionTarget('FirstClass(', 'FirstClass {');
  }

  Future<void> test_inComment_enumMember_qualified() async {
    addTestFile('''
/// [A.one].
enum A {
  one,
}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('A.', 'A {');
    assertHasRegionTarget('one]', 'one,');
  }

  Future<void> test_inComment_extensionMember() async {
    addTestFile('''
/// [myField]
extension on String {
  String get myField => '';
}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('myField]', 'myField =>');
  }

  Future<void> test_inComment_extensionMember_qualified() async {
    addTestFile('''
/// [StringExtension.myField]
extension StringExtension on String {
  String get myField => '';
}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('StringExtension.', 'StringExtension on');
    assertHasRegionTarget('myField]', 'myField =>');
  }

  Future<void> test_inComment_instanceMember_qualified() async {
    addTestFile('''
/// [A.myField].
class A {
  final String myField = '';
}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('A.', 'A {');
    assertHasRegionTarget('myField]', 'myField =');
  }

  Future<void> test_inComment_instanceMember_qualified_inherited() async {
    addTestFile('''
class A {
  final String myField = '';
}
/// [B.myField].
class B extends A {}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('B.', 'B extends');
    assertHasRegionTarget('myField]', 'myField =');
  }

  Future<void> test_inComment_namedConstructor_qualified() async {
    addTestFile('''
/// [A.named].
class A {
  A.named();
}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('A.named]', 'A {');
    assertHasRegionTarget('named]', 'named(');
  }

  Future<void> test_inComment_staticMember_qualified() async {
    addTestFile('''
/// [A.myStaticField].
class A {
  static final String myStaticField = '';
}
    ''');

    await prepareNavigation();
    assertHasRegionTarget('A.', 'A {');
    assertHasRegionTarget('myStaticField]', 'myStaticField =');
  }

  Future<void> test_instanceCreation_implicit() async {
    addTestFile('''
class A {
}
void f() {
  new A();
}
''');
    await prepareNavigation();
    assertHasRegionString('A()', 'A'.length);
    assertHasTarget('A {');
  }

  Future<void> test_instanceCreation_implicit_withTypeArgument() async {
    addTestFile('''
class A {}
class B<T> {}
void f() {
  new B<A>();
}
''');
    await prepareNavigation();
    {
      assertHasRegion('B<A>', 'B'.length);
      assertHasTarget('B<T> {');
    }
    {
      assertHasRegion('A>();', 'A'.length);
      assertHasTarget('A {');
    }
  }

  Future<void> test_instanceCreation_named() async {
    addTestFile('''
class A {
  A.named() {}
}
void f() {
  new A.named();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('A.named();', 'A'.length);
      assertHasTarget('A {');
    }
    {
      assertHasRegionString('named();', 'named'.length);
      assertHasTarget('named() {}');
    }
  }

  Future<void> test_instanceCreation_named_withTypeArgument() async {
    addTestFile('''
class A {}
class B<T> {
  B.named() {}
}
void f() {
  new B<A>.named();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('B<A>', 'B'.length);
      assertHasTarget('B<T> {');
    }
    {
      assertHasRegion('A>.named');
      assertHasTarget('A {');
    }
    {
      assertHasRegion('named();', 'named'.length);
      assertHasTarget('named() {}');
    }
  }

  Future<void> test_instanceCreation_unnamed() async {
    addTestFile('''
class A {
  A() {}
}
void f() {
  new A();
}
''');
    await prepareNavigation();
    assertHasRegionString('A();', 'A'.length);
    assertHasTarget('A() {}');
  }

  Future<void> test_instanceCreation_unnamed_withTypeArgument() async {
    addTestFile('''
class A {}
class B<T> {
  B() {}
}
void f() {
  new B<A>();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('B<A>();', 'B'.length);
      assertHasTarget('B() {}');
    }
    {
      assertHasRegion('A>();');
      assertHasTarget('A {');
    }
  }

  Future<void> test_instanceCreation_withImportPrefix_named() async {
    addTestFile('''
import 'dart:async' as ppp;
void f() {
  new ppp.Future.value(42);
}
''');
    await prepareNavigation();
    {
      assertHasRegion('ppp.');
      assertHasTarget('ppp;');
    }
    assertHasRegion('Future.value');
    assertHasRegion('value(42)');
  }

  Future<void> test_library() async {
    addTestFile('''
library my.lib;
''');
    await prepareNavigation();
    assertHasRegionString('my.lib');
    assertHasTargetString('my.lib');
  }

  Future<void> test_multiplyDefinedElement() async {
    newFile('$testPackageLibPath/libA.dart', 'library A; int TEST = 1;');
    newFile('$testPackageLibPath/libB.dart', 'library B; int TEST = 2;');
    addTestFile('''
import 'libA.dart';
import 'libB.dart';
void f() {
  TEST;
}
''');
    await prepareNavigation();
    assertNoRegionAt('TEST');
  }

  Future<void> test_namedExpression_name() async {
    addTestFile('''
void f(int a, int b, {int? c, int? d}) {}

void g() {
  f(0, c: 2, 1, d: 3);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('c: 2', 'c,');
    assertHasRegionTarget('d: 3', 'd}) {}');
  }

  Future<void> test_navigation_dart_example_api() async {
    final exampleLinkPath = 'examples/api/lib/test_file.dart';
    final exampleApiFile =
        convertPath(join(workspaceRootPath, exampleLinkPath));
    newFile(exampleApiFile, '/// Test');
    addTestFile('''
/// Dartdoc comment
/// {@tool dartpad}
/// Example description.
///
/// ** See code in $exampleLinkPath **
/// {@end-tool}
const int foo = 0;
''');
    await prepareNavigation();
    assertHasRegion(exampleLinkPath, 31);
    assertHasFileTarget(exampleApiFile, 0, 0);
  }

  Future<void> test_navigation_dart_example_api_multiple() async {
    final exampleLinkPath0 = 'examples/api/lib/test_file.0.dart';
    final exampleLinkPath1 = 'examples/api/lib/test_file.1.dart';
    final exampleApiFile0 =
        convertPath(join(workspaceRootPath, exampleLinkPath0));
    final exampleApiFile1 =
        convertPath(join(workspaceRootPath, exampleLinkPath1));
    newFile(exampleApiFile0, '/// Test 0');
    newFile(exampleApiFile1, '/// Test 1');
    addTestFile('''
/// Dartdoc comment
/// {@tool dartpad}
/// Example description.
///
/// ** See code in $exampleLinkPath0 **
/// {@end-tool}
///
/// {@tool dartpad}
/// Example description.
///
/// ** See code in $exampleLinkPath1 **
/// {@end-tool}
const int foo = 0;
''');
    await prepareNavigation();
    assertHasRegion(exampleLinkPath0, 33);
    assertHasFileTarget(exampleApiFile0, 0, 0);
    assertHasRegion(exampleLinkPath1, 33);
    assertHasFileTarget(exampleApiFile1, 0, 0);
  }

  Future<void> test_objectPattern_patternField_explicitlyNamed() async {
    addTestFile('''
class A {
  int get foo => 0;
}

void f(Object? x) {
  if (x case A(foo: var a)) {}
}
''');
    await prepareNavigation();

    assertHasRegionTarget('foo', 'foo =>');
  }

  Future<void> test_objectPattern_patternField_implicitlyNamed() async {
    addTestFile('''
class A {
  int get foo => 0;
}

void f(Object? x) {
  if (x case A(: var foo)) {}
}
''');
    await prepareNavigation();

    assertHasRegionTarget('foo))', 'foo =>');
  }

  Future<void> test_objectPattern_patternField_notResolved() async {
    addTestFile('''
class A {}

void f(Object? x) {
  if (x case A(foo: var a)) {}
}
''');
    await prepareNavigation();

    assertNoRegionAt('foo:');
  }

  Future<void> test_operator_arithmetic() async {
    addTestFile('''
class A {
  A operator +(other) => null;
  A operator -() => null;
  A operator -(other) => null;
  A operator *(other) => null;
  A operator /(other) => null;
}
void f() {
  var a = new A();
  a - 1;
  a + 2;
  -a; // unary
  --a;
  ++a;
  a--; // mm
  a++; // pp
  a -= 3;
  a += 4;
  a *= 5;
  a /= 6;
}
''');
    await prepareNavigation();
    assertHasOperatorRegion('- 1', 1, '-(other) => null', 1);
    assertHasOperatorRegion('+ 2', 1, '+(other) => null', 1);
    assertHasOperatorRegion('-a; // unary', 1, '-() => null', 1);
    assertHasOperatorRegion('--a;', 2, '-(other) => null', 1);
    assertHasOperatorRegion('++a;', 2, '+(other) => null', 1);
    assertHasOperatorRegion('--; // mm', 2, '-(other) => null', 1);
    assertHasOperatorRegion('++; // pp', 2, '+(other) => null', 1);
    assertHasOperatorRegion('-= 3', 2, '-(other) => null', 1);
    assertHasOperatorRegion('+= 4', 2, '+(other) => null', 1);
    assertHasOperatorRegion('*= 5', 2, '*(other) => null', 1);
    assertHasOperatorRegion('/= 6', 2, '/(other) => null', 1);
  }

  Future<void> test_operator_index() async {
    addTestFile('''
class A {
  A operator +(other) => null;
}
class B {
  A operator [](index) => null;
  operator []=(index, A value) {}
}
void f() {
  var b = new B();
  b[0] // [];
  b[1] = 1; // []=;
  b[2] += 2;
}
''');
    await prepareNavigation();
    assertHasOperatorRegion('[0', 1, '[](index)', 2);
    assertHasOperatorRegion('] // []', 1, '[](index)', 2);
    assertHasOperatorRegion('[1', 1, '[]=(index,', 3);
    assertHasOperatorRegion('] = 1;', 1, '[]=(index,', 3);
    assertHasOperatorRegion('[2', 1, '[]=(index,', 3);
    assertHasOperatorRegion('] += 2;', 1, '[]=(index,', 3);
    assertHasOperatorRegion('+= 2;', 2, '+(other)', 1);
  }

  Future<void> test_partOf() async {
    var libCode = 'library lib; part "test.dart";';
    var libFile = newFile('$testPackageLibPath/lib.dart', libCode).path;
    addTestFile('part of lib;');
    await prepareNavigation();
    assertHasRegionString('lib');
    assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
  }

  Future<void> test_propertyAccess_propertyName_read() async {
    addTestFile('''
class A {
  var f = 0;
}

void f(A a) {
  a.f;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('f;', 'f = 0');
  }

  Future<void> test_propertyAccess_propertyName_write() async {
    addTestFile('''
class A {
  var f = 0;
}

void f(A a) {
  a.f = 1;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('f = 1', 'f = 0');
  }

  Future<void> test_recordPattern_patternField() async {
    addTestFile('''
void f(Object? x) {
  if (x case (foo: var a,)) {}
}
''');
    await prepareNavigation();

    assertNoRegionAt('foo');
  }

  Future<void> test_redirectingConstructorInvocation() async {
    addTestFile('''
class A {
  A() {}
  A.foo() : this();
  A.bar() : this.foo();
}
''');
    await prepareNavigation();
    {
      assertHasRegion('this();');
      assertHasTarget('A() {}');
    }
    {
      assertHasRegion('this.foo');
      assertHasTarget('foo() :');
    }
    {
      assertHasRegion('foo();');
      assertHasTarget('foo() :');
    }
  }

  Future<void> test_string_configuration() async {
    newFile('$testPackageLibPath/lib.dart', '').path;
    var lib2File = newFile('$testPackageLibPath/lib2.dart', '').path;
    newFile(
        testFilePath, 'import "lib.dart" if (dart.library.html) "lib2.dart";');
    await prepareNavigation();
    assertHasRegionString('"lib2.dart"');
    assertHasFileTarget(lib2File, 0, 0);
  }

  Future<void> test_string_export() async {
    var libCode = 'library lib;';
    var libFile = newFile('$testPackageLibPath/lib.dart', libCode).path;
    addTestFile('export "lib.dart";');
    await prepareNavigation();
    assertHasRegionString('"lib.dart"');
    assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
  }

  Future<void> test_string_export_unresolvedUri() async {
    addTestFile('export "no.dart";');
    await prepareNavigation();
    assertNoRegionString('"no.dart"');
  }

  Future<void> test_string_import() async {
    var libCode = 'library lib;';
    var libFile = newFile('$testPackageLibPath/lib.dart', libCode).path;
    addTestFile('import "lib.dart";');
    await prepareNavigation();
    assertHasRegionString('"lib.dart"');
    assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
  }

  Future<void> test_string_import_noUri() async {
    addTestFile('import ;');
    await prepareNavigation();
    assertNoRegionAt('import ;');
  }

  Future<void> test_string_import_unresolvedUri() async {
    addTestFile('import "no.dart";');
    await prepareNavigation();
    assertNoRegionString('"no.dart"');
  }

  Future<void> test_string_part() async {
    var unitCode = 'part of lib;  f() {}';
    var unitFile = newFile('$testPackageLibPath/test_unit.dart', unitCode).path;
    addTestFile('''
library lib;
part "test_unit.dart";
''');
    await prepareNavigation();
    assertHasRegionString('"test_unit.dart"');
    assertHasFileTarget(unitFile, 0, 0);
  }

  Future<void> test_string_part_hasSource_notPart() async {
    addTestFile('''
library lib;
part "test_unit.dart";
''');
    await prepareNavigation();
    assertHasRegionString('"test_unit.dart"');
  }

  Future<void> test_string_part_invalidUri() async {
    addTestFile('''
part ":[invalid]";
''');
    await prepareNavigation();
    assertNoRegionString('":[invalid]"');
  }

  Future<void> test_superConstructorInvocation() async {
    addTestFile('''
class A {
  A() {}
  A.named() {}
}
class B extends A {
  B() : super();
  B.named() : super.named();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('super');
      assertHasTarget('A() {}');
    }
    {
      assertHasRegion('super.named');
      assertHasTarget('named() {}');
    }
    {
      assertHasRegion('named();');
      assertHasTarget('named() {}');
    }
  }

  Future<void> test_superConstructorInvocation_synthetic() async {
    addTestFile('''
class A {
}
class B extends A {
  B() : super();
}
''');
    await prepareNavigation();
    assertHasRegionString('super');
    assertHasTarget('A {');
  }

  Future<void> test_superFormalParameter_requiredNamed() async {
    addTestFile('''
class A {
  A({required int a});
}
class B extends A {
  B({required super.a}) : assert(a > 0);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('a}) :', 'a});');
    assertHasRegionTarget('a > 0', 'a}) :');
  }

  Future<void> test_superFormalParameter_requiredPositional() async {
    addTestFile('''
class A {
  A(int a);
}
class B extends A {
  B(super.a) : assert(a > 0);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('super.a', 'a);');
    assertHasRegionTarget('a) :', 'a);');
    assertHasRegionTarget('a > 0', 'a) :');
  }

  Future<void>
      test_superFormalParameter_requiredPositional_functionTyped() async {
    addTestFile('''
class A {
  A(Object a); // 0
}
class B extends A {
  B(int super.a<T>(T b)) : assert(a is Object);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('a<T>', 'a); // 0');
    assertHasRegion('int ');
    assertHasRegionTarget('T>', 'T>');
    assertHasRegionTarget('T b', 'T>');
    assertHasRegionTarget('b))', 'b))');
    assertHasRegionTarget('b))', 'b))');
    assertHasRegionTarget('a is', 'a<T>');
  }

  Future<void> test_superFormalParameter_requiredPositional_unresolved() async {
    addTestFile('''
class A {}
class B extends A {
  B(super.a); // 1
}
''');
    await prepareNavigation();
    assertNoRegionAt('a); // 1');
  }

  Future<void> test_targetElement() async {
    addTestFile('''
class AAA {}
void f() {
  AAA aaa = null;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('AAA aaa', 'AAA {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_targetElement_typedef_functionType() async {
    addTestFile('''
typedef A = void Function();

void f(A a) {}
''');
    await prepareNavigation();
    assertHasRegionTarget('A a', 'A =');
    expect(testTarget.kind, ElementKind.TYPE_ALIAS);
  }

  Future<void> test_targetElement_typedef_interfaceType() async {
    addTestFile('''
typedef A = List<int>;

void f(A a) {}
''');
    await prepareNavigation();
    assertHasRegionTarget('A a', 'A =');
    expect(testTarget.kind, ElementKind.TYPE_ALIAS);
  }

  Future<void> test_type_dynamic() async {
    addTestFile('''
void f() {
  dynamic v = null;
}
''');
    await prepareNavigation();
    assertNoRegionAt('dynamic');
  }

  Future<void> test_type_void() async {
    addTestFile('''
void f() {
}
''');
    await prepareNavigation();
    assertNoRegionAt('void');
  }

  Future<void> test_var_declaredVariable() async {
    addTestFile('''
class C {}
f(List<C> items) {
  for (var item in items) {}
}
''');
    await prepareNavigation();
    assertHasRegionTarget('var', 'C {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_var_localVariable_multiple_inferred_different() async {
    addTestFile('''
class A {}
class B {}
void f() {
  var a = new A(), b = new B();
}
''');
    await prepareNavigation();
    assertNoRegionAt('var');
  }

  Future<void> test_var_localVariable_multiple_inferred_same() async {
    addTestFile('''
class C {}
void f() {
  var a = new C(), b = new C();
}
''');
    await prepareNavigation();
    assertHasRegionTarget('var', 'C {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_var_localVariable_single_inferred() async {
    addTestFile('''
class C {}
f() {
  var c = new C();
}
''');
    await prepareNavigation();
    assertHasRegionTarget('var', 'C {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_var_localVariable_single_notInferred() async {
    addTestFile('''
f() {
  var x;
}
''');
    await prepareNavigation();
    assertNoRegionAt('var');
  }

  Future<void> test_var_topLevelVariable_multiple_inferred_different() async {
    addTestFile('''
class A {}
class B {}
var a = new A(), b = new B();
''');
    await prepareNavigation();
    assertNoRegionAt('var');
  }

  Future<void> test_var_topLevelVariable_multiple_inferred_same() async {
    addTestFile('''
class C {}
var a = new C(), b = new C();
''');
    await prepareNavigation();
    assertHasRegionTarget('var', 'C {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_var_topLevelVariable_single_inferred() async {
    addTestFile('''
class C {}
var c = new C();
''');
    await prepareNavigation();
    assertHasRegionTarget('var', 'C {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_var_topLevelVariable_single_notInferred() async {
    addTestFile('''
var x;
''');
    await prepareNavigation();
    assertNoRegionAt('var');
  }
}
