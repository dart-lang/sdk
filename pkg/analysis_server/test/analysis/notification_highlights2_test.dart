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
    defineReflectiveTests(AnalysisNotificationHighlightsTest);
    defineReflectiveTests(HighlightsWithControlFlowCollectionsTest);
    defineReflectiveTests(HighlightsWithNullSafetyTest);
    defineReflectiveTests(HighlightTypeTest);
  });
}

@reflectiveTest
class AnalysisNotificationHighlightsTest extends HighlightsTestSupport {
  Future<void> test_ANNOTATION_hasArguments() async {
    addTestFile('''
class AAA {
  const AAA(a, b, c);
}
@AAA(1, 2, 3) main() {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ANNOTATION, '@AAA(', '@AAA('.length);
    assertHasRegion(HighlightRegionType.ANNOTATION, ') main', ')'.length);
  }

  Future<void> test_ANNOTATION_noArguments() async {
    addTestFile('''
const AAA = 42;
@AAA main() {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ANNOTATION, '@AAA');
  }

  Future<void> test_BUILT_IN_abstract() async {
    addTestFile('''
abstract class A {};
abstract class B = Object with A;
main() {
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
main() {
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
main() {
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
main() async {
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

  Future<void> test_BUILT_IN_deferred() async {
    addTestFile('''
import 'dart:math' deferred as math;
main() {
  var deferred = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'deferred as math');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'deferred = 42');
  }

  Future<void> test_BUILT_IN_export() async {
    addTestFile('''
export "dart:math";
main() {
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
external main() {
  var external = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'external A()');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'external aaa()');
    assertHasRegion(HighlightRegionType.BUILT_IN, 'external main()');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'external = 42');
  }

  Future<void> test_BUILT_IN_factory() async {
    addTestFile('''
class A {
  A.named();
  factory A() => A.named();
}
main() {
  var factory = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'factory A()');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'factory = 42');
  }

  Future<void> test_BUILT_IN_get() async {
    addTestFile('''
get aaa => 1;
class A {
  get bbb => 2;
}
main() {
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
main() {
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
main() {
  var implements = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'implements A {}');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'implements = 42');
  }

  Future<void> test_BUILT_IN_import() async {
    addTestFile('''
import "foo.dart";
main() {
  var import = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'import "');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'import = 42');
  }

  Future<void> test_BUILT_IN_library() async {
    addTestFile('''
library lib;
main() {
  var library = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'library lib;');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'library = 42');
  }

  Future<void> test_BUILT_IN_native() async {
    addTestFile('''
class A native "A_native" {}
class B {
  bbb() native "bbb_native";
}
main() {
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
main() {
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
main() {
  var operator = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'operator +(');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'operator = 42');
  }

  Future<void> test_BUILT_IN_part() async {
    addTestFile('''
part "my_part.dart";
main() {
  var part = 42;
}''');
    newFile('/project/bin/my_part.dart', content: 'part of lib;');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'part "my_');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'part = 42');
  }

  Future<void> test_BUILT_IN_partOf() async {
    addTestFile('''
part of lib;
main() {
  var part = 1;
  var of = 2;
}''');
    _addLibraryForTestPart();
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'part of', 'part of'.length);
    assertNoRegion(HighlightRegionType.BUILT_IN, 'part = 1');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'of = 2');
  }

  Future<void> test_BUILT_IN_set() async {
    addTestFile('''
set aaa(x) {}
class A
  set bbb(x) {}
}
main() {
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
main() {
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
main() {
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
main() {
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
main() {
  var typedef = 42;
}''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'typedef A();');
    assertNoRegion(HighlightRegionType.BUILT_IN, 'typedef = 42');
  }

  Future<void> test_BUILT_IN_yield() async {
    addTestFile('''
main() async* {
  yield 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'yield 42');
  }

  Future<void> test_BUILT_IN_yieldStar() async {
    addTestFile('''
main() async* {
  yield* [];
}
''');
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.BUILT_IN, 'yield*');
  }

  Future<void> test_CLASS() async {
    addTestFile('''
class AAA {}
AAA aaa;
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.CLASS, 'AAA {}');
    assertHasRegion(HighlightRegionType.CLASS, 'AAA aaa');
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
void main() {
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

  Future<void> test_CONSTRUCTOR_explicitNew() async {
    addTestFile('''
class AAA<T> {
  AAA() {}
  AAA.name(p) {}
}
main() {
  new AAA<int>();
  new AAA<int>.name(42);
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

  Future<void> test_CONSTRUCTOR_implicitNew() async {
    addTestFile('''
class AAA<T> {
  AAA() {}
  AAA.name(p) {}
}
main() {
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

  Future<void> test_DIRECTIVE_partOf() async {
    addTestFile('''
part of lib;
''');
    _addLibraryForTestPart();
    await prepareHighlights();
    assertHasStringRegion(HighlightRegionType.DIRECTIVE, 'part of lib;');
  }

  Future<void> test_DYNAMIC_LOCAL_VARIABLE() async {
    addTestFile('''
f() {}
main(p) {
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
main(p) {
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

  Future<void> test_ENUM() async {
    addTestFile('''
enum MyEnum {A, B, C}
MyEnum value;
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ENUM, 'MyEnum {');
    assertHasRegion(HighlightRegionType.ENUM, 'MyEnum value;');
  }

  Future<void> test_ENUM_CONSTANT() async {
    addTestFile('''
enum MyEnum {AAA, BBB}
main() {
  print(MyEnum.AAA);
  print(MyEnum.BBB);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.ENUM_CONSTANT, 'AAA, ');
    assertHasRegion(HighlightRegionType.ENUM_CONSTANT, 'BBB}');
    assertHasRegion(HighlightRegionType.ENUM_CONSTANT, 'AAA);');
    assertHasRegion(HighlightRegionType.ENUM_CONSTANT, 'BBB);');
  }

  Future<void> test_FUNCTION_TYPE_ALIAS() async {
    addTestFile('''
typedef FFF(p);
main(FFF fff) {
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.FUNCTION_TYPE_ALIAS, 'FFF(p)');
    assertHasRegion(HighlightRegionType.FUNCTION_TYPE_ALIAS, 'FFF fff)');
  }

  Future<void> test_GETTER() async {
    addTestFile('''
get aaa => null;
class A {
  get bbb => null;
  static get ccc => null;
}
main(A a) {
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
main() {
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
main() {
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
main(A a) {
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

  Future<void> test_KEYWORD() async {
    addTestFile('''
main() {
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

  Future<void> test_KEYWORD_mixin() async {
    addTestFile('''
mixin M {}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.BUILT_IN, 'mixin');
  }

  Future<void> test_KEYWORD_void() async {
    addTestFile('''
void main() {
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'void main()');
  }

  Future<void> test_LABEL() async {
    addTestFile('''
main() {
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
main() {
  fff() {}
  fff();
  fff;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.LOCAL_FUNCTION_DECLARATION, 'fff() {}');
    assertHasRegion(HighlightRegionType.LOCAL_FUNCTION_REFERENCE, 'fff();');
    assertHasRegion(HighlightRegionType.LOCAL_FUNCTION_REFERENCE, 'fff;');
  }

  Future<void> test_LOCAL_VARIABLE() async {
    addTestFile('''
main() {
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
main(A a) {
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
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'aaa;');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_REFERENCE, 'bbb();');
    assertHasRegion(HighlightRegionType.STATIC_METHOD_REFERENCE, 'bbb;');
  }

  Future<void> test_METHOD_bestType() async {
    addTestFile('''
main(p) {
  if (p is List) {
    p.add(null);
  }
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'add(null)');
  }

  Future<void> test_PARAMETER() async {
    addTestFile('''
main(int p) {
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
main() {
  new C(aaa: 1, bbb: 2);
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.INSTANCE_FIELD_REFERENCE, 'aaa,');
    assertHasRegion(HighlightRegionType.PARAMETER_DECLARATION, 'bbb}');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'aaa: 1');
    assertHasRegion(HighlightRegionType.PARAMETER_REFERENCE, 'bbb: 2');
  }

  Future<void> test_SETTER_DECLARATION() async {
    addTestFile('''
set aaa(x) {}
class A {
  set bbb(x) {}
  static set ccc(x) {}
}
main(A a) {
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
main() {
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

  Future<void> test_TOP_LEVEL_FUNCTION() async {
    addTestFile('''
fff(p) {}
main() {
  fff(42);
}
''');
    await prepareHighlights();
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION, 'fff(p) {}');
    assertHasRegion(
        HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE, 'fff(42)');
  }

  Future<void> test_TOP_LEVEL_VARIABLE() async {
    addTestFile('''
const V1 = 1;
var V2 = 2;
@V1 // annotation
main() {
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
dynamic main() {
  dynamic = 42;
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.TYPE_NAME_DYNAMIC, 'dynamic main()');
    assertNoRegion(HighlightRegionType.IDENTIFIER_DEFAULT, 'dynamic main()');
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

  Future<void>
      test_UNRESOLVED_INSTANCE_MEMBER_REFERENCE_dynamicVarTarget() async {
    addTestFile('''
main(p) {
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
main(String str) {
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
}

class HighlightsTestSupport extends AbstractAnalysisTest {
  List<HighlightRegion> regions;

  final Completer<void> _resultsAvailable = Completer();

  void assertHasRawRegion(HighlightRegionType type, int offset, int length) {
    for (var region in regions) {
      if (region.offset == offset &&
          region.length == length &&
          region.type == type) {
        return;
      }
    }
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

  Future prepareHighlights() {
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
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
      if (params.file == testFile) {
        regions = params.regions;
        _resultsAvailable.complete();
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  void _addLibraryForTestPart() {
    newFile(join(testFolder, 'my_lib.dart'), content: '''
library lib;
part 'test.dart';
    ''');
  }
}

@reflectiveTest
class HighlightsWithControlFlowCollectionsTest extends HighlightsTestSupport {
  @failingTest
  Future<void> test_KEYWORD_awaitForIn_list() async {
    addTestFile('''
f(a) async {
  return [await for(var b in a) b];
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'await');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in');
  }

  @failingTest
  Future<void> test_KEYWORD_awaitForIn_map() async {
    addTestFile('''
f(a) async {
  return {await for(var b in a) b : 0};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'await');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in');
  }

  @failingTest
  Future<void> test_KEYWORD_awaitForIn_set() async {
    addTestFile('''
f(a) async {
  return {await for(var b in a) b};
}
''');
    await prepareHighlights();
    assertHasRegion(HighlightRegionType.KEYWORD, 'await');
    assertHasRegion(HighlightRegionType.KEYWORD, 'for');
    assertHasRegion(HighlightRegionType.KEYWORD, 'in');
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
}

@reflectiveTest
class HighlightsWithNullSafetyTest extends HighlightsTestSupport {
  @override
  void createProject({Map<String, String> packageRoots}) {
    addAnalysisOptionsFile('''
analyzer:
  enable-experiment:
    - non-nullable
''');
    super.createProject(packageRoots: packageRoots);
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
