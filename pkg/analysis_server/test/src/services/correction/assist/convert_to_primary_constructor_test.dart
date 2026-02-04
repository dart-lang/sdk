// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToPrimaryConstructorClassTest);
    defineReflectiveTests(ConvertToPrimaryConstructorEnumTest);
  });
}

@reflectiveTest
class ConvertToPrimaryConstructorClassTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToPrimaryConstructor;

  Future<void> test_noParameters_noBody_named() async {
    await resolveTestCode('''
class C {
  C^.n();
}
''');
    await assertHasAssist('''
class C.n() {
}
''');
  }

  Future<void> test_noParameters_noBody_notEnabled() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  C^();
}
''');
    await assertNoAssist();
  }

  Future<void> test_noParameters_noBody_unnamed() async {
    await resolveTestCode('''
class C {
  C^();
}
''');
    await assertHasAssist('''
class C() {
}
''');
  }

  Future<void> test_noParameters_withBody() async {
    await resolveTestCode('''
class C {
  C^() {
    print('c');
  }
}
''');
    await assertHasAssist('''
class C() {
  this {
    print('c');
  }
}
''');
  }

  Future<void> test_noParameters_withBodyAndInitializer() async {
    await resolveTestCode('''
class C {
  int _x;

  C^() : _x = 0 {
    print('c');
  }
}
''');
    await assertHasAssist('''
class C() {
  int _x;

  this : _x = 0 {
    print('c');
  }
}
''');
  }

  Future<void> test_noParameters_withInitializer() async {
    await resolveTestCode('''
class C {
  int _x;

  C^() : _x = 0;
}
''');
    await assertHasAssist('''
class C() {
  int _x;

  this : _x = 0;
}
''');
  }

  Future<void> test_noParameters_withKeyword_const() async {
    await resolveTestCode('''
class C {
  const C^();
}
''');
    await assertHasAssist('''
class const C() {
}
''');
  }

  Future<void> test_noParameters_withKeyword_external() async {
    await resolveTestCode('''
class C {
  external C^();
}
''');
    await assertNoAssist();
  }

  Future<void> test_noParameters_withKeyword_factory_nonRedirecting() async {
    await resolveTestCode('''
class C {
  factory C^() => C._();

  C._();
}
''');
    await assertNoAssist();
  }

  Future<void> test_noParameters_withKeyword_factory_redirecting() async {
    await resolveTestCode('''
class C {
  factory C^() = C._;

  C._();
}
''');
    await assertNoAssist();
  }

  Future<void> test_redirecting() async {
    await resolveTestCode('''
class C {
  C^() : this._();

  C._();
}
''');
    await assertNoAssist();
  }

  Future<void> test_withAnnotation() async {
    await resolveTestCode('''
class C {
  @a
  C^();
}

const a = 0;
''');
    await assertHasAssist('''
class C() {
  @a
  this;
}

const a = 0;
''');
  }

  Future<void> test_withConstructor_factory() async {
    await resolveTestCode('''
class C {
  C^();

  factory C.c() => C();
}
''');
    // TODO(brianwilkerson): Remove the extra whitespace.
    await assertHasAssist('''
class C() {

  factory C.c() => C();
}
''');
  }

  Future<void> test_withConstructor_nonRedirectingGenerative() async {
    await resolveTestCode('''
class C {
  C^();
  C.c();
}
''');
    await assertNoAssist();
  }

  Future<void> test_withConstructor_redirectingGenerative() async {
    await resolveTestCode('''
class C {
  C^();

  C.c() : this();
}
''');
    // TODO(brianwilkerson): Remove the extra whitespace.
    await assertHasAssist('''
class C() {

  C.c() : this();
}
''');
  }

  Future<void> test_withDocComment() async {
    await resolveTestCode('''
class C {
  /// C
  C^();
}

const a = 0;
''');
    await assertHasAssist('''
class C() {
  /// C
  this;
}

const a = 0;
''');
  }

  Future<void> test_withParameters_optionalNamed_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C^({this.x = 0});
}
''');
    // TODO(brianwilkerson): Remove the extra whitespace.
    await assertHasAssist('''
class C({this.x = 0}) {
  int x;

}
''');
  }

  Future<void> test_withParameters_optionalNamed_simple() async {
    await resolveTestCode('''
class C {
  int _x;

  C^({int x = 0}) : _x = x;
}
''');
    await assertHasAssist('''
class C({int x = 0}) {
  int _x;

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_optionalNamed_super() async {
    await resolveTestCode('''
class C extends B {
  C^({super.x = 0});
}

class B {
  int x;

  B({required this.x});
}
''');
    await assertHasAssist('''
class C({super.x = 0}) extends B {
}

class B {
  int x;

  B({required this.x});
}
''');
  }

  Future<void> test_withParameters_optionalPositional_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C^([this.x = 0]);
}
''');
    // TODO(brianwilkerson): Remove the extra whitespace.
    await assertHasAssist('''
class C([this.x = 0]) {
  int x;

}
''');
  }

  Future<void> test_withParameters_optionalPositional_simple() async {
    await resolveTestCode('''
class C {
  int _x;

  C^([int x = 0]) : _x = x;
}
''');
    await assertHasAssist('''
class C([int x = 0]) {
  int _x;

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_optionalPositional_super() async {
    await resolveTestCode('''
class C extends B {
  C^([super.x = 0]);
}

class B {
  int x;

  B(this.x);
}
''');
    await assertHasAssist('''
class C([super.x = 0]) extends B {
}

class B {
  int x;

  B(this.x);
}
''');
  }

  Future<void> test_withParameters_requiredNamed_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C^({required this.x});
}
''');
    // TODO(brianwilkerson): Remove the extra whitespace.
    await assertHasAssist('''
class C({required this.x}) {
  int x;

}
''');
  }

  Future<void> test_withParameters_requiredNamed_simple() async {
    await resolveTestCode('''
class C {
  int _x;

  C^({required int x}) : _x = x;
}
''');
    await assertHasAssist('''
class C({required int x}) {
  int _x;

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_requiredNamed_super() async {
    await resolveTestCode('''
class C extends B {
  C^({required super.x});
}

class B {
  int x;

  B({required this.x});
}
''');
    await assertHasAssist('''
class C({required super.x}) extends B {
}

class B {
  int x;

  B({required this.x});
}
''');
  }

  Future<void> test_withParameters_requiredPositional_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C^(this.x);
}
''');
    // TODO(brianwilkerson): Remove the extra whitespace.
    await assertHasAssist('''
class C(this.x) {
  int x;

}
''');
  }

  Future<void> test_withParameters_requiredPositional_simple() async {
    await resolveTestCode('''
class C {
  int _x;

  C^(int x) : _x = x;
}
''');
    await assertHasAssist('''
class C(int x) {
  int _x;

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_requiredPositional_super() async {
    await resolveTestCode('''
class C extends B {
  C^(super.x);
}

class B {
  int x;

  B(this.x);
}
''');
    await assertHasAssist('''
class C(super.x) extends B {
}

class B {
  int x;

  B(this.x);
}
''');
  }
}

@reflectiveTest
class ConvertToPrimaryConstructorEnumTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToPrimaryConstructor;

  Future<void> test_noParameters_noBody() async {
    await resolveTestCode('''
enum E {
  a, b;

  const E^();
}
''');
    await assertHasAssist('''
enum E() {
  a, b;

}
''');
  }

  Future<void> test_noParameters_noBody_notEnabled() async {
    await resolveTestCode('''
// @dart=3.10
enum E {
  a, b;

  const E^();
}
''');
    await assertNoAssist();
  }

  Future<void> test_noParameters_withInitializer() async {
    await resolveTestCode('''
enum E {
  a(1), b(2);

  final int x;

  const E^(this.x) : assert(x > 0);
}
''');
    await assertHasAssist('''
enum E(this.x) {
  a(1), b(2);

  final int x;

  this : assert(x > 0);
}
''');
  }

  Future<void> test_withParameters_requiredPositional_simple() async {
    await resolveTestCode('''
enum E {
  a(1), b(2);

  final int _x;

  const E^(int x) : _x = x;
}
''');
    await assertHasAssist('''
enum E(int x) {
  a(1), b(2);

  final int _x;

  this : _x = x;
}
''');
  }
}
