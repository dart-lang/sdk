// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentHighlightsTest);
  });
}

@reflectiveTest
class DocumentHighlightsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_bound_topLevelVariable_wildcard() => _testMarkedContent('''
var /*[0*/_/*0]*/ = 1;
void f() {
  var _ = 2;
  print(/*[1*/_/*1]*/);
}
''');

  Future<void> test_dartCode_issue5369_field() => _testMarkedContent('''
class A {
  var /*[0*/a/*0]*/ = [''].where((_) => true).toList();
  List<String> f() {
    return /*[1*/a/*1]*/;
  }
}

var a; // Not a reference
''');

  Future<void> test_dartCode_issue5369_functionType() => _testMarkedContent('''
class A {
  String m({ required String Function(String input) /*[0*/f/*0]*/ }) {
    return /*[1*/f/*1]*/('');
  }
}

var f; // Not a reference
''');

  Future<void> test_dartCode_issue5369_localVariable() => _testMarkedContent('''
class A {
  List<String> f() {
    var /*[0*/a/*0]*/ = [''].where((_) => true).toList();
    return /*[1*/a/*1]*/;
  }
}

var a; // Not a reference
''');

  Future<void> test_dartCode_issue5369_topLevelVariable() =>
      _testMarkedContent('''
var /*[0*/a/*0]*/ = [''].where((_) => true).toList();
var b = /*[1*/a/*1]*/;
''');

  Future<void> test_dotShorthand_class() => _testMarkedContent('''
A topA = ./*[0*/a/*0]*/;
class A {
  static A get /*[1*/a/*1]*/ => A();
}
void fn(A a) => print(a);
void f() {
  A a = ./*[2*/a/*2]*/;
  fn(./*[3*/a/*3]*/);
  A aa = A./*[4*/a/*4]*/;
}
''');

  Future<void> test_dotShorthand_enum() => _testMarkedContent('''
const A constA = ./*[0*/a/*0]*/;
enum A { /*[1*/a/*1]*/ }
void fn(A a) => print(a);
void f() {
  A a = ./*[2*/a/*2]*/;
  fn(./*[3*/a/*3]*/);
  A aa = A./*[4*/a/*4]*/;
}
''');

  Future<void> test_dotShorthand_extensionType() => _testMarkedContent('''
A topA = ./*[0*/a/*0]*/;
extension type A(int x) {
  static A get /*[1*/a/*1]*/ => A(1);
}
void fn(A a) => print(a);
void f() {
  A a = ./*[2*/a/*2]*/;
  fn(./*[3*/a/*3]*/);
  A aa = A./*[4*/a/*4]*/;
}
''');

  Future<void> test_forInLoop() => _testMarkedContent('''
void f() {
  for (final /*[0*/x/*0]*/ in []) {
    /*[1*/x/*1]*/;
  }
}
''');

  Future<void> test_formalParameters_closure() => _testMarkedContent('''
void f(void Function(int) _) {}

void g() => f((/*[0*/variable/*0]*/) {
  print(/*[1*/variable/*1]*/);
});
''');

  Future<void> test_formalParameters_function() => _testMarkedContent('''
void f(int /*[0*/parameter/*0]*/) {
  print(/*[1*/parameter/*1]*/);
}
''');

  Future<void> test_formalParameters_method() => _testMarkedContent('''
class C {
  void m(int /*[0*/parameter/*0]*/) {
    print(/*[1*/parameter/*1]*/);
  }
}
''');

  Future<void> test_functions() => _testMarkedContent('''
/*[0*/main/*0]*/() {
  /*[1*/main/*1]*/();
}
''');

  Future<void> test_invalidLineByOne() async {
    // Test that requesting a line that's too high by one returns a valid
    // error response instead of throwing.
    const content = '// single line';

    await initialize();
    await openFile(mainFileUri, content);

    // Lines are zero-based so 1 is invalid.
    var pos = Position(line: 1, character: 0);
    var request = getDocumentHighlights(mainFileUri, pos);

    await expectLater(
      request,
      throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)),
    );
  }

  Future<void> test_keyword_loop_do() => _testLoop('do', '', 'while (true);');

  Future<void> test_keyword_loop_for() => _testLoop('for', '(;;)', '');

  Future<void> test_keyword_loop_while() => _testLoop('while', '(true)', '');

  Future<void> test_keyword_loopWithSwitch_loopExit() => _testMarkedContent('''
void f(int i) {
  /*[0*/for/*0]*/ (;;) {
    /*[1*/break/*1]*/;
    /*[2*/continue/*2]*/;
    switch (i) {
      case 1:
        break;
        /*[3*/continue/*3]*/;
      case 2:
        break;
        /*[4*/continue/*4]*/;
    }
  }
}
''');

  Future<void> test_keyword_loopWithSwitch_switchExit() =>
      _testMarkedContent('''
void f(int i) {
  for (;;) {
    break;
    continue;
    /*[0*/switch/*0]*/ (i) {
      case 1:
        /*[1*/break/*1]*/;
        continue;
      case 2:
        /*[2*/break/*2]*/;
        continue;
    }
  }
}
''');

  Future<void> test_keyword_return_function() => _testMarkedContent('''
int f() {
  if (true) /*[0*/return/*0]*/ 1;
  /*[1*/return/*1]*/ 2;
}
''');

  Future<void> test_keyword_return_insideLoop() => _testMarkedContent('''
int f(int i) {
  for (;;) {
    switch (i) {
      case 1:
        /*[0*/return/*0]*/ 1;
      case 2:
        /*[1*/return/*1]*/ 2;
        break;
        continue;
    }
  }
  /*[2*/return/*2]*/ 2;
}
''');

  Future<void> test_keyword_return_method() => _testMarkedContent('''
class C {
  int m() {
    if (true) /*[0*/return/*0]*/ 1;
    /*[1*/return/*1]*/ 2;
  }
}
''');

  Future<void> test_keyword_return_nestedClosure() => _testMarkedContent('''
int outerFunction() {
  var a = () {
    var b = () {
      var c = () {
        return 1;
      };
      if (true) /*[0*/return/*0]*/ 1;
      /*[1*/return/*1]*/ 0;
    };
    return 1;
  };
  return 1;
}
''');

  Future<void> test_keyword_return_nestedFunction() => _testMarkedContent('''
int outerFunction() {
  int middleFunction() {
    int innerFunction() {
      return 1;
    }
    if (true) /*[0*/return/*0]*/ 1;
    /*[1*/return/*1]*/ 2;
  }
  return 1;
}
''');

  Future<void> test_keyword_yield_asyncGenerator() => _testMarkedContent('''
Stream<int> outerFunction() async* {
  Stream<int> middleFunction() async* {
    Stream<int> innerFunction() async* {
      yield 1;
      yield* Stream.value(0);
    }
    if (true) /*[0*/yield/*0]*/ 1;
    if (true) /*[1*/yield/*1]*/* Stream.value(0);
    /*[2*/yield/*2]*/ 2;
    /*[3*/yield/*3]*/* Stream.value(0);
  }
  yield 1;
  yield* Stream.value(0);
}
  ''');

  Future<void> test_keyword_yield_syncGenerator() => _testMarkedContent('''
Iterable<int> outerFunction() sync* {
  Iterable<int> middleFunction() sync* {
    Iterable<int> innerFunction() sync* {
      yield 1;
      yield* Iterable.empty();
    }
    if (true) /*[0*/yield/*0]*/ 1;
    if (true) /*[1*/yield/*1]*/* Iterable.empty();
    /*[2*/yield/*2]*/ 2;
    /*[3*/yield/*3]*/* Iterable.empty();
  }
  yield 1;
  yield* Iterable.empty();
}
  ''');

  Future<void> test_localVariable() => _testMarkedContent('''
void f() {
  var /*[0*/foo/*0]*/ = 1;
  print(/*[1*/foo/*1]*/);
  /*[2*/foo/*2]*/ = 2;
}
''');

  Future<void> test_method_underscore() => _testMarkedContent('''
class C {
  /*[0*/_/*0]*/() {
    /*[1*/_/*1]*/();
  }
}
''');

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);

    var highlights = await getDocumentHighlights(pubspecFileUri, startOfDocPos);

    // Non-Dart files should return empty results, not errors.
    expect(highlights, isEmpty);
  }

  Future<void> test_noResult() => _testMarkedContent('''
void f() {
  // This one is in a ^ comment!
}
''');

  Future<void> test_onlySelf() => _testMarkedContent('''
void f() {
  /*[0*/print/*0]*/('');
}
''');

  Future<void> test_onlySelf_wildcard() => _testMarkedContent('''
void f() {
  var /*[0*/_/*0]*/ = '';
}
''');

  Future<void> test_pattern_object_destructure() => _testMarkedContent('''
void f() {
  final MapEntry(:/*[0*/key/*0]*/) = const MapEntry<String, int>('a', 1);

  if (const MapEntry('a', 1) case MapEntry(:final /*[1*/ke^y/*1]*/)) {
    /*[2*/key/*2]*/;
  }
}
''');

  Future<void> test_prefix() => _testMarkedContent('''
import '' as /*[0*/p/*0]*/;

class A {
  void m() {
    /*[1*/p/*1]*/.foo();
    print(/*[2*/p/*2]*/.a);
  }
}

void foo() {}

/*[3*/p/*3]*/.A? a;
''');

  Future<void> test_prefixed() => _testMarkedContent('''
import '' as p;

class /*[0*/A/*0]*/ {}

p./*[1*/A/*1]*/? a;
''');

  Future<void> test_shadow_inner() => _testMarkedContent('''
void f() {
  var foo = 1;
  func() {
    var /*[0*/foo/*0]*/ = 2;
    print(/*[1*/foo/*1]*/);
  }
}
''');

  Future<void> test_shadow_outer() => _testMarkedContent('''
void f() {
  var /*[0*/foo/*0]*/ = 1;
  func() {
    var foo = 2;
    print(foo);
  }
  print(/*[1*/foo/*1]*/);
}
''');

  Future<void> test_topLevelVariable() => _testMarkedContent('''
String /*[0*/foo/*0]*/ = 'bar';
void f() {
  print(/*[1*/foo/*1]*/);
  /*[2*/foo/*2]*/ = '';
}
''');

  Future<void> test_topLevelVariable_underscore() => _testMarkedContent('''
String /*[0*/_/*0]*/ = 'bar';
void f() {
  print(/*[1*/_/*1]*/);
  /*[2*/_/*2]*/ = '';
}
''');

  Future<void> test_type_class_constructors() async {
    await _testMarkedContent('''
class /*[0*/A/*0]*/ {
  A(); // Unnamed constructor is own entity
  /*[1*/A/*1]*/.named();
}

/*[2*/A/*2]*/ a = A(); // Unnamed constructor is own entity
var b = /*[3*/A/*3]*/.new();
var c = /*[4*/A/*4]*/.new;
''');
  }

  /// The type name in unnamed constructors are their own entity and not
  /// part of the type name.
  Future<void> test_type_class_constructors_unnamed() async {
    await _testMarkedContent('''
class A {
  /*[0*/A/*0]*/();
  A.named();
}

A a = /*[1*/A/*1]*/();
var b = A./*[2*/new/*2]*/();
var c = A./*[3*/new/*3]*/;
''');
  }

  Future<void> test_typeAlias_class_declaration() => _testMarkedContent('''
class MyClass {}
mixin MyMixin {}
class /*[0*/MyAlias/*0]*/ = MyClass with MyMixin;
/*[1*/MyAlias/*1]*/? a;
''');

  Future<void> test_typeAlias_class_reference() => _testMarkedContent('''
class MyClass {}
mixin MyMixin {}
class /*[0*/MyAlias/*0]*/ = MyClass with MyMixin;
/*[1*/MyAlias/*1]*/? a;
''');

  Future<void> test_typeAlias_function_declaration() => _testMarkedContent('''
typedef /*[0*/myFunc/*0]*/();
/*[1*/myFunc/*1]*/? f;
''');

  Future<void> test_typeAlias_function_reference() => _testMarkedContent('''
typedef /*[0*/myFunc/*0]*/();
/*[1*/myFunc/*1]*/? f;
''');

  Future<void> test_typeAlias_generic_declaration() => _testMarkedContent('''
typedef /*[0*/TD/*0]*/ = String;

/*[1*/TD/*1]*/? a;
''');

  Future<void> test_typeAlias_generic_reference() => _testMarkedContent('''
typedef /*[0*/TD/*0]*/ = String;

/*[1*/TD/*1]*/? a;
''');

  /// Create three nested loops for this [loopKeyword] (outer/middle/inner)
  /// with all combinations of `break`/`continue`  (and with.without labels)
  /// and verify that the middle [loopKeyword] and all exit keywords that
  /// relate to that loop produce mutual ranges including each other.
  Future<void> _testLoop(
    String loopKeyword,
    String loopStart,
    String loopEnd,
  ) async {
    var content = '''
void f() {
    outer:
    $loopKeyword $loopStart {
      middle:
      /*[0*/$loopKeyword/*0]*/ $loopStart {
        inner:
        $loopKeyword $loopStart {
          break;
          continue;
          break inner;
          continue inner;
          /*[1*/break/*1]*/ middle;
          /*[2*/continue/*2]*/ middle;
          break outer;
          continue outer;
        } $loopEnd
        /*[3*/break/*3]*/;
        /*[4*/continue/*4]*/;
        /*[5*/break/*5]*/ middle;
        /*[6*/continue/*6]*/ middle;
        break outer;
        continue outer;
      } $loopEnd
      break;
      continue;
      break outer;
      continue outer;
    } $loopEnd
}
''';
    await _testMarkedContent(content);
  }

  /// Tests highlights in a Dart file using the provided content.
  ///
  /// The content should be marked up using the [TestCode] format.
  ///
  /// If the content contains positions, they will be used to fetch highlights
  /// and the resulting ranges verified.
  ///
  /// If the content contains no positions, only ranges, then the start and end
  /// of every range will be tested to ensure the full set of ranges are
  /// returned mutually for each.
  Future<void> _testMarkedContent(String content) async {
    var code = TestCode.parse(content);
    expect(
      code.positions.isNotEmpty || code.ranges.isNotEmpty,
      isTrue,
      reason: 'At least one position or range should be marked in the content',
    );

    await initialize();
    await openFile(mainFileUri, code.code);

    var positions =
        code.positions.isNotEmpty
            ? code.positions.map((position) => position.position)
            : code.ranges.expand(
              (range) => [range.range.start, range.range.end],
            );

    for (var position in positions) {
      var highlights = await getDocumentHighlights(mainFileUri, position);

      if (code.ranges.isEmpty) {
        expect(highlights, isEmpty);
      } else {
        code.verifyRanges(highlights!.map((highlight) => highlight.range));
      }
    }
  }
}
