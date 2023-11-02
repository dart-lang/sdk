// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnstableFinalFieldsTest);
  });
}

@reflectiveTest
class AvoidUnstableFinalFieldsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_unstable_final_fields';

  test_00lintGetMutableToplevelVariable() async {
    await assertDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

var jTop = 0;

class B01 extends A {
  B01(super.i);
  int get i => ++jTop + super.i; //LINT
}
''', [
      _lint(104),
    ]);
  }

  test_01lintOverrideMutableVariable() async {
    await assertDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B02 implements A {
  int i; //LINT
  B02(this.i);
}
''', [
      _lint(72),
    ]);
  }

  test_02noLintLateInitializedVariable() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

var jTop = 0;

class B03 implements A {
  late final int i = jTop++; //OK
}
''');
  }

  test_03noLintSuper() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B04 extends A {
  B04(super.i);
  int get i => super.i - 1; //OK
}
''');
  }

  test_04noLintStableInstanceGetter() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B05 implements A {
  final int j;
  B05(this.j);
  int get i => j; //OK
}
''');
  }

  test_05noLintConstant() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B06 implements A {
  int get i => 1; //OK
}
''');
  }

  test_06noLintConstantInBody() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B07 implements A {
  int get i //OK
  {
    return 1;
  }
}
''');
  }

  test_07lintMutableToplevelVariableInBody() async {
    await assertDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

var jTop = 0;

class B08 implements A {
  int get i //LINT
  {
    return jTop;
  }
}
''', [
      _lint(91),
    ]);
  }

  test_08noLintUnaryMinus() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B09 extends A {
  B09(super.i);
  int get i => -super.i; //OK
}
''');
  }

  test_09noLintConditional() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B10 implements A {
  final bool b;
  final int j;
  B10(this.b, this.j);
  int get i => b ? j : 10; //OK
}
''');
  }

  test_10lintUnstableCondition() async {
    await assertDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B11 implements A {
  bool b;
  final int j;
  B11(this.b, this.j);
  int get i => b ? 2 * j : 10; //LINT
}
''', [
      _lint(124),
    ]);
  }

  test_11noLintThrow() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B12 implements A {
  int get i => throw 0; //OK
}
''');
  }

  test_12noLintThrowInBody() async {
    await assertNoDiagnostics(r'''
class A {
  final int i;
  A(this.i);
}

class B13 implements A {
  int get i //OK
  {
    throw 0;
  }
}
''');
  }

  test_13lintMutableLateInstanceVariable() async {
    await assertDiagnostics(r'''
class C<X> {
  final C<X>? next;
  final C<X>? nextNext = null;
  final X? v = null;
  const C(this.next);
}

const cNever = C<Never>(null);

class D1<X> implements C<X> {
  late X x;
  C<X>? get next => cNever; //OK
  C<X>? get nextNext => this.next?.next; //OK
  X? get v => x; //LINT
}
''', [
      _lint(272),
    ]);
  }

  test_14lintInstanceTearoff() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F01 implements E {
  static late final Function fStatic = () {};
  Function get o => m; //LINT
  void m() {}
}
''', [
      _lint(131),
    ]);
  }

  test_15lintFunctionLiteral() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F02 implements E {
  Function get o => () {}; //LINT
}
''', [
      _lint(85),
    ]);
  }

  test_16noLintCascade() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F03 implements E {
  Function get o => print..toString(); //OK
}
''');
  }

  test_17noLintImportPrefix() async {
    await assertNoDiagnostics(r'''
import 'dart:math' as math;

class E {
  final Object? o;
  E(this.o);
}

class F04 implements E {
  Function get o => math.cos; //OK
}
''');
  }

  test_18noLintStaticTearOff() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
  static late final Function eStatic = () {};
}

class F05 implements E {
  Function get o => E.eStatic; //OK
}
''');
  }

  test_19lintListLiteral() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F06 implements E {
  List<int> get o => []; //LINT
}
''', [
      _lint(86),
    ]);
  }

  test_20noLintConstantMap() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F07 implements E {
  Set<double> get o => const {}; //OK
}
''');
  }

  test_21lintMapLiteral() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F08 implements E {
  Object get o => <String, String>{}; //LINT
}
''', [
      _lint(83),
    ]);
  }

  test_22noLintConstantSymbol() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F09 implements E {
  Symbol get o => #symbol; //OK
}
''');
  }

  test_23noLintConstantTypeLiteral() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F10 implements E {
  Type get o => int; //OK
}
''');
  }

  test_24lintTypeParameter() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F11<X> implements E {
  Type get o => X; //LINT
}
''', [
      _lint(84),
    ]);
  }

  test_25lintUnstableTypeLiteral() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F12<X> implements E {
  Type get o => F12<X>; //LINT
}
''', [
      _lint(84),
    ]);
  }

  test_26noLintConstantObjectExpression() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F13 implements E {
  const F13(int whatever);
  F13 get o => const F13(42); //OK
}
''');
  }

  test_27lintNewInstance() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

var jTop = 0;

class F14 implements E {
  F14(int whatever);
  F14 get o => F14(jTop); //LINT
}
''', [
      _lint(116),
    ]);
  }

  test_28noLintStringLiteral() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F15 implements E {
  String get o => 'Something and ${1 * 1}'; //OK
}
''');
  }

  test_29lintUnstableStringLiteral() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

const cNever = 42;

var jTop = 0;

class F16 implements E {
  String get o => 'Stuff, $cNever, but not $jTop'; //LINT
}
''', [
      _lint(118),
    ]);
  }

  test_30noLintTypeTest() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F17 implements E {
  bool get o => (this as dynamic) is E; //OK
}
''');
  }

  test_31lintUnstableTypeTest() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

dynamic jTop = 0;

class F18 implements E {
  bool get o => jTop is int; //LINT
}
''', [
      _lint(100),
    ]);
  }

  test_32noLintNonnullCheck() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F19 extends E {
  F19(super.o);
  Object get o => super.o!; //OK
}
''');
  }

  test_33noLintConstantObjectExpressionNamed() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F20 implements E {
  F20Helper get o => const F20Helper.named(15); //OK
}

class F20Helper {
  const F20Helper.named(int i);
}
''');
  }

  test_34noLintIdentical() async {
    await assertNoDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F21 implements E {
  bool get o => identical(const <int>[], const <int>[]); //OK
}
''');
  }

  test_35lintUnstableIdentical() async {
    await assertDiagnostics(r'''
class E {
  final Object? o;
  E(this.o);
}

class F22 implements E {
  bool get o => identical(<int>[], const <int>[]); //LINT
}
''', [
      _lint(81),
    ]);
  }

  test_36noLintDeclaredUnstableStringLiteral() async {
    await assertNoDiagnostics(r'''
class G {
  @Object()
  final String s;
  G(this.s);
}

var jTop = 0;

class H1 implements G {
  String get s => '${++jTop}'; //OK
}
''');
  }

  test_37lintMutableToplevelVariablePlusSuperInMixin() async {
    await assertDiagnostics(r'''
class I {
  final int i;
  I(this.i);
}

var jTop = 0;

mixin J1 on I {
  int get i => ++jTop + super.i; //LINT
}
''', [
      _lint(82),
    ]);
  }

  test_38lintMutableToplevelVariableInMixin() async {
    await assertDiagnostics(r'''
class I {
  final int i;
  I(this.i);
}

var jTop = 0;

mixin J2 implements I {
  int get i => ++jTop; //LINT
}
''', [
      _lint(90),
    ]);
  }

  test_39noLintGetterInMixinBinary() async {
    await assertNoDiagnostics(r'''
class I {
  final int i;
  I(this.i);
}

mixin J3 on I {
  int get i => super.i - 1; //OK
}
''');
  }

  test_40noLintGetterInMixinConstant() async {
    await assertNoDiagnostics(r'''
class I {
  final int i;
  I(this.i);
}

mixin J4 implements I {
  int get i => 1; //OK
}
''');
  }

  test_41noLintGetterInMixinUnaryMinus() async {
    await assertNoDiagnostics(r'''
class I {
  final int i;
  I(this.i);
}

mixin J5 on I {
  int get i => -super.i; //OK
}
''');
  }

  test_42noLintGetterInMixinNonnullCheck() async {
    await assertNoDiagnostics(r'''
class K {
  final Object? o;
  K(this.o);
}

mixin L1 on K {
  Object get o => super.o!; //OK
}
''');
  }

  test_43noLintDeclaredUnstableStringLiteralInMixin() async {
    await assertNoDiagnostics(r'''
class M {
  @Object()
  final String s;
  M(this.s);
}

var jTop = 0;

mixin N1 on M {
  String get s => '$jTop'; //OK
}
''');
  }

  test_44noLintDeclaredUnstableStringLiteralUnaryMinusInMixin() async {
    await assertNoDiagnostics(r'''
class M {
  @Object()
  final String s;
  M(this.s);
}

var jTop = 0;

mixin N2 implements M {
  String get s => '${-jTop}'; //OK
}
''');
  }

  test_45noLintInitializedFinalVariable() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

var jTop = 0;

enum P1 implements O {
  a,
  b,
  c;

  final int i = jTop++; //OK
}
''');
  }

  test_46noLintStableVariableInEnum() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

enum P2 implements O {
  a(10),
  b(12),
  c(14);

  final int j;
  const P2(this.j);
  int get i => j; //OK
}
''');
  }

  test_47noLintConstantInEnum() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

enum P3 implements O {
  a,
  b,
  c;

  int get i => 1; //OK
}
''');
  }

  test_48noLintConstantInBodyInEnum() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

enum P4 implements O {
  a,
  b,
  c;

  int get i //OK
  {
    return 1;
  }
}
''');
  }

  test_49lintMutableToplevelVariableInEnum() async {
    await assertDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

var jTop = 0;

enum P5 implements O {
  a,
  b,
  c;

  int get i //LINT
  {
    return jTop;
  }
}
''', [
      _lint(114),
    ]);
  }

  test_50noLintConditionalInEnum() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

enum P6 implements O {
  aa(true, 4),
  bb(true, 8),
  cc(false, 12);

  final bool b;
  final int j;
  const P6(this.b, this.j);
  int get i => b ? j : 10; //OK
}
''');
  }

  test_51lintUnstableConditionInEnum() async {
    await assertDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

bool bTop = true;

enum P7 implements O {
  aa(3),
  bb(5),
  cc(7);

  final int j;
  const P7(this.j);
  int get i => bTop ? 2 * j : 10; //LINT
}
''', [
      _lint(165),
    ]);
  }

  test_52noLintThrowInEnum() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

enum P8 implements O {
  a,
  b,
  c;

  int get i => throw 0; //OK
}
''');
  }

  test_53noLintThrowInBodyInEnum() async {
    await assertNoDiagnostics(r'''
abstract class O {
  final int i;
  O(this.i);
}

enum P9 implements O {
  a,
  b,
  c;

  int get i //OK
  {
    throw 0;
  }
}
''');
  }

  test_54lintInstanceTearoffInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R01 implements Q {
  a,
  b,
  c;

  static late final Function fStatic = () {};
  Function get o => m; //LINT
  void m() {}
}
''', [
      _lint(151),
    ]);
  }

  test_55lintFunctionLiteralInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R02 implements Q {
  a,
  b,
  c;

  Function get o => () {}; //LINT
}
''', [
      _lint(105),
    ]);
  }

  test_56noLintCascadeInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R03 implements Q {
  a,
  b,
  c;

  Function get o => print..toString(); //OK
}
''');
  }

  test_57noLintImportPrefixInEnum() async {
    await assertNoDiagnostics(r'''
import 'dart:math' as math;

abstract class Q {
  abstract final Object? o;
}

enum R04 implements Q {
  a,
  b,
  c;

  Function get o => math.cos; //OK
}
''');
  }

  test_58noLintStaticTearOffInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
  static late final Function qStatic = () {};
}

enum R05 implements Q {
  a,
  b,
  c;

  Function get o => Q.qStatic; //OK
}
''');
  }

  test_59lintListLiteralInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R06 implements Q {
  a,
  b,
  c;

  List<int> get o => []; //LINT
}
''', [
      _lint(106),
    ]);
  }

  test_60noLintConstantSetInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R07 implements Q {
  a,
  b,
  c;

  Set<double> get o => const {}; //OK
}
''');
  }

  test_61lintMapLiteralInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R08 implements Q {
  a,
  b,
  c;

  Object get o => <String, String>{}; //LINT
}
''', [
      _lint(103),
    ]);
  }

  test_62noLintConstantSymbolInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R09 implements Q {
  a,
  b,
  c;

  Symbol get o => #symbol; //OK
}
''');
  }

  test_63noLintConstantTypeLiteralInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R10 implements Q {
  a,
  b,
  c;

  Type get o => int; //OK
}
''');
  }

  test_64lintTypeParameterInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R11<X> implements Q {
  a,
  b,
  c;

  Type get o => X; //LINT
}
''', [
      _lint(104),
    ]);
  }

  test_65lintUnstableTypeLiteralInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R12<X> implements Q {
  a,
  b,
  c;

  Type get o => R12<X>; //LINT
}
''', [
      _lint(104),
    ]);
  }

  test_66noLintConstantObjectExpressionInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

class C {
  const C();
}

enum R13 implements Q {
  a(-1),
  b(-2),
  c(-3);

  const R13(int whatever);
  C get o => const C(); //OK
}
''');
  }

  test_67lintNewInstanceInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

var jTop = 0;

enum R14 implements Q {
  a(-10),
  b(-20),
  c(-30);

  const R14(int whatever);
  List<String> get o => List.from(const [], growable: false); //LINT
}
''', [
      _lint(166),
    ]);
  }

  test_68noLintStringLiteralInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R15 implements Q {
  a,
  b,
  c;

  String get o => 'Something and ${1 * 1}'; //OK
}
''');
  }

  test_69lintUnstableStringLiteralInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

const cNever = 42;

var jTop = 0;

enum R16 implements Q {
  a,
  b,
  c;

  String get o => 'Stuff, $cNever, but not $jTop'; //LINT
}
''', [
      _lint(138),
    ]);
  }

  test_70noLintTypeTestInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R17 implements Q {
  a,
  b,
  c;

  bool get o => (this as dynamic) is Q; //OK
}
''');
  }

  test_71lintUnstableTypeTestInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

dynamic jTop = 0;

enum R18 implements Q {
  a,
  b,
  c;

  bool get o => jTop is int; //LINT
}
''', [
      _lint(120),
    ]);
  }

  test_72noLintEnumInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R20 implements Q {
  a,
  b,
  c;

  R20Helper get o => R20Helper.b; //OK
}

enum R20Helper {
  a.named(999),
  b.named(-0.888),
  c.named(77.7);

  const R20Helper.named(num n);
}
''');
  }

  test_73noLintIdenticalInEnum() async {
    await assertNoDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R21 implements Q {
  a,
  b,
  c;

  bool get o => identical(const <int>[], const <int>[]); //OK
}
''');
  }

  test_74lintUnstableIdenticalInEnum() async {
    await assertDiagnostics(r'''
abstract class Q {
  abstract final Object? o;
}

enum R22 implements Q {
  a,
  b,
  c;

  bool get o => identical(<int>[], const <int>[]); //LINT
}
''', [
      _lint(101),
    ]);
  }

  // Make sure the lint in `test_76lintMutableVariableDoubleOverride`
  // is actually caused by the second override.
  test_75noLintSingleOverride() async {
    await assertNoDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

class S02 extends S01 {
  @override
  int get b => 0; //OK
}
''');
  }

  test_76lintMutableVariableDoubleOverride() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

class S02 extends S01 {
  @override
  int get b => 0; //OK
}

int get i2 => _i2++;
int _i2 = 0;

class S03 extends S02 {
  @override
  int get b => i2; //LINT
}
''', [
      _lint(215),
    ]);
  }

  test_77lintToStringViaStringLiteral() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

const S04 constS04 = S04();

int get i2 => _i2++;
int _i2 = 0;

class S04 extends S01 {
  const S04();

  @override
  String toString() => '$i2';

  @override
  String get s => '$constS04'; //LINT
}
''', [
      _lint(244),
    ]);
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/linter/issues/4766',
    reason: 'Not yet implemented',
  )
  test_78lintNosuchMethodForwarder() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

int get i2 => _i2++;
int _i2 = 0;

class S05 implements S01 { //LINT
  @override
  dynamic noSuchMethod(_) => i2;
}
''', [
      _lint(107),
    ]);
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/linter/issues/4765',
    reason: 'Not yet implemented',
  )
  test_79lintUnstableTopLevelGetterMixedIn() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

int get i2 => _i2++;
int _i2 = 0;

mixin S06 {
  int get b => i2;
}

class S07 extends S01 with S06 {} //LINT
''', [
      _lint(141),
    ]);
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/linter/issues/4764',
    reason: 'Not yet implemented',
  )
  test_80lintStabilityFromImplementsToInherited() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

class S08 extends S08Super implements S01 {} //LINT

int get i2 => _i2++;
int _i2 = 0;

class S08Super {
  int get b => i2;
  String get s => "$b";
}
''', [
      _lint(72),
    ]);
  }

  test_81lintUnstableGettersOnOther() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

class S09 extends S01 {
  final S09Helper sh = S09Helper();

  @override
  int get b => sh.z + sh.x; //LINT
}

int get i2 => _i2++;
int _i2 = 0;

class S09Helper {
  int get x => i2;
  int z = 1;
}
''', [
      _lint(155),
    ]);
  }

  test_82lintUnstableEquality() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

class S10 extends S01 {
  final S10Helper sh = S10Helper();

  @override
  int get b => (sh == sh) ? 0 : 1; //LINT
}

int get i2 => _i2++;
int _i2 = 0;

class S10Helper {
  @override
  bool operator ==(Object other) => i2.isEven;
}
''', [
      _lint(155),
    ]);
  }

  test_83lintUnstableGetterOnOther() async {
    await assertDiagnostics(r'''
class S01 {
  const S01();
  final int b = 0;
  final String s = '';
}

class S11 extends S01 {
  final S11Helper kh = S11Helper();

  @override
  int get b => kh.b; //LINT
}

int get i2 => _i2++;
int _i2 = 0;

class S11Helper {
  int get b => i2;
}
''', [
      _lint(155),
    ]);
  }

  ExpectedLint _lint(int offset) => lint(
        offset,
        1,
        messageContains: 'Avoid overriding a final field',
      );
}
