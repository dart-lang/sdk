// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationHighlightsTest);
    defineReflectiveTests(HighlightTypeTest);
  });
}

@reflectiveTest
class AnalysisNotificationHighlightsTest extends HighlightsTestSupport {
  @override
  List<String> get experiments => [
        Feature.inline_class.enableString,
        ...super.experiments,
      ];

  void assertHighlightText(TestCode testCode, int index, String expected) {
    var actual = _getHighlightText(testCode, index);
    if (actual != expected) {
      print(testCode.code.trimRight());
      print('-' * 32);
      print(actual);
    }
    expect(actual, expected);
  }

  Future<void> test_ANNOTATION_hasArguments() async {
    addTestFile('''
class AAA {
  const AAA(a, b, c);
}
@AAA(1, 2, 3) void f() {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ANNOTATION, '@AAA(', '@AAA('.length);
    assertHasRegion(HighlightRegionType.ANNOTATION, ') void f', ')'.length);
  }

  Future<void> test_ANNOTATION_hasTypeArguments_hasArguments() async {
    addTestFile('''
class AAA<T> {
  const AAA(a, b, c);
}

@AAA<int>(1, 2, 3) void f() {}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.ANNOTATION, '@AAA', '@AAA<int>('.length);
    assertHasRegion(HighlightRegionType.ANNOTATION, ') void', ')'.length);
    assertHasRegion(HighlightRegionType.CLASS, 'int>');
  }

  Future<void> test_ANNOTATION_noArguments() async {
    addTestFile('''
const AAA = 42;
@AAA void f() {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ANNOTATION, '@AAA');
  }

  Future<void> test_BUILT_IN_abstract() async {
    addTestFile('''
abstract class A {};
abstract class B = Object with A;
void f() {
  var abstract = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'abstract class A');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'abstract class B');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'abstract = 42');
  }

  Future<void> test_BUILT_IN_as() async {
    addTestFile('''
import 'dart:math' as math;
void f() {
  p as int;
  var as = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'as math');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'as int');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'as = 42');
  }

  Future<void> test_BUILT_IN_async() async {
    addTestFile('''
fa() async {}
fb() async* {}
void f() {
  bool async = false;
}
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'async');
    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'async*');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'async = false');
  }

  Future<void> test_BUILT_IN_await() async {
    addTestFile('''
void f() async {
  await 42;
  await for (var item in []) {
    print(item);
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'await 42');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'await for');
  }

  Future<void> test_BUILT_IN_awaitForIn_list() async {
    addTestFile('''
f(a) async {
  return [await for(var b in a) b];
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'await');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for');
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in');
  }

  Future<void> test_BUILT_IN_awaitForIn_map() async {
    addTestFile('''
f(a) async {
  return {await for(var b in a) b : 0};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'await');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for');
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in');
  }

  Future<void> test_BUILT_IN_awaitForIn_set() async {
    addTestFile('''
f(a) async {
  return {await for(var b in a) b};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'await');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for');
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in');
  }

  Future<void> test_BUILT_IN_base() async {
    addTestFile('''
base class A {}
base mixin M {}
base class B = Object with M;
void f() {
  var base = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'base class A');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'base mixin M');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'base class B');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'base = 42');
  }

  Future<void> test_BUILT_IN_deferred() async {
    addTestFile('''
import 'dart:math' deferred as math;
void f() {
  var deferred = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'deferred as math');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'deferred = 42');
  }

  Future<void> test_BUILT_IN_export() async {
    addTestFile('''
export "dart:math";
void f() {
  var export = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'export "dart:');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'export = 42');
  }

  Future<void> test_BUILT_IN_external() async {
    addTestFile('''
class A {
  external A();
  external aaa();
}
external f() {
  var external = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'external A()');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'external aaa()');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'external f()');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'external = 42');
  }

  Future<void> test_BUILT_IN_factory() async {
    addTestFile('''
class A {
  A.named();
  factory A() => A.named();
}
void f() {
  var factory = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'factory A()');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'factory = 42');
  }

  Future<void> test_BUILT_IN_final() async {
    addTestFile('''
final class A {}
final class B = Object with M;
void f() {
  var final = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'final class A');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'final class B');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'final = 42');
  }

  Future<void> test_BUILT_IN_Function() async {
    addTestFile('''
typedef F = void Function();

void f(void Function() a, Function b) {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'Function();');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'Function() a');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'Function b');
  }

  Future<void> test_BUILT_IN_get() async {
    addTestFile('''
get aaa => 1;
class A {
  get bbb => 2;
}
void f() {
  var get = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'get aaa =>');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'get bbb =>');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'get = 42');
  }

  Future<void> test_BUILT_IN_hide() async {
    addTestFile('''
import 'foo.dart' hide Foo;
void f() {
  var hide = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'hide Foo');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'hide = 42');
  }

  Future<void> test_BUILT_IN_implements() async {
    addTestFile('''
class A {}
class B implements A {}
void f() {
  var implements = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'implements A {}');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'implements = 42');
  }

  Future<void> test_BUILT_IN_import() async {
    addTestFile('''
import "foo.dart";
void f() {
  var import = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'import "');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'import = 42');
  }

  Future<void> test_BUILT_IN_interface() async {
    addTestFile('''
interface class A {}
interface class B = Object with M;
void f() {
  var interface = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'interface class A');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'interface class B');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'interface = 42');
  }

  Future<void> test_BUILT_IN_library() async {
    addTestFile('''
library lib;
void f() {
  var library = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'library lib;');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'library = 42');
  }

  Future<void> test_BUILT_IN_mixin() async {
    addTestFile('''
mixin class A {}
mixin M {}
mixin class B = Object with M;
void f() {
  var mixin = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'mixin class A');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'mixin class B');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'mixin = 42');
  }

  Future<void> test_BUILT_IN_native() async {
    addTestFile('''
class A native "A_native" {}
class B {
  bbb() native "bbb_native";
}
void f() {
  var native = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'native "A_');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'native "bbb_');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'native = 42');
  }

  Future<void> test_BUILT_IN_on_inMixin() async {
    addTestFile('''
mixin M on N {}
class N {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'on N');
  }

  Future<void> test_BUILT_IN_on_inTry() async {
    addTestFile('''
void f() {
  try {
  } on int catch (e) {
  }
  var on = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'on int');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'on = 42');
  }

  Future<void> test_BUILT_IN_operator() async {
    addTestFile('''
class A {
  operator +(x) => null;
}
void f() {
  var operator = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'operator +(');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'operator = 42');
  }

  Future<void> test_BUILT_IN_part() async {
    addTestFile('''
part "my_part.dart";
void f() {
  var part = 42;
}''');
    newFile('/project/bin/my_part.dart', 'part of lib;');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'part "my_');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'part = 42');
  }

  Future<void> test_BUILT_IN_partOf() async {
    addTestFile('''
part of my.lib.name;
void f() {
  var part = 1;
  var of = 2;
}''');
    _addLibraryForTestPart();
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'part of', 'part of'.length);
    assertNoRegion(HighlightRegionType.BUILT_IN, 'part = 1');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'of = 2');
  }

  Future<void> test_BUILT_IN_sealed() async {
    addTestFile('''
sealed class A {}
sealed class B = Object with M;
void f() {
  var sealed = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'sealed class A');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'sealed class B');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'sealed = 42');
  }

  Future<void> test_BUILT_IN_set() async {
    addTestFile('''
set aaa(x) {}
class A
  set bbb(x) {}
}
void f() {
  var set = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'set aaa(');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'set bbb(');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'set = 42');
  }

  Future<void> test_BUILT_IN_show() async {
    addTestFile('''
import 'foo.dart' show Foo;
void f() {
  var show = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'show Foo');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'show = 42');
  }

  Future<void> test_BUILT_IN_static() async {
    addTestFile('''
class A {
  static aaa;
  static bbb() {}
}
void f() {
  var static = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'static aaa;');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'static bbb()');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'static = 42');
  }

  Future<void> test_BUILT_IN_sync() async {
    addTestFile('''
fa() sync {}
fb() sync* {}
void f() {
  bool sync = false;
}
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'sync');
    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'sync*');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'sync = false');
  }

  Future<void> test_BUILT_IN_typedef() async {
    addTestFile('''
typedef A();
typedef B = void Function();
typedef C = List<int>;
void f() {
  var typedef = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'typedef A();');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'typedef B =');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'typedef C =');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'typedef = 42');
  }

  Future<void> test_BUILT_IN_yield() async {
    addTestFile('''
void f() async* {
  yield 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'yield 42');
  }

  Future<void> test_BUILT_IN_yieldStar() async {
    addTestFile('''
void f() async* {
  yield* [];
}
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'yield*');
  }

  Future<void> test_caseClause_case() async {
    addTestFile('''
void f(Object o) {
  if (o case 0) {}
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'case');
  }

  Future<void> test_castPattern_as() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case var x as int:
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'as int');
  }

  Future<void> test_CLASS() async {
    addTestFile('''
class AAA {}
AAA aaa;
Never nnn() => throw '';
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'AAA {}');
    assertHasRegion(HighlightRegionType.CLASS, 'AAA aaa');
    assertHasRegion(HighlightRegionType.CLASS, 'Never nnn');
  }

  Future<void> test_class_constructor_fieldFormalParameter() async {
    var testCode = TestCode.parse(r'''
class A {
  final int foo;
  A(this.foo);
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 5 |class| KEYWORD
6 + 1 |A| CLASS
12 + 5 |final| KEYWORD
18 + 3 |int| CLASS
22 + 3 |foo| INSTANCE_FIELD_DECLARATION
29 + 1 |A| CLASS
31 + 4 |this| KEYWORD
36 + 3 |foo| INSTANCE_FIELD_REFERENCE
''');
  }

  Future<void> test_class_method_functionTypedFormalParameter() async {
    var testCode = TestCode.parse(r'''
class A {
  void foo(int bar(String a)) {}
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 5 |class| KEYWORD
6 + 1 |A| CLASS
12 + 4 |void| KEYWORD
17 + 3 |foo| INSTANCE_METHOD_DECLARATION
21 + 3 |int| CLASS
25 + 3 |bar| PARAMETER_DECLARATION
29 + 6 |String| CLASS
36 + 1 |a| PARAMETER_DECLARATION
''');
  }

  Future<void> test_CLASS_notDynamic() async {
    addTestFile('''
dynamic f() {}
''');
    await prepareHighlights();
    assertNoRegion(HighlightRegionType.CLASS, 'dynamic f()');
  }

  Future<void> test_CLASS_notVoid() async {
    addTestFile('''
void f() {}
''');
    await prepareHighlights();
    assertNoRegion(HighlightRegionType.CLASS, 'void f()');
  }

  Future<void> test_COMMENT() async {
    addTestFile('''
/**
 * documentation comment
 */
void f() {
  // end-of-line comment
  my_function(1);
}

void my_function(String a) {
 /* block comment */
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.COMMENT_DOCUMENTATION, '/**', 32);
    assertHasRegion(HighlightRegionType.COMMENT_END_OF_LINE, '//', 22);
    assertHasRegion(HighlightRegionType.COMMENT_BLOCK, '/* b', 19);
  }

  Future<void> test_constantPattern_const() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case (const [0]):
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'const');
  }

  Future<void> test_CONSTRUCTOR_explicitNew() async {
    addTestFile('''
class AAA<T> {
  AAA() {}
  AAA.name(p) {}
}
void f() {
  new AAA<int>();
  new AAA<int>.name(42);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'AAA<int>(');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'AAA<int>.name(');
    assertHasRegion(HighlightRegionType.CLASS, 'int>(');
    assertHasRegion(HighlightRegionType.CLASS, 'int>.name(');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'name(42)');
  }

  Future<void> test_CONSTRUCTOR_implicitNew() async {
    addTestFile('''
class AAA<T> {
  AAA() {}
  AAA.name(p) {}
}
void f() {
  AAA<int>();
  AAA<int>.name(42);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'AAA<int>(');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'AAA<int>.name(');
    assertHasRegion(HighlightRegionType.CLASS, 'int>(');
    assertHasRegion(HighlightRegionType.CLASS, 'int>.name(');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'name(p)');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR, 'name(42)');
  }

  Future<void> test_CONSTRUCTOR_TEAR_OFF_named() async {
    addTestFile('''
class A<T> {
  A.named();
}
void f() {
  A<int>.named;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'A<int');
    assertHasRegion(HighlightRegionType.CLASS, 'int>');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR_TEAR_OFF, 'named;');
  }

  Future<void> test_CONSTRUCTOR_TEAR_OFF_new_declared() async {
    addTestFile('''
class A<T> {
  A.new();
}
void f() {
  A<int>.new;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'A<int');
    assertHasRegion(HighlightRegionType.CLASS, 'int>');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR_TEAR_OFF, 'new;');
  }

  Future<void> test_CONSTRUCTOR_TEAR_OFF_new_synthetic() async {
    addTestFile('''
class A<T> {}
void f() {
  A<int>.new;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'A<int');
    assertHasRegion(HighlightRegionType.CLASS, 'int>');
    assertHasRegion(HighlightRegionType.CONSTRUCTOR_TEAR_OFF, 'new;');
  }

  Future<void> test_declaredVariablePattern_final() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case (final x as int):
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'final');
  }

  Future<void> test_declaredVariablePattern_var() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case (var x as int):
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
  }

  Future<void> test_DIRECTIVE() async {
    addTestFile('''
library lib;
import 'dart:math';
export 'dart:math';
part 'part.dart';
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.DIRECTIVE, 'library lib;');
    assertHasStringRegion(HighlightRegionType.DIRECTIVE, "import 'dart:math';");
    assertHasStringRegion(HighlightRegionType.DIRECTIVE, "export 'dart:math';");
    assertHasStringRegion(HighlightRegionType.DIRECTIVE, "part 'part.dart';");
  }

  Future<void> test_DIRECTIVE_configuration() async {
    addTestFile('''
import 'dart:math'
  if (dart.library.io) 'dart:io'
  if (dart.library.html) 'dart:html';
export 'dart:math'
  if (dart.library.io) 'dart:io'
  if (dart.library.html) 'dart:html';
''');
    await prepareHighlights();

    assertHasStringRegion(HighlightRegionType.DIRECTIVE, '''
import 'dart:math'
  if (dart.library.io) 'dart:io'
  if (dart.library.html) 'dart:html';''');

    assertHasStringRegion(HighlightRegionType.DIRECTIVE, '''
export 'dart:math'
  if (dart.library.io) 'dart:io'
  if (dart.library.html) 'dart:html';''');

    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'if');
    assertHasStringRegion(HighlightRegionType.LITERAL_STRING, "'dart:math'");
    assertHasStringRegion(HighlightRegionType.LITERAL_STRING, "'dart:io'");
    assertHasStringRegion(HighlightRegionType.LITERAL_STRING, "'dart:html'");
  }

  Future<void> test_DIRECTIVE_partOf() async {
    addTestFile('''
part of my.lib.name;
''');
    _addLibraryForTestPart();
    await prepareHighlights();
    assertHasStringRegion(
      HighlightRegionType.DIRECTIVE,
      'part of my.lib.name;',
    );
  }

  Future<void> test_DYNAMIC_LOCAL_VARIABLE() async {
    addTestFile('''
f() {}
void f(p) {
  var v = f();
  v;
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION, 'v = f()');
    assertHasRegion(HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE, 'v;');
  }

  Future<void> test_DYNAMIC_PARAMETER() async {
    addTestFile('''
void f(p) {
  print(p);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION, 'p)');
    assertHasRegion(HighlightRegionType.DYNAMIC_PARAMETER_REFERENCE, 'p);');
  }

  Future<void> test_DYNAMIC_VARIABLE_field() async {
    addTestFile('''
class A {
  var f;
  m() {
    f = 1;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_DECLARATION, 'f;');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_REFERENCE, 'f = 1');
  }

  Future<void> test_enum_constant() async {
    var testCode = TestCode.parse(r'''
enum MyEnum {AAA, BBB}

void f() {
  MyEnum.AAA;
  MyEnum.BBB;
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 4 |enum| KEYWORD
5 + 6 |MyEnum| ENUM
13 + 3 |AAA| ENUM_CONSTANT
18 + 3 |BBB| ENUM_CONSTANT
24 + 4 |void| KEYWORD
29 + 1 |f| TOP_LEVEL_FUNCTION_DECLARATION
37 + 6 |MyEnum| ENUM
44 + 3 |AAA| ENUM_CONSTANT
51 + 6 |MyEnum| ENUM
58 + 3 |BBB| ENUM_CONSTANT
''');
  }

  Future<void> test_enum_constructor() async {
    var testCode = TestCode.parse(r'''
const a = 0;

enum E<T> {
  [!v<int>.named(a);
  E.named(T a);!]
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, 0, r'''
28 + 1 |v| ENUM_CONSTANT
30 + 3 |int| CLASS
35 + 5 |named| CONSTRUCTOR
41 + 1 |a| TOP_LEVEL_GETTER_REFERENCE
47 + 1 |E| ENUM
49 + 5 |named| CONSTRUCTOR
55 + 1 |T| TYPE_PARAMETER
57 + 1 |a| PARAMETER_DECLARATION
''');
  }

  Future<void> test_enum_field_instance() async {
    addTestFile('''
enum E {
  v;
  final int a = 0;
  E(this.a);
}

void f(E e) {
  e.a;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int ');
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_DECLARATION, 'a = 0');
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_REFERENCE, 'a);');
    assertHasRegion(HighlightRegionType.INSTANCE_GETTER_REFERENCE, 'a;');
  }

  Future<void> test_enum_field_static() async {
    addTestFile('''
enum E {
  v;
  static final int a = 0;
}

void f() {
  E.a;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int ');
    assertHasRegion(HighlightRegionType.STATIC_FIELD_DECLARATION, 'a = 0');
    assertHasRegion(HighlightRegionType.STATIC_GETTER_REFERENCE, 'a;');
  }

  Future<void> test_enum_getter_instance() async {
    addTestFile('''
enum E {
  v;
  int get foo => 0;
}

void f(E e) {
  e.foo;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int get');
    assertHasRegion(HighlightRegionType.INSTANCE_GETTER_DECLARATION, 'foo =>');
    assertHasRegion(HighlightRegionType.INSTANCE_GETTER_REFERENCE, 'foo;');
  }

  Future<void> test_enum_getter_static() async {
    addTestFile('''
enum E {
  v;
  static int get foo => 0;
}

void f() {
  E.foo;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int get');
    assertHasRegion(HighlightRegionType.STATIC_GETTER_DECLARATION, 'foo =>');
    assertHasRegion(HighlightRegionType.STATIC_GETTER_REFERENCE, 'foo;');
  }

  Future<void> test_enum_method_instance() async {
    addTestFile('''
enum E {
  v;
  int foo(int a) {
    return a;
  }
}

void f(E e) {
  e.foo();
  e.foo;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int foo');
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_DECLARATION, 'foo(int');
    assertHasRegion(HighlightRegionType.CLASS, 'int a');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'a)');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'a;');
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'foo();');
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_TEAR_OFF, 'foo;');
  }

  Future<void> test_enum_method_static() async {
    addTestFile('''
enum E {
  v;
  static int foo(int a) {
    return a;
  }
}

void f() {
  E.foo();
  E.foo;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int foo');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_DECLARATION, 'foo(int');
    assertHasRegion(HighlightRegionType.CLASS, 'int a');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'a)');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'a;');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_REFERENCE, 'foo();');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_TEAR_OFF, 'foo;');
  }

  Future<void> test_enum_name() async {
    addTestFile('''
enum MyEnum {A, B, C}

MyEnum value;
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ENUM, 'MyEnum {');
    assertHasRegion(HighlightRegionType.ENUM, 'MyEnum value;');
  }

  Future<void> test_enum_setter_instance() async {
    addTestFile('''
enum E {
  v;
  set foo(int _) {}
}

void f(E e) {
  e.foo = 0;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int _');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_DECLARATION, 'foo(int');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_REFERENCE, 'foo = 0;');
  }

  Future<void> test_enum_setter_static() async {
    addTestFile('''
enum E {
  v;
  static set foo(int _) {}
}

void f() {
  E.foo = 0;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int _');
    assertHasRegion(HighlightRegionType.STATIC_SETTER_DECLARATION, 'foo(int');
    assertHasRegion(HighlightRegionType.STATIC_SETTER_REFERENCE, 'foo = 0;');
  }

  Future<void> test_enum_typeParameter() async {
    addTestFile('''
enum E<T> {
  v;
  T? foo() => null;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T>');
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T?');
  }

  Future<void> test_EXTENSION() async {
    addTestFile('''
extension E on int {
  void foo() {}
  static void bar() {}
}
void f() {
  E(0).foo();
  E.bar();
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.EXTENSION, 'E on int');
    assertHasRegion(HighlightRegionType.EXTENSION, 'E(0)');
    assertHasRegion(HighlightRegionType.EXTENSION, 'E.bar()');
  }

  Future<void> test_extensionType() async {
    final testCode = TestCode.parse(r'''
extension type A<T>.named(int it) implements num {}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 9 |extension| BUILT_IN
10 + 4 |type| BUILT_IN
15 + 1 |A| EXTENSION_TYPE
17 + 1 |T| TYPE_PARAMETER
20 + 5 |named| CONSTRUCTOR
26 + 3 |int| CLASS
30 + 2 |it| INSTANCE_FIELD_DECLARATION
34 + 10 |implements| BUILT_IN
45 + 3 |num| CLASS
''');
  }

  Future<void> test_forEachPartsWithPattern_final() async {
    addTestFile('''
void f(List<Object> l) {
  for (final i as int in l) {}
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'final');
  }

  Future<void> test_forEachPartsWithPattern_var() async {
    addTestFile('''
void f(List<Object> l) {
  for (var i as int in l) {}
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
  }

  Future<void> test_forPartsWithDeclarations() async {
    addTestFile('''
void f() {
  for (var i = 0; i < 10; i++) {}
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LOCAL_VARIABLE_DECLARATION, 'i = 0');
    assertHasRegion(HighlightRegionType.LOCAL_VARIABLE_REFERENCE, 'i < 10');
    assertHasRegion(HighlightRegionType.LOCAL_VARIABLE_REFERENCE, 'i++');
  }

  Future<void> test_forPartsWithDeclarations_dynamic() async {
    addTestFile('''
void f() {
  for (dynamic i = 0; i < 10; i++) {}
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION, 'i = 0');
    assertHasRegion(
        HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE, 'i < 10');
    assertHasRegion(
        HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE, 'i++');
  }

  Future<void> test_FUNCTION_TYPE_ALIAS() async {
    addTestFile('''
typedef A();
typedef B = void Function();
void f(A a, B b) {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.FUNCTION_TYPE_ALIAS, 'A();');
    assertHasRegion(HighlightRegionType.FUNCTION_TYPE_ALIAS, 'A a');
    assertHasRegion(HighlightRegionType.FUNCTION_TYPE_ALIAS, 'B = ');
    assertHasRegion(HighlightRegionType.FUNCTION_TYPE_ALIAS, 'B b');
  }

  Future<void> test_GETTER() async {
    addTestFile('''
get aaa => null;
class A {
  get bbb => null;
  static get ccc => null;
}
void f(A a) {
  aaa;
  a.bbb;
  A.ccc;
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_GETTER_DECLARATION, 'aaa => null');
    assertHasRegion(
        HighlightRegionType.INSTANCE_GETTER_DECLARATION, 'bbb => null');
    assertHasRegion(
        HighlightRegionType.STATIC_GETTER_DECLARATION, 'ccc => null');
    assertHasRegion(HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE, 'aaa;');
    assertHasRegion(HighlightRegionType.INSTANCE_GETTER_REFERENCE, 'bbb;');
    assertHasRegion(HighlightRegionType.STATIC_GETTER_REFERENCE, 'ccc;');
  }

  Future<void> test_IDENTIFIER_DEFAULT() async {
    addTestFile('''
void f() {
  aaa = 42;
  bbb(84);
  CCC ccc;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.IDENTIFIER_DEFAULT, 'aaa = 42');
    assertHasRegion(HighlightRegionType.IDENTIFIER_DEFAULT, 'bbb(84)');
    assertHasRegion(HighlightRegionType.IDENTIFIER_DEFAULT, 'CCC ccc');
  }

  Future<void> test_IMPORT_PREFIX() async {
    addTestFile('''
import 'dart:math' as ma;
void f() {
  ma.max(1, 2);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.IMPORT_PREFIX, 'ma;');
    assertHasRegion(HighlightRegionType.IMPORT_PREFIX, 'ma.max');
  }

  Future<void> test_INSTANCE_FIELD() async {
    addTestFile('''
class A {
  int aaa = 1;
  int bbb = 2;
  A([this.bbb = 3]);
}
void f(A a) {
  a.aaa = 4;
  a.bbb = 5;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_DECLARATION, 'aaa = 1');
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_DECLARATION, 'bbb = 2');
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_REFERENCE, 'bbb = 3');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_REFERENCE, 'aaa = 4');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_REFERENCE, 'bbb = 5');
  }

  Future<void> test_INSTANCE_FIELD_dynamic() async {
    addTestFile('''
class A {
  var f;
  A(this.f);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_DECLARATION, 'f;');
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_REFERENCE, 'f);');
  }

  Future<void> test_instanceCreation_class() async {
    final testCode = TestCode.parse(r'''
class A {
  A.named(int it);
}
void f() {
  [!A.named(0)!];
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, 0, r'''
44 + 1 |A| CONSTRUCTOR
46 + 5 |named| CONSTRUCTOR
52 + 1 |0| LITERAL_INTEGER
''');
  }

  Future<void> test_instanceCreation_extensionType() async {
    final testCode = TestCode.parse(r'''
extension type A.named(T it) {}
void f() {
  [!A.named(0)!];
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, 0, r'''
45 + 1 |A| CONSTRUCTOR
47 + 5 |named| CONSTRUCTOR
53 + 1 |0| LITERAL_INTEGER
''');
  }

  Future<void> test_KEYWORD() async {
    addTestFile('''
void f() {
  assert(true);
  for (;;) break;
  switch (0) {
    case 0: break;
    default: break;
  }
  try {} catch (e) {}
  const v1 = 0;
  for (;;) continue;
  do {} while (true);
  if (true) {} else {}
  var v2 = false;
  final v3 = 1;
  try {} finally {}
  for (var v4 in []) {}
  v3 is int;
  new A();
  try {} catch (e) {rethrow;}
  var v5 = true;
  while (true) {}
}
class A {}
class B extends A {
  B() : super();
  m() {
    return this;
  }
}
class C = Object with A;
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'assert(true)');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for (;;)');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for (var v4 in');
    assertHasRegion(HighlightRegionType.KEYWORD, 'var v4 in');
    assertHasRegion(HighlightRegionType.KEYWORD, 'break;');
    assertHasRegion(HighlightRegionType.KEYWORD, 'case 0:');
    assertHasRegion(HighlightRegionType.KEYWORD, 'catch (e) {}');
    assertHasRegion(HighlightRegionType.KEYWORD, 'class A {}');
    assertHasRegion(HighlightRegionType.KEYWORD, 'const v1');
    assertHasRegion(HighlightRegionType.KEYWORD, 'continue;');
    assertHasRegion(HighlightRegionType.KEYWORD, 'default:');
    assertHasRegion(HighlightRegionType.KEYWORD, 'do {} while');
    assertHasRegion(HighlightRegionType.KEYWORD, 'if (true)');
    assertHasRegion(HighlightRegionType.KEYWORD, 'false;');
    assertHasRegion(HighlightRegionType.KEYWORD, 'final v3 =');
    assertHasRegion(HighlightRegionType.KEYWORD, 'finally {}');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in []');
    assertHasRegion(HighlightRegionType.KEYWORD, 'is int');
    assertHasRegion(HighlightRegionType.KEYWORD, 'new A();');
    assertHasRegion(HighlightRegionType.KEYWORD, 'rethrow;');
    assertHasRegion(HighlightRegionType.KEYWORD, 'return this');
    assertHasRegion(HighlightRegionType.KEYWORD, 'super();');
    assertHasRegion(HighlightRegionType.KEYWORD, 'switch (0)');
    assertHasRegion(HighlightRegionType.KEYWORD, 'this;');
    assertHasRegion(HighlightRegionType.KEYWORD, 'true;');
    assertHasRegion(HighlightRegionType.KEYWORD, 'try {');
    assertHasRegion(HighlightRegionType.KEYWORD, 'while (true) {}');
    assertHasRegion(HighlightRegionType.KEYWORD, 'while (true);');
    assertHasRegion(HighlightRegionType.KEYWORD, 'with A;');
  }

  Future<void> test_KEYWORD_const_constructor() async {
    addTestFile('''
class A {
  const A(); // 1
}
const a = const A(); // 2
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'const A(); // 1');
    assertHasRegion(HighlightRegionType.KEYWORD, 'const a =');
    assertHasRegion(HighlightRegionType.KEYWORD, 'const A(); // 2');
  }

  Future<void> test_KEYWORD_const_list() async {
    addTestFile('''
var v = const [];
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'const');
  }

  Future<void> test_KEYWORD_const_map() async {
    addTestFile('''
var v = const {0 : 1};
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'const');
  }

  Future<void> test_KEYWORD_const_set() async {
    addTestFile('''
var v = const {0};
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'const');
  }

  Future<void> test_KEYWORD_if_list() async {
    addTestFile('''
f(a, b) {
  return [if (a < b) 'a'];
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
  }

  Future<void> test_KEYWORD_if_map() async {
    addTestFile('''
f(a, b) {
  return {if (a < b) 'a' : 1};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
  }

  Future<void> test_KEYWORD_if_set() async {
    addTestFile('''
f(a, b) {
  return {if (a < b) 'a'};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
  }

  Future<void> test_KEYWORD_ifElse_list() async {
    addTestFile('''
f(a, b) {
  return [if (a < b) 'a' else 'b'];
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
    assertHasRegion(HighlightRegionType.KEYWORD, 'else');
  }

  Future<void> test_KEYWORD_ifElse_map() async {
    addTestFile('''
f(a, b) {
  return {if (a < b) 'a' : 1 else 'b' : 2};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
    assertHasRegion(HighlightRegionType.KEYWORD, 'else');
  }

  Future<void> test_KEYWORD_ifElse_set() async {
    addTestFile('''
f(a, b) {
  return {if (a < b) 'a' else 'b'};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
    assertHasRegion(HighlightRegionType.KEYWORD, 'else');
  }

  Future<void> test_KEYWORD_ifElse_statement() async {
    addTestFile('''
f(a, b) {
  if (a < b) {} else {}
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'if');
    assertHasRegion(HighlightRegionType.KEYWORD, 'else');
  }

  Future<void> test_KEYWORD_late() async {
    addTestFile('''
class C {
  late int x;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'late');
  }

  Future<void> test_KEYWORD_required() async {
    addTestFile('''
void f({required int x}) {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'required');
  }

  Future<void> test_KEYWORD_void() async {
    addTestFile('''
void f() {
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'void f()');
  }

  Future<void> test_LABEL() async {
    addTestFile('''
void f() {
myLabel:
  while (true) {
    break myLabel;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LABEL, 'myLabel:');
    assertHasRegion(HighlightRegionType.LABEL, 'myLabel;');
  }

  Future<void> test_LIBRARY_NAME_libraryDirective() async {
    addTestFile('''
library my.lib.name;
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.LIBRARY_NAME, 'my.lib.name');
  }

  Future<void> test_LIBRARY_NAME_partOfDirective() async {
    _addLibraryForTestPart();
    addTestFile('''
part of my.lib.name;
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.LIBRARY_NAME, 'my.lib.name');
  }

  Future<void> test_LITERAL_BOOLEAN() async {
    addTestFile('var V = true;');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LITERAL_BOOLEAN, 'true;');
  }

  Future<void> test_LITERAL_DOUBLE() async {
    addTestFile('var V = 4.2;');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LITERAL_DOUBLE, '4.2;', '4.2'.length);
  }

  Future<void> test_LITERAL_INTEGER() async {
    addTestFile('var V = 42;');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LITERAL_INTEGER, '42;');
  }

  Future<void> test_LITERAL_LIST() async {
    addTestFile('var V = <int>[1, 2, 3];');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.LITERAL_LIST, '<int>[1, 2, 3]');
  }

  Future<void> test_LITERAL_MAP() async {
    addTestFile("var V = const <int, String>{1: 'a', 2: 'b', 3: 'c'};");
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.LITERAL_MAP,
        "const <int, String>{1: 'a', 2: 'b', 3: 'c'}");
  }

  Future<void> test_LITERAL_STRING() async {
    addTestFile('var V = "abc";');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.LITERAL_STRING, '"abc";', '"abc"'.length);
  }

  Future<void> test_LOCAL_FUNCTION() async {
    addTestFile('''
void f() {
  fff() {}
  fff();
  fff;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LOCAL_FUNCTION_DECLARATION, 'fff() {}');
    assertHasRegion(HighlightRegionType.LOCAL_FUNCTION_REFERENCE, 'fff();');
    assertHasRegion(HighlightRegionType.LOCAL_FUNCTION_TEAR_OFF, 'fff;');
  }

  Future<void> test_LOCAL_VARIABLE() async {
    addTestFile('''
void f() {
  int vvv = 0;
  vvv;
  vvv = 1;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LOCAL_VARIABLE_DECLARATION, 'vvv = 0');
    assertHasRegion(HighlightRegionType.LOCAL_VARIABLE_REFERENCE, 'vvv;');
    assertHasRegion(HighlightRegionType.LOCAL_VARIABLE_REFERENCE, 'vvv = 1;');
  }

  Future<void> test_METHOD() async {
    addTestFile('''
class A {
  aaa() {}
  static bbb() {}
}
void f(A a) {
  a.aaa();
  a.aaa;
  A.bbb();
  A.bbb;
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.INSTANCE_METHOD_DECLARATION, 'aaa() {}');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_DECLARATION, 'bbb() {}');
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'aaa();');
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_TEAR_OFF, 'aaa;');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_REFERENCE, 'bbb();');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_TEAR_OFF, 'bbb;');
  }

  Future<void> test_METHOD_bestType() async {
    addTestFile('''
void f(p) {
  if (p is List) {
    p.add(null);
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'add(null)');
  }

  Future<void> test_mixin() async {
    var testCode = TestCode.parse(r'''
mixin M on int {}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 5 |mixin| BUILT_IN
6 + 1 |M| MIXIN
8 + 2 |on| BUILT_IN
11 + 3 |int| CLASS
''');
  }

  Future<void> test_mixin_base() async {
    var testCode = TestCode.parse(r'''
base mixin M {}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 4 |base| BUILT_IN
5 + 5 |mixin| BUILT_IN
11 + 1 |M| MIXIN
''');
  }

  Future<void> test_namedExpression_namedParameter() async {
    addTestFile('''
void f({int a}) {}

void g() {
  f(a: 0);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'a})');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'a: 0');
  }

  Future<void> test_namedType_extensionType() async {
    final testCode = TestCode.parse(r'''
extension type A<T>(T it) {}
void f([!A<int>!] a) {}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, 0, r'''
36 + 1 |A| EXTENSION_TYPE
38 + 3 |int| CLASS
''');
  }

  Future<void> test_PARAMETER() async {
    addTestFile('''
void f(int p) {
  p;
  p = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'p) {');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'p;');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'p = 42');
  }

  Future<void> test_PARAMETER_named() async {
    addTestFile('''
class C {
  final int aaa;
  C({this.aaa, int bbb});
}
void f() {
  new C(aaa: 1, bbb: 2);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_REFERENCE, 'aaa,');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'bbb}');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'aaa: 1');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'bbb: 2');
  }

  Future<void> test_PARAMETER_named_anywhere() async {
    addTestFile('''
void f(int aaa, int bbb, {int? ccc, int? ddd}) {}

void g() {
  f(0, ccc: 2, 1, ddd: 3);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'ccc: 2');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'ddd: 3');
  }

  Future<void> test_PARAMETER_super_children() async {
    addTestFile('''
class A {
  A(Object aaa);
}
class B extends A {
  B(int super.aaa<T>(double a /*0*/));
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int');
    assertHasRegion(HighlightRegionType.CLASS, 'double');
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T>');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'a /*0*/');
  }

  Future<void> test_PARAMETER_super_requiredNamed() async {
    addTestFile('''
class A {
  A({required int aaa});
}
class B extends A {
  B({required super.aaa /*0*/});
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'required super.aaa');
    assertHasRegion(HighlightRegionType.KEYWORD, 'super.aaa');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'aaa /*0*/');
  }

  Future<void> test_PARAMETER_super_requiredPositional() async {
    addTestFile('''
class A {
  A(int aaa);
}
class B extends A {
  B(super.aaa /*0*/);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'super.aaa');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'aaa /*0*/');
  }

  Future<void> test_patternVariableDeclaration_final() async {
    addTestFile('''
void f(Object o) {
  final i as int = o;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'final');
  }

  Future<void> test_patternVariableDeclaration_var() async {
    addTestFile('''
void f(Object o) {
  var i as int = o;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
  }

  Future<void> test_propertyAccess_extensionTypeName() async {
    final testCode = TestCode.parse(r'''
extension type A.named(T it) {
  static const V = 0;
}
void f() {
  [!A.V!];
}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, 0, r'''
68 + 1 |A| EXTENSION_TYPE
70 + 1 |V| STATIC_GETTER_REFERENCE
''');
  }

  Future<void> test_recordTypeAnnotation_named() async {
    addTestFile('''
({int f1, String f2})? r;
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int f1');
    assertHasRegion(HighlightRegionType.FIELD, 'f1');
    assertHasRegion(HighlightRegionType.CLASS, 'String f2');
    assertHasRegion(HighlightRegionType.FIELD, 'f2');
  }

  Future<void> test_recordTypeAnnotation_positional() async {
    addTestFile('''
(int, String f2)? r;
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'int, ');
    assertHasRegion(HighlightRegionType.CLASS, 'String f2)');
    assertHasRegion(HighlightRegionType.FIELD, 'f2)');
  }

  Future<void> test_recordTypeLiteral_named() async {
    final code = '(0, f1: 1, f2: 2)';
    addTestFile('''
final r = $code;
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.LITERAL_RECORD, code);
    assertHasRegion(HighlightRegionType.LITERAL_INTEGER, '0,');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'f1:');
    assertHasRegion(HighlightRegionType.LITERAL_INTEGER, '1,');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'f2:');
    assertHasRegion(HighlightRegionType.LITERAL_INTEGER, '2)');
  }

  Future<void> test_SETTER_DECLARATION() async {
    addTestFile('''
set aaa(x) {}
class A {
  set bbb(x) {}
  static set ccc(x) {}
}
void f(A a) {
  aaa = 1;
  a.bbb = 2;
  A.ccc = 3;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.TOP_LEVEL_SETTER_DECLARATION, 'aaa(x)');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_DECLARATION, 'bbb(x)');
    assertHasRegion(HighlightRegionType.STATIC_SETTER_DECLARATION, 'ccc(x)');
    assertHasRegion(HighlightRegionType.TOP_LEVEL_SETTER_REFERENCE, 'aaa = 1');
    assertHasRegion(HighlightRegionType.INSTANCE_SETTER_REFERENCE, 'bbb = 2');
    assertHasRegion(HighlightRegionType.STATIC_SETTER_REFERENCE, 'ccc = 3');
  }

  Future<void> test_STATIC_FIELD() async {
    addTestFile('''
class A {
  static aaa = 1;
  static get bbb => null;
  static set ccc(x) {}
}
void f() {
  A.aaa = 2;
  A.bbb;
  A.ccc = 3;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.STATIC_FIELD_DECLARATION, 'aaa = 1');
    assertHasRegion(HighlightRegionType.STATIC_SETTER_REFERENCE, 'aaa = 2');
    assertHasRegion(HighlightRegionType.STATIC_GETTER_REFERENCE, 'bbb;');
    assertHasRegion(HighlightRegionType.STATIC_SETTER_REFERENCE, 'ccc = 3');
  }

  Future<void> test_switchExpression_switch() async {
    addTestFile('''
String f(Object o) {
  return switch (o) {
    3 => '3';
  };
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'switch');
  }

  Future<void> test_TOP_LEVEL_FUNCTION() async {
    addTestFile('''
fff(p) {}
void f() {
  fff(42);
  fff;
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION, 'fff(p) {}');
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE, 'fff(42)');
    assertHasRegion(HighlightRegionType.TOP_LEVEL_FUNCTION_TEAR_OFF, 'fff;');
  }

  Future<void> test_TOP_LEVEL_VARIABLE() async {
    addTestFile('''
const V1 = 1;
var V2 = 2;
@V1 // annotation
void f() {
  print(V1);
  V2 = 3;
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION, 'V1 = 1');
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION, 'V2 = 2');
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE, 'V1 // annotation');
    assertHasRegion(HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE, 'V1);');
    assertHasRegion(HighlightRegionType.TOP_LEVEL_SETTER_REFERENCE, 'V2 = 3');
  }

  Future<void> test_TYPE_NAME_DYNAMIC() async {
    addTestFile('''
dynamic f() {
  dynamic = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.TYPE_NAME_DYNAMIC, 'dynamic f()');
    assertNoRegion(HighlightRegionType.IDENTIFIER_DEFAULT, 'dynamic f()');
    assertNoRegion(HighlightRegionType.TYPE_NAME_DYNAMIC, 'dynamic = 42');
  }

  Future<void> test_TYPE_PARAMETER() async {
    addTestFile('''
class A<T> {
  T fff;
  T mmm(T p) => null;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T> {');
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T fff;');
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T mmm(');
    assertHasRegion(HighlightRegionType.TYPE_PARAMETER, 'T p)');
  }

  Future<void> test_typedef_classic() async {
    var testCode = TestCode.parse(r'''
typedef int MyFunction<T extends num>(T a, String b);
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 3 |int| CLASS
12 + 10 |MyFunction| FUNCTION_TYPE_ALIAS
23 + 1 |T| TYPE_PARAMETER
33 + 3 |num| CLASS
38 + 1 |T| TYPE_PARAMETER
40 + 1 |a| PARAMETER_DECLARATION
43 + 6 |String| CLASS
50 + 1 |b| PARAMETER_DECLARATION
''');
  }

  Future<void> test_typedef_classic_functionTypedFormalParameter() async {
    var testCode = TestCode.parse(r'''
typedef int MyFunction(bool foo());
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 3 |int| CLASS
12 + 10 |MyFunction| FUNCTION_TYPE_ALIAS
23 + 4 |bool| CLASS
28 + 3 |foo| PARAMETER_DECLARATION
''');
  }

  Future<void> test_typedef_classic_reference() async {
    var testCode = TestCode.parse(r'''
typedef void MyFunction();
void f(MyFunction a) {}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 4 |void| KEYWORD
13 + 10 |MyFunction| FUNCTION_TYPE_ALIAS
27 + 4 |void| KEYWORD
32 + 1 |f| TOP_LEVEL_FUNCTION_DECLARATION
34 + 10 |MyFunction| FUNCTION_TYPE_ALIAS
45 + 1 |a| PARAMETER_DECLARATION
''');
  }

  Future<void> test_typedef_modern_dynamicType() async {
    var testCode = TestCode.parse(r'''
typedef A = dynamic;
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 1 |A| TYPE_ALIAS
12 + 7 |dynamic| TYPE_NAME_DYNAMIC
''');
  }

  Future<void> test_typedef_modern_functionType() async {
    var testCode = TestCode.parse(r'''
typedef MyFunction = int Function(int a, {required String b});
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 10 |MyFunction| FUNCTION_TYPE_ALIAS
21 + 3 |int| CLASS
25 + 8 |Function| BUILT_IN
34 + 3 |int| CLASS
38 + 1 |a| PARAMETER_DECLARATION
42 + 8 |required| KEYWORD
51 + 6 |String| CLASS
58 + 1 |b| PARAMETER_DECLARATION
''');
  }

  Future<void> test_typedef_modern_interfaceType() async {
    var testCode = TestCode.parse(r'''
typedef A = double;
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 1 |A| TYPE_ALIAS
12 + 6 |double| CLASS
''');
  }

  Future<void> test_typedef_modern_interfaceType_typeArguments() async {
    var testCode = TestCode.parse(r'''
typedef A = Map<int, String>;
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 1 |A| TYPE_ALIAS
12 + 3 |Map| CLASS
16 + 3 |int| CLASS
21 + 6 |String| CLASS
''');
  }

  Future<void> test_typedef_modern_reference() async {
    var testCode = TestCode.parse(r'''
typedef A = void Function();
void f(A a) {}
''');
    addTestFile(testCode.code);
    await prepareHighlights();
    assertHighlightText(testCode, -1, r'''
0 + 7 |typedef| BUILT_IN
8 + 1 |A| FUNCTION_TYPE_ALIAS
12 + 4 |void| KEYWORD
17 + 8 |Function| BUILT_IN
29 + 4 |void| KEYWORD
34 + 1 |f| TOP_LEVEL_FUNCTION_DECLARATION
36 + 1 |A| FUNCTION_TYPE_ALIAS
38 + 1 |a| PARAMETER_DECLARATION
''');
  }

  Future<void>
      test_UNRESOLVED_INSTANCE_MEMBER_REFERENCE_dynamicVarTarget() async {
    addTestFile('''
void f(p) {
  p.aaa;
  p.aaa++;
  p.aaa += 0;
  ++p.aaa; // ++
  p.aaa = 0;
  p.bbb(0);
  ''.length.ccc().ddd();
}
''');
    await prepareHighlights();
    var type = HighlightRegionType.UNRESOLVED_INSTANCE_MEMBER_REFERENCE;
    assertHasRegion(type, 'aaa');
    assertHasRegion(type, 'aaa++');
    assertHasRegion(type, 'aaa += 0');
    assertHasRegion(type, 'aaa; // ++');
    assertHasRegion(type, 'aaa =');
    assertHasRegion(type, 'bbb(');
    assertHasRegion(type, 'ddd()');
  }

  Future<void>
      test_UNRESOLVED_INSTANCE_MEMBER_REFERENCE_nonDynamicTarget() async {
    addTestFile('''
import 'dart:math' as math;
void f(String str) {
  new Object().aaa();
  math.bbb();
  str.ccc();
}
class A {
  m() {
    unresolved(1);
    this.unresolved(2);
    super.unresolved(3);
  }
}
''');
    await prepareHighlights();
    var type = HighlightRegionType.IDENTIFIER_DEFAULT;
    assertHasRegion(type, 'aaa()');
    assertHasRegion(type, 'bbb()');
    assertHasRegion(type, 'ccc()');
    assertHasRegion(type, 'unresolved(1)');
    assertHasRegion(type, 'unresolved(2)');
    assertHasRegion(type, 'unresolved(3)');
  }

  Future<void> test_whenClause_when() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case [int a, int n] when n > 0:
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'when');
  }

  Future<void> test_wildcardPattern_final() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case (final _ as int):
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'final');
  }

  Future<void> test_wildcardPattern_var() async {
    addTestFile('''
void f(Object o) {
  switch (o) {
    case (var _ as int):
      return;
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'var');
  }

  /// Returns the textual dump of the highlight regions that intersect with
  /// the [index]th range in [testCode] (or all code if `-1`).
  String _getHighlightText(TestCode testCode, int index) {
    var window = index == -1
        ? SourceRange(0, testCode.code.length)
        : testCode.ranges[index].sourceRange;

    // TODO(scheglov) Apparently, we don't sort in the server.
    var sortedRegions = regions.sortedBy<num>((e) => e.offset);

    var buffer = StringBuffer();
    for (var region in sortedRegions) {
      var offset = region.offset;
      var end = offset + region.length;
      if (window.contains(offset) || window.contains(end)) {
        var regionDesc = '$offset + ${region.length}';
        var regionCode = testCode.code.substring(offset, end);
        buffer.writeln('$regionDesc |$regionCode| ${region.type.name}');
      }
    }
    return buffer.toString();
  }
}

class HighlightsTestSupport extends PubPackageAnalysisServerTest {
  late List<HighlightRegion> regions;

  final Completer<void> _resultsAvailable = Completer();

  void assertHasRawRegion(HighlightRegionType type, int offset, int length) {
    for (var region in regions) {
      if (region.offset == offset &&
          region.length == length &&
          region.type == type) {
        return;
      }
    }
    // Attempt to figure out what's wrong with the expectation.
    for (var region in regions) {
      if (region.offset == offset && region.length == length) {
        fail('Expected a type of $type, but found a type of ${region.type} at '
            'offset=$offset; length=$length.');
      }
    }
    // Fall back to a general failure message.
    regions.sort((first, second) => first.offset.compareTo(second.offset));
    fail('Expected to find (offset=$offset; length=$length; type=$type) in\n'
        '${regions.join('\n')}');
  }

  void assertHasRegion(HighlightRegionType type, String search,
      [int length = -1]) {
    var offset = findOffset(search);
    length = findRegionLength(search, length);
    assertHasRawRegion(type, offset, length);
  }

  void assertHasStringRegion(HighlightRegionType type, String str) {
    var offset = findOffset(str);
    var length = str.length;
    assertHasRawRegion(type, offset, length);
  }

  void assertNoRawRegion(HighlightRegionType type, int offset, int length) {
    for (var region in regions) {
      if (region.offset == offset &&
          region.length == length &&
          region.type == type) {
        fail(
            'Not expected to find (offset=$offset; length=$length; type=$type) in\n'
            '${regions.join('\n')}');
      }
    }
  }

  void assertNoRegion(HighlightRegionType type, String search,
      [int length = -1]) {
    var offset = findOffset(search);
    length = findRegionLength(search, length);
    assertNoRawRegion(type, offset, length);
  }

  int findRegionLength(String search, int length) {
    if (length == -1) {
      length = 0;
      while (length < search.length) {
        var c = search.codeUnitAt(length);
        if (length == 0 && c == '@'.codeUnitAt(0)) {
          length++;
          continue;
        }
        if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
            c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
            c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
          break;
        }
        length++;
      }
    }
    return length;
  }

  Future<void> prepareHighlights() async {
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    return _resultsAvailable.future;
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
      print('SERVER_NOTIFICATION_ERROR: ${notification.toJson()}');
      _resultsAvailable.complete();
      fail('SERVER_NOTIFICATION_ERROR');
    }
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = AnalysisHighlightsParams.fromNotification(notification);
      if (params.file == testFile.path) {
        regions = params.regions;
        _resultsAvailable.complete();
      }
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  void _addLibraryForTestPart() {
    newFile('$testPackageLibPath/my_lib.dart', '''
library my.lib.name;
part 'test.dart';
    ''');
  }
}

@reflectiveTest
class HighlightTypeTest {
  void test_constructor() {
    expect(HighlightRegionType.CLASS,
        HighlightRegionType(HighlightRegionType.CLASS.name));
  }

  void test_toString() {
    expect(HighlightRegionType.CLASS.toString(), 'HighlightRegionType.CLASS');
  }

  void test_valueOf_unknown() {
    expect(() {
      HighlightRegionType('no-such-type');
    }, throwsException);
  }
}
