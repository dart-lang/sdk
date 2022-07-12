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
Matcher _isItem(
  CallHierarchyKind kind,
  String displayName,
  String file, {
  required SourceRange nameRange,
  required SourceRange codeRange,
}) =>
    TypeMatcher<CallHierarchyItem>()
        .having((e) => e.kind, 'kind', kind)
        .having((e) => e.displayName, 'displayName', displayName)
        .having((e) => e.file, 'file', file)
        .having((e) => e.nameRange, 'nameRange', nameRange)
        .having((e) => e.codeRange, 'codeRange', codeRange);

/// Matches a [CallHierarchyCalls] result with the given element/ranges.
Matcher _isResult(
  CallHierarchyKind kind,
  String displayName,
  String file, {
  required SourceRange nameRange,
  required SourceRange codeRange,
  List<SourceRange>? ranges,
}) {
  var matcher = TypeMatcher<CallHierarchyCalls>().having(
      (c) => c.item,
      'item',
      _isItem(kind, displayName, file,
          nameRange: nameRange, codeRange: codeRange));

  if (ranges != null) {
    matcher = matcher.having((c) => c.ranges, 'ranges', ranges);
  }

  return matcher;
}

abstract class AbstractCallHierarchyTest extends AbstractSingleUnitTest {
  final startOfFile = SourceRange(0, 0);

  /// Gets the entire range for [code].
  SourceRange entireRange(String code) =>
      SourceRange(0, withoutMarkers(code).length);

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

  // Gets the code range between markers in the form `/*1*/` where `1` is
  // [number].
  SourceRange rangeNumbered(int number, String code) {
    code = withoutMarkers(code);
    final marker = '/*$number*/';
    final start = code.indexOf(marker) + marker.length;
    final end = code.lastIndexOf(marker);
    expect(start, greaterThanOrEqualTo(0 + marker.length));
    expect(end, greaterThan(start));
    return SourceRange(start, end - start);
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
  /*1*/Fo^o(String a) {}/*1*/
}
    ''';

    final target = await findTarget(contents);
    expect(
      target,
      _isItem(
        CallHierarchyKind.constructor,
        'Foo',
        testFile,
        nameRange: rangeAtSearch('Foo(', contents, 'Foo'),
        codeRange: rangeNumbered(1, contents),
      ),
    );
  }

  Future<void> test_constructorCall() async {
    final contents = '''
import 'other.dart';

void f() {
  final foo = Fo^o();
}
    ''';

    final otherContents = '''
class Foo {
  /*1*/Foo();/*1*/
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo',
          otherFile,
          nameRange: rangeAtSearch('Foo(', otherContents, 'Foo'),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_extension_method() async {
    final contents = '''
extension StringExtension on String {
  /*1*/void myMet^hod() {}/*1*/
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          testFile,
          nameRange: rangeAtSearch('myMethod', contents),
          codeRange: rangeNumbered(1, contents),
        ));
  }

  Future<void> test_extension_methodCall() async {
    final contents = '''
import 'other.dart';

void f() {
  ''.myMet^hod();
}
    ''';

    final otherContents = '''
extension StringExtension on String {
  /*1*/void myMethod() {}/*1*/
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          otherFile,
          nameRange: rangeAtSearch('myMethod', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_function() async {
    final contents = '''
/*1*/void myFun^ction() {}/*1*/
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.function,
          'myFunction',
          testFile,
          nameRange: rangeAtSearch('myFunction', contents),
          codeRange: rangeNumbered(1, contents),
        ));
  }

  Future<void> test_functionCall() async {
    final contents = '''
import 'other.dart' as f;

void f() {
  f.myFun^ction();
}
    ''';

    final otherContents = '''
/*1*/void myFunction() {}/*1*/
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.function,
          'myFunction',
          otherFile,
          nameRange: rangeAtSearch('myFunction', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_getter() async {
    final contents = '''
class Foo {
  /*1*/String get fo^o => '';/*1*/
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'get foo',
          testFile,
          nameRange: rangeAtSearch('foo', contents),
          codeRange: rangeNumbered(1, contents),
        ));
  }

  Future<void> test_getterCall() async {
    final contents = '''
import 'other.dart';

void f() {
  final foo = ba^r;
}
    ''';

    final otherContents = '''
/*1*/String get bar => '';/*1*/
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'get bar',
          otherFile,
          nameRange: rangeAtSearch('bar', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_implicitConstructorCall() async {
    // Even if a constructor is implicit, we might want to be able to get the
    // incoming calls, so we should return the class location as a stand-in
    // (although with the Kind still set to constructor).
    final contents = '''
import 'other.dart';

void f() {
  final foo = Fo^o();
}
    ''';

    final otherContents = '''
/*1*/class Foo {}/*1*/
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo',
          otherFile,
          nameRange: rangeAtSearch('Foo {', otherContents, 'Foo'),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_method() async {
    final contents = '''
class Foo {
  /*1*/void myMet^hod() {}/*1*/
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          testFile,
          nameRange: rangeAtSearch('myMethod', contents),
          codeRange: rangeNumbered(1, contents),
        ));
  }

  Future<void> test_methodCall() async {
    final contents = '''
import 'other.dart';

void f() {
  Foo().myMet^hod();
}
    ''';

    final otherContents = '''
class Foo {
  /*1*/void myMethod() {}/*1*/
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          otherFile,
          nameRange: rangeAtSearch('myMethod', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_mixin_method() async {
    final contents = '''
mixin Bar {
  /*1*/void myMet^hod() {}/*1*/
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.method,
          'myMethod',
          testFile,
          nameRange: rangeAtSearch('myMethod', contents),
          codeRange: rangeNumbered(1, contents),
        ));
  }

  Future<void> test_mixin_methodCall() async {
    final contents = '''
import 'other.dart';

void f() {
  Foo().myMet^hod();
}
    ''';

    final otherContents = '''
class Bar {
  /*1*/void myMethod() {}/*1*/
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
          nameRange: rangeAtSearch('myMethod', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
class Foo {
  /*1*/Foo.Ba^r(String a) {}/*1*/
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo.Bar',
          testFile,
          nameRange: rangeAtSearch('Bar', contents),
          codeRange: rangeNumbered(1, contents),
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

void f() {
  final foo = Foo.Ba^r();
}
    ''';

    final otherContents = '''
class Foo {
  /*1*/Foo.Bar();/*1*/
}
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.constructor,
          'Foo.Bar',
          otherFile,
          nameRange: rangeAtSearch('Bar', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_namedConstructorCall_typeName() async {
    final contents = '''
import 'other.dart';

void f() {
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
  /*1*/set fo^o(String value) {}/*1*/
}
    ''';

    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'set foo',
          testFile,
          nameRange: rangeAtSearch('foo', contents),
          codeRange: rangeNumbered(1, contents),
        ));
  }

  Future<void> test_setterCall() async {
    final contents = '''
import 'other.dart';

void f() {
  ba^r = '';
}
    ''';

    final otherContents = '''
/*1*/set bar(String value) {}/*1*/
    ''';

    addSource(otherFile, otherContents);
    await expectTarget(
        contents,
        _isItem(
          CallHierarchyKind.property,
          'set bar',
          otherFile,
          nameRange: rangeAtSearch('bar', otherContents),
          codeRange: rangeNumbered(1, otherContents),
        ));
  }

  Future<void> test_whitespace() async {
    await expectNoTarget(' ^  void f() {}');
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
/*1*/class Bar {
  final foo2 = Foo();
  /*2*/Foo get foo3 => Foo();/*2*/
  /*3*/Bar() {
    final foo4 = Foo();
  }/*3*/
  /*4*/void bar() {
    final foo5 = Foo();
    final foo6 = Foo();
  }/*4*/
}/*1*/
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'Foo');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile,
            nameRange: startOfFile,
            codeRange: entireRange(otherContents),
            ranges: [
              rangeAfter('foo1 = '),
            ]),
        _isResult(CallHierarchyKind.class_, 'Bar', otherFile,
            nameRange: rangeAtSearch('Bar {', otherContents, 'Bar'),
            codeRange: rangeNumbered(1, otherContents),
            ranges: [
              rangeAfter('foo2 = '),
            ]),
        _isResult(CallHierarchyKind.property, 'get foo3', otherFile,
            nameRange: rangeAtSearch('foo3', otherContents),
            codeRange: rangeNumbered(2, otherContents),
            ranges: [
              rangeAfter('foo3 => '),
            ]),
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            nameRange: rangeAtSearch('Bar() {', otherContents, 'Bar'),
            codeRange: rangeNumbered(3, otherContents),
            ranges: [
              rangeAfter('foo4 = '),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            nameRange: rangeAtSearch('bar() {', otherContents, 'bar'),
            codeRange: rangeNumbered(4, otherContents),
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

/*1*/void f() {
  ''.myMethod();
}/*1*/
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
            nameRange: rangeAtSearch('f() {', otherContents, 'f'),
            codeRange: rangeNumbered(1, otherContents),
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

/*1*/class Bar {
  final foo2 = myFunction();
  /*2*/String get foo3 => myFunction();/*2*/
  /*3*/Bar() {
    final foo4 = myFunction();
  }/*3*/
  /*4*/void bar() {
    final foo5 = myFunction();
    final foo6 = myFunction();
  }/*4*/
}/*1*/
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'myFunction');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile,
            nameRange: startOfFile,
            codeRange: entireRange(otherContents),
            ranges: [
              rangeAfter('foo1 = '),
            ]),
        _isResult(CallHierarchyKind.class_, 'Bar', otherFile,
            nameRange: rangeAtSearch('Bar {', otherContents, 'Bar'),
            codeRange: rangeNumbered(1, otherContents),
            ranges: [
              rangeAfter('foo2 = '),
            ]),
        _isResult(CallHierarchyKind.property, 'get foo3', otherFile,
            nameRange: rangeAtSearch('foo3', otherContents),
            codeRange: rangeNumbered(2, otherContents),
            ranges: [
              rangeAfter('foo3 => '),
            ]),
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            nameRange: rangeAtSearch('Bar() {', otherContents, 'Bar'),
            codeRange: rangeNumbered(3, otherContents),
            ranges: [
              rangeAfter('foo4 = '),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            nameRange: rangeAtSearch('bar() {', otherContents, 'bar'),
            codeRange: rangeNumbered(4, otherContents),
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
/*1*/class Bar {
  final foo2 = foo;
  /*2*/Foo get foo3 => foo;/*2*/
  /*3*/Bar() {
    final foo4 = foo;
  }/*3*/
  /*4*/void bar() {
    final foo5 = foo;
    final foo6 = foo;
  }/*4*/
}/*1*/
    ''';

    // Gets the expected range that follows the string [prefix].
    SourceRange rangeAfter(String prefix) =>
        rangeAfterPrefix(prefix, otherContents, 'foo');

    addSource(otherFile, otherContents);
    final calls = await findIncomingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile,
            nameRange: startOfFile,
            codeRange: entireRange(otherContents),
            ranges: [
              rangeAfter('foo1 = '),
            ]),
        _isResult(CallHierarchyKind.class_, 'Bar', otherFile,
            nameRange: rangeAtSearch('Bar {', otherContents, 'Bar'),
            codeRange: rangeNumbered(1, otherContents),
            ranges: [
              rangeAfter('foo2 = '),
            ]),
        _isResult(CallHierarchyKind.property, 'get foo3', otherFile,
            nameRange: rangeAtSearch('foo3', otherContents),
            codeRange: rangeNumbered(2, otherContents),
            ranges: [
              rangeAfter('foo3 => '),
            ]),
        _isResult(CallHierarchyKind.constructor, 'Bar', otherFile,
            nameRange: rangeAtSearch('Bar() {', otherContents, 'Bar'),
            codeRange: rangeNumbered(3, otherContents),
            ranges: [
              rangeAfter('foo4 = '),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            nameRange: rangeAtSearch('bar() {', otherContents, 'bar'),
            codeRange: rangeNumbered(4, otherContents),
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

/*1*/void f() {
  final foo1 = Fo^o();
}/*1*/
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
            nameRange: rangeAtSearch('f() {', contents, 'f'),
            codeRange: rangeNumbered(1, contents),
            ranges: [
              rangeAfter('foo1 = ', contents),
            ]),
        _isResult(CallHierarchyKind.file, 'other.dart', otherFile,
            nameRange: startOfFile,
            codeRange: entireRange(otherContents),
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

/*1*/void f() {
  Foo().myMethod();
  final tearoff = Foo().myMethod;
}/*1*/
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
            nameRange: rangeAtSearch('f() {', otherContents, 'f'),
            codeRange: rangeNumbered(1, otherContents),
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

/*1*/void f() {
  Foo().myMethod();
}/*1*/
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
            nameRange: rangeAtSearch('f() {', otherContents, 'f'),
            codeRange: rangeNumbered(1, otherContents),
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

/*1*/void f() {
  final foo = Foo.Bar();
}/*1*/
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
            nameRange: rangeAtSearch('f() {', otherContents, 'f'),
            codeRange: rangeNumbered(1, otherContents),
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
  /*1*/Bar() {
    /*a*/foo = '';
  }/*1*/
  /*2*/void bar() {
    /*b*/foo = '';
    /*c*/foo = '';
  }/*2*/
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
            nameRange: rangeAtSearch('Bar() {', otherContents, 'Bar'),
            codeRange: rangeNumbered(1, otherContents),
            ranges: [
              rangeAfter('/*a*/'),
            ]),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            nameRange: rangeAtSearch('bar() {', otherContents, 'bar'),
            codeRange: rangeNumbered(2, otherContents),
            ranges: [
              rangeAfter('/*b*/'),
              rangeAfter('/*c*/'),
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
  /*1*/A();/*1*/
}

/*2*/class B {
}/*2*/
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A', otherFile,
            nameRange: rangeAtSearch('A();', otherContents, 'A'),
            codeRange: rangeNumbered(1, otherContents),
            ranges: [
              rangeAtSearch('A()', contents, 'A'),
              rangeAfterPrefix('constructorTearoffA = A.', contents, 'new'),
            ]),
        _isResult(CallHierarchyKind.constructor, 'B', otherFile,
            nameRange: rangeAtSearch('B {', otherContents, 'B'),
            codeRange: rangeNumbered(2, otherContents),
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
  /*1*/void bar() {}/*1*/
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            nameRange: rangeAtSearch('bar() {', otherContents, 'bar'),
            codeRange: rangeNumbered(1, otherContents),
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
  /*1*/void nested() {
    f(); // not a call of 'foo'
  }/*1*/
  f(); // 1
  final tearoff = f;
  nested();
  final nestedTearoff = nested;
}
    ''';

    final otherContents = '''
/*1*/void f() {}/*1*/
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.function, 'f', otherFile,
            nameRange: rangeAtSearch('f() {', otherContents, 'f'),
            codeRange: rangeNumbered(1, otherContents),
            ranges: [
              rangeAtSearch('f(); // 1', contents, 'f'),
              rangeAfterPrefix('tearoff = ', contents, 'f'),
            ]),
        _isResult(CallHierarchyKind.function, 'nested', testFile,
            nameRange: rangeAtSearch('nested() {', contents, 'nested'),
            codeRange: rangeNumbered(1, contents),
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
/*1*/class A {
  /*2*/String get b => '';/*2*/
}/*1*/
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(
          CallHierarchyKind.constructor,
          'A',
          otherFile,
          nameRange: rangeAtSearch('A {', otherContents, 'A'),
          codeRange: rangeNumbered(1, otherContents),
        ),
        _isResult(CallHierarchyKind.property, 'get b', otherFile,
            nameRange: rangeAtSearch('b => ', otherContents, 'b'),
            codeRange: rangeNumbered(2, otherContents),
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

void f() {
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
/*1*/class A {
  String field;
  /*2*/void bar() {}/*2*/
}/*1*/
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(
          CallHierarchyKind.constructor,
          'A',
          otherFile,
          nameRange: rangeAtSearch('A {', otherContents, 'A'),
          codeRange: rangeNumbered(1, otherContents),
        ),
        _isResult(CallHierarchyKind.method, 'bar', otherFile,
            nameRange: rangeAtSearch('bar() {', otherContents, 'bar'),
            codeRange: rangeNumbered(2, otherContents),
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
  /*2*/void foo() {}/*2*/
}

/*1*/class A with OtherMixin {}/*1*/
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(
          CallHierarchyKind.constructor,
          'A',
          otherFile,
          nameRange: rangeAtSearch('A with', otherContents, 'A'),
          codeRange: rangeNumbered(1, otherContents),
        ),
        _isResult(CallHierarchyKind.method, 'foo', otherFile,
            nameRange: rangeAtSearch('foo() {', otherContents, 'foo'),
            codeRange: rangeNumbered(2, otherContents),
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
  /*1*/A.named();/*1*/
}
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(CallHierarchyKind.constructor, 'A.named', otherFile,
            nameRange: rangeAtSearch('named', otherContents),
            codeRange: rangeNumbered(1, otherContents),
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
/*1*/class A {
  /*2*/set b(String value) {}/*2*/
}/*1*/
    ''';

    addSource(otherFile, otherContents);
    final calls = await findOutgoingCalls(contents);
    expect(
      calls,
      unorderedEquals([
        _isResult(
          CallHierarchyKind.constructor,
          'A',
          otherFile,
          nameRange: rangeAtSearch('A {', otherContents, 'A'),
          codeRange: rangeNumbered(1, otherContents),
        ),
        _isResult(CallHierarchyKind.property, 'set b', otherFile,
            nameRange: rangeAtSearch('b(String ', otherContents, 'b'),
            codeRange: rangeNumbered(2, otherContents),
            ranges: [
              rangeAfterPrefix('a.', contents, 'b'),
              rangeAfterPrefix('A().', contents, 'b'),
            ]),
      ]),
    );
  }
}
