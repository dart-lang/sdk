// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnitApiSignatureTest);
  });
}

@reflectiveTest
class UnitApiSignatureTest extends Object with ResourceProviderMixin {
  FileSystemState fileSystemState;

  Future<Null> assertNotSameSignature(String oldCode, String newCode) async {
    assertSignature(oldCode, newCode, same: false);
  }

  Future<Null> assertSameSignature(String oldCode, String newCode) async {
    assertSignature(oldCode, newCode, same: true);
  }

  Future<Null> assertSignature(String oldCode, String newCode,
      {bool same}) async {
    var path = convertPath('/test.dart');

    newFile(path, content: oldCode);
    var file = fileSystemState.getFileForPath(path);
    var lastSignature = file.apiSignature;

    newFile(path, content: newCode);
    await file.refresh();

    var newSignature = file.apiSignature;
    if (same) {
      expect(newSignature, lastSignature);
    } else {
      expect(newSignature, isNot(lastSignature));
    }
  }

  void setUp() {
    var sdk = new MockSdk(resourceProvider: resourceProvider);
    var sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      new PackageMapUriResolver(resourceProvider, <String, List<Folder>>{
        'aaa': [getFolder('/aaa/lib')],
        'bbb': [getFolder('/bbb/lib')],
      }),
      new ResourceUriResolver(resourceProvider)
    ], null, resourceProvider);
    fileSystemState = new FileSystemState(
        new PerformanceLog(new StringBuffer()),
        new MemoryByteStore(),
        new FileContentOverlay(),
        resourceProvider,
        sourceFactory,
        new AnalysisOptionsImpl(),
        new Uint32List(0),
        new Uint32List(0));
  }

  test_class_annotation() async {
    await assertNotSameSignature(r'''
const a = 0;

class C {}
''', r'''
const a = 0;

@a
class C {}
''');
  }

  test_class_constructor_block_to_empty() async {
    await assertSameSignature(r'''
class C {
  C() {
    var v = 1;
  }
}
''', r'''
class C {
  C();
}
''');
  }

  test_class_constructor_body() async {
    await assertSameSignature(r'''
class C {
  C() {
    var v = 1;
  }
}
''', r'''
class C {
  C() {
    var v = 2;
  }
}
''');
  }

  test_class_constructor_empty_to_block() async {
    await assertSameSignature(r'''
class C {
  C();
}
''', r'''
class C {
  C() {
    var v = 1;
  }
}
''');
  }

  test_class_constructor_initializer_const() async {
    await assertNotSameSignature(r'''
class C {
  final int f;
  const C() : f = 1;
}
''', r'''
class C {
  final int f;
  const C() : f = 2;
}
''');
  }

  test_class_constructor_initializer_empty() async {
    await assertSameSignature(r'''
class C {
  C.foo() : ;
}
''', r'''
class C {
  C.foo() : f;
}
''');
  }

  test_class_constructor_initializer_notConst() async {
    await assertSameSignature(r'''
class C {
  final int f;
  C.foo() : f = 1;
  const C.bar();
}
''', r'''
class C {
  final int f;
  C.foo() : f = 2;
  const C.bar();
}
''');
  }

  test_class_constructor_parameters_add() async {
    await assertNotSameSignature(r'''
class C {
  C(int a);
}
''', r'''
class C {
  C(int a, int b);
}
''');
  }

  test_class_constructor_parameters_remove() async {
    await assertNotSameSignature(r'''
class C {
  C(int a, int b);
}
''', r'''
class C {
  C(int a);
}
''');
  }

  test_class_constructor_parameters_rename() async {
    await assertNotSameSignature(r'''
class C {
  C(int a);
}
''', r'''
class C {
  C(int b);
}
''');
  }

  test_class_constructor_parameters_type() async {
    await assertNotSameSignature(r'''
class C {
  C(int p);
}
''', r'''
class C {
  C(double p);
}
''');
  }

  test_class_extends() async {
    await assertNotSameSignature(r'''
class A {}
class B {}
''', r'''
class A {}
class B extends A {}
''');
  }

  test_class_field_withoutType() async {
    await assertNotSameSignature(r'''
class C {
  var a = 1;
}
''', r'''
class C {
  var a = 2;
}
''');
  }

  test_class_field_withoutType2() async {
    await assertNotSameSignature(r'''
class C {
  var a = 1, b = 2, c, d = 4;
}
''', r'''
class C {
  var a = 1, b, c = 3, d = 4;
}
''');
  }

  test_class_field_withType() async {
    await assertSameSignature(r'''
class C {
  int a = 1, b, c = 3;
}
''', r'''
class C {
  int a = 0, b = 2, c;
}
''');
  }

  test_class_field_withType_const() async {
    await assertNotSameSignature(r'''
class C {
  static const int a = 1;
}
''', r'''
class C {
  static const int a = 2;
}
''');
  }

  test_class_field_withType_final_hasConstConstructor() async {
    await assertNotSameSignature(r'''
class C {
  final int a = 1;
  const C();
}
''', r'''
class C {
  final int a = 2;
  const C();
}
''');
  }

  test_class_field_withType_final_noConstConstructor() async {
    await assertSameSignature(r'''
class C {
  final int a = 1;
}
''', r'''
class C {
  final int a = 2;
}
''');
  }

  test_class_field_withType_hasConstConstructor() async {
    await assertSameSignature(r'''
class C {
  int a = 1;
  const C();
}
''', r'''
class C {
  int a = 2;
  const C();
}
''');
  }

  test_class_field_withType_static_final_hasConstConstructor() async {
    await assertSameSignature(r'''
class C {
  static final int a = 1;
  const C();
}
''', r'''
class C {
  static final int a = 2;
  const C();
}
''');
  }

  test_class_field_withType_static_hasConstConstructor() async {
    await assertSameSignature(r'''
class C {
  static int a = 1;
  const C();
}
''', r'''
class C {
  static int a = 2;
  const C();
}
''');
  }

  test_class_implements() async {
    await assertNotSameSignature(r'''
class A {}
class B {}
''', r'''
class A {}
class B implements A {}
''');
  }

  test_class_method_annotation() async {
    await assertNotSameSignature(r'''
const a = 0;

class C {
  void foo() {}
}
''', r'''
const a = 0;

class C {
  @a
  void foo() {}
}
''');
  }

  test_class_method_body_async_to_sync() async {
    await assertSameSignature(r'''
class C {
  Future foo() async {}
}
''', r'''
class C {
  Future foo() {}
}
''');
  }

  test_class_method_body_block() async {
    await assertSameSignature(r'''
class C {
  int foo() {
    return 1;
  }
}
''', r'''
class C {
  int foo() {
    return 2;
  }
}
''');
  }

  test_class_method_body_block_to_expression() async {
    await assertSameSignature(r'''
class C {
  int foo() {
    return 1;
  }
}
''', r'''
class C {
  int foo() => 2;
}
''');
  }

  test_class_method_body_empty_to_block() async {
    await assertSameSignature(r'''
class C {
  int foo();
}
''', r'''
class C {
  int foo() {
    var v = 0;
  }
}
''');
  }

  test_class_method_body_expression() async {
    await assertSameSignature(r'''
class C {
  int foo() => 1;
}
''', r'''
class C {
  int foo() => 2;
}
''');
  }

  test_class_method_body_sync_to_async() async {
    await assertSameSignature(r'''
class C {
  Future foo() {}
}
''', r'''
class C {
  Future foo() async {}
}
''');
  }

  test_class_method_getter_body_block_to_expression() async {
    await assertSameSignature(r'''
class C {
  int get foo {
    return 1;
  }
}
''', r'''
class C {
  int get foo => 2;
}
''');
  }

  test_class_method_getter_body_empty_to_expression() async {
    await assertSameSignature(r'''
class C {
  int get foo;
}
''', r'''
class C {
  int get foo => 2;
}
''');
  }

  test_class_method_parameters_add() async {
    await assertNotSameSignature(r'''
class C {
  foo(int a) {}
}
''', r'''
class C {
  foo(int a, int b) {}
}
''');
  }

  test_class_method_parameters_remove() async {
    await assertNotSameSignature(r'''
class C {
  foo(int a, int b) {}
}
''', r'''
class C {
  foo(int a) {}
}
''');
  }

  test_class_method_parameters_rename() async {
    await assertNotSameSignature(r'''
class C {
  void foo(int a) {}
}
''', r'''
class C {
  void foo(int b) {}
}
''');
  }

  test_class_method_parameters_type() async {
    await assertNotSameSignature(r'''
class C {
  void foo(int p) {}
}
''', r'''
class C {
  void foo(double p) {}
}
''');
  }

  test_class_method_returnType() async {
    await assertNotSameSignature(r'''
class C {
  int foo() => 0;
}
''', r'''
class C {
  num foo() => 0;
}
''');
  }

  test_class_method_typeParameters_add() async {
    await assertNotSameSignature(r'''
class C {
  void foo() {}
}
''', r'''
class C {
  void foo<T>() {}
}
''');
  }

  test_class_method_typeParameters_remove() async {
    await assertNotSameSignature(r'''
class C {
  void foo<T>() {}
}
''', r'''
class C {
  void foo() {}
}
''');
  }

  test_class_method_typeParameters_rename() async {
    await assertNotSameSignature(r'''
class C {
  void foo<T>() {}
}
''', r'''
class C {
  void foo<U>() {}
}
''');
  }

  test_class_modifier() async {
    await assertNotSameSignature(r'''
class C {}
''', r'''
abstract class C {}
''');
  }

  test_class_with() async {
    await assertNotSameSignature(r'''
class A {}
class B {}
class C extends A {}
''', r'''
class A {}
class B {}
class C extends A with B {}
''');
  }

  test_commentAdd() async {
    await assertSameSignature(r'''
var a = 1;
var b = 2;
var c = 3;
''', r'''
var a = 1; // comment

/// comment 1
/// comment 2
var b = 2;

/**
 *  Comment
 */
var c = 3;
''');
  }

  test_commentRemove() async {
    await assertSameSignature(r'''
var a = 1; // comment

/// comment 1
/// comment 2
var b = 2;

/**
 *  Comment
 */
var c = 3;
''', r'''
var a = 1;
var b = 2;
var c = 3;
''');
  }

  test_function_annotation() async {
    await assertNotSameSignature(r'''
const a = 0;

void foo() {}
''', r'''
const a = 0;

@a
void foo() {}
''');
  }

  test_function_body_async_to_sync() async {
    await assertSameSignature(r'''
Future foo() async {}
''', r'''
Future foo() {}
''');
  }

  test_function_body_block() async {
    await assertSameSignature(r'''
int foo() {
  return 1;
}
''', r'''
int foo() {
  return 2;
}
''');
  }

  test_function_body_block_to_expression() async {
    await assertSameSignature(r'''
int foo() {
  return 1;
}
''', r'''
int foo() => 2;
''');
  }

  test_function_body_expression() async {
    await assertSameSignature(r'''
int foo() => 1;
''', r'''
int foo() => 2;
''');
  }

  test_function_body_sync_to_async() async {
    await assertSameSignature(r'''
Future foo() {}
''', r'''
Future foo() async {}
''');
  }

  test_function_getter_block_to_expression() async {
    await assertSameSignature(r'''
int get foo {
  return 1;
}
''', r'''
int get foo => 2;
''');
  }

  test_function_parameters_rename() async {
    await assertNotSameSignature(r'''
void foo(int a) {}
''', r'''
void foo(int b) {}
''');
  }

  test_function_parameters_type() async {
    await assertNotSameSignature(r'''
void foo(int p) {}
''', r'''
void foo(double p) {}
''');
  }

  test_function_returnType() async {
    await assertNotSameSignature(r'''
int foo() => 0;
''', r'''
num foo() => 0;
''');
  }

  test_function_typeParameters_add() async {
    await assertNotSameSignature(r'''
void foo() {}
''', r'''
void foo<T>() {}
''');
  }

  test_function_typeParameters_remove() async {
    await assertNotSameSignature(r'''
void foo<T>() {}
''', r'''
void foo() {}
''');
  }

  test_function_typeParameters_rename() async {
    await assertNotSameSignature(r'''
void foo<T>() {}
''', r'''
void foo<U>() {}
''');
  }

  test_mixin_field_withoutType() async {
    await assertNotSameSignature(r'''
mixin M {
  var a = 1;
}
''', r'''
mixin M {
  var a = 2;
}
''');
  }

  test_mixin_field_withType() async {
    await assertSameSignature(r'''
mixin M {
  int a = 1, b, c = 3;
}
''', r'''
mixin M {
  int a = 0, b = 2, c;
}
''');
  }

  test_mixin_implements() async {
    await assertNotSameSignature(r'''
class A {}
mixin M {}
''', r'''
class A {}
mixin M implements A {}
''');
  }

  test_mixin_method_body_block() async {
    await assertSameSignature(r'''
mixin M {
  int foo() {
    return 1;
  }
}
''', r'''
mixin M {
  int foo() {
    return 2;
  }
}
''');
  }

  test_mixin_method_body_expression() async {
    await assertSameSignature(r'''
mixin M {
  int foo() => 1;
}
''', r'''
mixin M {
  int foo() => 2;
}
''');
  }

  test_mixin_on() async {
    await assertNotSameSignature(r'''
class A {}
mixin M {}
''', r'''
class A {}
mixin M on A {}
''');
  }

  test_topLevelVariable_withoutType() async {
    await assertNotSameSignature(r'''
var a = 1;
''', r'''
var a = 2;
''');
  }

  test_topLevelVariable_withoutType2() async {
    await assertNotSameSignature(r'''
var a = 1, b = 2, c, d = 4;;
''', r'''
var a = 1, b, c = 3, d = 4;;
''');
  }

  test_topLevelVariable_withType() async {
    await assertSameSignature(r'''
int a = 1, b, c = 3;
''', r'''
int a = 0, b = 2, c;
''');
  }

  test_topLevelVariable_withType_const() async {
    await assertNotSameSignature(r'''
const int a = 1;
''', r'''
const int a = 2;
''');
  }

  test_topLevelVariable_withType_final() async {
    await assertSameSignature(r'''
final int a = 1;
''', r'''
final int a = 2;
''');
  }

  test_typedef_generic_parameters_type() async {
    await assertNotSameSignature(r'''
typedef F = void Function(int);
''', r'''
typedef F = void Function(double);
''');
  }
}
