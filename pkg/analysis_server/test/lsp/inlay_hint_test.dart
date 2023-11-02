// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeInlayHintTest);
    defineReflectiveTests(ParameterNameInlayHintTest);
  });
}

@reflectiveTest
class ParameterNameInlayHintTest extends _AbstractInlayHintTest {
  Future<void> test_beforeTypes() async {
    final content = '''
void f(Object a) {
  f([1, 2]);
}
''';
    final expected = '''
void f(Object a) {
  f((Parameter:a:) (Type:<int>)[1, 2]);
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_location() async {
    final code = TestCode.parse('''
void f(int /*[0*/a/*0]*/) {}
void g() {
  f(1);
}
''');
    final hints = await _fetchHints(code.code);
    final location = hints.single.labelParts.single.location!;

    expect(location.uri, mainFileUri);
    expect(location.range, code.range.range);
  }

  Future<void> test_named() async {
    final content = '''
void f({required int? a, int? b}) {
  f(a: a); // already named
}
''';
    final expected = '''
void f({required int? a, int? b}) {
  f(a: a); // already named
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_optionalPositional() async {
    final content = '''
void f([int? a, int? b]) {
  f(a);
}
''';
    final expected = '''
void f([int? a, int? b]) {
  f((Parameter:a:) a);
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_requiredPositional() async {
    final content = '''
void f(int a, int b) {
  f(a, b);
}
''';
    final expected = '''
void f(int a, int b) {
  f((Parameter:a:) a, (Parameter:b:) b);
}
''';
    await _expectHints(content, expected);
  }

  /// Don't try to produce hints for parameters without names.
  Future<void> test_unnamed() async {
    final content = '''
void f(void Function(int) a) => a(1);
''';
    await _expectNoHints(content);
  }

  /// Similar to test_unnamed, this (invalid/incomplete) code triggered an
  /// additional error where the nameOffset of the parameter element was -1.
  /// https://github.com/Dart-Code/Dart-Code/issues/4436
  Future<void> test_unnamed2() async {
    final content = '''
void f() {
  <int, void Function(int)>{
  0
  }[0]!(0);
}
''';

    await _expectNoHints(content);
  }
}

@reflectiveTest
class TypeInlayHintTest extends _AbstractInlayHintTest {
  Future<void> test_class_field() async {
    final content = '''
class A {
  final i1 = 1;
}
''';
    final expected = '''
class A {
  final (Type:int) i1 = 1;
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_class_typeArguments() async {
    final content = '''
class A<T1, T2> {
  A(T1 a, T2 b) {}
}

void f() {
  final a = A('', 1);
}
''';
    final expected = '''
class A<T1, T2> {
  A(T1 a, T2 b) {}
}

void f() {
  final (Type:A<String, int>) a = A(Type:<String, int>)((Parameter:a:) '', (Parameter:b:) 1);
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_documentUpdates() async {
    final content = '''
final a = 1;
''';
    await initialize();

    // Start with a blank document expecting no hints,
    await openFile(mainFileUri, '');
    final hintsBeforeChange = await getInlayHints(
      mainFileUri,
      startOfDocRange,
    );

    // Update the document to ensure we get latest hints.
    // Don't await `replaceFile` because we want to check the server correctly
    // handles an inlayHints request that immediately follows a document update.
    unawaited(replaceFile(1, mainFileUri, content));
    final hintsAfterChange = await getInlayHints(
      mainFileUri,
      rangeOfWholeContent(content),
    );

    expect(hintsBeforeChange, isEmpty);
    expect(hintsAfterChange, isNotEmpty);
  }

  Future<void> test_function_typeArguments() async {
    final content = '''
void f1<T1, T2>(T1 a, T2 b) {}

void f() {
  f1('', 1);
}
''';
    final expected = '''
void f1<T1, T2>(T1 a, T2 b) {}

void f() {
  f1(Type:<String, int>)((Parameter:a:) '', (Parameter:b:) 1);
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_getter() async {
    final content = '''
get f => 1;
''';
    final expected = '''
(Type:dynamic) get f => 1;
''';
    await _expectHints(content, expected);
  }

  Future<void> test_leadingAnnotation() async {
    final content = '''
@deprecated
f() => '';

class A {
  @deprecated
  f() => '';
}
''';
    final expected = '''
@deprecated
(Type:dynamic) f() => '';

class A {
  @deprecated
  (Type:dynamic) f() => '';
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_leadingComment() async {
    final content = '''
// Comment
f() => '';

class A {
  // Comment
  f() => '';
}
''';
    final expected = '''
// Comment
(Type:dynamic) f() => '';

class A {
  // Comment
  (Type:dynamic) f() => '';
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_leadingDocumentation() async {
    final content = '''
/// Documentation
f() => '';

class A {
  /// Documentation
  f() => '';
}
''';
    final expected = '''
/// Documentation
(Type:dynamic) f() => '';

class A {
  /// Documentation
  (Type:dynamic) f() => '';
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_localFunction_returnType() async {
    // Check inferred return types for local functions have type hints.
    final content = '''
void f() {
  g() => '';
  h() { return ''; }
  i() {}
  void j() {}
}
''';
    final expected = '''
void f() {
  (Type:String) g() => '';
  (Type:String) h() { return ''; }
  (Type:Null) i() {}
  void j() {}
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_location_local() async {
    final code = TestCode.parse('''
class /*[0*/A/*0]*/ {}
final a1 = A();
''');
    final hints = await _fetchHints(code.code);
    final location = hints.single.labelParts.single.location!;

    expect(location.uri, mainFileUri);
    expect(location.range, code.range.range);
  }

  Future<void> test_location_records() async {
    final code = TestCode.parse('''
class /*[0*/A/*0]*/<T> {}
class /*[1*/B/*1]*/ {}
class /*[2*/C/*2]*/ {}
final x = A<(B, C, {B b2, C c2})>();
''');
    final ranges = code.ranges.map((r) => r.range).toList();
    final hints = await _fetchHints(code.code);
    final parts = hints.single.labelParts;

    // Check the parts of the label.
    expect(
      parts.map((p) => (p.value, p.location?.range)),
      equals([
        ('A', ranges[0]),
        ('<', null),
        ('(', null),
        ('B', ranges[1]),
        (', ', null),
        ('C', ranges[2]),
        (', ', null),
        ('{', null),
        ('B', ranges[1]),
        (' b2', null),
        (', ', null),
        ('C', ranges[2]),
        (' c2', null),
        ('}', null),
        (')', null),
        ('>', null),
      ]),
    );
  }

  Future<void> test_location_sdk() async {
    final code = TestCode.parse('''
final a1 = '';
''');
    final hints = await _fetchHints(code.code);
    final location = hints.single.labelParts.single.location!;

    expect(location.uri,
        pathContext.toUri(convertPath('/sdk/lib/core/core.dart')));
    // Check range looks like sensible values.
    expect(location.range.start.line, greaterThanOrEqualTo(1));
    expect(location.range.start.character,
        greaterThanOrEqualTo('abstract class '.length));
    expect(location.range.end.line, location.range.start.line);
    expect(location.range.end.character,
        location.range.start.character + 'String'.length);
  }

  Future<void> test_location_typeArguments() async {
    final code = TestCode.parse('''
class /*[0*/A/*0]*/<T> {}
class /*[1*/B/*1]*/<T> {}
class /*[2*/C/*2]*/ {}
final x = A<B<C>>();
''');
    final ranges = code.ranges.map((r) => r.range).toList();
    final hints = await _fetchHints(code.code);
    final parts = hints.single.labelParts;

    // Check the parts of the label.
    expect(
      parts.map((p) => (p.value, p.location?.range)),
      equals([
        ('A', ranges[0]),
        ('<', null),
        ('B', ranges[1]),
        ('<', null),
        ('C', ranges[2]),
        ('>', null),
        ('>', null),
      ]),
    );
  }

  Future<void> test_method_parameters() async {
    final content = '''
class A {
  void m1(int a, [String? b]) {}
  void m2(int a, {String? b, required String c}) {}
}
class B extends A {
  @override
  void m1(a, [b]) {}
  void m2(a, {b, required c}) {}
  void m3(a, {b}) {}
}
''';
    final expected = '''
class A {
  void m1(int a, [String? b]) {}
  void m2(int a, {String? b, required String c}) {}
}
class B extends A {
  @override
  void m1((Type:int) a, [(Type:String?) b]) {}
  void m2((Type:int) a, {(Type:String?) b, required (Type:String) c}) {}
  void m3((Type:dynamic) a, {(Type:dynamic) b}) {}
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_method_returnType() async {
    final content = '''
class A {
  f() => '';
}
''';
    // method return types are not inferred and always `dynamic`.
    final expected = '''
class A {
  (Type:dynamic) f() => '';
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_method_typeArguments() async {
    final content = '''
class A {
  void m1<T1, T2>(T1 a, T2 b) {}
}

void f() {
  final a = A();
  a.m1('', 1);
}
''';
    final expected = '''
class A {
  void m1<T1, T2>(T1 a, T2 b) {}
}

void f() {
  final (Type:A) a = A();
  a.m1(Type:<String, int>)((Parameter:a:) '', (Parameter:b:) 1);
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_patterns_destructure() async {
    final content = '''
void f() {
  final (i, ) = (1, );
  final (j, k) = (1, 2);
  final (int i2, ) = (1, );
  final (int j2, int k2) = (1, 2);
}
''';
    final expected = '''
void f() {
  final ((Type:int) i, ) = (1, );
  final ((Type:int) j, (Type:int) k) = (1, 2);
  final (int i2, ) = (1, );
  final (int j2, int k2) = (1, 2);
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_patterns_ifCase() async {
    final content = '''
void f() {
  final (int, {(int, ) test}) pattern = (test: (10,), 2);
  if (pattern case final p) {}
}
''';
    final expected = '''
void f() {
  final (int, {(int, ) test}) pattern = (test: (10,), 2);
  if (pattern case final (Type:(int, {(int,) test})) p) {}
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_patterns_ifCase_typeArguments() async {
    final content = '''
class Box<T> {
  final T value;
  Box(this.value);
}

void f(Box<List<String>> a) {
  if (a case Box(value: List(:final int length))) {}
}
''';
    final expected = '''
class Box<T> {
  final T value;
  Box(this.value);
}

void f(Box<List<String>> a) {
  if (a case Box(Type:<List<String>>)(value: List(Type:<String>)(:final int length))) {}
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_patterns_switchExpression() async {
    final content = '''
void f() {
  final (int, {(int, ) test}) pattern = (test: (10,), 2);
  final Null _switch = switch (pattern) {
    (:final test, var i) => null,
  };
}
''';
    final expected = '''
void f() {
  final (int, {(int, ) test}) pattern = (test: (10,), 2);
  final Null _switch = switch (pattern) {
    (:final (Type:(int,)) test, var (Type:int) i) => null,
  };
}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_records_singlePositionalComma() async {
    final content = '''
final withComma = (1,);
final noComma1 = (1, 2);
final noComma2 = (a: '');
final noComma3 = (1, a: '');
''';
    final expected = '''
final (Type:(int,)) withComma = (1,);
final (Type:(int, int)) noComma1 = (1, 2);
final (Type:({String a})) noComma2 = (a: '');
final (Type:(int, {String a})) noComma3 = (1, a: '');
''';
    await _expectHints(content, expected);
  }

  Future<void> test_setter() async {
    final content = '''
set f(int i) {}
''';
    // Setters are always `void` so we don't show a label there.
    final expected = '''
set f(int i) {}
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelFunction_returnType() async {
    final content = '''
f() => '';
''';
    // top-level function return types are not inferred and always `dynamic`
    final expected = '''
(Type:dynamic) f() => '';
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_closureResult() async {
    final content = '''
var c1 = (() => 3)();
int c2 = (() => 3)(); // already typed
''';
    final expected = '''
var (Type:int) c1 = (() => 3)();
int c2 = (() => 3)(); // already typed
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_functionResult() async {
    final content = '''
String f() => '';
final s1 = f();
final String s2 = f(); // already typed
''';
    final expected = '''
String f() => '';
final (Type:String) s1 = f();
final String s2 = f(); // already typed
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_functionType() async {
    final content = '''
final f1 = (List<String> x) => x;
final List<String> Function(List<String>) f2 = (List<String> x) => x; // already typed
''';
    final expected = '''
final (Type:List<String> Function(List<String>)) f1 = (List<String> x) => x;
final List<String> Function(List<String>) f2 = (List<String> x) => x; // already typed
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_literal() async {
    final content = '''
final i1 = 1;
const i2 = 1;
var i3 = 1;
final i4 = 2, s1 = '';
int i5 = 1; // already typed
''';
    final expected = '''
final (Type:int) i1 = 1;
const (Type:int) i2 = 1;
var (Type:int) i3 = 1;
final (Type:int) i4 = 2, (Type:String) s1 = '';
int i5 = 1; // already typed
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_literalList() async {
    final content = '''
final l1 = [1, 2, 3];
final l2 = [1, '', 3];
final l3 = ['', null, ''];
final l4 = <Object>[1, 2, 3];
final List<Object> l5 = [1, 2, 3];
''';
    final expected = '''
final (Type:List<int>) l1 = (Type:<int>)[1, 2, 3];
final (Type:List<Object>) l2 = (Type:<Object>)[1, '', 3];
final (Type:List<String?>) l3 = (Type:<String?>)['', null, ''];
final (Type:List<Object>) l4 = <Object>[1, 2, 3];
final List<Object> l5 = (Type:<Object>)[1, 2, 3];
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_literalMap() async {
    final content = '''
final m1 = {1: '', 2: ''};
final m2 = {'': [1]};
final m3 = {'': null};
final m4 = <Object, String>{1: '', 2: ''};
final Map<int, String> m1 = {1: '', 2: ''};
''';
    final expected = '''
final (Type:Map<int, String>) m1 = (Type:<int, String>){1: '', 2: ''};
final (Type:Map<String, List<int>>) m2 = (Type:<String, List<int>>){'': (Type:<int>)[1]};
final (Type:Map<String, Null>) m3 = (Type:<String, Null>){'': null};
final (Type:Map<Object, String>) m4 = <Object, String>{1: '', 2: ''};
final Map<int, String> m1 = (Type:<int, String>){1: '', 2: ''};
''';
    await _expectHints(content, expected);
  }

  Future<void> test_topLevelVariable_literalSet() async {
    final content = '''
final s1 = {1, 2, 3};
final s2 = {1, '', 3};
final s3 = {'', null, ''};
final s4 = <Object>{1, 2, 3};
final Set<Object> s5 = {1, 2, 3};
''';
    final expected = '''
final (Type:Set<int>) s1 = (Type:<int>){1, 2, 3};
final (Type:Set<Object>) s2 = (Type:<Object>){1, '', 3};
final (Type:Set<String?>) s3 = (Type:<String?>){'', null, ''};
final (Type:Set<Object>) s4 = <Object>{1, 2, 3};
final Set<Object> s5 = (Type:<Object>){1, 2, 3};
''';
    await _expectHints(content, expected);
  }
}

class _AbstractInlayHintTest extends AbstractLspAnalysisServerTest {
  /// Substitutes text from [hints] into [content] to produce a text
  /// representation that can be easily tested.
  ///
  /// Label kinds will be included as well as their text, with leading or
  /// trailing spaces based on padding flags on the hint.
  ///
  /// ```
  /// final a = 1;
  /// ```
  ///
  /// May become:
  ///
  /// ```
  /// final (Type:int) a = 1;
  /// ```
  String substituteHints(String content, List<InlayHint> hints) {
    hints.sort((h1, h2) => positionCompare(h1.position, h2.position));
    final buffer = StringBuffer();
    final lineInfo = LineInfo.fromContent(content);

    var lastOffset = 0;
    for (final hint in hints) {
      // First add any text from the last hint up to this hint.
      final offset = toOffset(lineInfo, hint.position).result;
      buffer.write(content.substring(lastOffset, offset));

      // Then add the hint. Include the kind in parens so it can be tested too,
      // and add a trailing/leading space based on settings.
      _writeHintDescription(buffer, hint);
      lastOffset = offset;
    }
    // Finally, write anything after the last hint.
    buffer.write(content.substring(lastOffset));

    return buffer.toString();
  }

  Future<void> _expectHints(
      String content, String expectedContentWithHints) async {
    final hints = await _fetchHints(content);
    final actualContentWithHints = substituteHints(content, hints);
    expect(actualContentWithHints, expectedContentWithHints);
  }

  Future<void> _expectNoHints(String content) async {
    final hints = await _fetchHints(content);
    expect(hints, isEmpty);
  }

  Future<List<InlayHint>> _fetchHints(String content) async {
    await initialize();
    await openFile(mainFileUri, content);
    final hints = await getInlayHints(
      mainFileUri,
      rangeOfWholeContent(content),
    );
    return hints;
  }

  /// Helper to write a text representation of [hint] into [buffer].
  void _writeHintDescription(StringBuffer buffer, InlayHint hint) {
    // TODO(dantup): Improve the LSP enum codegen to allow us to get the names
    //  of int-based enums.
    final kindNames = {
      InlayHintKind.Type: 'Type',
      InlayHintKind.Parameter: 'Parameter',
    };

    if (hint.paddingLeft ?? false) {
      buffer.write(' ');
    }
    buffer.write('(');
    if (hint.kind != null) {
      buffer
        ..write(kindNames[hint.kind])
        ..write(':');
    }
    buffer.write(hint.textLabel);
    buffer.write(')');
    if (hint.paddingRight ?? false) {
      buffer.write(' ');
    }
  }
}

extension _InlayHintExtension on InlayHint {
  /// Returns the parts of an InlayHint label.
  List<InlayHintLabelPart> get labelParts => label.map(
        (parts) => parts,
        (string) => throw 'Expected InlayHintLabelPart, got String',
      );

  /// Returns the visible text of the InlayHint, concatenating any parts.
  String get textLabel => label.map(
        // Unwrap where an InlayHint may provide its label in multiple
        // `InlayHintLabelPart`s.
        (parts) => parts.map((part) => part.value).join(),
        (string) => string,
      );
}
