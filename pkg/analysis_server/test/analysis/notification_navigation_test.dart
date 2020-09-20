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

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationNavigationTest);
  });
}

class AbstractNavigationTest extends AbstractAnalysisTest {
  List<NavigationRegion> regions;
  List<NavigationTarget> targets;
  List<String> targetFiles;

  NavigationRegion testRegion;
  List<int> testTargetIndexes;
  List<NavigationTarget> testTargets;
  NavigationTarget testTarget;

  /// Validates that there is a target in [testTargetIndexes] with [file],
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
  void assertHasRegionTarget(String regionSearch, String targetSearch) {
    assertHasRegion(regionSearch);
    assertHasTarget(targetSearch);
  }

  /// Validates that there is a target in [testTargets]  with [testFile], at the
  /// offset of [search] in [testFile], and with the given [length] or the
  /// length of an leading identifier in [search].
  void assertHasTarget(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    assertHasFileTarget(testFile, offset, length);
  }

  /// Validates that there is a target in [testTargets]  with [testFile], at the
  /// offset of [str] in [testFile], and with the length of  [str].
  void assertHasTargetString(String str) {
    assertHasTarget(str, str.length);
  }

  /// Validates that there is no a region at [search] and with the given
  /// [length].
  void assertNoRegion(String search, int length) {
    var offset = findOffset(search);
    findRegion(offset, length, false);
  }

  /// Validates that there is no a region at [search] with any length.
  void assertNoRegionAt(String search) {
    var offset = findOffset(search);
    findRegion(offset, -1, false);
  }

  /// Validates that there is no a region for [search] string.
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
        fail('$lastEnd was expected to be > $offset in\n' + regions.join('\n'));
      }
      lastEnd = offset + region.length;
    }
  }

  /// Finds the navigation region with the given [offset] and [length].
  /// If [length] is `-1`, then it is ignored.
  ///
  /// If [exists] is `true`, then fails if such region does not exist.
  /// Otherwise remembers this it into [testRegion].
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

  Future prepareNavigation() async {
    addAnalysisSubscription(AnalysisService.NAVIGATION, testFile);
    await _resultsAvailable.future;
    assertRegionsSorted();
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
      var params = AnalysisNavigationParams.fromNotification(notification);
      if (params.file == testFile) {
        regions = params.regions;
        targets = params.targets;
        targetFiles = params.files;
        _resultsAvailable.complete();
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
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

  Future<void> test_annotationConstructor_implicit() async {
    addTestFile('''
class A {
}
@A()
main() {
}
''');
    await prepareNavigation();
    assertHasRegionString('A()', 'A'.length);
    assertHasTarget('A {');
  }

  Future<void> test_annotationConstructor_importPrefix() async {
    newFile(join(testFolder, 'my_annotation.dart'), content: r'''
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
main() {
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
main() {
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
main() {
}
''');
    await prepareNavigation();
    assertHasRegionString('A()', 'A'.length);
    assertHasTarget('A();', 0);
  }

  Future<void> test_annotationField() async {
    addTestFile('''
const myan = new Object();
@myan // ref
main() {
}
''');
    await prepareNavigation();
    assertHasRegion('myan // ref');
    assertHasTarget('myan = new Object();');
  }

  Future<void> test_annotationField_importPrefix() async {
    newFile(join(testFolder, 'mayn.dart'), content: r'''
library an;
const myan = new Object();
''');
    addTestFile('''
import 'mayn.dart' as man;
@man.myan // ref
main() {
}
''');
    await prepareNavigation();
    assertHasRegion('myan // ref');
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

  Future<void> test_constructor_named() async {
    addTestFile('''
class A {
  A.named(BBB p) {}
}
class BBB {}
''');
    await prepareNavigation();
    // has region for complete "A.named"
    assertHasRegionString('A.named');
    assertHasTarget('named(BBB');
    // no separate regions for "A" and "named"
    assertNoRegion('A.named(', 'A'.length);
    assertNoRegion('named(', 'named'.length);
    // validate that we don't forget to resolve parameters
    assertHasRegionTarget('BBB p', 'BBB {}');
  }

  Future<void> test_constructor_unnamed() async {
    addTestFile('''
class A {
  A(BBB p) {}
}
class BBB {}
''');
    await prepareNavigation();
    // has region for complete "A.named"
    assertHasRegion('A(BBB');
    assertHasTarget('A(BBB', 0);
    // validate that we don't forget to resolve parameters
    assertHasRegionTarget('BBB p', 'BBB {}');
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

  Future<void> test_factoryRedirectingConstructor_implicit() async {
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
      test_factoryRedirectingConstructor_implicit_withTypeArgument() async {
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

  Future<void> test_factoryRedirectingConstructor_named() async {
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
      assertHasTarget('named();');
    }
    {
      assertHasRegionString('named;', 'named'.length);
      assertHasTarget('named();');
    }
  }

  Future<void>
      test_factoryRedirectingConstructor_named_withTypeArgument() async {
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
      assertHasTarget('named() {}');
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

  Future<void> test_factoryRedirectingConstructor_unnamed() async {
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
    assertHasTarget('B() {}', 0);
  }

  Future<void>
      test_factoryRedirectingConstructor_unnamed_withTypeArgument() async {
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
      assertHasTarget('C() {}', 0);
    }
    {
      assertHasRegion('A>;');
      assertHasTarget('A {');
    }
  }

  Future<void> test_factoryRedirectingConstructor_unresolved() async {
    addTestFile('''
class A {
  factory A() = B;
}
''');
    await prepareNavigation();
    // don't check regions, but there should be no exceptions
  }

  Future<void> test_fieldFormalParameter() async {
    addTestFile('''
class AAA {
  int fff = 123;
  AAA(this.fff);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('fff);', 'fff = 123');
  }

  Future<void> test_fieldFormalParameter_unresolved() async {
    addTestFile('''
class AAA {
  AAA(this.fff);
}
''');
    await prepareNavigation();
    assertNoRegion('fff);', 3);
  }

  Future<void> test_identifier_resolved() async {
    addTestFile('''
class AAA {}
main() {
  AAA aaa = null;
  print(aaa);
}
''');
    await prepareNavigation();
    assertHasRegionTarget('AAA aaa', 'AAA {}');
    assertHasRegionTarget('aaa);', 'aaa = null');
    assertHasRegionTarget('main() {', 'main() {');
  }

  Future<void> test_identifier_unresolved() async {
    addTestFile('''
main() {
  print(vvv);
}
''');
    await prepareNavigation();
    assertNoRegionString('vvv');
  }

  Future<void> test_identifier_whenStrayImportDirective() async {
    addTestFile('''
main() {
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

  Future<void> test_instanceCreation_implicit() async {
    addTestFile('''
class A {
}
main() {
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
main() {
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
main() {
  new A.named();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('A.named();', 'A'.length);
      assertHasTarget('named() {}');
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
main() {
  new B<A>.named();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('B<A>', 'B'.length);
      assertHasTarget('named() {}');
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
main() {
  new A();
}
''');
    await prepareNavigation();
    assertHasRegionString('A();', 'A'.length);
    assertHasTarget('A() {}', 0);
  }

  Future<void> test_instanceCreation_unnamed_withTypeArgument() async {
    addTestFile('''
class A {}
class B<T> {
  B() {}
}
main() {
  new B<A>();
}
''');
    await prepareNavigation();
    {
      assertHasRegionString('B<A>();', 'B'.length);
      assertHasTarget('B() {}', 0);
    }
    {
      assertHasRegion('A>();');
      assertHasTarget('A {');
    }
  }

  Future<void> test_instanceCreation_withImportPrefix_named() async {
    addTestFile('''
import 'dart:async' as ppp;
main() {
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
    newFile('$projectPath/bin/libA.dart', content: 'library A; int TEST = 1;');
    newFile('$projectPath/bin/libB.dart', content: 'library B; int TEST = 2;');
    addTestFile('''
import 'libA.dart';
import 'libB.dart';
main() {
  TEST;
}
''');
    await prepareNavigation();
    assertNoRegionAt('TEST');
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
main() {
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
main() {
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
    var libFile = newFile('$projectPath/bin/lib.dart', content: libCode).path;
    addTestFile('part of lib;');
    await prepareNavigation();
    assertHasRegionString('lib');
    assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
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
      assertHasTarget('A() {}', 0);
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
    newFile('$projectPath/bin/lib.dart', content: '').path;
    var lib2File = newFile('$projectPath/bin/lib2.dart', content: '').path;
    addTestFile('import "lib.dart" if (dart.library.html) "lib2.dart";');
    await prepareNavigation();
    assertHasRegionString('"lib2.dart"');
    assertHasFileTarget(lib2File, 0, 0);
  }

  Future<void> test_string_export() async {
    var libCode = 'library lib;';
    var libFile = newFile('$projectPath/bin/lib.dart', content: libCode).path;
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
    var libFile = newFile('$projectPath/bin/lib.dart', content: libCode).path;
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
    var unitFile =
        newFile('$projectPath/bin/test_unit.dart', content: unitCode).path;
    addTestFile('''
library lib;
part "test_unit.dart";
''');
    await prepareNavigation();
    assertHasRegionString('"test_unit.dart"');
    assertHasFileTarget(unitFile, 0, 0);
  }

  Future<void> test_string_part_invalidUri() async {
    addTestFile('''
part ":[invalid]";
''');
    await prepareNavigation();
    assertNoRegionString('":[invalid]"');
  }

  Future<void> test_string_part_unresolvedUri() async {
    addTestFile('''
library lib;
part "test_unit.dart";
''');
    await prepareNavigation();
    assertNoRegionString('"test_unit.dart"');
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
      assertHasTarget('A() {}', 0);
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

  Future<void> test_targetElement() async {
    addTestFile('''
class AAA {}
main() {
  AAA aaa = null;
}
''');
    await prepareNavigation();
    assertHasRegionTarget('AAA aaa', 'AAA {}');
    expect(testTarget.kind, ElementKind.CLASS);
  }

  Future<void> test_type_dynamic() async {
    addTestFile('''
main() {
  dynamic v = null;
}
''');
    await prepareNavigation();
    assertNoRegionAt('dynamic');
  }

  Future<void> test_type_void() async {
    addTestFile('''
void main() {
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
