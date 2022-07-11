// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_call_hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CallHierarchyComputerFindTargetTest);
    defineReflectiveTests(CallHierarchyComputerIncomingCallsTest);
    defineReflectiveTests(CallHierarchyComputerOutgoingCallsTest);
  });
}

/// Matches a [CallHierarchyItem] with the given name/kind/file.
Matcher _isItem(CallHierarchyKind kind, String displayName, String file,
        SourceRange range) =>
    TypeMatcher<CallHierarchyItem>()
        .having((e) => e.kind, 'kind', kind)
        .having((e) => e.displayName, 'displayName', displayName)
        .having((e) => e.file, 'file', file)
        .having((e) => e.range, 'range', range);

/// Matches a [CallHierarchyCalls] result with the given element/ranges.
Matcher _isResult(
  CallHierarchyKind kind,
  String displayName,
  String file,
  SourceRange range, {
  List<SourceRange>? ranges,
}) {
  var matcher = TypeMatcher<CallHierarchyCalls>()
      .having((c) => c.item, 'item', _isItem(kind, displayName, file, range));

  if (ranges != null) {
    matcher = matcher.having((c) => c.ranges, 'ranges', ranges);
  }

  return matcher;
}

abstract class AbstractCallHierarchyTest extends AbstractSingleUnitTest {
  final startOfFile = SourceRange(0, 0);

  // Gets the expected range that follows the string [prefix] in [code] with a
  // length of [match.length].
  SourceRange rangeAfterPrefix(String prefix, String code, String match) =>
      SourceRange(
          withoutMarkers(code).indexOf(prefix) + prefix.length, match.length);

  // Gets the expected range that starts at [search] in [code] with a
  // length of [match.length].
  SourceRange rangeAtSearch(String search, String code, [String? match]) {
    final index = withoutMarkers(code).indexOf(search);
    expect(index, greaterThanOrEqualTo(0));
    return SourceRange(index, (match ?? search).length);
  }

  String withoutMarkers(String code) => code.replaceAll('^', '');
}

@reflectiveTest
class CallHierarchyComputerFindTargetTest extends AbstractCallHierarchyTest {
  late String otherFile;

  Future<void> expectNoTarget(String content) async {
    await expectTarget(content, isNull);
  }

  Future<void> expectTarget(String content, Matcher matcher) async {
    final target = await findTarget(content);
    expect(target, matcher);
  }

  Future<CallHierarchyItem?> findTarget(String code) async {
    final marker = code.indexOf('^');
    expect(marker, greaterThanOrEqualTo(0));
    addTestSource(withoutMarkers(code));
    final result =
        await (await session).getResolvedUnit(testFile) as ResolvedUnitResult;

    return DartCallHierarchyComputer(result).findTarget(marker);
  }

  @override
  void setUp() {
    super.setUp();
    otherFile = convertPath('$testPackageLibPath/other.dart');
  }

  Future<void> test_args() async {
    await expectNoTarget('main(int ^a) {}');
  }

  Future<void> test_block() async {
    await expectNoTarget('f() {^}');
  }

  Future<void> test_comment() async {
    await expectNoTarget('f() {} // this is a ^comment');
  }

  Future<void> test_constructor() async {
    final contents = '''
class Foo {
  Fo^o(String a) {}
}
    ''';

    final target = await findTarget(contents);
    expect(
      target,
      _isItem(
        CallHierarchyKind.constructor,
        'Foo',
        testFile,
        rangeAtSearch('Foo(', contents, 'Foo'),
      ),
    );
  }

  Future<void> test_constructorCall() async {
    final contents = '''
import 'other.dart';

f() {
  final foo = Fo^o();
}
    ''';

    final otherContents = '''
class Foo {
  Foo();
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo',
          otherFile,
          rangeAtSearch('Foo(', otherContents, 'Foo'),
        ));
  }

  Future<void> test_extension_method() async {
    final contents = '''
extension StringExtension on String {
  void myMet^hod() {}
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          testFile,
          rangeAtSearch('myMethod', contents),
        ));
  }

  Future<void> test_extension_methodCall() async {
    final contents = '''
import 'other.dart';

f() {
  ''.myMet^hod();
}
    ''';

    final otherContents = '''
extension StringExtension on String {
  void myMethod() {}
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          otherFile,
          rangeAtSearch('myMethod', otherContents),
        ));
  }

  Future<void> test_function() async {
    final contents = '''
void myFun^ction() {}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.function,
          'myFunction',
          testFile,
          rangeAtSearch('myFunction', contents),
        ));
  }

  Future<void> test_functionCall() async {
    final contents = '''
import 'other.dart' as f;

f() {
  f.myFun^ction();
}
    ''';

    final otherContents = '''
void myFunction() {}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.function,
          'myFunction',
          otherFile,
          rangeAtSearch('myFunction', otherContents),
        ));
  }

  Future<void> test_getter() async {
    final contents = '''
class Foo {
  String get fo^o => '';
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'get foo',
          testFile,
          rangeAtSearch('foo', contents),
        ));
  }

  Future<void> test_getterCall() async {
    final contents = '''
import 'other.dart';

f() {
  final foo = ba^r;
}
    ''';

    final otherContents = '''
String get bar => '';
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'get bar',
          otherFile,
          rangeAtSearch('bar', otherContents),
        ));
  }

  Future<void> test_implicitConstructorCall() async {
    // Even if a constructor is implicit, we might want to be able to get the
    // incoming calls, so we should return the class location as a stand-in
    // (although with the Kind still set to constructor).
    final contents = '''
import 'other.dart';

f() {
  final foo = Fo^o();
}
    ''';

    final otherContents = '''
class Foo {}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo',
          otherFile,
          rangeAtSearch('Foo {', otherContents, 'Foo'),
        ));
  }

  Future<void> test_method() async {
    final contents = '''
class Foo {
  void myMet^hod() {}
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          testFile,
          rangeAtSearch('myMethod', contents),
        ));
  }

  Future<void> test_methodCall() async {
    final contents = '''
import 'other.dart';

f() {
  Foo().myMet^hod();
}
    ''';

    final otherContents = '''
class Foo {
  void myMethod() {}
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          otherFile,
          rangeAtSearch('myMethod', otherContents),
        ));
  }

  Future<void> test_mixin_method() async {
    final contents = '''
mixin Bar {
  void myMet^hod() {}
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          testFile,
          rangeAtSearch('myMethod', contents),
        ));
  }

  Future<void> test_mixin_methodCall() async {
    final contents = '''
import 'other.dart';

f() {
  Foo().myMet^hod();
}
    ''';

    final otherContents = '''
class Bar {
  void myMethod() {}
}

class Foo with Bar {}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          otherFile,
          rangeAtSearch('myMethod', otherContents),
        ));
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
class Foo {
  Foo.Ba^r(String a) {}
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo.Bar',
          testFile,
          rangeAtSearch('Bar', contents),
        ));
  }

  Future<void> test_namedConstructor_typeName() async {
    final contents = '''
class Foo {
  Fo^o.Bar(String a) {}
}
    ''';

    await expectNoTarget(contents);
  }

  Future<void> test_namedConstructorCall() async {
    final contents = '''
import 'other.dart';

f() {
  final foo = Foo.Ba^r();
}
    ''';

    final otherContents = '''
class Foo {
  Foo.Bar();
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo.Bar',
          otherFile,
          rangeAtSearch('Bar', otherContents),
        ));
  }

  Future<void> test_namedConstructorCall_typeName() async {
    final contents = '''
import 'other.dart';

f() {
  final foo = Fo^o.Bar();
}
    ''';

    final otherContents = '''
class Foo {
  Foo.Bar();
}
    ''';

    addSource(otherFile, otherContents);
    await expectNoTarget(contents);
  }

  Future<void> test_setter() async {
    final contents = '''
class Foo {
  set fo^o(Strin value) {};
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'set foo',
          testFile,
          rangeAtSearch('foo', contents),
        ));
  }

  Future<void> test_setterCall() async {
    final contents = '''
import 'other.dart';

f() {
  ba^r = '';
}
    ''';

    final otherContents = '''
set bar(String value) {}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'set bar',
          otherFile,
          rangeAtSearch('bar', otherContents),
        ));
  }

  Future<void> test_whitespace() async {
    await expectNoTarget(' ^  f() {}');
  }
}

@reflectiveTest
class CallHierarchyComputerIncomingCallsTest extends AbstractCallHierarchyTest {
  late String otherFile;
  late SearchEngine searchEngine;

  Future<List<CallHierarchyCalls>> findIncomingCalls(String code) async {
    final marker = code.indexOf('^');
    expect(marker, greaterThanOrEqualTo(0));
    addTestSource(withoutMarkers(code));
    final session_ = await session;

    var result = await session_.getResolvedUnit(testFile) as ResolvedUnitResult;
    expect(result.errors, isEmpty);
    var computer = DartCallHierarchyComputer(result);
    // It's possible that the target is in a different file (because we were
    // invoked on a call and not a declaration), so fetch the resolved unit
    // for the target.
    final target = computer.findTarget(marker)!;
    if (target.file != testFile) {
      result =
          await session_.getResolvedUnit(target.file) as ResolvedUnitResult;
      expect(result.errors, isEmpty);
      computer = DartCallHierarchyComputer(result);
    }
    return computer.findIncomingCalls(target, searchEngine);
  }

  @override
  void setUp() {
    super.setUp();
    otherFile = convertPath('$testPackageLibPath/other.dart');
    searchEngine = SearchEngineImpl([
      driverFor(testPackageRootPath),
    ]);
  }

  Future<void> test_constructor() async {
    final contents = '''
class Foo {
  Fo^o();
}
    ''';

    final otherContents = '''
import 'test.dart';

final foo1 = Foo();
class Bar {
  final foo2 = Foo();
  Foo get foo3 => Foo();
  Bar() {
    final foo4 = Foo();
  }
  void bar() {
    final foo5 = Foo();
    final foo6 = Foo();
  }
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'Foo');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile, startOfFile,
            ranges: [
              rangeAfter('foo1 = '),
            ]),
        _isResult(CallHierarchyKind.class_, 'Bar', otherFile,
            rangeAtSearch('Bar {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('foo2 = '),
            ]),
        _isResult(CallHierarchyKind.property, 'foo3', otherFile,
            rangeAtSearch('foo3', otherContents),
            ranges: [
              rangeAfter('foo3 => '),
            ]),
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            rangeAtSearch('Bar() {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('foo4 = '),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            rangeAtSearch('bar() {', otherContents, 'bar'),
            ranges: [
              rangeAfter('foo5 = '),
              rangeAfter('foo6 = '),
            ]),
      ]),
    );
  }

  Future<void> test_extension_method() async {
    final contents = '''
extension StringExtension on String {
  void myMet^hod() {}
}
    ''';

    final otherContents = '''
import 'test.dart';

void f() {
  ''.myMethod();
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'myMethod');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', otherFile,
            rangeAtSearch('f() {', otherContents, 'f'),
            ranges: [
              rangeAfter("''."),
            ]),
      ]),
    );
  }

  Future<void> test_function() async {
    final contents = '''
String myFun^ction() => '';
    ''';

    final otherContents = '''
import 'test.dart';

final foo1 = myFunction();

class Bar {
  final foo2 = myFunction();
  String get foo3 => myFunction();
  Bar() {
    final foo4 = myFunction();
  }
  void bar() {
    final foo5 = myFunction();
    final foo6 = myFunction();
  }
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'myFunction');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile, startOfFile,
            ranges: [
              rangeAfter('foo1 = '),
            ]),
        _isResult(CallHierarchyKind.class_, 'Bar', otherFile,
            rangeAtSearch('Bar {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('foo2 = '),
            ]),
        _isResult(CallHierarchyKind.property, 'foo3', otherFile,
            rangeAtSearch('foo3', otherContents),
            ranges: [
              rangeAfter('foo3 => '),
            ]),
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            rangeAtSearch('Bar() {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('foo4 = '),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            rangeAtSearch('bar() {', otherContents, 'bar'),
            ranges: [
              rangeAfter('foo5 = '),
              rangeAfter('foo6 = '),
            ]),
      ]),
    );
  }

  Future<void> test_getter() async {
    final contents = '''
String get f^oo => '';
    ''';

    final otherContents = '''
import 'test.dart';

final foo1 = foo;
class Bar {
  final foo2 = foo;
  Foo get foo3 => foo;
  Bar() {
    final foo4 = foo;
  }
  void bar() {
    final foo5 = foo;
    final foo6 = foo;
  }
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'foo');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile, startOfFile,
            ranges: [
              rangeAfter('foo1 = '),
            ]),
        _isResult(CallHierarchyKind.class_, 'Bar', otherFile,
            rangeAtSearch('Bar {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('foo2 = '),
            ]),
        _isResult(CallHierarchyKind.property, 'foo3', otherFile,
            rangeAtSearch('foo3', otherContents),
            ranges: [
              rangeAfter('foo3 => '),
            ]),
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            rangeAtSearch('Bar() {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('foo4 = '),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            rangeAtSearch('bar() {', otherContents, 'bar'),
            ranges: [
              rangeAfter('foo5 = '),
              rangeAfter('foo6 = '),
            ]),
      ]),
    );
  }

  Future<void> test_implicitConstructor() async {
    // We still expect to be able to navigate with implicit constructors. This
    // is done by the target being the class, but with a kind of Constructor.
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

f() {
  final foo1 = Fo^o();
}
    ''';

    final otherContents = '''
class Foo {}

final foo2 = Foo();
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix, String code) =>
        rangeAfterPrefix(prefix, code, 'Foo');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', testFile,
            rangeAtSearch('f() {', contents, 'f'),
            ranges: [
              rangeAfter('foo1 = ', contents),
            ]),
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile, startOfFile,
            ranges: [
              rangeAfter('foo2 = ', otherContents),
            ]),
      ]),
    );
  }

  Future<void> test_method() async {
    final contents = '''
class Foo {
  void myMet^hod() {}
}
    ''';

    final otherContents = '''
import 'test.dart';

void f() {
  Foo().myMethod();
  final tearoff = Foo().myMethod;
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'myMethod');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', otherFile,
            rangeAtSearch('f() {', otherContents, 'f'),
            ranges: [
              rangeAfter('Foo().'),
              rangeAfter('tearoff = Foo().'),
            ]),
      ]),
    );
  }

  Future<void> test_mixin_method() async {
    final contents = '''
mixin Bar {
  void myMet^hod() {}
}

class Foo with Bar {}
    ''';

    final otherContents = '''
import 'test.dart';

void f() {
  Foo().myMethod();
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'myMethod');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', otherFile,
            rangeAtSearch('f() {', otherContents, 'f'),
            ranges: [
              rangeAfter('Foo().'),
            ]),
      ]),
    );
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
class Foo {
  Foo.B^ar();
}
    ''';

    final otherContents = '''
import 'test.dart';

f() {
  final foo = Foo.Bar();
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'Bar');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', otherFile,
            rangeAtSearch('f() {', otherContents, 'f'),
            ranges: [
              rangeAfter('foo = Foo.'),
            ]),
      ]),
    );
  }

  Future<void> test_setter() async {
    final contents = '''
set fo^o(String value) {}
    ''';

    final otherContents = '''
import 'test.dart';

class Bar {
  Bar() {
    /*1*/foo = '';
  }
  void bar() {
    /*2*/foo = '';
    /*3*/foo = '';
  }
}
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'foo');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            rangeAtSearch('Bar() {', otherContents, 'Bar'),
            ranges: [
              rangeAfter('/*1*/'),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            rangeAtSearch('bar() {', otherContents, 'bar'),
            ranges: [
              rangeAfter('/*2*/'),
              rangeAfter('/*3*/'),
            ]),
      ]),
    );
  }
}

@reflectiveTest
class CallHierarchyComputerOutgoingCallsTest extends AbstractCallHierarchyTest {
  late String otherFile;

  Future<List<CallHierarchyCalls>> findOutgoingCalls(String code) async {
    final marker = code.indexOf('^');
    expect(marker, greaterThanOrEqualTo(0));
    addTestSource(withoutMarkers(code));
    final session_ = await session;

    var result = await session_.getResolvedUnit(testFile) as ResolvedUnitResult;
    expect(result.errors, isEmpty);
    var computer = DartCallHierarchyComputer(result);
    // It's possible that the target is in a different file (because we were
    // invoked on a call and not a declaration), so fetch the resolved unit
    // for the target.
    final target = computer.findTarget(marker)!;
    if (target.file != testFile) {
      result =
          await session_.getResolvedUnit(target.file) as ResolvedUnitResult;
      expect(result.errors, isEmpty);
      computer = DartCallHierarchyComputer(result);
    }
    return computer.findOutgoingCalls(target);
  }

  @override
  void setUp() {
    super.setUp();
    otherFile = convertPath('$testPackageLibPath/other.dart');
  }

  Future<void> test_constructor() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

class Foo {
  Fo^o() {
    final a = A();
    final constructorTearoffA = A.new;
    final b = B();
    final constructorTearoffB = B.new;
  }
}
    ''';

    final otherContents = '''
class A {
  A();
}

class B {
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A', otherFile,
            rangeAtSearch('A();', otherContents, 'A'),
            ranges: [
              rangeAtSearch('A()', contents, 'A'),
              rangeAfterPrefix('constructorTearoffA = A.', contents, 'new'),
            ]),
        _isResult(CallHierarchyKind.constructor, 'B', otherFile,
            rangeAtSearch('B {', otherContents, 'B'),
            ranges: [
              rangeAtSearch('B()', contents, 'B'),
              rangeAfterPrefix('constructorTearoffB = B.', contents, 'new'),
            ]),
      ]),
    );
  }

  Future<void> test_extension_method() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

extension StringExtension on String {
  void fo^o() {
    ''.bar();
    final tearoff = ''.bar;
  }
}
    ''';

    final otherContents = '''
extension StringExtension on String {
  bar() {}
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            rangeAtSearch('bar() {', otherContents, 'bar'),
            ranges: [
              rangeAtSearch('bar();', contents, 'bar'),
              rangeAtSearch('bar;', contents, 'bar'),
            ]),
      ]),
    );
  }

  Future<void> test_function() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

void fo^o() {
  void nested() {
    f(); // not a call of 'foo'
  }
  f(); // 1
  final tearoff = f;
  nested();
  final nestedTearoff = nested;
}
    ''';

    final otherContents = '''
void f() {}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', otherFile,
            rangeAtSearch('f() {', otherContents, 'f'),
            ranges: [
              rangeAtSearch('f(); // 1', contents, 'f'),
              rangeAfterPrefix('tearoff = ', contents, 'f'),
            ]),
        _isResult(CallHierarchyKind.function, 'nested', testFile,
            rangeAtSearch('nested() {', contents, 'nested'),
            ranges: [
              rangeAtSearch('nested();', contents, 'nested'),
              rangeAfterPrefix('nestedTearoff = ', contents, 'nested'),
            ]),
      ]),
    );
  }

  Future<void> test_getter() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

String get fo^o {
  final a = A();
  final b = a.b;
  final c = A().b;
  return '';
}
    ''';

    final otherContents = '''
class A {
  String get b => '';
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A', otherFile,
            rangeAtSearch('A {', otherContents, 'A')),
        _isResult(CallHierarchyKind.property, 'get b', otherFile,
            rangeAtSearch('b => ', otherContents, 'b'),
            ranges: [
              rangeAfterPrefix('a.', contents, 'b'),
              rangeAfterPrefix('A().', contents, 'b'),
            ]),
      ]),
    );
  }

  Future<void> test_implicitConstructor() async {
    // We can still begin navigating from an implicit constructor (so we can
    // search for inbound calls), so we should ensure that trying to fetch
    // outbound calls returns empty (and doesn't fail).
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

f() {
  final foo1 = Fo^o();
}
    ''';

    final otherContents = '''
class Foo {}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(calls, isEmpty);
  }

  Future<void> test_method() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

class Foo {
  void fo^o() {
    final a = A();
    a.bar();
    final tearoff = a.bar;
    // non-calls
    var x = 1;
    var y = x;
    a.field;
  }
}
    ''';

    final otherContents = '''
class A {
  String field;
  void bar() {}
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A', otherFile,
            rangeAtSearch('A {', otherContents, 'A')),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            rangeAtSearch('bar() {', otherContents, 'bar'),
            ranges: [
              rangeAfterPrefix('a.', contents, 'bar'),
              rangeAfterPrefix('tearoff = a.', contents, 'bar'),
            ]),
      ]),
    );
  }

  Future<void> test_mixin_method() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

mixin MyMixin {
  void f^() {
    final a = A();
    a.foo();
    A().foo();
    final tearoff = a.foo;
  }
}
    ''';

    final otherContents = '''
mixin OtherMixin {
  void foo() {}
}

class A with OtherMixin {}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A', otherFile,
            rangeAtSearch('A with', otherContents, 'A')),
        _isResult(CallHierarchyKind.method, 'foo', otherFile,
            rangeAtSearch('foo() {', otherContents, 'foo'),
            ranges: [
              rangeAfterPrefix('a.', contents, 'foo'),
              rangeAfterPrefix('A().', contents, 'foo'),
              rangeAfterPrefix('tearoff = a.', contents, 'foo'),
            ]),
      ]),
    );
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
// ignore_for_file: unused_local_variable
import 'other.dart';

class Foo {
  Foo.B^ar() {
    final a = A.named();
    final constructorTearoff = A.named;
  }
}
    ''';

    final otherContents = '''
void f() {}
class A {
  A.named();
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A.named', otherFile,
            rangeAtSearch('named', otherContents),
            ranges: [
              rangeAfterPrefix('a = A.', contents, 'named'),
              rangeAfterPrefix('constructorTearoff = A.', contents, 'named'),
            ]),
      ]),
    );
  }

  Future<void> test_setter() async {
    final contents = '''
import 'other.dart';

set fo^o(String value) {
  final a = A();
  a.b = '';
  A().b = '';
}
    ''';

    final otherContents = '''
class A {
  set b(String value) {}
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A', otherFile,
            rangeAtSearch('A {', otherContents, 'A')),
        _isResult(CallHierarchyKind.property, 'set b', otherFile,
            rangeAtSearch('b(String ', otherContents, 'b'),
            ranges: [
              rangeAfterPrefix('a.', contents, 'b'),
              rangeAfterPrefix('A().', contents, 'b'),
            ]),
      ]),
    );
  }
}
