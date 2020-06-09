// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/constant/potentially_constant_test.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalThrowsExceptionTest);
    defineReflectiveTests(ConstEvalThrowsExceptionWithNullSafetyTest);
    defineReflectiveTests(ConstEvalThrowsExceptionWithConstantUpdateTest);
  });
}

/// TODO(paulberry): move other tests from [CompileTimeErrorCodeTestBase] to
/// this class.
@reflectiveTest
class ConstEvalThrowsExceptionTest extends DriverResolutionTest {
  test_CastError_intToDouble_constructor_importAnalyzedAfter() async {
    // See dartbug.com/35993
    newFile('/test/lib/other.dart', content: '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await assertNoErrorsInCode(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_CastError_intToDouble_constructor_importAnalyzedBefore() async {
    // See dartbug.com/35993
    newFile('/test/lib/other.dart', content: '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await assertNoErrorsInCode(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_default_constructor_arg_empty_map_import() async {
    newFile('/test/lib/other.dart', content: '''
class C {
  final Map<String, int> m;
  const C({this.m = const <String, int>{}})
    : assert(m != null);
}
''');
    await assertErrorsInCode('''
import 'other.dart';

main() {
  var c = const C();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    assertErrorsInList(
      otherFileResult.errors,
      expectedErrorsByNullability(
        nullable: [
          error(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE, 97, 7),
        ],
        legacy: [],
      ),
    );
  }

  test_finalAlreadySet_initializer() async {
    // If a final variable has an initializer at the site of its declaration,
    // and at the site of the constructor, then invoking that constructor would
    // produce a runtime error; hence invoking that constructor via the "const"
    // keyword results in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C() : x = 2;
}
var x = const C();
''', [
      error(StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          39, 1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 56, 9),
    ]);
  }

  test_finalAlreadySet_initializing_formal() async {
    // If a final variable has an initializer at the site of its declaration,
    // and it is initialized using an initializing formal at the site of the
    // constructor, then invoking that constructor would produce a runtime
    // error; hence invoking that constructor via the "const" keyword results
    // in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C(this.x);
}
var x = const C(2);
''', [
      error(StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          40, 1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 54, 10),
    ]);
  }

  test_fromEnvironment_assertInitializer() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x) : assert(x >= 0);
}

main() {
  var c = const A(int.fromEnvironment('x'));
  print(c);
}
''');
  }

  test_ifElement_false_thenNotEvaluated() async {
    await assertErrorsInCode(
        '''
const dynamic nil = null;
const c = [if (1 < 0) nil + 1];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 37, 18),
              ]);
  }

  test_ifElement_nonBoolCondition_list() async {
    await assertErrorsInCode(
        '''
const dynamic nonBool = 3;
const c = const [if (nonBool) 'a'];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 48, 7),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 44, 16),
                error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 48, 7),
              ]);
  }

  test_ifElement_nonBoolCondition_map() async {
    await assertErrorsInCode(
        '''
const dynamic nonBool = null;
const c = const {if (nonBool) 'a' : 1};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 51, 7),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 47, 20),
                error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 51, 7),
              ]);
  }

  test_ifElement_nonBoolCondition_set() async {
    await assertErrorsInCode(
        '''
const dynamic nonBool = 'a';
const c = const {if (nonBool) 3};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 50, 7),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 46, 14),
                error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 50, 7),
              ]);
  }

  test_ifElement_true_elseNotEvaluated() async {
    await assertErrorsInCode(
        '''
const dynamic nil = null;
const c = [if (0 < 1) 3 else nil + 1];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 37, 25),
              ]);
  }

  test_invalid_constructorFieldInitializer_fromSeparateLibrary() async {
    newFile('/test/lib/lib.dart', content: r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
const a = const A();
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 29, 9),
    ]);
  }

  test_unaryBitNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = ~D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_unaryNegated_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = -D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_unaryNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = !D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionWithConstantUpdateTest
    extends ConstEvalThrowsExceptionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );

  test_binaryMinus_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = D - 5;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);

    await assertErrorsInCode('''
const dynamic D = null;
const C = 5 - D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  test_binaryPlus_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = D + 5;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);

    await assertErrorsInCode('''
const dynamic D = null;
const C = 5 + D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  test_eqEq_nonPrimitiveRightOperand() async {
    await assertNoErrorsInCode('''
const c = const T.eq(1, const Object());
class T {
  final Object value;
  const T.eq(Object o1, Object o2) : value = o1 == o2;
}
''');
  }

  test_fromEnvironment_ifElement() async {
    await assertNoErrorsInCode('''
const b = bool.fromEnvironment('foo');

main() {
  const l1 = [1, 2, 3];
  const l2 = [if (b) ...l1];
  print(l2);
}
''');
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionWithNullSafetyTest
    extends ConstEvalThrowsExceptionTest with WithNullSafetyMixin {
  test_asExpression_typeParameter() async {
    await assertErrorsInCode('''
class C<T> {
  final t;
  const C(dynamic x) : t = x as T;
}

main() {
  const C<int>(0);
  const C<int>('foo');
  const C<int>(null);
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 92, 19),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 115, 18),
    ]);
  }

  test_asExpression_typeParameter_nested() async {
    await assertErrorsInCode('''
class C<T> {
  final t;
  const C(dynamic x) : t = x as List<T>;
}

main() {
  const C<int>(<int>[]);
  const C<int>(<num>[]);
  const C<int>(null);
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 104, 21),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 129, 18),
    ]);
  }
}
