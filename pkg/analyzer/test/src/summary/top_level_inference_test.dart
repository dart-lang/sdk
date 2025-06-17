// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelInferenceTest);
    defineReflectiveTests(TopLevelInferenceErrorsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopLevelInferenceErrorsTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_initializer_additive() async {
    await _assertErrorOnlyLeft(['+', '-']);
  }

  test_initializer_assign() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = a += 1;
var t2 = a = 2;
''');
  }

  test_initializer_binary_onlyLeft() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = (a = 1) + (a = 2);
''');
  }

  test_initializer_bitwise() async {
    await _assertErrorOnlyLeft(['&', '|', '^']);
  }

  test_initializer_boolean() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = ((a = 1) == 0) || ((a = 2) == 0);
var t2 = ((a = 1) == 0) && ((a = 2) == 0);
var t3 = !((a = 1) == 0);
''');
  }

  test_initializer_cascade() async {
    await assertNoErrorsInCode('''
var a = 0;
var t = (a = 1)..isEven;
''');
  }

  test_initializer_classField_instance_instanceCreation() async {
    await assertNoErrorsInCode('''
class A<T> {}
class B {
  var t1 = new A<int>();
  var t2 = new A();
}
''');
  }

  test_initializer_classField_static_instanceCreation() async {
    await assertNoErrorsInCode('''
class A<T> {}
class B {
  static var t1 = 1;
  static var t2 = new A();
}
''');
  }

  test_initializer_conditional() async {
    await assertNoErrorsInCode('''
var a = 1;
var b = true;
var t = b
    ? (a = 1)
    : (a = 2);
''');
  }

  test_initializer_dependencyCycle() async {
    await assertErrorsInCode(
      '''
var a = b;
var b = a;
''',
      [
        error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 1),
        error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 15, 1),
      ],
    );
  }

  test_initializer_equality() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = ((a = 1) == 0) == ((a = 2) == 0);
var t2 = ((a = 1) == 0) != ((a = 2) == 0);
''');
  }

  test_initializer_extractIndex() async {
    await assertNoErrorsInCode('''
var a = [0, 1.2];
var b0 = a[0];
var b1 = a[1];
''');
  }

  test_initializer_functionLiteral_blockBody() async {
    await assertNoErrorsInCode('''
var t = (int p) {};
''');
    assertType(findElement2.topVar('t').type, 'Null Function(int)');
  }

  test_initializer_functionLiteral_expressionBody() async {
    await assertNoErrorsInCode('''
var a = 0;
var t = (int p) => (a = 1);
''');
    assertType(findElement2.topVar('t').type, 'int Function(int)');
  }

  test_initializer_functionLiteral_parameters_withoutType() async {
    await assertNoErrorsInCode('''
var t = (int a, b,int c, d) => 0;
''');
    assertType(
      findElement2.topVar('t').type,
      'int Function(int, dynamic, int, dynamic)',
    );
  }

  test_initializer_hasTypeAnnotation() async {
    await assertNoErrorsInCode('''
var a = 1;
int t = (a = 1);
''');
  }

  test_initializer_identifier() async {
    await assertNoErrorsInCode('''
int top_function() => 0;
var top_variable = 0;
int get top_getter => 0;
class A {
  static var static_field = 0;
  static int get static_getter => 0;
  static int static_method() => 0;
  int instance_method() => 0;
}
var t1 = top_function;
var t2 = top_variable;
var t3 = top_getter;
var t4 = A.static_field;
var t5 = A.static_getter;
var t6 = A.static_method;
var t7 = new A().instance_method;
''');
  }

  test_initializer_identifier_error() async {
    await assertNoErrorsInCode('''
var a = 0;
var b = (a = 1);
var c = b;
''');
  }

  test_initializer_ifNull() async {
    await assertNoErrorsInCode('''
int? a = 1;
var t = a ?? 2;
''');
  }

  test_initializer_instanceCreation_withoutTypeParameters() async {
    await assertNoErrorsInCode('''
class A {}
var t = new A();
''');
  }

  test_initializer_instanceCreation_withTypeParameters() async {
    await assertNoErrorsInCode('''
class A<T> {}
var t1 = new A<int>();
var t2 = new A();
''');
  }

  test_initializer_instanceGetter() async {
    await assertNoErrorsInCode('''
class A {
  int f = 1;
}
var a = new A().f;
''');
  }

  test_initializer_methodInvocation_function() async {
    await assertNoErrorsInCode('''
int f1() => 0;
T f2<T>() => throw 0;
var t1 = f1();
var t2 = f2();
var t3 = f2<int>();
''');
  }

  test_initializer_methodInvocation_method() async {
    await assertNoErrorsInCode('''
class A {
  int m1() => 0;
  T m2<T>() => throw 0;
}
var a = new A();
var t1 = a.m1();
var t2 = a.m2();
var t3 = a.m2<int>();
''');
  }

  test_initializer_multiplicative() async {
    await _assertErrorOnlyLeft(['*', '/', '%', '~/']);
  }

  test_initializer_postfixIncDec() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = a++;
var t2 = a--;
''');
  }

  test_initializer_prefixIncDec() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = ++a;
var t2 = --a;
''');
  }

  test_initializer_relational() async {
    await _assertErrorOnlyLeft(['>', '>=', '<', '<=']);
  }

  test_initializer_shift() async {
    await _assertErrorOnlyLeft(['<<', '>>']);
  }

  test_initializer_typedList() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = <int>[a = 1];
''');
  }

  test_initializer_typedMap() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = <int, int>{(a = 1) : (a = 2)};
''');
  }

  test_initializer_untypedList() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = [
    a = 1,
    2,
    3,
];
''');
  }

  test_initializer_untypedMap() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = {
    (a = 1) :
        (a = 2),
};
''');
  }

  test_override_conflictFieldType() async {
    await assertErrorsInCode(
      '''
abstract class A {
  int aaa = 0;
}
abstract class B {
  String aaa = '0';
}
class C implements A, B {
  var aaa;
}
''',
      [
        error(
          CompileTimeErrorCode.INVALID_OVERRIDE,
          109,
          3,
          contextMessages: [message(testFile, 64, 3)],
        ),
        error(
          CompileTimeErrorCode.INVALID_OVERRIDE,
          109,
          3,
          contextMessages: [message(testFile, 25, 3)],
        ),
      ],
    );
  }

  test_override_conflictParameterType_method() async {
    await assertErrorsInCode(
      '''
abstract class A {
  void mmm(int a);
}
abstract class B {
  void mmm(String a);
}
class C implements A, B {
  void mmm(a) {}
}
''',
      [error(CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE, 116, 3)],
    );
  }

  Future<void> _assertErrorOnlyLeft(List<String> operators) async {
    String code = 'var a = 1;\n';
    for (var i = 0; i < operators.length; i++) {
      String operator = operators[i];
      code += 'var t$i = (a = 1) $operator (a = 2);\n';
    }
    await assertNoErrorsInCode(code);
  }
}

@reflectiveTest
class TopLevelInferenceTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_initializer_additive() async {
    var library = await _encodeDecodeLibrary(r'''
var vPlusIntInt = 1 + 2;
var vPlusIntDouble = 1 + 2.0;
var vPlusDoubleInt = 1.0 + 2;
var vPlusDoubleDouble = 1.0 + 2.0;
var vMinusIntInt = 1 - 2;
var vMinusIntDouble = 1 - 2.0;
var vMinusDoubleInt = 1.0 - 2;
var vMinusDoubleDouble = 1.0 - 2.0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vPlusIntInt @4
          element: <testLibrary>::@topLevelVariable::vPlusIntInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vPlusIntDouble @29
          element: <testLibrary>::@topLevelVariable::vPlusIntDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vPlusDoubleInt @59
          element: <testLibrary>::@topLevelVariable::vPlusDoubleInt
          getter: #F8
          setter: #F9
        #F10 hasInitializer vPlusDoubleDouble @89
          element: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
          getter: #F11
          setter: #F12
        #F13 hasInitializer vMinusIntInt @124
          element: <testLibrary>::@topLevelVariable::vMinusIntInt
          getter: #F14
          setter: #F15
        #F16 hasInitializer vMinusIntDouble @150
          element: <testLibrary>::@topLevelVariable::vMinusIntDouble
          getter: #F17
          setter: #F18
        #F19 hasInitializer vMinusDoubleInt @181
          element: <testLibrary>::@topLevelVariable::vMinusDoubleInt
          getter: #F20
          setter: #F21
        #F22 hasInitializer vMinusDoubleDouble @212
          element: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
          getter: #F23
          setter: #F24
      getters
        #F2 synthetic vPlusIntInt
          element: <testLibrary>::@getter::vPlusIntInt
          returnType: int
          variable: #F1
        #F5 synthetic vPlusIntDouble
          element: <testLibrary>::@getter::vPlusIntDouble
          returnType: double
          variable: #F4
        #F8 synthetic vPlusDoubleInt
          element: <testLibrary>::@getter::vPlusDoubleInt
          returnType: double
          variable: #F7
        #F11 synthetic vPlusDoubleDouble
          element: <testLibrary>::@getter::vPlusDoubleDouble
          returnType: double
          variable: #F10
        #F14 synthetic vMinusIntInt
          element: <testLibrary>::@getter::vMinusIntInt
          returnType: int
          variable: #F13
        #F17 synthetic vMinusIntDouble
          element: <testLibrary>::@getter::vMinusIntDouble
          returnType: double
          variable: #F16
        #F20 synthetic vMinusDoubleInt
          element: <testLibrary>::@getter::vMinusDoubleInt
          returnType: double
          variable: #F19
        #F23 synthetic vMinusDoubleDouble
          element: <testLibrary>::@getter::vMinusDoubleDouble
          returnType: double
          variable: #F22
      setters
        #F3 synthetic vPlusIntInt
          element: <testLibrary>::@setter::vPlusIntInt
          formalParameters
            #F25 _vPlusIntInt
              element: <testLibrary>::@setter::vPlusIntInt::@formalParameter::_vPlusIntInt
        #F6 synthetic vPlusIntDouble
          element: <testLibrary>::@setter::vPlusIntDouble
          formalParameters
            #F26 _vPlusIntDouble
              element: <testLibrary>::@setter::vPlusIntDouble::@formalParameter::_vPlusIntDouble
        #F9 synthetic vPlusDoubleInt
          element: <testLibrary>::@setter::vPlusDoubleInt
          formalParameters
            #F27 _vPlusDoubleInt
              element: <testLibrary>::@setter::vPlusDoubleInt::@formalParameter::_vPlusDoubleInt
        #F12 synthetic vPlusDoubleDouble
          element: <testLibrary>::@setter::vPlusDoubleDouble
          formalParameters
            #F28 _vPlusDoubleDouble
              element: <testLibrary>::@setter::vPlusDoubleDouble::@formalParameter::_vPlusDoubleDouble
        #F15 synthetic vMinusIntInt
          element: <testLibrary>::@setter::vMinusIntInt
          formalParameters
            #F29 _vMinusIntInt
              element: <testLibrary>::@setter::vMinusIntInt::@formalParameter::_vMinusIntInt
        #F18 synthetic vMinusIntDouble
          element: <testLibrary>::@setter::vMinusIntDouble
          formalParameters
            #F30 _vMinusIntDouble
              element: <testLibrary>::@setter::vMinusIntDouble::@formalParameter::_vMinusIntDouble
        #F21 synthetic vMinusDoubleInt
          element: <testLibrary>::@setter::vMinusDoubleInt
          formalParameters
            #F31 _vMinusDoubleInt
              element: <testLibrary>::@setter::vMinusDoubleInt::@formalParameter::_vMinusDoubleInt
        #F24 synthetic vMinusDoubleDouble
          element: <testLibrary>::@setter::vMinusDoubleDouble
          formalParameters
            #F32 _vMinusDoubleDouble
              element: <testLibrary>::@setter::vMinusDoubleDouble::@formalParameter::_vMinusDoubleDouble
  topLevelVariables
    hasInitializer vPlusIntInt
      reference: <testLibrary>::@topLevelVariable::vPlusIntInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vPlusIntInt
      setter: <testLibrary>::@setter::vPlusIntInt
    hasInitializer vPlusIntDouble
      reference: <testLibrary>::@topLevelVariable::vPlusIntDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vPlusIntDouble
      setter: <testLibrary>::@setter::vPlusIntDouble
    hasInitializer vPlusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleInt
      firstFragment: #F7
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleInt
      setter: <testLibrary>::@setter::vPlusDoubleInt
    hasInitializer vPlusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleDouble
      setter: <testLibrary>::@setter::vPlusDoubleDouble
    hasInitializer vMinusIntInt
      reference: <testLibrary>::@topLevelVariable::vMinusIntInt
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::vMinusIntInt
      setter: <testLibrary>::@setter::vMinusIntInt
    hasInitializer vMinusIntDouble
      reference: <testLibrary>::@topLevelVariable::vMinusIntDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vMinusIntDouble
      setter: <testLibrary>::@setter::vMinusIntDouble
    hasInitializer vMinusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleInt
      firstFragment: #F19
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleInt
      setter: <testLibrary>::@setter::vMinusDoubleInt
    hasInitializer vMinusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
      firstFragment: #F22
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleDouble
      setter: <testLibrary>::@setter::vMinusDoubleDouble
  getters
    synthetic static vPlusIntInt
      reference: <testLibrary>::@getter::vPlusIntInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vPlusIntInt
    synthetic static vPlusIntDouble
      reference: <testLibrary>::@getter::vPlusIntDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusIntDouble
    synthetic static vPlusDoubleInt
      reference: <testLibrary>::@getter::vPlusDoubleInt
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleInt
    synthetic static vPlusDoubleDouble
      reference: <testLibrary>::@getter::vPlusDoubleDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
    synthetic static vMinusIntInt
      reference: <testLibrary>::@getter::vMinusIntInt
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMinusIntInt
    synthetic static vMinusIntDouble
      reference: <testLibrary>::@getter::vMinusIntDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusIntDouble
    synthetic static vMinusDoubleInt
      reference: <testLibrary>::@getter::vMinusDoubleInt
      firstFragment: #F20
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleInt
    synthetic static vMinusDoubleDouble
      reference: <testLibrary>::@getter::vMinusDoubleDouble
      firstFragment: #F23
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
  setters
    synthetic static vPlusIntInt
      reference: <testLibrary>::@setter::vPlusIntInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vPlusIntInt
          firstFragment: #F25
          type: int
      returnType: void
    synthetic static vPlusIntDouble
      reference: <testLibrary>::@setter::vPlusIntDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vPlusIntDouble
          firstFragment: #F26
          type: double
      returnType: void
    synthetic static vPlusDoubleInt
      reference: <testLibrary>::@setter::vPlusDoubleInt
      firstFragment: #F9
      formalParameters
        requiredPositional _vPlusDoubleInt
          firstFragment: #F27
          type: double
      returnType: void
    synthetic static vPlusDoubleDouble
      reference: <testLibrary>::@setter::vPlusDoubleDouble
      firstFragment: #F12
      formalParameters
        requiredPositional _vPlusDoubleDouble
          firstFragment: #F28
          type: double
      returnType: void
    synthetic static vMinusIntInt
      reference: <testLibrary>::@setter::vMinusIntInt
      firstFragment: #F15
      formalParameters
        requiredPositional _vMinusIntInt
          firstFragment: #F29
          type: int
      returnType: void
    synthetic static vMinusIntDouble
      reference: <testLibrary>::@setter::vMinusIntDouble
      firstFragment: #F18
      formalParameters
        requiredPositional _vMinusIntDouble
          firstFragment: #F30
          type: double
      returnType: void
    synthetic static vMinusDoubleInt
      reference: <testLibrary>::@setter::vMinusDoubleInt
      firstFragment: #F21
      formalParameters
        requiredPositional _vMinusDoubleInt
          firstFragment: #F31
          type: double
      returnType: void
    synthetic static vMinusDoubleDouble
      reference: <testLibrary>::@setter::vMinusDoubleDouble
      firstFragment: #F24
      formalParameters
        requiredPositional _vMinusDoubleDouble
          firstFragment: #F32
          type: double
      returnType: void
''');
  }

  test_initializer_as() async {
    var library = await _encodeDecodeLibrary(r'''
var V = 1 as num;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer V @4
          element: <testLibrary>::@topLevelVariable::V
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: num
          variable: #F1
      setters
        #F3 synthetic V
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 _V
              element: <testLibrary>::@setter::V::@formalParameter::_V
  topLevelVariables
    hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: num
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::V
  setters
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        requiredPositional _V
          firstFragment: #F4
          type: num
      returnType: void
''');
  }

  test_initializer_assign() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1;
var t1 = (a = 2);
var t2 = (a += 2);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer t1 @15
          element: <testLibrary>::@topLevelVariable::t1
          getter: #F5
          setter: #F6
        #F7 hasInitializer t2 @33
          element: <testLibrary>::@topLevelVariable::t2
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
          variable: #F1
        #F5 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
          variable: #F4
        #F8 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
          variable: #F7
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F10 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F11 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F9 synthetic t2
          element: <testLibrary>::@setter::t2
          formalParameters
            #F12 _t2
              element: <testLibrary>::@setter::t2::@formalParameter::_t2
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F10
          type: int
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F6
      formalParameters
        requiredPositional _t1
          firstFragment: #F11
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F9
      formalParameters
        requiredPositional _t2
          firstFragment: #F12
          type: int
      returnType: void
''');
  }

  test_initializer_assign_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var a = [0];
var t1 = (a[0] = 2);
var t2 = (a[0] += 2);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer t1 @17
          element: <testLibrary>::@topLevelVariable::t1
          getter: #F5
          setter: #F6
        #F7 hasInitializer t2 @38
          element: <testLibrary>::@topLevelVariable::t2
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: List<int>
          variable: #F1
        #F5 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
          variable: #F4
        #F8 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
          variable: #F7
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F10 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F11 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F9 synthetic t2
          element: <testLibrary>::@setter::t2
          formalParameters
            #F12 _t2
              element: <testLibrary>::@setter::t2::@formalParameter::_t2
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F10
          type: List<int>
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F6
      formalParameters
        requiredPositional _t1
          firstFragment: #F11
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F9
      formalParameters
        requiredPositional _t2
          firstFragment: #F12
          type: int
      returnType: void
''');
  }

  test_initializer_assign_prefixed() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f;
}
var a = new A();
var t1 = (a.f = 1);
var t2 = (a.f += 2);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 f @16
              element: <testLibrary>::@class::A::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
      topLevelVariables
        #F7 hasInitializer a @25
          element: <testLibrary>::@topLevelVariable::a
          getter: #F8
          setter: #F9
        #F10 hasInitializer t1 @42
          element: <testLibrary>::@topLevelVariable::t1
          getter: #F11
          setter: #F12
        #F13 hasInitializer t2 @62
          element: <testLibrary>::@topLevelVariable::t2
          getter: #F14
          setter: #F15
      getters
        #F8 synthetic a
          element: <testLibrary>::@getter::a
          returnType: A
          variable: #F7
        #F11 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
          variable: #F10
        #F14 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
          variable: #F13
      setters
        #F9 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F16 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F12 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F17 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F15 synthetic t2
          element: <testLibrary>::@setter::t2
          formalParameters
            #F18 _t2
              element: <testLibrary>::@setter::t2::@formalParameter::_t2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F9
      formalParameters
        requiredPositional _a
          firstFragment: #F16
          type: A
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F12
      formalParameters
        requiredPositional _t1
          firstFragment: #F17
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F15
      formalParameters
        requiredPositional _t2
          firstFragment: #F18
          type: int
      returnType: void
''');
  }

  test_initializer_assign_prefixed_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  int f;
}
abstract class C implements I {}
C c;
var t1 = (c.f = 1);
var t2 = (c.f += 2);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I @6
          element: <testLibrary>::@class::I
          fields
            #F2 f @16
              element: <testLibrary>::@class::I::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::I::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::I::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::I::@setter::f::@formalParameter::_f
        #F7 class C @36
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 c @56
          element: <testLibrary>::@topLevelVariable::c
          getter: #F10
          setter: #F11
        #F12 hasInitializer t1 @63
          element: <testLibrary>::@topLevelVariable::t1
          getter: #F13
          setter: #F14
        #F15 hasInitializer t2 @83
          element: <testLibrary>::@topLevelVariable::t2
          getter: #F16
          setter: #F17
      getters
        #F10 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F9
        #F13 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
          variable: #F12
        #F16 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
          variable: #F15
      setters
        #F11 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F18 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F14 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F19 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F17 synthetic t2
          element: <testLibrary>::@setter::t2
          formalParameters
            #F20 _t2
              element: <testLibrary>::@setter::t2::@formalParameter::_t2
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        f
          reference: <testLibrary>::@class::I::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::I::@getter::f
          setter: <testLibrary>::@class::I::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F9
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F12
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F15
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F10
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F16
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F11
      formalParameters
        requiredPositional _c
          firstFragment: #F18
          type: C
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F14
      formalParameters
        requiredPositional _t1
          firstFragment: #F19
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F17
      formalParameters
        requiredPositional _t2
          firstFragment: #F20
          type: int
      returnType: void
''');
  }

  test_initializer_assign_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  int f;
}
abstract class C implements I {}
C getC() => null;
var t1 = (getC().f = 1);
var t2 = (getC().f += 2);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I @6
          element: <testLibrary>::@class::I
          fields
            #F2 f @16
              element: <testLibrary>::@class::I::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::I::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::I::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::I::@setter::f::@formalParameter::_f
        #F7 class C @36
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 hasInitializer t1 @76
          element: <testLibrary>::@topLevelVariable::t1
          getter: #F10
          setter: #F11
        #F12 hasInitializer t2 @101
          element: <testLibrary>::@topLevelVariable::t2
          getter: #F13
          setter: #F14
      getters
        #F10 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
          variable: #F9
        #F13 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
          variable: #F12
      setters
        #F11 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F15 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F14 synthetic t2
          element: <testLibrary>::@setter::t2
          formalParameters
            #F16 _t2
              element: <testLibrary>::@setter::t2::@formalParameter::_t2
      functions
        #F17 getC @56
          element: <testLibrary>::@function::getC
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        f
          reference: <testLibrary>::@class::I::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::I::@getter::f
          setter: <testLibrary>::@class::I::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    hasInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F9
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F12
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F11
      formalParameters
        requiredPositional _t1
          firstFragment: #F15
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F14
      formalParameters
        requiredPositional _t2
          firstFragment: #F16
          type: int
      returnType: void
  functions
    getC
      reference: <testLibrary>::@function::getC
      firstFragment: #F17
      returnType: C
''');
  }

  test_initializer_await() async {
    var library = await _encodeDecodeLibrary(r'''
import 'dart:async';
int fValue() => 42;
Future<int> fFuture() async => 42;
var uValue = () async => await fValue();
var uFuture = () async => await fFuture();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer uValue @80
          element: <testLibrary>::@topLevelVariable::uValue
          getter: #F2
          setter: #F3
        #F4 hasInitializer uFuture @121
          element: <testLibrary>::@topLevelVariable::uFuture
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic uValue
          element: <testLibrary>::@getter::uValue
          returnType: Future<int> Function()
          variable: #F1
        #F5 synthetic uFuture
          element: <testLibrary>::@getter::uFuture
          returnType: Future<int> Function()
          variable: #F4
      setters
        #F3 synthetic uValue
          element: <testLibrary>::@setter::uValue
          formalParameters
            #F7 _uValue
              element: <testLibrary>::@setter::uValue::@formalParameter::_uValue
        #F6 synthetic uFuture
          element: <testLibrary>::@setter::uFuture
          formalParameters
            #F8 _uFuture
              element: <testLibrary>::@setter::uFuture::@formalParameter::_uFuture
      functions
        #F9 fValue @25
          element: <testLibrary>::@function::fValue
        #F10 fFuture @53
          element: <testLibrary>::@function::fFuture
  topLevelVariables
    hasInitializer uValue
      reference: <testLibrary>::@topLevelVariable::uValue
      firstFragment: #F1
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uValue
      setter: <testLibrary>::@setter::uValue
    hasInitializer uFuture
      reference: <testLibrary>::@topLevelVariable::uFuture
      firstFragment: #F4
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uFuture
      setter: <testLibrary>::@setter::uFuture
  getters
    synthetic static uValue
      reference: <testLibrary>::@getter::uValue
      firstFragment: #F2
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uValue
    synthetic static uFuture
      reference: <testLibrary>::@getter::uFuture
      firstFragment: #F5
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uFuture
  setters
    synthetic static uValue
      reference: <testLibrary>::@setter::uValue
      firstFragment: #F3
      formalParameters
        requiredPositional _uValue
          firstFragment: #F7
          type: Future<int> Function()
      returnType: void
    synthetic static uFuture
      reference: <testLibrary>::@setter::uFuture
      firstFragment: #F6
      formalParameters
        requiredPositional _uFuture
          firstFragment: #F8
          type: Future<int> Function()
      returnType: void
  functions
    fValue
      reference: <testLibrary>::@function::fValue
      firstFragment: #F9
      returnType: int
    fFuture
      reference: <testLibrary>::@function::fFuture
      firstFragment: #F10
      returnType: Future<int>
''');
  }

  test_initializer_bitwise() async {
    var library = await _encodeDecodeLibrary(r'''
var vBitXor = 1 ^ 2;
var vBitAnd = 1 & 2;
var vBitOr = 1 | 2;
var vBitShiftLeft = 1 << 2;
var vBitShiftRight = 1 >> 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vBitXor @4
          element: <testLibrary>::@topLevelVariable::vBitXor
          getter: #F2
          setter: #F3
        #F4 hasInitializer vBitAnd @25
          element: <testLibrary>::@topLevelVariable::vBitAnd
          getter: #F5
          setter: #F6
        #F7 hasInitializer vBitOr @46
          element: <testLibrary>::@topLevelVariable::vBitOr
          getter: #F8
          setter: #F9
        #F10 hasInitializer vBitShiftLeft @66
          element: <testLibrary>::@topLevelVariable::vBitShiftLeft
          getter: #F11
          setter: #F12
        #F13 hasInitializer vBitShiftRight @94
          element: <testLibrary>::@topLevelVariable::vBitShiftRight
          getter: #F14
          setter: #F15
      getters
        #F2 synthetic vBitXor
          element: <testLibrary>::@getter::vBitXor
          returnType: int
          variable: #F1
        #F5 synthetic vBitAnd
          element: <testLibrary>::@getter::vBitAnd
          returnType: int
          variable: #F4
        #F8 synthetic vBitOr
          element: <testLibrary>::@getter::vBitOr
          returnType: int
          variable: #F7
        #F11 synthetic vBitShiftLeft
          element: <testLibrary>::@getter::vBitShiftLeft
          returnType: int
          variable: #F10
        #F14 synthetic vBitShiftRight
          element: <testLibrary>::@getter::vBitShiftRight
          returnType: int
          variable: #F13
      setters
        #F3 synthetic vBitXor
          element: <testLibrary>::@setter::vBitXor
          formalParameters
            #F16 _vBitXor
              element: <testLibrary>::@setter::vBitXor::@formalParameter::_vBitXor
        #F6 synthetic vBitAnd
          element: <testLibrary>::@setter::vBitAnd
          formalParameters
            #F17 _vBitAnd
              element: <testLibrary>::@setter::vBitAnd::@formalParameter::_vBitAnd
        #F9 synthetic vBitOr
          element: <testLibrary>::@setter::vBitOr
          formalParameters
            #F18 _vBitOr
              element: <testLibrary>::@setter::vBitOr::@formalParameter::_vBitOr
        #F12 synthetic vBitShiftLeft
          element: <testLibrary>::@setter::vBitShiftLeft
          formalParameters
            #F19 _vBitShiftLeft
              element: <testLibrary>::@setter::vBitShiftLeft::@formalParameter::_vBitShiftLeft
        #F15 synthetic vBitShiftRight
          element: <testLibrary>::@setter::vBitShiftRight
          formalParameters
            #F20 _vBitShiftRight
              element: <testLibrary>::@setter::vBitShiftRight::@formalParameter::_vBitShiftRight
  topLevelVariables
    hasInitializer vBitXor
      reference: <testLibrary>::@topLevelVariable::vBitXor
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vBitXor
      setter: <testLibrary>::@setter::vBitXor
    hasInitializer vBitAnd
      reference: <testLibrary>::@topLevelVariable::vBitAnd
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vBitAnd
      setter: <testLibrary>::@setter::vBitAnd
    hasInitializer vBitOr
      reference: <testLibrary>::@topLevelVariable::vBitOr
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vBitOr
      setter: <testLibrary>::@setter::vBitOr
    hasInitializer vBitShiftLeft
      reference: <testLibrary>::@topLevelVariable::vBitShiftLeft
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vBitShiftLeft
      setter: <testLibrary>::@setter::vBitShiftLeft
    hasInitializer vBitShiftRight
      reference: <testLibrary>::@topLevelVariable::vBitShiftRight
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::vBitShiftRight
      setter: <testLibrary>::@setter::vBitShiftRight
  getters
    synthetic static vBitXor
      reference: <testLibrary>::@getter::vBitXor
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitXor
    synthetic static vBitAnd
      reference: <testLibrary>::@getter::vBitAnd
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    synthetic static vBitOr
      reference: <testLibrary>::@getter::vBitOr
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitOr
    synthetic static vBitShiftLeft
      reference: <testLibrary>::@getter::vBitShiftLeft
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    synthetic static vBitShiftRight
      reference: <testLibrary>::@getter::vBitShiftRight
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftRight
  setters
    synthetic static vBitXor
      reference: <testLibrary>::@setter::vBitXor
      firstFragment: #F3
      formalParameters
        requiredPositional _vBitXor
          firstFragment: #F16
          type: int
      returnType: void
    synthetic static vBitAnd
      reference: <testLibrary>::@setter::vBitAnd
      firstFragment: #F6
      formalParameters
        requiredPositional _vBitAnd
          firstFragment: #F17
          type: int
      returnType: void
    synthetic static vBitOr
      reference: <testLibrary>::@setter::vBitOr
      firstFragment: #F9
      formalParameters
        requiredPositional _vBitOr
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vBitShiftLeft
      reference: <testLibrary>::@setter::vBitShiftLeft
      firstFragment: #F12
      formalParameters
        requiredPositional _vBitShiftLeft
          firstFragment: #F19
          type: int
      returnType: void
    synthetic static vBitShiftRight
      reference: <testLibrary>::@setter::vBitShiftRight
      firstFragment: #F15
      formalParameters
        requiredPositional _vBitShiftRight
          firstFragment: #F20
          type: int
      returnType: void
''');
  }

  test_initializer_cascade() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int a;
  void m() {}
}
var vSetField = new A()..a = 1;
var vInvokeMethod = new A()..m();
var vBoth = new A()..a = 1..m();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 a @16
              element: <testLibrary>::@class::A::@field::a
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: int
              variable: #F2
          setters
            #F4 synthetic a
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 _a
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_a
          methods
            #F7 m @26
              element: <testLibrary>::@class::A::@method::m
      topLevelVariables
        #F8 hasInitializer vSetField @39
          element: <testLibrary>::@topLevelVariable::vSetField
          getter: #F9
          setter: #F10
        #F11 hasInitializer vInvokeMethod @71
          element: <testLibrary>::@topLevelVariable::vInvokeMethod
          getter: #F12
          setter: #F13
        #F14 hasInitializer vBoth @105
          element: <testLibrary>::@topLevelVariable::vBoth
          getter: #F15
          setter: #F16
      getters
        #F9 synthetic vSetField
          element: <testLibrary>::@getter::vSetField
          returnType: A
          variable: #F8
        #F12 synthetic vInvokeMethod
          element: <testLibrary>::@getter::vInvokeMethod
          returnType: A
          variable: #F11
        #F15 synthetic vBoth
          element: <testLibrary>::@getter::vBoth
          returnType: A
          variable: #F14
      setters
        #F10 synthetic vSetField
          element: <testLibrary>::@setter::vSetField
          formalParameters
            #F17 _vSetField
              element: <testLibrary>::@setter::vSetField::@formalParameter::_vSetField
        #F13 synthetic vInvokeMethod
          element: <testLibrary>::@setter::vInvokeMethod
          formalParameters
            #F18 _vInvokeMethod
              element: <testLibrary>::@setter::vInvokeMethod::@formalParameter::_vInvokeMethod
        #F16 synthetic vBoth
          element: <testLibrary>::@setter::vBoth
          formalParameters
            #F19 _vBoth
              element: <testLibrary>::@setter::vBoth::@formalParameter::_vBoth
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F4
          formalParameters
            requiredPositional _a
              firstFragment: #F6
              type: int
          returnType: void
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F7
          returnType: void
  topLevelVariables
    hasInitializer vSetField
      reference: <testLibrary>::@topLevelVariable::vSetField
      firstFragment: #F8
      type: A
      getter: <testLibrary>::@getter::vSetField
      setter: <testLibrary>::@setter::vSetField
    hasInitializer vInvokeMethod
      reference: <testLibrary>::@topLevelVariable::vInvokeMethod
      firstFragment: #F11
      type: A
      getter: <testLibrary>::@getter::vInvokeMethod
      setter: <testLibrary>::@setter::vInvokeMethod
    hasInitializer vBoth
      reference: <testLibrary>::@topLevelVariable::vBoth
      firstFragment: #F14
      type: A
      getter: <testLibrary>::@getter::vBoth
      setter: <testLibrary>::@setter::vBoth
  getters
    synthetic static vSetField
      reference: <testLibrary>::@getter::vSetField
      firstFragment: #F9
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vSetField
    synthetic static vInvokeMethod
      reference: <testLibrary>::@getter::vInvokeMethod
      firstFragment: #F12
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vInvokeMethod
    synthetic static vBoth
      reference: <testLibrary>::@getter::vBoth
      firstFragment: #F15
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vBoth
  setters
    synthetic static vSetField
      reference: <testLibrary>::@setter::vSetField
      firstFragment: #F10
      formalParameters
        requiredPositional _vSetField
          firstFragment: #F17
          type: A
      returnType: void
    synthetic static vInvokeMethod
      reference: <testLibrary>::@setter::vInvokeMethod
      firstFragment: #F13
      formalParameters
        requiredPositional _vInvokeMethod
          firstFragment: #F18
          type: A
      returnType: void
    synthetic static vBoth
      reference: <testLibrary>::@setter::vBoth
      firstFragment: #F16
      formalParameters
        requiredPositional _vBoth
          firstFragment: #F19
          type: A
      returnType: void
''');
  }

  /// A simple or qualified identifier referring to a top level function, static
  /// variable, field, getter; or a static class variable, static getter or
  /// method; or an instance method; has the inferred type of the identifier.
  ///
  test_initializer_classField_useInstanceGetter() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f = 1;
}
class B {
  A a;
}
class C {
  B b;
}
class X {
  A a = new A();
  B b = new B();
  C c = new C();
  var t01 = a.f;
  var t02 = b.a.f;
  var t03 = c.b.a.f;
  var t11 = new A().f;
  var t12 = new B().a.f;
  var t13 = new C().b.a.f;
  var t21 = newA().f;
  var t22 = newB().a.f;
  var t23 = newC().b.a.f;
}
A newA() => new A();
B newB() => new B();
C newC() => new C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer f @16
              element: <testLibrary>::@class::A::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
        #F7 class B @31
          element: <testLibrary>::@class::B
          fields
            #F8 a @39
              element: <testLibrary>::@class::B::@field::a
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic a
              element: <testLibrary>::@class::B::@getter::a
              returnType: A
              variable: #F8
          setters
            #F10 synthetic a
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F12 _a
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::_a
        #F13 class C @50
          element: <testLibrary>::@class::C
          fields
            #F14 b @58
              element: <testLibrary>::@class::C::@field::b
              getter2: #F15
              setter2: #F16
          constructors
            #F17 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F15 synthetic b
              element: <testLibrary>::@class::C::@getter::b
              returnType: B
              variable: #F14
          setters
            #F16 synthetic b
              element: <testLibrary>::@class::C::@setter::b
              formalParameters
                #F18 _b
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::_b
        #F19 class X @69
          element: <testLibrary>::@class::X
          fields
            #F20 hasInitializer a @77
              element: <testLibrary>::@class::X::@field::a
              getter2: #F21
              setter2: #F22
            #F23 hasInitializer b @94
              element: <testLibrary>::@class::X::@field::b
              getter2: #F24
              setter2: #F25
            #F26 hasInitializer c @111
              element: <testLibrary>::@class::X::@field::c
              getter2: #F27
              setter2: #F28
            #F29 hasInitializer t01 @130
              element: <testLibrary>::@class::X::@field::t01
              getter2: #F30
              setter2: #F31
            #F32 hasInitializer t02 @147
              element: <testLibrary>::@class::X::@field::t02
              getter2: #F33
              setter2: #F34
            #F35 hasInitializer t03 @166
              element: <testLibrary>::@class::X::@field::t03
              getter2: #F36
              setter2: #F37
            #F38 hasInitializer t11 @187
              element: <testLibrary>::@class::X::@field::t11
              getter2: #F39
              setter2: #F40
            #F41 hasInitializer t12 @210
              element: <testLibrary>::@class::X::@field::t12
              getter2: #F42
              setter2: #F43
            #F44 hasInitializer t13 @235
              element: <testLibrary>::@class::X::@field::t13
              getter2: #F45
              setter2: #F46
            #F47 hasInitializer t21 @262
              element: <testLibrary>::@class::X::@field::t21
              getter2: #F48
              setter2: #F49
            #F50 hasInitializer t22 @284
              element: <testLibrary>::@class::X::@field::t22
              getter2: #F51
              setter2: #F52
            #F53 hasInitializer t23 @308
              element: <testLibrary>::@class::X::@field::t23
              getter2: #F54
              setter2: #F55
          constructors
            #F56 synthetic new
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
          getters
            #F21 synthetic a
              element: <testLibrary>::@class::X::@getter::a
              returnType: A
              variable: #F20
            #F24 synthetic b
              element: <testLibrary>::@class::X::@getter::b
              returnType: B
              variable: #F23
            #F27 synthetic c
              element: <testLibrary>::@class::X::@getter::c
              returnType: C
              variable: #F26
            #F30 synthetic t01
              element: <testLibrary>::@class::X::@getter::t01
              returnType: int
              variable: #F29
            #F33 synthetic t02
              element: <testLibrary>::@class::X::@getter::t02
              returnType: int
              variable: #F32
            #F36 synthetic t03
              element: <testLibrary>::@class::X::@getter::t03
              returnType: int
              variable: #F35
            #F39 synthetic t11
              element: <testLibrary>::@class::X::@getter::t11
              returnType: int
              variable: #F38
            #F42 synthetic t12
              element: <testLibrary>::@class::X::@getter::t12
              returnType: int
              variable: #F41
            #F45 synthetic t13
              element: <testLibrary>::@class::X::@getter::t13
              returnType: int
              variable: #F44
            #F48 synthetic t21
              element: <testLibrary>::@class::X::@getter::t21
              returnType: int
              variable: #F47
            #F51 synthetic t22
              element: <testLibrary>::@class::X::@getter::t22
              returnType: int
              variable: #F50
            #F54 synthetic t23
              element: <testLibrary>::@class::X::@getter::t23
              returnType: int
              variable: #F53
          setters
            #F22 synthetic a
              element: <testLibrary>::@class::X::@setter::a
              formalParameters
                #F57 _a
                  element: <testLibrary>::@class::X::@setter::a::@formalParameter::_a
            #F25 synthetic b
              element: <testLibrary>::@class::X::@setter::b
              formalParameters
                #F58 _b
                  element: <testLibrary>::@class::X::@setter::b::@formalParameter::_b
            #F28 synthetic c
              element: <testLibrary>::@class::X::@setter::c
              formalParameters
                #F59 _c
                  element: <testLibrary>::@class::X::@setter::c::@formalParameter::_c
            #F31 synthetic t01
              element: <testLibrary>::@class::X::@setter::t01
              formalParameters
                #F60 _t01
                  element: <testLibrary>::@class::X::@setter::t01::@formalParameter::_t01
            #F34 synthetic t02
              element: <testLibrary>::@class::X::@setter::t02
              formalParameters
                #F61 _t02
                  element: <testLibrary>::@class::X::@setter::t02::@formalParameter::_t02
            #F37 synthetic t03
              element: <testLibrary>::@class::X::@setter::t03
              formalParameters
                #F62 _t03
                  element: <testLibrary>::@class::X::@setter::t03::@formalParameter::_t03
            #F40 synthetic t11
              element: <testLibrary>::@class::X::@setter::t11
              formalParameters
                #F63 _t11
                  element: <testLibrary>::@class::X::@setter::t11::@formalParameter::_t11
            #F43 synthetic t12
              element: <testLibrary>::@class::X::@setter::t12
              formalParameters
                #F64 _t12
                  element: <testLibrary>::@class::X::@setter::t12::@formalParameter::_t12
            #F46 synthetic t13
              element: <testLibrary>::@class::X::@setter::t13
              formalParameters
                #F65 _t13
                  element: <testLibrary>::@class::X::@setter::t13::@formalParameter::_t13
            #F49 synthetic t21
              element: <testLibrary>::@class::X::@setter::t21
              formalParameters
                #F66 _t21
                  element: <testLibrary>::@class::X::@setter::t21::@formalParameter::_t21
            #F52 synthetic t22
              element: <testLibrary>::@class::X::@setter::t22
              formalParameters
                #F67 _t22
                  element: <testLibrary>::@class::X::@setter::t22::@formalParameter::_t22
            #F55 synthetic t23
              element: <testLibrary>::@class::X::@setter::t23
              formalParameters
                #F68 _t23
                  element: <testLibrary>::@class::X::@setter::t23::@formalParameter::_t23
      functions
        #F69 newA @332
          element: <testLibrary>::@function::newA
        #F70 newB @353
          element: <testLibrary>::@function::newB
        #F71 newC @374
          element: <testLibrary>::@function::newC
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        a
          reference: <testLibrary>::@class::B::@field::a
          firstFragment: #F8
          type: A
          getter: <testLibrary>::@class::B::@getter::a
          setter: <testLibrary>::@class::B::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F10
          formalParameters
            requiredPositional _a
              firstFragment: #F12
              type: A
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      fields
        b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F14
          type: B
          getter: <testLibrary>::@class::C::@getter::b
          setter: <testLibrary>::@class::C::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F17
      getters
        synthetic b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F15
          returnType: B
          variable: <testLibrary>::@class::C::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F16
          formalParameters
            requiredPositional _b
              firstFragment: #F18
              type: B
          returnType: void
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F19
      fields
        hasInitializer a
          reference: <testLibrary>::@class::X::@field::a
          firstFragment: #F20
          type: A
          getter: <testLibrary>::@class::X::@getter::a
          setter: <testLibrary>::@class::X::@setter::a
        hasInitializer b
          reference: <testLibrary>::@class::X::@field::b
          firstFragment: #F23
          type: B
          getter: <testLibrary>::@class::X::@getter::b
          setter: <testLibrary>::@class::X::@setter::b
        hasInitializer c
          reference: <testLibrary>::@class::X::@field::c
          firstFragment: #F26
          type: C
          getter: <testLibrary>::@class::X::@getter::c
          setter: <testLibrary>::@class::X::@setter::c
        hasInitializer t01
          reference: <testLibrary>::@class::X::@field::t01
          firstFragment: #F29
          type: int
          getter: <testLibrary>::@class::X::@getter::t01
          setter: <testLibrary>::@class::X::@setter::t01
        hasInitializer t02
          reference: <testLibrary>::@class::X::@field::t02
          firstFragment: #F32
          type: int
          getter: <testLibrary>::@class::X::@getter::t02
          setter: <testLibrary>::@class::X::@setter::t02
        hasInitializer t03
          reference: <testLibrary>::@class::X::@field::t03
          firstFragment: #F35
          type: int
          getter: <testLibrary>::@class::X::@getter::t03
          setter: <testLibrary>::@class::X::@setter::t03
        hasInitializer t11
          reference: <testLibrary>::@class::X::@field::t11
          firstFragment: #F38
          type: int
          getter: <testLibrary>::@class::X::@getter::t11
          setter: <testLibrary>::@class::X::@setter::t11
        hasInitializer t12
          reference: <testLibrary>::@class::X::@field::t12
          firstFragment: #F41
          type: int
          getter: <testLibrary>::@class::X::@getter::t12
          setter: <testLibrary>::@class::X::@setter::t12
        hasInitializer t13
          reference: <testLibrary>::@class::X::@field::t13
          firstFragment: #F44
          type: int
          getter: <testLibrary>::@class::X::@getter::t13
          setter: <testLibrary>::@class::X::@setter::t13
        hasInitializer t21
          reference: <testLibrary>::@class::X::@field::t21
          firstFragment: #F47
          type: int
          getter: <testLibrary>::@class::X::@getter::t21
          setter: <testLibrary>::@class::X::@setter::t21
        hasInitializer t22
          reference: <testLibrary>::@class::X::@field::t22
          firstFragment: #F50
          type: int
          getter: <testLibrary>::@class::X::@getter::t22
          setter: <testLibrary>::@class::X::@setter::t22
        hasInitializer t23
          reference: <testLibrary>::@class::X::@field::t23
          firstFragment: #F53
          type: int
          getter: <testLibrary>::@class::X::@getter::t23
          setter: <testLibrary>::@class::X::@setter::t23
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F56
      getters
        synthetic a
          reference: <testLibrary>::@class::X::@getter::a
          firstFragment: #F21
          returnType: A
          variable: <testLibrary>::@class::X::@field::a
        synthetic b
          reference: <testLibrary>::@class::X::@getter::b
          firstFragment: #F24
          returnType: B
          variable: <testLibrary>::@class::X::@field::b
        synthetic c
          reference: <testLibrary>::@class::X::@getter::c
          firstFragment: #F27
          returnType: C
          variable: <testLibrary>::@class::X::@field::c
        synthetic t01
          reference: <testLibrary>::@class::X::@getter::t01
          firstFragment: #F30
          returnType: int
          variable: <testLibrary>::@class::X::@field::t01
        synthetic t02
          reference: <testLibrary>::@class::X::@getter::t02
          firstFragment: #F33
          returnType: int
          variable: <testLibrary>::@class::X::@field::t02
        synthetic t03
          reference: <testLibrary>::@class::X::@getter::t03
          firstFragment: #F36
          returnType: int
          variable: <testLibrary>::@class::X::@field::t03
        synthetic t11
          reference: <testLibrary>::@class::X::@getter::t11
          firstFragment: #F39
          returnType: int
          variable: <testLibrary>::@class::X::@field::t11
        synthetic t12
          reference: <testLibrary>::@class::X::@getter::t12
          firstFragment: #F42
          returnType: int
          variable: <testLibrary>::@class::X::@field::t12
        synthetic t13
          reference: <testLibrary>::@class::X::@getter::t13
          firstFragment: #F45
          returnType: int
          variable: <testLibrary>::@class::X::@field::t13
        synthetic t21
          reference: <testLibrary>::@class::X::@getter::t21
          firstFragment: #F48
          returnType: int
          variable: <testLibrary>::@class::X::@field::t21
        synthetic t22
          reference: <testLibrary>::@class::X::@getter::t22
          firstFragment: #F51
          returnType: int
          variable: <testLibrary>::@class::X::@field::t22
        synthetic t23
          reference: <testLibrary>::@class::X::@getter::t23
          firstFragment: #F54
          returnType: int
          variable: <testLibrary>::@class::X::@field::t23
      setters
        synthetic a
          reference: <testLibrary>::@class::X::@setter::a
          firstFragment: #F22
          formalParameters
            requiredPositional _a
              firstFragment: #F57
              type: A
          returnType: void
        synthetic b
          reference: <testLibrary>::@class::X::@setter::b
          firstFragment: #F25
          formalParameters
            requiredPositional _b
              firstFragment: #F58
              type: B
          returnType: void
        synthetic c
          reference: <testLibrary>::@class::X::@setter::c
          firstFragment: #F28
          formalParameters
            requiredPositional _c
              firstFragment: #F59
              type: C
          returnType: void
        synthetic t01
          reference: <testLibrary>::@class::X::@setter::t01
          firstFragment: #F31
          formalParameters
            requiredPositional _t01
              firstFragment: #F60
              type: int
          returnType: void
        synthetic t02
          reference: <testLibrary>::@class::X::@setter::t02
          firstFragment: #F34
          formalParameters
            requiredPositional _t02
              firstFragment: #F61
              type: int
          returnType: void
        synthetic t03
          reference: <testLibrary>::@class::X::@setter::t03
          firstFragment: #F37
          formalParameters
            requiredPositional _t03
              firstFragment: #F62
              type: int
          returnType: void
        synthetic t11
          reference: <testLibrary>::@class::X::@setter::t11
          firstFragment: #F40
          formalParameters
            requiredPositional _t11
              firstFragment: #F63
              type: int
          returnType: void
        synthetic t12
          reference: <testLibrary>::@class::X::@setter::t12
          firstFragment: #F43
          formalParameters
            requiredPositional _t12
              firstFragment: #F64
              type: int
          returnType: void
        synthetic t13
          reference: <testLibrary>::@class::X::@setter::t13
          firstFragment: #F46
          formalParameters
            requiredPositional _t13
              firstFragment: #F65
              type: int
          returnType: void
        synthetic t21
          reference: <testLibrary>::@class::X::@setter::t21
          firstFragment: #F49
          formalParameters
            requiredPositional _t21
              firstFragment: #F66
              type: int
          returnType: void
        synthetic t22
          reference: <testLibrary>::@class::X::@setter::t22
          firstFragment: #F52
          formalParameters
            requiredPositional _t22
              firstFragment: #F67
              type: int
          returnType: void
        synthetic t23
          reference: <testLibrary>::@class::X::@setter::t23
          firstFragment: #F55
          formalParameters
            requiredPositional _t23
              firstFragment: #F68
              type: int
          returnType: void
  functions
    newA
      reference: <testLibrary>::@function::newA
      firstFragment: #F69
      returnType: A
    newB
      reference: <testLibrary>::@function::newB
      firstFragment: #F70
      returnType: B
    newC
      reference: <testLibrary>::@function::newC
      firstFragment: #F71
      returnType: C
''');
  }

  test_initializer_conditional() async {
    var library = await _encodeDecodeLibrary(r'''
var V = true ? 1 : 2.3;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer V @4
          element: <testLibrary>::@topLevelVariable::V
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: num
          variable: #F1
      setters
        #F3 synthetic V
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 _V
              element: <testLibrary>::@setter::V::@formalParameter::_V
  topLevelVariables
    hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: num
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::V
  setters
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        requiredPositional _V
          firstFragment: #F4
          type: num
      returnType: void
''');
  }

  test_initializer_equality() async {
    var library = await _encodeDecodeLibrary(r'''
var vEq = 1 == 2;
var vNotEq = 1 != 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vEq @4
          element: <testLibrary>::@topLevelVariable::vEq
          getter: #F2
          setter: #F3
        #F4 hasInitializer vNotEq @22
          element: <testLibrary>::@topLevelVariable::vNotEq
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic vEq
          element: <testLibrary>::@getter::vEq
          returnType: bool
          variable: #F1
        #F5 synthetic vNotEq
          element: <testLibrary>::@getter::vNotEq
          returnType: bool
          variable: #F4
      setters
        #F3 synthetic vEq
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F7 _vEq
              element: <testLibrary>::@setter::vEq::@formalParameter::_vEq
        #F6 synthetic vNotEq
          element: <testLibrary>::@setter::vNotEq
          formalParameters
            #F8 _vNotEq
              element: <testLibrary>::@setter::vNotEq::@formalParameter::_vNotEq
  topLevelVariables
    hasInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasInitializer vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    synthetic static vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    synthetic static vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    synthetic static vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F3
      formalParameters
        requiredPositional _vEq
          firstFragment: #F7
          type: bool
      returnType: void
    synthetic static vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F6
      formalParameters
        requiredPositional _vNotEq
          firstFragment: #F8
          type: bool
      returnType: void
''');
  }

  test_initializer_error_methodInvocation_cycle_topLevel() async {
    var library = await _encodeDecodeLibrary(r'''
var a = b.foo();
var b = a.foo();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer b @21
          element: <testLibrary>::@topLevelVariable::b
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F5 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F4
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F7 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F8 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F7
          type: dynamic
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        requiredPositional _b
          firstFragment: #F8
          type: dynamic
      returnType: void
''');
  }

  test_initializer_error_methodInvocation_cycle_topLevel_self() async {
    var library = await _encodeDecodeLibrary(r'''
var a = a.foo();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F4 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F4
          type: dynamic
      returnType: void
''');
  }

  test_initializer_extractIndex() async {
    var library = await _encodeDecodeLibrary(r'''
var a = [0, 1.2];
var b0 = a[0];
var b1 = a[1];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer b0 @22
          element: <testLibrary>::@topLevelVariable::b0
          getter: #F5
          setter: #F6
        #F7 hasInitializer b1 @37
          element: <testLibrary>::@topLevelVariable::b1
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: List<num>
          variable: #F1
        #F5 synthetic b0
          element: <testLibrary>::@getter::b0
          returnType: num
          variable: #F4
        #F8 synthetic b1
          element: <testLibrary>::@getter::b1
          returnType: num
          variable: #F7
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F10 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic b0
          element: <testLibrary>::@setter::b0
          formalParameters
            #F11 _b0
              element: <testLibrary>::@setter::b0::@formalParameter::_b0
        #F9 synthetic b1
          element: <testLibrary>::@setter::b1
          formalParameters
            #F12 _b1
              element: <testLibrary>::@setter::b1::@formalParameter::_b1
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<num>
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b0
      reference: <testLibrary>::@topLevelVariable::b0
      firstFragment: #F4
      type: num
      getter: <testLibrary>::@getter::b0
      setter: <testLibrary>::@setter::b0
    hasInitializer b1
      reference: <testLibrary>::@topLevelVariable::b1
      firstFragment: #F7
      type: num
      getter: <testLibrary>::@getter::b1
      setter: <testLibrary>::@setter::b1
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b0
      reference: <testLibrary>::@getter::b0
      firstFragment: #F5
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b0
    synthetic static b1
      reference: <testLibrary>::@getter::b1
      firstFragment: #F8
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b1
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F10
          type: List<num>
      returnType: void
    synthetic static b0
      reference: <testLibrary>::@setter::b0
      firstFragment: #F6
      formalParameters
        requiredPositional _b0
          firstFragment: #F11
          type: num
      returnType: void
    synthetic static b1
      reference: <testLibrary>::@setter::b1
      firstFragment: #F9
      formalParameters
        requiredPositional _b1
          firstFragment: #F12
          type: num
      returnType: void
''');
  }

  test_initializer_extractProperty_explicitlyTyped_differentLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_initializer_extractProperty_explicitlyTyped_sameLibrary() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  int f = 0;
}
var x = new C().f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer f @16
              element: <testLibrary>::@class::C::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::C::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::_f
      topLevelVariables
        #F7 hasInitializer x @29
          element: <testLibrary>::@topLevelVariable::x
          getter: #F8
          setter: #F9
      getters
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F7
      setters
        #F9 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F10 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        requiredPositional _x
          firstFragment: #F10
          type: int
      returnType: void
''');
  }

  test_initializer_extractProperty_explicitlyTyped_sameLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'test.dart'; // just do make it part of the library cycle
class C {
  int f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_initializer_extractProperty_implicitlyTyped_differentLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  var f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_initializer_extractProperty_implicitlyTyped_sameLibrary() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  var f = 0;
}
var x = new C().f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer f @16
              element: <testLibrary>::@class::C::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::C::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::_f
      topLevelVariables
        #F7 hasInitializer x @29
          element: <testLibrary>::@topLevelVariable::x
          getter: #F8
          setter: #F9
      getters
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F7
      setters
        #F9 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F10 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        requiredPositional _x
          firstFragment: #F10
          type: int
      returnType: void
''');
  }

  test_initializer_extractProperty_implicitlyTyped_sameLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'test.dart'; // just do make it part of the library cycle
class C {
  var f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_initializer_extractProperty_inStaticField() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f;
}
class B {
  static var t = new A().f;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 f @16
              element: <testLibrary>::@class::A::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
        #F7 class B @27
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer t @44
              element: <testLibrary>::@class::B::@field::t
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic t
              element: <testLibrary>::@class::B::@getter::t
              returnType: int
              variable: #F8
          setters
            #F10 synthetic t
              element: <testLibrary>::@class::B::@setter::t
              formalParameters
                #F12 _t
                  element: <testLibrary>::@class::B::@setter::t::@formalParameter::_t
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F6
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        static hasInitializer t
          reference: <testLibrary>::@class::B::@field::t
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::t
          setter: <testLibrary>::@class::B::@setter::t
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic static t
          reference: <testLibrary>::@class::B::@getter::t
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::B::@field::t
      setters
        synthetic static t
          reference: <testLibrary>::@class::B::@setter::t
          firstFragment: #F10
          formalParameters
            requiredPositional _t
              firstFragment: #F12
              type: int
          returnType: void
''');
  }

  test_initializer_extractProperty_prefixedIdentifier() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  bool b;
}
C c;
var x = c.b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 b @17
              element: <testLibrary>::@class::C::@field::b
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 synthetic b
              element: <testLibrary>::@class::C::@getter::b
              returnType: bool
              variable: #F2
          setters
            #F4 synthetic b
              element: <testLibrary>::@class::C::@setter::b
              formalParameters
                #F6 _b
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::_b
      topLevelVariables
        #F7 c @24
          element: <testLibrary>::@topLevelVariable::c
          getter: #F8
          setter: #F9
        #F10 hasInitializer x @31
          element: <testLibrary>::@topLevelVariable::x
          getter: #F11
          setter: #F12
      getters
        #F8 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F7
        #F11 synthetic x
          element: <testLibrary>::@getter::x
          returnType: bool
          variable: #F10
      setters
        #F9 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F13 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F12 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F14 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::C::@getter::b
          setter: <testLibrary>::@class::C::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        synthetic b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F3
          returnType: bool
          variable: <testLibrary>::@class::C::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F4
          formalParameters
            requiredPositional _b
              firstFragment: #F6
              type: bool
          returnType: void
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F7
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F8
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F11
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F9
      formalParameters
        requiredPositional _c
          firstFragment: #F13
          type: C
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F12
      formalParameters
        requiredPositional _x
          firstFragment: #F14
          type: bool
      returnType: void
''');
  }

  test_initializer_extractProperty_prefixedIdentifier_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  bool b;
}
abstract class C implements I {}
C c;
var x = c.b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I @6
          element: <testLibrary>::@class::I
          fields
            #F2 b @17
              element: <testLibrary>::@class::I::@field::b
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 synthetic b
              element: <testLibrary>::@class::I::@getter::b
              returnType: bool
              variable: #F2
          setters
            #F4 synthetic b
              element: <testLibrary>::@class::I::@setter::b
              formalParameters
                #F6 _b
                  element: <testLibrary>::@class::I::@setter::b::@formalParameter::_b
        #F7 class C @37
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 c @57
          element: <testLibrary>::@topLevelVariable::c
          getter: #F10
          setter: #F11
        #F12 hasInitializer x @64
          element: <testLibrary>::@topLevelVariable::x
          getter: #F13
          setter: #F14
      getters
        #F10 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F9
        #F13 synthetic x
          element: <testLibrary>::@getter::x
          returnType: bool
          variable: #F12
      setters
        #F11 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F15 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F14 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F16 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        b
          reference: <testLibrary>::@class::I::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::I::@getter::b
          setter: <testLibrary>::@class::I::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F5
      getters
        synthetic b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F3
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F4
          formalParameters
            requiredPositional _b
              firstFragment: #F6
              type: bool
          returnType: void
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F9
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F12
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F10
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F13
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F11
      formalParameters
        requiredPositional _c
          firstFragment: #F15
          type: C
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F14
      formalParameters
        requiredPositional _x
          firstFragment: #F16
          type: bool
      returnType: void
''');
  }

  test_initializer_extractProperty_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  bool b;
}
abstract class C implements I {}
C f() => null;
var x = f().b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I @6
          element: <testLibrary>::@class::I
          fields
            #F2 b @17
              element: <testLibrary>::@class::I::@field::b
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 synthetic b
              element: <testLibrary>::@class::I::@getter::b
              returnType: bool
              variable: #F2
          setters
            #F4 synthetic b
              element: <testLibrary>::@class::I::@setter::b
              formalParameters
                #F6 _b
                  element: <testLibrary>::@class::I::@setter::b::@formalParameter::_b
        #F7 class C @37
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 hasInitializer x @74
          element: <testLibrary>::@topLevelVariable::x
          getter: #F10
          setter: #F11
      getters
        #F10 synthetic x
          element: <testLibrary>::@getter::x
          returnType: bool
          variable: #F9
      setters
        #F11 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
      functions
        #F13 f @57
          element: <testLibrary>::@function::f
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        b
          reference: <testLibrary>::@class::I::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::I::@getter::b
          setter: <testLibrary>::@class::I::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F5
      getters
        synthetic b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F3
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F4
          formalParameters
            requiredPositional _b
              firstFragment: #F6
              type: bool
          returnType: void
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F9
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
      formalParameters
        requiredPositional _x
          firstFragment: #F12
          type: bool
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F13
      returnType: C
''');
  }

  test_initializer_fromInstanceMethod() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 1;
}
var x = A().foo();
var y = B().foo();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo @16
              element: <testLibrary>::@class::A::@method::foo
        #F4 class B @36
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 foo @52
              element: <testLibrary>::@class::B::@method::foo
      topLevelVariables
        #F7 hasInitializer x @70
          element: <testLibrary>::@topLevelVariable::x
          getter: #F8
          setter: #F9
        #F10 hasInitializer y @89
          element: <testLibrary>::@topLevelVariable::y
          getter: #F11
          setter: #F12
      getters
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F7
        #F11 synthetic y
          element: <testLibrary>::@getter::y
          returnType: int
          variable: #F10
      setters
        #F9 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F13 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
        #F12 synthetic y
          element: <testLibrary>::@setter::y
          formalParameters
            #F14 _y
              element: <testLibrary>::@setter::y::@formalParameter::_y
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          returnType: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F6
          returnType: int
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::y
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        requiredPositional _x
          firstFragment: #F13
          type: int
      returnType: void
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F12
      formalParameters
        requiredPositional _y
          firstFragment: #F14
          type: int
      returnType: void
''');
  }

  test_initializer_functionExpression() async {
    var library = await _encodeDecodeLibrary(r'''
import 'dart:async';
var vFuture = new Future<int>(42);
var v_noParameters_inferredReturnType = () => 42;
var v_hasParameter_withType_inferredReturnType = (String a) => 42;
var v_hasParameter_withType_returnParameter = (String a) => a;
var v_async_returnValue = () async => 42;
var v_async_returnFuture = () async => vFuture;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer vFuture @25
          element: <testLibrary>::@topLevelVariable::vFuture
          getter: #F2
          setter: #F3
        #F4 hasInitializer v_noParameters_inferredReturnType @60
          element: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
          getter: #F5
          setter: #F6
        #F7 hasInitializer v_hasParameter_withType_inferredReturnType @110
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
          getter: #F8
          setter: #F9
        #F10 hasInitializer v_hasParameter_withType_returnParameter @177
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
          getter: #F11
          setter: #F12
        #F13 hasInitializer v_async_returnValue @240
          element: <testLibrary>::@topLevelVariable::v_async_returnValue
          getter: #F14
          setter: #F15
        #F16 hasInitializer v_async_returnFuture @282
          element: <testLibrary>::@topLevelVariable::v_async_returnFuture
          getter: #F17
          setter: #F18
      getters
        #F2 synthetic vFuture
          element: <testLibrary>::@getter::vFuture
          returnType: Future<int>
          variable: #F1
        #F5 synthetic v_noParameters_inferredReturnType
          element: <testLibrary>::@getter::v_noParameters_inferredReturnType
          returnType: int Function()
          variable: #F4
        #F8 synthetic v_hasParameter_withType_inferredReturnType
          element: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
          returnType: int Function(String)
          variable: #F7
        #F11 synthetic v_hasParameter_withType_returnParameter
          element: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
          returnType: String Function(String)
          variable: #F10
        #F14 synthetic v_async_returnValue
          element: <testLibrary>::@getter::v_async_returnValue
          returnType: Future<int> Function()
          variable: #F13
        #F17 synthetic v_async_returnFuture
          element: <testLibrary>::@getter::v_async_returnFuture
          returnType: Future<int> Function()
          variable: #F16
      setters
        #F3 synthetic vFuture
          element: <testLibrary>::@setter::vFuture
          formalParameters
            #F19 _vFuture
              element: <testLibrary>::@setter::vFuture::@formalParameter::_vFuture
        #F6 synthetic v_noParameters_inferredReturnType
          element: <testLibrary>::@setter::v_noParameters_inferredReturnType
          formalParameters
            #F20 _v_noParameters_inferredReturnType
              element: <testLibrary>::@setter::v_noParameters_inferredReturnType::@formalParameter::_v_noParameters_inferredReturnType
        #F9 synthetic v_hasParameter_withType_inferredReturnType
          element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
          formalParameters
            #F21 _v_hasParameter_withType_inferredReturnType
              element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType::@formalParameter::_v_hasParameter_withType_inferredReturnType
        #F12 synthetic v_hasParameter_withType_returnParameter
          element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
          formalParameters
            #F22 _v_hasParameter_withType_returnParameter
              element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter::@formalParameter::_v_hasParameter_withType_returnParameter
        #F15 synthetic v_async_returnValue
          element: <testLibrary>::@setter::v_async_returnValue
          formalParameters
            #F23 _v_async_returnValue
              element: <testLibrary>::@setter::v_async_returnValue::@formalParameter::_v_async_returnValue
        #F18 synthetic v_async_returnFuture
          element: <testLibrary>::@setter::v_async_returnFuture
          formalParameters
            #F24 _v_async_returnFuture
              element: <testLibrary>::@setter::v_async_returnFuture::@formalParameter::_v_async_returnFuture
  topLevelVariables
    hasInitializer vFuture
      reference: <testLibrary>::@topLevelVariable::vFuture
      firstFragment: #F1
      type: Future<int>
      getter: <testLibrary>::@getter::vFuture
      setter: <testLibrary>::@setter::vFuture
    hasInitializer v_noParameters_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
      firstFragment: #F4
      type: int Function()
      getter: <testLibrary>::@getter::v_noParameters_inferredReturnType
      setter: <testLibrary>::@setter::v_noParameters_inferredReturnType
    hasInitializer v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
      firstFragment: #F7
      type: int Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      setter: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
    hasInitializer v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
      firstFragment: #F10
      type: String Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      setter: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
    hasInitializer v_async_returnValue
      reference: <testLibrary>::@topLevelVariable::v_async_returnValue
      firstFragment: #F13
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnValue
      setter: <testLibrary>::@setter::v_async_returnValue
    hasInitializer v_async_returnFuture
      reference: <testLibrary>::@topLevelVariable::v_async_returnFuture
      firstFragment: #F16
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnFuture
      setter: <testLibrary>::@setter::v_async_returnFuture
  getters
    synthetic static vFuture
      reference: <testLibrary>::@getter::vFuture
      firstFragment: #F2
      returnType: Future<int>
      variable: <testLibrary>::@topLevelVariable::vFuture
    synthetic static v_noParameters_inferredReturnType
      reference: <testLibrary>::@getter::v_noParameters_inferredReturnType
      firstFragment: #F5
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
    synthetic static v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F8
      returnType: int Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
    synthetic static v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      firstFragment: #F11
      returnType: String Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
    synthetic static v_async_returnValue
      reference: <testLibrary>::@getter::v_async_returnValue
      firstFragment: #F14
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnValue
    synthetic static v_async_returnFuture
      reference: <testLibrary>::@getter::v_async_returnFuture
      firstFragment: #F17
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnFuture
  setters
    synthetic static vFuture
      reference: <testLibrary>::@setter::vFuture
      firstFragment: #F3
      formalParameters
        requiredPositional _vFuture
          firstFragment: #F19
          type: Future<int>
      returnType: void
    synthetic static v_noParameters_inferredReturnType
      reference: <testLibrary>::@setter::v_noParameters_inferredReturnType
      firstFragment: #F6
      formalParameters
        requiredPositional _v_noParameters_inferredReturnType
          firstFragment: #F20
          type: int Function()
      returnType: void
    synthetic static v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F9
      formalParameters
        requiredPositional _v_hasParameter_withType_inferredReturnType
          firstFragment: #F21
          type: int Function(String)
      returnType: void
    synthetic static v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
      firstFragment: #F12
      formalParameters
        requiredPositional _v_hasParameter_withType_returnParameter
          firstFragment: #F22
          type: String Function(String)
      returnType: void
    synthetic static v_async_returnValue
      reference: <testLibrary>::@setter::v_async_returnValue
      firstFragment: #F15
      formalParameters
        requiredPositional _v_async_returnValue
          firstFragment: #F23
          type: Future<int> Function()
      returnType: void
    synthetic static v_async_returnFuture
      reference: <testLibrary>::@setter::v_async_returnFuture
      firstFragment: #F18
      formalParameters
        requiredPositional _v_async_returnFuture
          firstFragment: #F24
          type: Future<int> Function()
      returnType: void
''');
  }

  test_initializer_functionExpressionInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
var v = (() => 42)();
''');
    // TODO(scheglov): add more function expression tests
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v @4
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
          variable: #F1
      setters
        #F3 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        requiredPositional _v
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_initializer_functionInvocation_hasTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
T f<T>() => null;
var vHasTypeArgument = f<int>();
var vNoTypeArgument = f();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vHasTypeArgument @22
          element: <testLibrary>::@topLevelVariable::vHasTypeArgument
          getter: #F2
          setter: #F3
        #F4 hasInitializer vNoTypeArgument @55
          element: <testLibrary>::@topLevelVariable::vNoTypeArgument
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic vHasTypeArgument
          element: <testLibrary>::@getter::vHasTypeArgument
          returnType: int
          variable: #F1
        #F5 synthetic vNoTypeArgument
          element: <testLibrary>::@getter::vNoTypeArgument
          returnType: dynamic
          variable: #F4
      setters
        #F3 synthetic vHasTypeArgument
          element: <testLibrary>::@setter::vHasTypeArgument
          formalParameters
            #F7 _vHasTypeArgument
              element: <testLibrary>::@setter::vHasTypeArgument::@formalParameter::_vHasTypeArgument
        #F6 synthetic vNoTypeArgument
          element: <testLibrary>::@setter::vNoTypeArgument
          formalParameters
            #F8 _vNoTypeArgument
              element: <testLibrary>::@setter::vNoTypeArgument::@formalParameter::_vNoTypeArgument
      functions
        #F9 f @2
          element: <testLibrary>::@function::f
          typeParameters
            #F10 T @4
              element: #E0 T
  topLevelVariables
    hasInitializer vHasTypeArgument
      reference: <testLibrary>::@topLevelVariable::vHasTypeArgument
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vHasTypeArgument
      setter: <testLibrary>::@setter::vHasTypeArgument
    hasInitializer vNoTypeArgument
      reference: <testLibrary>::@topLevelVariable::vNoTypeArgument
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::vNoTypeArgument
      setter: <testLibrary>::@setter::vNoTypeArgument
  getters
    synthetic static vHasTypeArgument
      reference: <testLibrary>::@getter::vHasTypeArgument
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vHasTypeArgument
    synthetic static vNoTypeArgument
      reference: <testLibrary>::@getter::vNoTypeArgument
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::vNoTypeArgument
  setters
    synthetic static vHasTypeArgument
      reference: <testLibrary>::@setter::vHasTypeArgument
      firstFragment: #F3
      formalParameters
        requiredPositional _vHasTypeArgument
          firstFragment: #F7
          type: int
      returnType: void
    synthetic static vNoTypeArgument
      reference: <testLibrary>::@setter::vNoTypeArgument
      firstFragment: #F6
      formalParameters
        requiredPositional _vNoTypeArgument
          firstFragment: #F8
          type: dynamic
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F9
      typeParameters
        #E0 T
          firstFragment: #F10
      returnType: T
''');
  }

  test_initializer_functionInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
String f(int p) => null;
var vOkArgumentType = f(1);
var vWrongArgumentType = f(2.0);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vOkArgumentType @29
          element: <testLibrary>::@topLevelVariable::vOkArgumentType
          getter: #F2
          setter: #F3
        #F4 hasInitializer vWrongArgumentType @57
          element: <testLibrary>::@topLevelVariable::vWrongArgumentType
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic vOkArgumentType
          element: <testLibrary>::@getter::vOkArgumentType
          returnType: String
          variable: #F1
        #F5 synthetic vWrongArgumentType
          element: <testLibrary>::@getter::vWrongArgumentType
          returnType: String
          variable: #F4
      setters
        #F3 synthetic vOkArgumentType
          element: <testLibrary>::@setter::vOkArgumentType
          formalParameters
            #F7 _vOkArgumentType
              element: <testLibrary>::@setter::vOkArgumentType::@formalParameter::_vOkArgumentType
        #F6 synthetic vWrongArgumentType
          element: <testLibrary>::@setter::vWrongArgumentType
          formalParameters
            #F8 _vWrongArgumentType
              element: <testLibrary>::@setter::vWrongArgumentType::@formalParameter::_vWrongArgumentType
      functions
        #F9 f @7
          element: <testLibrary>::@function::f
          formalParameters
            #F10 p @13
              element: <testLibrary>::@function::f::@formalParameter::p
  topLevelVariables
    hasInitializer vOkArgumentType
      reference: <testLibrary>::@topLevelVariable::vOkArgumentType
      firstFragment: #F1
      type: String
      getter: <testLibrary>::@getter::vOkArgumentType
      setter: <testLibrary>::@setter::vOkArgumentType
    hasInitializer vWrongArgumentType
      reference: <testLibrary>::@topLevelVariable::vWrongArgumentType
      firstFragment: #F4
      type: String
      getter: <testLibrary>::@getter::vWrongArgumentType
      setter: <testLibrary>::@setter::vWrongArgumentType
  getters
    synthetic static vOkArgumentType
      reference: <testLibrary>::@getter::vOkArgumentType
      firstFragment: #F2
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vOkArgumentType
    synthetic static vWrongArgumentType
      reference: <testLibrary>::@getter::vWrongArgumentType
      firstFragment: #F5
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vWrongArgumentType
  setters
    synthetic static vOkArgumentType
      reference: <testLibrary>::@setter::vOkArgumentType
      firstFragment: #F3
      formalParameters
        requiredPositional _vOkArgumentType
          firstFragment: #F7
          type: String
      returnType: void
    synthetic static vWrongArgumentType
      reference: <testLibrary>::@setter::vWrongArgumentType
      firstFragment: #F6
      formalParameters
        requiredPositional _vWrongArgumentType
          firstFragment: #F8
          type: String
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F9
      formalParameters
        requiredPositional p
          firstFragment: #F10
          type: int
      returnType: String
''');
  }

  test_initializer_identifier() async {
    var library = await _encodeDecodeLibrary(r'''
String topLevelFunction(int p) => null;
var topLevelVariable = 0;
int get topLevelGetter => 0;
class A {
  static var staticClassVariable = 0;
  static int get staticGetter => 0;
  static String staticClassMethod(int p) => null;
  String instanceClassMethod(int p) => null;
}
var r_topLevelFunction = topLevelFunction;
var r_topLevelVariable = topLevelVariable;
var r_topLevelGetter = topLevelGetter;
var r_staticClassVariable = A.staticClassVariable;
var r_staticGetter = A.staticGetter;
var r_staticClassMethod = A.staticClassMethod;
var instanceOfA = new A();
var r_instanceClassMethod = instanceOfA.instanceClassMethod;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @101
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer staticClassVariable @118
              element: <testLibrary>::@class::A::@field::staticClassVariable
              getter2: #F3
              setter2: #F4
            #F5 synthetic staticGetter
              element: <testLibrary>::@class::A::@field::staticGetter
              getter2: #F6
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic staticClassVariable
              element: <testLibrary>::@class::A::@getter::staticClassVariable
              returnType: int
              variable: #F2
            #F6 staticGetter @160
              element: <testLibrary>::@class::A::@getter::staticGetter
              returnType: int
              variable: #F5
          setters
            #F4 synthetic staticClassVariable
              element: <testLibrary>::@class::A::@setter::staticClassVariable
              formalParameters
                #F8 _staticClassVariable
                  element: <testLibrary>::@class::A::@setter::staticClassVariable::@formalParameter::_staticClassVariable
          methods
            #F9 staticClassMethod @195
              element: <testLibrary>::@class::A::@method::staticClassMethod
              formalParameters
                #F10 p @217
                  element: <testLibrary>::@class::A::@method::staticClassMethod::@formalParameter::p
            #F11 instanceClassMethod @238
              element: <testLibrary>::@class::A::@method::instanceClassMethod
              formalParameters
                #F12 p @262
                  element: <testLibrary>::@class::A::@method::instanceClassMethod::@formalParameter::p
      topLevelVariables
        #F13 hasInitializer topLevelVariable @44
          element: <testLibrary>::@topLevelVariable::topLevelVariable
          getter: #F14
          setter: #F15
        #F16 hasInitializer r_topLevelFunction @280
          element: <testLibrary>::@topLevelVariable::r_topLevelFunction
          getter: #F17
          setter: #F18
        #F19 hasInitializer r_topLevelVariable @323
          element: <testLibrary>::@topLevelVariable::r_topLevelVariable
          getter: #F20
          setter: #F21
        #F22 hasInitializer r_topLevelGetter @366
          element: <testLibrary>::@topLevelVariable::r_topLevelGetter
          getter: #F23
          setter: #F24
        #F25 hasInitializer r_staticClassVariable @405
          element: <testLibrary>::@topLevelVariable::r_staticClassVariable
          getter: #F26
          setter: #F27
        #F28 hasInitializer r_staticGetter @456
          element: <testLibrary>::@topLevelVariable::r_staticGetter
          getter: #F29
          setter: #F30
        #F31 hasInitializer r_staticClassMethod @493
          element: <testLibrary>::@topLevelVariable::r_staticClassMethod
          getter: #F32
          setter: #F33
        #F34 hasInitializer instanceOfA @540
          element: <testLibrary>::@topLevelVariable::instanceOfA
          getter: #F35
          setter: #F36
        #F37 hasInitializer r_instanceClassMethod @567
          element: <testLibrary>::@topLevelVariable::r_instanceClassMethod
          getter: #F38
          setter: #F39
        #F40 synthetic topLevelGetter (offset=-1)
          element: <testLibrary>::@topLevelVariable::topLevelGetter
          getter: #F41
      getters
        #F14 synthetic topLevelVariable
          element: <testLibrary>::@getter::topLevelVariable
          returnType: int
          variable: #F13
        #F17 synthetic r_topLevelFunction
          element: <testLibrary>::@getter::r_topLevelFunction
          returnType: String Function(int)
          variable: #F16
        #F20 synthetic r_topLevelVariable
          element: <testLibrary>::@getter::r_topLevelVariable
          returnType: int
          variable: #F19
        #F23 synthetic r_topLevelGetter
          element: <testLibrary>::@getter::r_topLevelGetter
          returnType: int
          variable: #F22
        #F26 synthetic r_staticClassVariable
          element: <testLibrary>::@getter::r_staticClassVariable
          returnType: int
          variable: #F25
        #F29 synthetic r_staticGetter
          element: <testLibrary>::@getter::r_staticGetter
          returnType: int
          variable: #F28
        #F32 synthetic r_staticClassMethod
          element: <testLibrary>::@getter::r_staticClassMethod
          returnType: String Function(int)
          variable: #F31
        #F35 synthetic instanceOfA
          element: <testLibrary>::@getter::instanceOfA
          returnType: A
          variable: #F34
        #F38 synthetic r_instanceClassMethod
          element: <testLibrary>::@getter::r_instanceClassMethod
          returnType: String Function(int)
          variable: #F37
        #F41 topLevelGetter @74
          element: <testLibrary>::@getter::topLevelGetter
          returnType: int
          variable: #F40
      setters
        #F15 synthetic topLevelVariable
          element: <testLibrary>::@setter::topLevelVariable
          formalParameters
            #F42 _topLevelVariable
              element: <testLibrary>::@setter::topLevelVariable::@formalParameter::_topLevelVariable
        #F18 synthetic r_topLevelFunction
          element: <testLibrary>::@setter::r_topLevelFunction
          formalParameters
            #F43 _r_topLevelFunction
              element: <testLibrary>::@setter::r_topLevelFunction::@formalParameter::_r_topLevelFunction
        #F21 synthetic r_topLevelVariable
          element: <testLibrary>::@setter::r_topLevelVariable
          formalParameters
            #F44 _r_topLevelVariable
              element: <testLibrary>::@setter::r_topLevelVariable::@formalParameter::_r_topLevelVariable
        #F24 synthetic r_topLevelGetter
          element: <testLibrary>::@setter::r_topLevelGetter
          formalParameters
            #F45 _r_topLevelGetter
              element: <testLibrary>::@setter::r_topLevelGetter::@formalParameter::_r_topLevelGetter
        #F27 synthetic r_staticClassVariable
          element: <testLibrary>::@setter::r_staticClassVariable
          formalParameters
            #F46 _r_staticClassVariable
              element: <testLibrary>::@setter::r_staticClassVariable::@formalParameter::_r_staticClassVariable
        #F30 synthetic r_staticGetter
          element: <testLibrary>::@setter::r_staticGetter
          formalParameters
            #F47 _r_staticGetter
              element: <testLibrary>::@setter::r_staticGetter::@formalParameter::_r_staticGetter
        #F33 synthetic r_staticClassMethod
          element: <testLibrary>::@setter::r_staticClassMethod
          formalParameters
            #F48 _r_staticClassMethod
              element: <testLibrary>::@setter::r_staticClassMethod::@formalParameter::_r_staticClassMethod
        #F36 synthetic instanceOfA
          element: <testLibrary>::@setter::instanceOfA
          formalParameters
            #F49 _instanceOfA
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::_instanceOfA
        #F39 synthetic r_instanceClassMethod
          element: <testLibrary>::@setter::r_instanceClassMethod
          formalParameters
            #F50 _r_instanceClassMethod
              element: <testLibrary>::@setter::r_instanceClassMethod::@formalParameter::_r_instanceClassMethod
      functions
        #F51 topLevelFunction @7
          element: <testLibrary>::@function::topLevelFunction
          formalParameters
            #F52 p @28
              element: <testLibrary>::@function::topLevelFunction::@formalParameter::p
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasInitializer staticClassVariable
          reference: <testLibrary>::@class::A::@field::staticClassVariable
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::staticClassVariable
          setter: <testLibrary>::@class::A::@setter::staticClassVariable
        synthetic static staticGetter
          reference: <testLibrary>::@class::A::@field::staticGetter
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::staticGetter
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F7
      getters
        synthetic static staticClassVariable
          reference: <testLibrary>::@class::A::@getter::staticClassVariable
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::staticClassVariable
        static staticGetter
          reference: <testLibrary>::@class::A::@getter::staticGetter
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::staticGetter
      setters
        synthetic static staticClassVariable
          reference: <testLibrary>::@class::A::@setter::staticClassVariable
          firstFragment: #F4
          formalParameters
            requiredPositional _staticClassVariable
              firstFragment: #F8
              type: int
          returnType: void
      methods
        static staticClassMethod
          reference: <testLibrary>::@class::A::@method::staticClassMethod
          firstFragment: #F9
          formalParameters
            requiredPositional p
              firstFragment: #F10
              type: int
          returnType: String
        instanceClassMethod
          reference: <testLibrary>::@class::A::@method::instanceClassMethod
          firstFragment: #F11
          formalParameters
            requiredPositional p
              firstFragment: #F12
              type: int
          returnType: String
  topLevelVariables
    hasInitializer topLevelVariable
      reference: <testLibrary>::@topLevelVariable::topLevelVariable
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::topLevelVariable
      setter: <testLibrary>::@setter::topLevelVariable
    hasInitializer r_topLevelFunction
      reference: <testLibrary>::@topLevelVariable::r_topLevelFunction
      firstFragment: #F16
      type: String Function(int)
      getter: <testLibrary>::@getter::r_topLevelFunction
      setter: <testLibrary>::@setter::r_topLevelFunction
    hasInitializer r_topLevelVariable
      reference: <testLibrary>::@topLevelVariable::r_topLevelVariable
      firstFragment: #F19
      type: int
      getter: <testLibrary>::@getter::r_topLevelVariable
      setter: <testLibrary>::@setter::r_topLevelVariable
    hasInitializer r_topLevelGetter
      reference: <testLibrary>::@topLevelVariable::r_topLevelGetter
      firstFragment: #F22
      type: int
      getter: <testLibrary>::@getter::r_topLevelGetter
      setter: <testLibrary>::@setter::r_topLevelGetter
    hasInitializer r_staticClassVariable
      reference: <testLibrary>::@topLevelVariable::r_staticClassVariable
      firstFragment: #F25
      type: int
      getter: <testLibrary>::@getter::r_staticClassVariable
      setter: <testLibrary>::@setter::r_staticClassVariable
    hasInitializer r_staticGetter
      reference: <testLibrary>::@topLevelVariable::r_staticGetter
      firstFragment: #F28
      type: int
      getter: <testLibrary>::@getter::r_staticGetter
      setter: <testLibrary>::@setter::r_staticGetter
    hasInitializer r_staticClassMethod
      reference: <testLibrary>::@topLevelVariable::r_staticClassMethod
      firstFragment: #F31
      type: String Function(int)
      getter: <testLibrary>::@getter::r_staticClassMethod
      setter: <testLibrary>::@setter::r_staticClassMethod
    hasInitializer instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F34
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasInitializer r_instanceClassMethod
      reference: <testLibrary>::@topLevelVariable::r_instanceClassMethod
      firstFragment: #F37
      type: String Function(int)
      getter: <testLibrary>::@getter::r_instanceClassMethod
      setter: <testLibrary>::@setter::r_instanceClassMethod
    synthetic topLevelGetter
      reference: <testLibrary>::@topLevelVariable::topLevelGetter
      firstFragment: #F40
      type: int
      getter: <testLibrary>::@getter::topLevelGetter
  getters
    synthetic static topLevelVariable
      reference: <testLibrary>::@getter::topLevelVariable
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelVariable
    synthetic static r_topLevelFunction
      reference: <testLibrary>::@getter::r_topLevelFunction
      firstFragment: #F17
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_topLevelFunction
    synthetic static r_topLevelVariable
      reference: <testLibrary>::@getter::r_topLevelVariable
      firstFragment: #F20
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelVariable
    synthetic static r_topLevelGetter
      reference: <testLibrary>::@getter::r_topLevelGetter
      firstFragment: #F23
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelGetter
    synthetic static r_staticClassVariable
      reference: <testLibrary>::@getter::r_staticClassVariable
      firstFragment: #F26
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticClassVariable
    synthetic static r_staticGetter
      reference: <testLibrary>::@getter::r_staticGetter
      firstFragment: #F29
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticGetter
    synthetic static r_staticClassMethod
      reference: <testLibrary>::@getter::r_staticClassMethod
      firstFragment: #F32
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_staticClassMethod
    synthetic static instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F35
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    synthetic static r_instanceClassMethod
      reference: <testLibrary>::@getter::r_instanceClassMethod
      firstFragment: #F38
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_instanceClassMethod
    static topLevelGetter
      reference: <testLibrary>::@getter::topLevelGetter
      firstFragment: #F41
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelGetter
  setters
    synthetic static topLevelVariable
      reference: <testLibrary>::@setter::topLevelVariable
      firstFragment: #F15
      formalParameters
        requiredPositional _topLevelVariable
          firstFragment: #F42
          type: int
      returnType: void
    synthetic static r_topLevelFunction
      reference: <testLibrary>::@setter::r_topLevelFunction
      firstFragment: #F18
      formalParameters
        requiredPositional _r_topLevelFunction
          firstFragment: #F43
          type: String Function(int)
      returnType: void
    synthetic static r_topLevelVariable
      reference: <testLibrary>::@setter::r_topLevelVariable
      firstFragment: #F21
      formalParameters
        requiredPositional _r_topLevelVariable
          firstFragment: #F44
          type: int
      returnType: void
    synthetic static r_topLevelGetter
      reference: <testLibrary>::@setter::r_topLevelGetter
      firstFragment: #F24
      formalParameters
        requiredPositional _r_topLevelGetter
          firstFragment: #F45
          type: int
      returnType: void
    synthetic static r_staticClassVariable
      reference: <testLibrary>::@setter::r_staticClassVariable
      firstFragment: #F27
      formalParameters
        requiredPositional _r_staticClassVariable
          firstFragment: #F46
          type: int
      returnType: void
    synthetic static r_staticGetter
      reference: <testLibrary>::@setter::r_staticGetter
      firstFragment: #F30
      formalParameters
        requiredPositional _r_staticGetter
          firstFragment: #F47
          type: int
      returnType: void
    synthetic static r_staticClassMethod
      reference: <testLibrary>::@setter::r_staticClassMethod
      firstFragment: #F33
      formalParameters
        requiredPositional _r_staticClassMethod
          firstFragment: #F48
          type: String Function(int)
      returnType: void
    synthetic static instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F36
      formalParameters
        requiredPositional _instanceOfA
          firstFragment: #F49
          type: A
      returnType: void
    synthetic static r_instanceClassMethod
      reference: <testLibrary>::@setter::r_instanceClassMethod
      firstFragment: #F39
      formalParameters
        requiredPositional _r_instanceClassMethod
          firstFragment: #F50
          type: String Function(int)
      returnType: void
  functions
    topLevelFunction
      reference: <testLibrary>::@function::topLevelFunction
      firstFragment: #F51
      formalParameters
        requiredPositional p
          firstFragment: #F52
          type: int
      returnType: String
''');
  }

  test_initializer_identifier_error_cycle_classField() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  static var a = B.b;
}
class B {
  static var b = A.a;
}
var c = A.a;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer a @23
              element: <testLibrary>::@class::A::@field::a
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: dynamic
              variable: #F2
          setters
            #F4 synthetic a
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 _a
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_a
        #F7 class B @40
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer b @57
              element: <testLibrary>::@class::B::@field::b
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic b
              element: <testLibrary>::@class::B::@getter::b
              returnType: dynamic
              variable: #F8
          setters
            #F10 synthetic b
              element: <testLibrary>::@class::B::@setter::b
              formalParameters
                #F12 _b
                  element: <testLibrary>::@class::B::@setter::b::@formalParameter::_b
      topLevelVariables
        #F13 hasInitializer c @72
          element: <testLibrary>::@topLevelVariable::c
          getter: #F14
          setter: #F15
      getters
        #F14 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F13
      setters
        #F15 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F16 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasInitializer a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        synthetic static a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F4
          formalParameters
            requiredPositional _a
              firstFragment: #F6
              type: dynamic
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        static hasInitializer b
          reference: <testLibrary>::@class::B::@field::b
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::b
          setter: <testLibrary>::@class::B::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic static b
          reference: <testLibrary>::@class::B::@getter::b
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::b
      setters
        synthetic static b
          reference: <testLibrary>::@class::B::@setter::b
          firstFragment: #F10
          formalParameters
            requiredPositional _b
              firstFragment: #F12
              type: dynamic
          returnType: void
  topLevelVariables
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F13
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F15
      formalParameters
        requiredPositional _c
          firstFragment: #F16
          type: dynamic
      returnType: void
''');
  }

  test_initializer_identifier_error_cycle_mix() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  static var a = b;
}
var b = A.a;
var c = b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer a @23
              element: <testLibrary>::@class::A::@field::a
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: dynamic
              variable: #F2
          setters
            #F4 synthetic a
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 _a
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_a
      topLevelVariables
        #F7 hasInitializer b @36
          element: <testLibrary>::@topLevelVariable::b
          getter: #F8
          setter: #F9
        #F10 hasInitializer c @49
          element: <testLibrary>::@topLevelVariable::c
          getter: #F11
          setter: #F12
      getters
        #F8 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F7
        #F11 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F10
      setters
        #F9 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F13 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
        #F12 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F14 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasInitializer a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        synthetic static a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F4
          formalParameters
            requiredPositional _a
              firstFragment: #F6
              type: dynamic
          returnType: void
  topLevelVariables
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F7
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F9
      formalParameters
        requiredPositional _b
          firstFragment: #F13
          type: dynamic
      returnType: void
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F12
      formalParameters
        requiredPositional _c
          firstFragment: #F14
          type: dynamic
      returnType: void
''');
  }

  test_initializer_identifier_error_cycle_topLevel() async {
    var library = await _encodeDecodeLibrary(r'''
final a = b;
final b = c;
final c = a;
final d = a;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
        #F3 hasInitializer b @19
          element: <testLibrary>::@topLevelVariable::b
          getter: #F4
        #F5 hasInitializer c @32
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
        #F7 hasInitializer d @45
          element: <testLibrary>::@topLevelVariable::d
          getter: #F8
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F3
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F5
        #F8 synthetic d
          element: <testLibrary>::@getter::d
          returnType: dynamic
          variable: #F7
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::c
    final hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F7
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_initializer_identifier_formalParameter() async {
    // TODO(scheglov): I don't understand this yet
  }

  @skippedTest
  test_initializer_instanceCreation_hasTypeParameter() async {
    var library = await _encodeDecodeLibrary(r'''
class A<T> {}
var a = new A<int>();
var b = new A();
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
class A<T> {
}
A<int> a;
dynamic b;
''');
  }

  test_initializer_instanceCreation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {}
var a = new A();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F3 hasInitializer a @15
          element: <testLibrary>::@topLevelVariable::a
          getter: #F4
          setter: #F5
      getters
        #F4 synthetic a
          element: <testLibrary>::@getter::a
          returnType: A
          variable: #F3
      setters
        #F5 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        requiredPositional _a
          firstFragment: #F6
          type: A
      returnType: void
''');
  }

  test_initializer_instanceGetterOfObject() async {
    var library = await _encodeDecodeLibrary(r'''
dynamic f() => null;
var s = f().toString();
var h = f().hashCode;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer s @25
          element: <testLibrary>::@topLevelVariable::s
          getter: #F2
          setter: #F3
        #F4 hasInitializer h @49
          element: <testLibrary>::@topLevelVariable::h
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic s
          element: <testLibrary>::@getter::s
          returnType: String
          variable: #F1
        #F5 synthetic h
          element: <testLibrary>::@getter::h
          returnType: int
          variable: #F4
      setters
        #F3 synthetic s
          element: <testLibrary>::@setter::s
          formalParameters
            #F7 _s
              element: <testLibrary>::@setter::s::@formalParameter::_s
        #F6 synthetic h
          element: <testLibrary>::@setter::h
          formalParameters
            #F8 _h
              element: <testLibrary>::@setter::h::@formalParameter::_h
      functions
        #F9 f @8
          element: <testLibrary>::@function::f
  topLevelVariables
    hasInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F1
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasInitializer h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    synthetic static s
      reference: <testLibrary>::@getter::s
      firstFragment: #F2
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    synthetic static h
      reference: <testLibrary>::@getter::h
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    synthetic static s
      reference: <testLibrary>::@setter::s
      firstFragment: #F3
      formalParameters
        requiredPositional _s
          firstFragment: #F7
          type: String
      returnType: void
    synthetic static h
      reference: <testLibrary>::@setter::h
      firstFragment: #F6
      formalParameters
        requiredPositional _h
          firstFragment: #F8
          type: int
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F9
      returnType: dynamic
''');
  }

  test_initializer_instanceGetterOfObject_prefixed() async {
    var library = await _encodeDecodeLibrary(r'''
dynamic d;
var s = d.toString();
var h = d.hashCode;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 d @8
          element: <testLibrary>::@topLevelVariable::d
          getter: #F2
          setter: #F3
        #F4 hasInitializer s @15
          element: <testLibrary>::@topLevelVariable::s
          getter: #F5
          setter: #F6
        #F7 hasInitializer h @37
          element: <testLibrary>::@topLevelVariable::h
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic d
          element: <testLibrary>::@getter::d
          returnType: dynamic
          variable: #F1
        #F5 synthetic s
          element: <testLibrary>::@getter::s
          returnType: String
          variable: #F4
        #F8 synthetic h
          element: <testLibrary>::@getter::h
          returnType: int
          variable: #F7
      setters
        #F3 synthetic d
          element: <testLibrary>::@setter::d
          formalParameters
            #F10 _d
              element: <testLibrary>::@setter::d::@formalParameter::_d
        #F6 synthetic s
          element: <testLibrary>::@setter::s
          formalParameters
            #F11 _s
              element: <testLibrary>::@setter::s::@formalParameter::_s
        #F9 synthetic h
          element: <testLibrary>::@setter::h
          formalParameters
            #F12 _h
              element: <testLibrary>::@setter::h::@formalParameter::_h
  topLevelVariables
    d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
    hasInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F4
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasInitializer h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
    synthetic static s
      reference: <testLibrary>::@getter::s
      firstFragment: #F5
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    synthetic static h
      reference: <testLibrary>::@getter::h
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    synthetic static d
      reference: <testLibrary>::@setter::d
      firstFragment: #F3
      formalParameters
        requiredPositional _d
          firstFragment: #F10
          type: dynamic
      returnType: void
    synthetic static s
      reference: <testLibrary>::@setter::s
      firstFragment: #F6
      formalParameters
        requiredPositional _s
          firstFragment: #F11
          type: String
      returnType: void
    synthetic static h
      reference: <testLibrary>::@setter::h
      firstFragment: #F9
      formalParameters
        requiredPositional _h
          firstFragment: #F12
          type: int
      returnType: void
''');
  }

  test_initializer_is() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1.2;
var b = a is int;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer b @17
          element: <testLibrary>::@topLevelVariable::b
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: double
          variable: #F1
        #F5 synthetic b
          element: <testLibrary>::@getter::b
          returnType: bool
          variable: #F4
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F7 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F8 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: double
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: double
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F7
          type: double
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        requiredPositional _b
          firstFragment: #F8
          type: bool
      returnType: void
''');
  }

  @skippedTest
  test_initializer_literal() async {
    var library = await _encodeDecodeLibrary(r'''
var vNull = null;
var vBoolFalse = false;
var vBoolTrue = true;
var vInt = 1;
var vIntLong = 0x9876543210987654321;
var vDouble = 2.3;
var vString = 'abc';
var vStringConcat = 'aaa' 'bbb';
var vStringInterpolation = 'aaa ${true} ${42} bbb';
var vSymbol = #aaa.bbb.ccc;
''');
    checkElementText(library, r'''
Null vNull;
bool vBoolFalse;
bool vBoolTrue;
int vInt;
int vIntLong;
double vDouble;
String vString;
String vStringConcat;
String vStringInterpolation;
Symbol vSymbol;
''');
  }

  test_initializer_literal_list_typed() async {
    var library = await _encodeDecodeLibrary(r'''
var vObject = <Object>[1, 2, 3];
var vNum = <num>[1, 2, 3];
var vNumEmpty = <num>[];
var vInt = <int>[1, 2, 3];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vObject @4
          element: <testLibrary>::@topLevelVariable::vObject
          getter: #F2
          setter: #F3
        #F4 hasInitializer vNum @37
          element: <testLibrary>::@topLevelVariable::vNum
          getter: #F5
          setter: #F6
        #F7 hasInitializer vNumEmpty @64
          element: <testLibrary>::@topLevelVariable::vNumEmpty
          getter: #F8
          setter: #F9
        #F10 hasInitializer vInt @89
          element: <testLibrary>::@topLevelVariable::vInt
          getter: #F11
          setter: #F12
      getters
        #F2 synthetic vObject
          element: <testLibrary>::@getter::vObject
          returnType: List<Object>
          variable: #F1
        #F5 synthetic vNum
          element: <testLibrary>::@getter::vNum
          returnType: List<num>
          variable: #F4
        #F8 synthetic vNumEmpty
          element: <testLibrary>::@getter::vNumEmpty
          returnType: List<num>
          variable: #F7
        #F11 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
          variable: #F10
      setters
        #F3 synthetic vObject
          element: <testLibrary>::@setter::vObject
          formalParameters
            #F13 _vObject
              element: <testLibrary>::@setter::vObject::@formalParameter::_vObject
        #F6 synthetic vNum
          element: <testLibrary>::@setter::vNum
          formalParameters
            #F14 _vNum
              element: <testLibrary>::@setter::vNum::@formalParameter::_vNum
        #F9 synthetic vNumEmpty
          element: <testLibrary>::@setter::vNumEmpty
          formalParameters
            #F15 _vNumEmpty
              element: <testLibrary>::@setter::vNumEmpty::@formalParameter::_vNumEmpty
        #F12 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F16 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
  topLevelVariables
    hasInitializer vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F1
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
    hasInitializer vNum
      reference: <testLibrary>::@topLevelVariable::vNum
      firstFragment: #F4
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasInitializer vNumEmpty
      reference: <testLibrary>::@topLevelVariable::vNumEmpty
      firstFragment: #F7
      type: List<num>
      getter: <testLibrary>::@getter::vNumEmpty
      setter: <testLibrary>::@setter::vNumEmpty
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F10
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
  getters
    synthetic static vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F2
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
    synthetic static vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F5
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    synthetic static vNumEmpty
      reference: <testLibrary>::@getter::vNumEmpty
      firstFragment: #F8
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNumEmpty
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F11
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
  setters
    synthetic static vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F3
      formalParameters
        requiredPositional _vObject
          firstFragment: #F13
          type: List<Object>
      returnType: void
    synthetic static vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F6
      formalParameters
        requiredPositional _vNum
          firstFragment: #F14
          type: List<num>
      returnType: void
    synthetic static vNumEmpty
      reference: <testLibrary>::@setter::vNumEmpty
      firstFragment: #F9
      formalParameters
        requiredPositional _vNumEmpty
          firstFragment: #F15
          type: List<num>
      returnType: void
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F12
      formalParameters
        requiredPositional _vInt
          firstFragment: #F16
          type: List<int>
      returnType: void
''');
  }

  test_initializer_literal_list_untyped() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1, 2, 3];
var vNum = [1, 2.0];
var vObject = [1, 2.0, '333'];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vInt @4
          element: <testLibrary>::@topLevelVariable::vInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vNum @26
          element: <testLibrary>::@topLevelVariable::vNum
          getter: #F5
          setter: #F6
        #F7 hasInitializer vObject @47
          element: <testLibrary>::@topLevelVariable::vObject
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
          variable: #F1
        #F5 synthetic vNum
          element: <testLibrary>::@getter::vNum
          returnType: List<num>
          variable: #F4
        #F8 synthetic vObject
          element: <testLibrary>::@getter::vObject
          returnType: List<Object>
          variable: #F7
      setters
        #F3 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F10 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F6 synthetic vNum
          element: <testLibrary>::@setter::vNum
          formalParameters
            #F11 _vNum
              element: <testLibrary>::@setter::vNum::@formalParameter::_vNum
        #F9 synthetic vObject
          element: <testLibrary>::@setter::vObject
          formalParameters
            #F12 _vObject
              element: <testLibrary>::@setter::vObject::@formalParameter::_vObject
  topLevelVariables
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasInitializer vNum
      reference: <testLibrary>::@topLevelVariable::vNum
      firstFragment: #F4
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasInitializer vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F7
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F5
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    synthetic static vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F8
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vInt
          firstFragment: #F10
          type: List<int>
      returnType: void
    synthetic static vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F6
      formalParameters
        requiredPositional _vNum
          firstFragment: #F11
          type: List<num>
      returnType: void
    synthetic static vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F9
      formalParameters
        requiredPositional _vObject
          firstFragment: #F12
          type: List<Object>
      returnType: void
''');
  }

  @skippedTest
  test_initializer_literal_list_untyped_empty() async {
    var library = await _encodeDecodeLibrary(r'''
var vNonConst = [];
var vConst = const [];
''');
    checkElementText(library, r'''
List<dynamic> vNonConst;
List<Null> vConst;
''');
  }

  test_initializer_literal_map_typed() async {
    var library = await _encodeDecodeLibrary(r'''
var vObjectObject = <Object, Object>{1: 'a'};
var vComparableObject = <Comparable<int>, Object>{1: 'a'};
var vNumString = <num, String>{1: 'a'};
var vNumStringEmpty = <num, String>{};
var vIntString = <int, String>{};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vObjectObject @4
          element: <testLibrary>::@topLevelVariable::vObjectObject
          getter: #F2
          setter: #F3
        #F4 hasInitializer vComparableObject @50
          element: <testLibrary>::@topLevelVariable::vComparableObject
          getter: #F5
          setter: #F6
        #F7 hasInitializer vNumString @109
          element: <testLibrary>::@topLevelVariable::vNumString
          getter: #F8
          setter: #F9
        #F10 hasInitializer vNumStringEmpty @149
          element: <testLibrary>::@topLevelVariable::vNumStringEmpty
          getter: #F11
          setter: #F12
        #F13 hasInitializer vIntString @188
          element: <testLibrary>::@topLevelVariable::vIntString
          getter: #F14
          setter: #F15
      getters
        #F2 synthetic vObjectObject
          element: <testLibrary>::@getter::vObjectObject
          returnType: Map<Object, Object>
          variable: #F1
        #F5 synthetic vComparableObject
          element: <testLibrary>::@getter::vComparableObject
          returnType: Map<Comparable<int>, Object>
          variable: #F4
        #F8 synthetic vNumString
          element: <testLibrary>::@getter::vNumString
          returnType: Map<num, String>
          variable: #F7
        #F11 synthetic vNumStringEmpty
          element: <testLibrary>::@getter::vNumStringEmpty
          returnType: Map<num, String>
          variable: #F10
        #F14 synthetic vIntString
          element: <testLibrary>::@getter::vIntString
          returnType: Map<int, String>
          variable: #F13
      setters
        #F3 synthetic vObjectObject
          element: <testLibrary>::@setter::vObjectObject
          formalParameters
            #F16 _vObjectObject
              element: <testLibrary>::@setter::vObjectObject::@formalParameter::_vObjectObject
        #F6 synthetic vComparableObject
          element: <testLibrary>::@setter::vComparableObject
          formalParameters
            #F17 _vComparableObject
              element: <testLibrary>::@setter::vComparableObject::@formalParameter::_vComparableObject
        #F9 synthetic vNumString
          element: <testLibrary>::@setter::vNumString
          formalParameters
            #F18 _vNumString
              element: <testLibrary>::@setter::vNumString::@formalParameter::_vNumString
        #F12 synthetic vNumStringEmpty
          element: <testLibrary>::@setter::vNumStringEmpty
          formalParameters
            #F19 _vNumStringEmpty
              element: <testLibrary>::@setter::vNumStringEmpty::@formalParameter::_vNumStringEmpty
        #F15 synthetic vIntString
          element: <testLibrary>::@setter::vIntString
          formalParameters
            #F20 _vIntString
              element: <testLibrary>::@setter::vIntString::@formalParameter::_vIntString
  topLevelVariables
    hasInitializer vObjectObject
      reference: <testLibrary>::@topLevelVariable::vObjectObject
      firstFragment: #F1
      type: Map<Object, Object>
      getter: <testLibrary>::@getter::vObjectObject
      setter: <testLibrary>::@setter::vObjectObject
    hasInitializer vComparableObject
      reference: <testLibrary>::@topLevelVariable::vComparableObject
      firstFragment: #F4
      type: Map<Comparable<int>, Object>
      getter: <testLibrary>::@getter::vComparableObject
      setter: <testLibrary>::@setter::vComparableObject
    hasInitializer vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F7
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasInitializer vNumStringEmpty
      reference: <testLibrary>::@topLevelVariable::vNumStringEmpty
      firstFragment: #F10
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumStringEmpty
      setter: <testLibrary>::@setter::vNumStringEmpty
    hasInitializer vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F13
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
  getters
    synthetic static vObjectObject
      reference: <testLibrary>::@getter::vObjectObject
      firstFragment: #F2
      returnType: Map<Object, Object>
      variable: <testLibrary>::@topLevelVariable::vObjectObject
    synthetic static vComparableObject
      reference: <testLibrary>::@getter::vComparableObject
      firstFragment: #F5
      returnType: Map<Comparable<int>, Object>
      variable: <testLibrary>::@topLevelVariable::vComparableObject
    synthetic static vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F8
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    synthetic static vNumStringEmpty
      reference: <testLibrary>::@getter::vNumStringEmpty
      firstFragment: #F11
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumStringEmpty
    synthetic static vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F14
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
  setters
    synthetic static vObjectObject
      reference: <testLibrary>::@setter::vObjectObject
      firstFragment: #F3
      formalParameters
        requiredPositional _vObjectObject
          firstFragment: #F16
          type: Map<Object, Object>
      returnType: void
    synthetic static vComparableObject
      reference: <testLibrary>::@setter::vComparableObject
      firstFragment: #F6
      formalParameters
        requiredPositional _vComparableObject
          firstFragment: #F17
          type: Map<Comparable<int>, Object>
      returnType: void
    synthetic static vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F9
      formalParameters
        requiredPositional _vNumString
          firstFragment: #F18
          type: Map<num, String>
      returnType: void
    synthetic static vNumStringEmpty
      reference: <testLibrary>::@setter::vNumStringEmpty
      firstFragment: #F12
      formalParameters
        requiredPositional _vNumStringEmpty
          firstFragment: #F19
          type: Map<num, String>
      returnType: void
    synthetic static vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F15
      formalParameters
        requiredPositional _vIntString
          firstFragment: #F20
          type: Map<int, String>
      returnType: void
''');
  }

  test_initializer_literal_map_untyped() async {
    var library = await _encodeDecodeLibrary(r'''
var vIntString = {1: 'a', 2: 'b'};
var vNumString = {1: 'a', 2.0: 'b'};
var vIntObject = {1: 'a', 2: 3.0};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vIntString @4
          element: <testLibrary>::@topLevelVariable::vIntString
          getter: #F2
          setter: #F3
        #F4 hasInitializer vNumString @39
          element: <testLibrary>::@topLevelVariable::vNumString
          getter: #F5
          setter: #F6
        #F7 hasInitializer vIntObject @76
          element: <testLibrary>::@topLevelVariable::vIntObject
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic vIntString
          element: <testLibrary>::@getter::vIntString
          returnType: Map<int, String>
          variable: #F1
        #F5 synthetic vNumString
          element: <testLibrary>::@getter::vNumString
          returnType: Map<num, String>
          variable: #F4
        #F8 synthetic vIntObject
          element: <testLibrary>::@getter::vIntObject
          returnType: Map<int, Object>
          variable: #F7
      setters
        #F3 synthetic vIntString
          element: <testLibrary>::@setter::vIntString
          formalParameters
            #F10 _vIntString
              element: <testLibrary>::@setter::vIntString::@formalParameter::_vIntString
        #F6 synthetic vNumString
          element: <testLibrary>::@setter::vNumString
          formalParameters
            #F11 _vNumString
              element: <testLibrary>::@setter::vNumString::@formalParameter::_vNumString
        #F9 synthetic vIntObject
          element: <testLibrary>::@setter::vIntObject
          formalParameters
            #F12 _vIntObject
              element: <testLibrary>::@setter::vIntObject::@formalParameter::_vIntObject
  topLevelVariables
    hasInitializer vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F1
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
    hasInitializer vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F4
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasInitializer vIntObject
      reference: <testLibrary>::@topLevelVariable::vIntObject
      firstFragment: #F7
      type: Map<int, Object>
      getter: <testLibrary>::@getter::vIntObject
      setter: <testLibrary>::@setter::vIntObject
  getters
    synthetic static vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F2
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
    synthetic static vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F5
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    synthetic static vIntObject
      reference: <testLibrary>::@getter::vIntObject
      firstFragment: #F8
      returnType: Map<int, Object>
      variable: <testLibrary>::@topLevelVariable::vIntObject
  setters
    synthetic static vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F3
      formalParameters
        requiredPositional _vIntString
          firstFragment: #F10
          type: Map<int, String>
      returnType: void
    synthetic static vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F6
      formalParameters
        requiredPositional _vNumString
          firstFragment: #F11
          type: Map<num, String>
      returnType: void
    synthetic static vIntObject
      reference: <testLibrary>::@setter::vIntObject
      firstFragment: #F9
      formalParameters
        requiredPositional _vIntObject
          firstFragment: #F12
          type: Map<int, Object>
      returnType: void
''');
  }

  @skippedTest
  test_initializer_literal_map_untyped_empty() async {
    var library = await _encodeDecodeLibrary(r'''
var vNonConst = {};
var vConst = const {};
''');
    checkElementText(library, r'''
Map<dynamic, dynamic> vNonConst;
Map<Null, Null> vConst;
''');
  }

  test_initializer_logicalBool() async {
    var library = await _encodeDecodeLibrary(r'''
var a = true;
var b = true;
var vEq = 1 == 2;
var vAnd = a && b;
var vOr = a || b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer b @18
          element: <testLibrary>::@topLevelVariable::b
          getter: #F5
          setter: #F6
        #F7 hasInitializer vEq @32
          element: <testLibrary>::@topLevelVariable::vEq
          getter: #F8
          setter: #F9
        #F10 hasInitializer vAnd @50
          element: <testLibrary>::@topLevelVariable::vAnd
          getter: #F11
          setter: #F12
        #F13 hasInitializer vOr @69
          element: <testLibrary>::@topLevelVariable::vOr
          getter: #F14
          setter: #F15
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: bool
          variable: #F1
        #F5 synthetic b
          element: <testLibrary>::@getter::b
          returnType: bool
          variable: #F4
        #F8 synthetic vEq
          element: <testLibrary>::@getter::vEq
          returnType: bool
          variable: #F7
        #F11 synthetic vAnd
          element: <testLibrary>::@getter::vAnd
          returnType: bool
          variable: #F10
        #F14 synthetic vOr
          element: <testLibrary>::@getter::vOr
          returnType: bool
          variable: #F13
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F16 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F17 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
        #F9 synthetic vEq
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F18 _vEq
              element: <testLibrary>::@setter::vEq::@formalParameter::_vEq
        #F12 synthetic vAnd
          element: <testLibrary>::@setter::vAnd
          formalParameters
            #F19 _vAnd
              element: <testLibrary>::@setter::vAnd::@formalParameter::_vAnd
        #F15 synthetic vOr
          element: <testLibrary>::@setter::vOr
          formalParameters
            #F20 _vOr
              element: <testLibrary>::@setter::vOr::@formalParameter::_vOr
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F7
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasInitializer vAnd
      reference: <testLibrary>::@topLevelVariable::vAnd
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::vAnd
      setter: <testLibrary>::@setter::vAnd
    hasInitializer vOr
      reference: <testLibrary>::@topLevelVariable::vOr
      firstFragment: #F13
      type: bool
      getter: <testLibrary>::@getter::vOr
      setter: <testLibrary>::@setter::vOr
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    synthetic static vAnd
      reference: <testLibrary>::@getter::vAnd
      firstFragment: #F11
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vAnd
    synthetic static vOr
      reference: <testLibrary>::@getter::vOr
      firstFragment: #F14
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vOr
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F16
          type: bool
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        requiredPositional _b
          firstFragment: #F17
          type: bool
      returnType: void
    synthetic static vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F9
      formalParameters
        requiredPositional _vEq
          firstFragment: #F18
          type: bool
      returnType: void
    synthetic static vAnd
      reference: <testLibrary>::@setter::vAnd
      firstFragment: #F12
      formalParameters
        requiredPositional _vAnd
          firstFragment: #F19
          type: bool
      returnType: void
    synthetic static vOr
      reference: <testLibrary>::@setter::vOr
      firstFragment: #F15
      formalParameters
        requiredPositional _vOr
          firstFragment: #F20
          type: bool
      returnType: void
''');
  }

  @skippedTest
  test_initializer_methodInvocation_hasTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  List<T> m<T>() => null;
}
var vWithTypeArgument = new A().m<int>();
var vWithoutTypeArgument = new A().m();
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
class A {
  List<T> m<T>(int p) {}
}
List<int> vWithTypeArgument;
dynamic vWithoutTypeArgument;
''');
  }

  test_initializer_methodInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int p) => null;
}
var instanceOfA = new A();
var v1 = instanceOfA.m();
var v2 = new A().m();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 p @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::p
      topLevelVariables
        #F5 hasInitializer instanceOfA @43
          element: <testLibrary>::@topLevelVariable::instanceOfA
          getter: #F6
          setter: #F7
        #F8 hasInitializer v1 @70
          element: <testLibrary>::@topLevelVariable::v1
          getter: #F9
          setter: #F10
        #F11 hasInitializer v2 @96
          element: <testLibrary>::@topLevelVariable::v2
          getter: #F12
          setter: #F13
      getters
        #F6 synthetic instanceOfA
          element: <testLibrary>::@getter::instanceOfA
          returnType: A
          variable: #F5
        #F9 synthetic v1
          element: <testLibrary>::@getter::v1
          returnType: String
          variable: #F8
        #F12 synthetic v2
          element: <testLibrary>::@getter::v2
          returnType: String
          variable: #F11
      setters
        #F7 synthetic instanceOfA
          element: <testLibrary>::@setter::instanceOfA
          formalParameters
            #F14 _instanceOfA
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::_instanceOfA
        #F10 synthetic v1
          element: <testLibrary>::@setter::v1
          formalParameters
            #F15 _v1
              element: <testLibrary>::@setter::v1::@formalParameter::_v1
        #F13 synthetic v2
          element: <testLibrary>::@setter::v2
          formalParameters
            #F16 _v2
              element: <testLibrary>::@setter::v2::@formalParameter::_v2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional p
              firstFragment: #F4
              type: int
          returnType: String
  topLevelVariables
    hasInitializer instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F5
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasInitializer v1
      reference: <testLibrary>::@topLevelVariable::v1
      firstFragment: #F8
      type: String
      getter: <testLibrary>::@getter::v1
      setter: <testLibrary>::@setter::v1
    hasInitializer v2
      reference: <testLibrary>::@topLevelVariable::v2
      firstFragment: #F11
      type: String
      getter: <testLibrary>::@getter::v2
      setter: <testLibrary>::@setter::v2
  getters
    synthetic static instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F6
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    synthetic static v1
      reference: <testLibrary>::@getter::v1
      firstFragment: #F9
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v1
    synthetic static v2
      reference: <testLibrary>::@getter::v2
      firstFragment: #F12
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v2
  setters
    synthetic static instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F7
      formalParameters
        requiredPositional _instanceOfA
          firstFragment: #F14
          type: A
      returnType: void
    synthetic static v1
      reference: <testLibrary>::@setter::v1
      firstFragment: #F10
      formalParameters
        requiredPositional _v1
          firstFragment: #F15
          type: String
      returnType: void
    synthetic static v2
      reference: <testLibrary>::@setter::v2
      firstFragment: #F13
      formalParameters
        requiredPositional _v2
          firstFragment: #F16
          type: String
      returnType: void
''');
  }

  test_initializer_multiplicative() async {
    var library = await _encodeDecodeLibrary(r'''
var vModuloIntInt = 1 % 2;
var vModuloIntDouble = 1 % 2.0;
var vMultiplyIntInt = 1 * 2;
var vMultiplyIntDouble = 1 * 2.0;
var vMultiplyDoubleInt = 1.0 * 2;
var vMultiplyDoubleDouble = 1.0 * 2.0;
var vDivideIntInt = 1 / 2;
var vDivideIntDouble = 1 / 2.0;
var vDivideDoubleInt = 1.0 / 2;
var vDivideDoubleDouble = 1.0 / 2.0;
var vFloorDivide = 1 ~/ 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vModuloIntInt @4
          element: <testLibrary>::@topLevelVariable::vModuloIntInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vModuloIntDouble @31
          element: <testLibrary>::@topLevelVariable::vModuloIntDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vMultiplyIntInt @63
          element: <testLibrary>::@topLevelVariable::vMultiplyIntInt
          getter: #F8
          setter: #F9
        #F10 hasInitializer vMultiplyIntDouble @92
          element: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
          getter: #F11
          setter: #F12
        #F13 hasInitializer vMultiplyDoubleInt @126
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
          getter: #F14
          setter: #F15
        #F16 hasInitializer vMultiplyDoubleDouble @160
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
          getter: #F17
          setter: #F18
        #F19 hasInitializer vDivideIntInt @199
          element: <testLibrary>::@topLevelVariable::vDivideIntInt
          getter: #F20
          setter: #F21
        #F22 hasInitializer vDivideIntDouble @226
          element: <testLibrary>::@topLevelVariable::vDivideIntDouble
          getter: #F23
          setter: #F24
        #F25 hasInitializer vDivideDoubleInt @258
          element: <testLibrary>::@topLevelVariable::vDivideDoubleInt
          getter: #F26
          setter: #F27
        #F28 hasInitializer vDivideDoubleDouble @290
          element: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
          getter: #F29
          setter: #F30
        #F31 hasInitializer vFloorDivide @327
          element: <testLibrary>::@topLevelVariable::vFloorDivide
          getter: #F32
          setter: #F33
      getters
        #F2 synthetic vModuloIntInt
          element: <testLibrary>::@getter::vModuloIntInt
          returnType: int
          variable: #F1
        #F5 synthetic vModuloIntDouble
          element: <testLibrary>::@getter::vModuloIntDouble
          returnType: double
          variable: #F4
        #F8 synthetic vMultiplyIntInt
          element: <testLibrary>::@getter::vMultiplyIntInt
          returnType: int
          variable: #F7
        #F11 synthetic vMultiplyIntDouble
          element: <testLibrary>::@getter::vMultiplyIntDouble
          returnType: double
          variable: #F10
        #F14 synthetic vMultiplyDoubleInt
          element: <testLibrary>::@getter::vMultiplyDoubleInt
          returnType: double
          variable: #F13
        #F17 synthetic vMultiplyDoubleDouble
          element: <testLibrary>::@getter::vMultiplyDoubleDouble
          returnType: double
          variable: #F16
        #F20 synthetic vDivideIntInt
          element: <testLibrary>::@getter::vDivideIntInt
          returnType: double
          variable: #F19
        #F23 synthetic vDivideIntDouble
          element: <testLibrary>::@getter::vDivideIntDouble
          returnType: double
          variable: #F22
        #F26 synthetic vDivideDoubleInt
          element: <testLibrary>::@getter::vDivideDoubleInt
          returnType: double
          variable: #F25
        #F29 synthetic vDivideDoubleDouble
          element: <testLibrary>::@getter::vDivideDoubleDouble
          returnType: double
          variable: #F28
        #F32 synthetic vFloorDivide
          element: <testLibrary>::@getter::vFloorDivide
          returnType: int
          variable: #F31
      setters
        #F3 synthetic vModuloIntInt
          element: <testLibrary>::@setter::vModuloIntInt
          formalParameters
            #F34 _vModuloIntInt
              element: <testLibrary>::@setter::vModuloIntInt::@formalParameter::_vModuloIntInt
        #F6 synthetic vModuloIntDouble
          element: <testLibrary>::@setter::vModuloIntDouble
          formalParameters
            #F35 _vModuloIntDouble
              element: <testLibrary>::@setter::vModuloIntDouble::@formalParameter::_vModuloIntDouble
        #F9 synthetic vMultiplyIntInt
          element: <testLibrary>::@setter::vMultiplyIntInt
          formalParameters
            #F36 _vMultiplyIntInt
              element: <testLibrary>::@setter::vMultiplyIntInt::@formalParameter::_vMultiplyIntInt
        #F12 synthetic vMultiplyIntDouble
          element: <testLibrary>::@setter::vMultiplyIntDouble
          formalParameters
            #F37 _vMultiplyIntDouble
              element: <testLibrary>::@setter::vMultiplyIntDouble::@formalParameter::_vMultiplyIntDouble
        #F15 synthetic vMultiplyDoubleInt
          element: <testLibrary>::@setter::vMultiplyDoubleInt
          formalParameters
            #F38 _vMultiplyDoubleInt
              element: <testLibrary>::@setter::vMultiplyDoubleInt::@formalParameter::_vMultiplyDoubleInt
        #F18 synthetic vMultiplyDoubleDouble
          element: <testLibrary>::@setter::vMultiplyDoubleDouble
          formalParameters
            #F39 _vMultiplyDoubleDouble
              element: <testLibrary>::@setter::vMultiplyDoubleDouble::@formalParameter::_vMultiplyDoubleDouble
        #F21 synthetic vDivideIntInt
          element: <testLibrary>::@setter::vDivideIntInt
          formalParameters
            #F40 _vDivideIntInt
              element: <testLibrary>::@setter::vDivideIntInt::@formalParameter::_vDivideIntInt
        #F24 synthetic vDivideIntDouble
          element: <testLibrary>::@setter::vDivideIntDouble
          formalParameters
            #F41 _vDivideIntDouble
              element: <testLibrary>::@setter::vDivideIntDouble::@formalParameter::_vDivideIntDouble
        #F27 synthetic vDivideDoubleInt
          element: <testLibrary>::@setter::vDivideDoubleInt
          formalParameters
            #F42 _vDivideDoubleInt
              element: <testLibrary>::@setter::vDivideDoubleInt::@formalParameter::_vDivideDoubleInt
        #F30 synthetic vDivideDoubleDouble
          element: <testLibrary>::@setter::vDivideDoubleDouble
          formalParameters
            #F43 _vDivideDoubleDouble
              element: <testLibrary>::@setter::vDivideDoubleDouble::@formalParameter::_vDivideDoubleDouble
        #F33 synthetic vFloorDivide
          element: <testLibrary>::@setter::vFloorDivide
          formalParameters
            #F44 _vFloorDivide
              element: <testLibrary>::@setter::vFloorDivide::@formalParameter::_vFloorDivide
  topLevelVariables
    hasInitializer vModuloIntInt
      reference: <testLibrary>::@topLevelVariable::vModuloIntInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vModuloIntInt
      setter: <testLibrary>::@setter::vModuloIntInt
    hasInitializer vModuloIntDouble
      reference: <testLibrary>::@topLevelVariable::vModuloIntDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vModuloIntDouble
      setter: <testLibrary>::@setter::vModuloIntDouble
    hasInitializer vMultiplyIntInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vMultiplyIntInt
      setter: <testLibrary>::@setter::vMultiplyIntInt
    hasInitializer vMultiplyIntDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::vMultiplyIntDouble
      setter: <testLibrary>::@setter::vMultiplyIntDouble
    hasInitializer vMultiplyDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleInt
      setter: <testLibrary>::@setter::vMultiplyDoubleInt
    hasInitializer vMultiplyDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleDouble
      setter: <testLibrary>::@setter::vMultiplyDoubleDouble
    hasInitializer vDivideIntInt
      reference: <testLibrary>::@topLevelVariable::vDivideIntInt
      firstFragment: #F19
      type: double
      getter: <testLibrary>::@getter::vDivideIntInt
      setter: <testLibrary>::@setter::vDivideIntInt
    hasInitializer vDivideIntDouble
      reference: <testLibrary>::@topLevelVariable::vDivideIntDouble
      firstFragment: #F22
      type: double
      getter: <testLibrary>::@getter::vDivideIntDouble
      setter: <testLibrary>::@setter::vDivideIntDouble
    hasInitializer vDivideDoubleInt
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleInt
      firstFragment: #F25
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleInt
      setter: <testLibrary>::@setter::vDivideDoubleInt
    hasInitializer vDivideDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
      firstFragment: #F28
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleDouble
      setter: <testLibrary>::@setter::vDivideDoubleDouble
    hasInitializer vFloorDivide
      reference: <testLibrary>::@topLevelVariable::vFloorDivide
      firstFragment: #F31
      type: int
      getter: <testLibrary>::@getter::vFloorDivide
      setter: <testLibrary>::@setter::vFloorDivide
  getters
    synthetic static vModuloIntInt
      reference: <testLibrary>::@getter::vModuloIntInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vModuloIntInt
    synthetic static vModuloIntDouble
      reference: <testLibrary>::@getter::vModuloIntDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vModuloIntDouble
    synthetic static vMultiplyIntInt
      reference: <testLibrary>::@getter::vMultiplyIntInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntInt
    synthetic static vMultiplyIntDouble
      reference: <testLibrary>::@getter::vMultiplyIntDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
    synthetic static vMultiplyDoubleInt
      reference: <testLibrary>::@getter::vMultiplyDoubleInt
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
    synthetic static vMultiplyDoubleDouble
      reference: <testLibrary>::@getter::vMultiplyDoubleDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
    synthetic static vDivideIntInt
      reference: <testLibrary>::@getter::vDivideIntInt
      firstFragment: #F20
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntInt
    synthetic static vDivideIntDouble
      reference: <testLibrary>::@getter::vDivideIntDouble
      firstFragment: #F23
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntDouble
    synthetic static vDivideDoubleInt
      reference: <testLibrary>::@getter::vDivideDoubleInt
      firstFragment: #F26
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleInt
    synthetic static vDivideDoubleDouble
      reference: <testLibrary>::@getter::vDivideDoubleDouble
      firstFragment: #F29
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
    synthetic static vFloorDivide
      reference: <testLibrary>::@getter::vFloorDivide
      firstFragment: #F32
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vFloorDivide
  setters
    synthetic static vModuloIntInt
      reference: <testLibrary>::@setter::vModuloIntInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vModuloIntInt
          firstFragment: #F34
          type: int
      returnType: void
    synthetic static vModuloIntDouble
      reference: <testLibrary>::@setter::vModuloIntDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vModuloIntDouble
          firstFragment: #F35
          type: double
      returnType: void
    synthetic static vMultiplyIntInt
      reference: <testLibrary>::@setter::vMultiplyIntInt
      firstFragment: #F9
      formalParameters
        requiredPositional _vMultiplyIntInt
          firstFragment: #F36
          type: int
      returnType: void
    synthetic static vMultiplyIntDouble
      reference: <testLibrary>::@setter::vMultiplyIntDouble
      firstFragment: #F12
      formalParameters
        requiredPositional _vMultiplyIntDouble
          firstFragment: #F37
          type: double
      returnType: void
    synthetic static vMultiplyDoubleInt
      reference: <testLibrary>::@setter::vMultiplyDoubleInt
      firstFragment: #F15
      formalParameters
        requiredPositional _vMultiplyDoubleInt
          firstFragment: #F38
          type: double
      returnType: void
    synthetic static vMultiplyDoubleDouble
      reference: <testLibrary>::@setter::vMultiplyDoubleDouble
      firstFragment: #F18
      formalParameters
        requiredPositional _vMultiplyDoubleDouble
          firstFragment: #F39
          type: double
      returnType: void
    synthetic static vDivideIntInt
      reference: <testLibrary>::@setter::vDivideIntInt
      firstFragment: #F21
      formalParameters
        requiredPositional _vDivideIntInt
          firstFragment: #F40
          type: double
      returnType: void
    synthetic static vDivideIntDouble
      reference: <testLibrary>::@setter::vDivideIntDouble
      firstFragment: #F24
      formalParameters
        requiredPositional _vDivideIntDouble
          firstFragment: #F41
          type: double
      returnType: void
    synthetic static vDivideDoubleInt
      reference: <testLibrary>::@setter::vDivideDoubleInt
      firstFragment: #F27
      formalParameters
        requiredPositional _vDivideDoubleInt
          firstFragment: #F42
          type: double
      returnType: void
    synthetic static vDivideDoubleDouble
      reference: <testLibrary>::@setter::vDivideDoubleDouble
      firstFragment: #F30
      formalParameters
        requiredPositional _vDivideDoubleDouble
          firstFragment: #F43
          type: double
      returnType: void
    synthetic static vFloorDivide
      reference: <testLibrary>::@setter::vFloorDivide
      firstFragment: #F33
      formalParameters
        requiredPositional _vFloorDivide
          firstFragment: #F44
          type: int
      returnType: void
''');
  }

  test_initializer_onlyLeft() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1;
var vEq = a == ((a = 2) == 0);
var vNotEq = a != ((a = 2) == 0);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer vEq @15
          element: <testLibrary>::@topLevelVariable::vEq
          getter: #F5
          setter: #F6
        #F7 hasInitializer vNotEq @46
          element: <testLibrary>::@topLevelVariable::vNotEq
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
          variable: #F1
        #F5 synthetic vEq
          element: <testLibrary>::@getter::vEq
          returnType: bool
          variable: #F4
        #F8 synthetic vNotEq
          element: <testLibrary>::@getter::vNotEq
          returnType: bool
          variable: #F7
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F10 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic vEq
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F11 _vEq
              element: <testLibrary>::@setter::vEq::@formalParameter::_vEq
        #F9 synthetic vNotEq
          element: <testLibrary>::@setter::vNotEq
          formalParameters
            #F12 _vNotEq
              element: <testLibrary>::@setter::vNotEq::@formalParameter::_vNotEq
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasInitializer vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F7
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    synthetic static vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F10
          type: int
      returnType: void
    synthetic static vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F6
      formalParameters
        requiredPositional _vEq
          firstFragment: #F11
          type: bool
      returnType: void
    synthetic static vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F9
      formalParameters
        requiredPositional _vNotEq
          firstFragment: #F12
          type: bool
      returnType: void
''');
  }

  test_initializer_parenthesized() async {
    var library = await _encodeDecodeLibrary(r'''
var V = (42);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer V @4
          element: <testLibrary>::@topLevelVariable::V
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: int
          variable: #F1
      setters
        #F3 synthetic V
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 _V
              element: <testLibrary>::@setter::V::@formalParameter::_V
  topLevelVariables
    hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
  setters
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        requiredPositional _V
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_initializer_postfix() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = 1;
var vDouble = 2.0;
var vIncInt = vInt++;
var vDecInt = vInt--;
var vIncDouble = vDouble++;
var vDecDouble = vDouble--;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vInt @4
          element: <testLibrary>::@topLevelVariable::vInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vDouble @18
          element: <testLibrary>::@topLevelVariable::vDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vIncInt @37
          element: <testLibrary>::@topLevelVariable::vIncInt
          getter: #F8
          setter: #F9
        #F10 hasInitializer vDecInt @59
          element: <testLibrary>::@topLevelVariable::vDecInt
          getter: #F11
          setter: #F12
        #F13 hasInitializer vIncDouble @81
          element: <testLibrary>::@topLevelVariable::vIncDouble
          getter: #F14
          setter: #F15
        #F16 hasInitializer vDecDouble @109
          element: <testLibrary>::@topLevelVariable::vDecDouble
          getter: #F17
          setter: #F18
      getters
        #F2 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: int
          variable: #F1
        #F5 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: double
          variable: #F4
        #F8 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
          variable: #F7
        #F11 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt
          returnType: int
          variable: #F10
        #F14 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
          variable: #F13
        #F17 synthetic vDecDouble
          element: <testLibrary>::@getter::vDecDouble
          returnType: double
          variable: #F16
      setters
        #F3 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F19 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F6 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F20 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F9 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F21 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F12 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt
          formalParameters
            #F22 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@formalParameter::_vDecInt
        #F15 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F23 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F18 synthetic vDecDouble
          element: <testLibrary>::@setter::vDecDouble
          formalParameters
            #F24 _vDecDouble
              element: <testLibrary>::@setter::vDecDouble::@formalParameter::_vDecDouble
  topLevelVariables
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vInt
          firstFragment: #F19
          type: int
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vDouble
          firstFragment: #F20
          type: double
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        requiredPositional _vIncInt
          firstFragment: #F21
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F12
      formalParameters
        requiredPositional _vDecInt
          firstFragment: #F22
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        requiredPositional _vIncDouble
          firstFragment: #F23
          type: double
      returnType: void
    synthetic static vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F18
      formalParameters
        requiredPositional _vDecDouble
          firstFragment: #F24
          type: double
      returnType: void
''');
  }

  test_initializer_postfix_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1];
var vDouble = [2.0];
var vIncInt = vInt[0]++;
var vDecInt = vInt[0]--;
var vIncDouble = vDouble[0]++;
var vDecDouble = vDouble[0]--;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vInt @4
          element: <testLibrary>::@topLevelVariable::vInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vDouble @20
          element: <testLibrary>::@topLevelVariable::vDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vIncInt @41
          element: <testLibrary>::@topLevelVariable::vIncInt
          getter: #F8
          setter: #F9
        #F10 hasInitializer vDecInt @66
          element: <testLibrary>::@topLevelVariable::vDecInt
          getter: #F11
          setter: #F12
        #F13 hasInitializer vIncDouble @91
          element: <testLibrary>::@topLevelVariable::vIncDouble
          getter: #F14
          setter: #F15
        #F16 hasInitializer vDecDouble @122
          element: <testLibrary>::@topLevelVariable::vDecDouble
          getter: #F17
          setter: #F18
      getters
        #F2 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
          variable: #F1
        #F5 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: List<double>
          variable: #F4
        #F8 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
          variable: #F7
        #F11 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt
          returnType: int
          variable: #F10
        #F14 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
          variable: #F13
        #F17 synthetic vDecDouble
          element: <testLibrary>::@getter::vDecDouble
          returnType: double
          variable: #F16
      setters
        #F3 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F19 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F6 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F20 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F9 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F21 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F12 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt
          formalParameters
            #F22 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@formalParameter::_vDecInt
        #F15 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F23 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F18 synthetic vDecDouble
          element: <testLibrary>::@setter::vDecDouble
          formalParameters
            #F24 _vDecDouble
              element: <testLibrary>::@setter::vDecDouble::@formalParameter::_vDecDouble
  topLevelVariables
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vInt
          firstFragment: #F19
          type: List<int>
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vDouble
          firstFragment: #F20
          type: List<double>
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        requiredPositional _vIncInt
          firstFragment: #F21
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F12
      formalParameters
        requiredPositional _vDecInt
          firstFragment: #F22
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        requiredPositional _vIncDouble
          firstFragment: #F23
          type: double
      returnType: void
    synthetic static vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F18
      formalParameters
        requiredPositional _vDecDouble
          firstFragment: #F24
          type: double
      returnType: void
''');
  }

  test_initializer_prefix_incDec() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = 1;
var vDouble = 2.0;
var vIncInt = ++vInt;
var vDecInt = --vInt;
var vIncDouble = ++vDouble;
var vDecInt = --vDouble;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vInt @4
          element: <testLibrary>::@topLevelVariable::vInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vDouble @18
          element: <testLibrary>::@topLevelVariable::vDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vIncInt @37
          element: <testLibrary>::@topLevelVariable::vIncInt
          getter: #F8
          setter: #F9
        #F10 hasInitializer vDecInt @59
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::0
          getter: #F11
          setter: #F12
        #F13 hasInitializer vIncDouble @81
          element: <testLibrary>::@topLevelVariable::vIncDouble
          getter: #F14
          setter: #F15
        #F16 hasInitializer vDecInt @109
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::1
          getter: #F17
          setter: #F18
      getters
        #F2 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: int
          variable: #F1
        #F5 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: double
          variable: #F4
        #F8 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
          variable: #F7
        #F11 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::0
          returnType: int
          variable: #F10
        #F14 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
          variable: #F13
        #F17 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::1
          returnType: double
          variable: #F16
      setters
        #F3 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F19 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F6 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F20 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F9 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F21 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F12 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt::@def::0
          formalParameters
            #F22 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@def::0::@formalParameter::_vDecInt
        #F15 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F23 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F18 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt::@def::1
          formalParameters
            #F24 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@def::1::@formalParameter::_vDecInt
  topLevelVariables
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::0
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt::@def::0
      setter: <testLibrary>::@setter::vDecInt::@def::0
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecInt::@def::1
      setter: <testLibrary>::@setter::vDecInt::@def::1
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::0
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::1
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vInt
          firstFragment: #F19
          type: int
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vDouble
          firstFragment: #F20
          type: double
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        requiredPositional _vIncInt
          firstFragment: #F21
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::0
      firstFragment: #F12
      formalParameters
        requiredPositional _vDecInt
          firstFragment: #F22
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        requiredPositional _vIncDouble
          firstFragment: #F23
          type: double
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::1
      firstFragment: #F18
      formalParameters
        requiredPositional _vDecInt
          firstFragment: #F24
          type: double
      returnType: void
''');
  }

  @skippedTest
  test_initializer_prefix_incDec_custom() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  B operator+(int v) => null;
}
class B {}
var a = new A();
var vInc = ++a;
var vDec = --a;
''');
    checkElementText(library, r'''
A a;
B vInc;
B vDec;
''');
  }

  test_initializer_prefix_incDec_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1];
var vDouble = [2.0];
var vIncInt = ++vInt[0];
var vDecInt = --vInt[0];
var vIncDouble = ++vDouble[0];
var vDecInt = --vDouble[0];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vInt @4
          element: <testLibrary>::@topLevelVariable::vInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vDouble @20
          element: <testLibrary>::@topLevelVariable::vDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vIncInt @41
          element: <testLibrary>::@topLevelVariable::vIncInt
          getter: #F8
          setter: #F9
        #F10 hasInitializer vDecInt @66
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::0
          getter: #F11
          setter: #F12
        #F13 hasInitializer vIncDouble @91
          element: <testLibrary>::@topLevelVariable::vIncDouble
          getter: #F14
          setter: #F15
        #F16 hasInitializer vDecInt @122
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::1
          getter: #F17
          setter: #F18
      getters
        #F2 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
          variable: #F1
        #F5 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: List<double>
          variable: #F4
        #F8 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
          variable: #F7
        #F11 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::0
          returnType: int
          variable: #F10
        #F14 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
          variable: #F13
        #F17 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::1
          returnType: double
          variable: #F16
      setters
        #F3 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F19 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F6 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F20 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F9 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F21 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F12 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt::@def::0
          formalParameters
            #F22 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@def::0::@formalParameter::_vDecInt
        #F15 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F23 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F18 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt::@def::1
          formalParameters
            #F24 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@def::1::@formalParameter::_vDecInt
  topLevelVariables
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::0
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt::@def::0
      setter: <testLibrary>::@setter::vDecInt::@def::0
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecInt::@def::1
      setter: <testLibrary>::@setter::vDecInt::@def::1
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::0
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::1
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vInt
          firstFragment: #F19
          type: List<int>
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vDouble
          firstFragment: #F20
          type: List<double>
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        requiredPositional _vIncInt
          firstFragment: #F21
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::0
      firstFragment: #F12
      formalParameters
        requiredPositional _vDecInt
          firstFragment: #F22
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        requiredPositional _vIncDouble
          firstFragment: #F23
          type: double
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::1
      firstFragment: #F18
      formalParameters
        requiredPositional _vDecInt
          firstFragment: #F24
          type: double
      returnType: void
''');
  }

  test_initializer_prefix_not() async {
    var library = await _encodeDecodeLibrary(r'''
var vNot = !true;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vNot @4
          element: <testLibrary>::@topLevelVariable::vNot
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic vNot
          element: <testLibrary>::@getter::vNot
          returnType: bool
          variable: #F1
      setters
        #F3 synthetic vNot
          element: <testLibrary>::@setter::vNot
          formalParameters
            #F4 _vNot
              element: <testLibrary>::@setter::vNot::@formalParameter::_vNot
  topLevelVariables
    hasInitializer vNot
      reference: <testLibrary>::@topLevelVariable::vNot
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vNot
      setter: <testLibrary>::@setter::vNot
  getters
    synthetic static vNot
      reference: <testLibrary>::@getter::vNot
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNot
  setters
    synthetic static vNot
      reference: <testLibrary>::@setter::vNot
      firstFragment: #F3
      formalParameters
        requiredPositional _vNot
          firstFragment: #F4
          type: bool
      returnType: void
''');
  }

  test_initializer_prefix_other() async {
    var library = await _encodeDecodeLibrary(r'''
var vNegateInt = -1;
var vNegateDouble = -1.0;
var vComplement = ~1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vNegateInt @4
          element: <testLibrary>::@topLevelVariable::vNegateInt
          getter: #F2
          setter: #F3
        #F4 hasInitializer vNegateDouble @25
          element: <testLibrary>::@topLevelVariable::vNegateDouble
          getter: #F5
          setter: #F6
        #F7 hasInitializer vComplement @51
          element: <testLibrary>::@topLevelVariable::vComplement
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic vNegateInt
          element: <testLibrary>::@getter::vNegateInt
          returnType: int
          variable: #F1
        #F5 synthetic vNegateDouble
          element: <testLibrary>::@getter::vNegateDouble
          returnType: double
          variable: #F4
        #F8 synthetic vComplement
          element: <testLibrary>::@getter::vComplement
          returnType: int
          variable: #F7
      setters
        #F3 synthetic vNegateInt
          element: <testLibrary>::@setter::vNegateInt
          formalParameters
            #F10 _vNegateInt
              element: <testLibrary>::@setter::vNegateInt::@formalParameter::_vNegateInt
        #F6 synthetic vNegateDouble
          element: <testLibrary>::@setter::vNegateDouble
          formalParameters
            #F11 _vNegateDouble
              element: <testLibrary>::@setter::vNegateDouble::@formalParameter::_vNegateDouble
        #F9 synthetic vComplement
          element: <testLibrary>::@setter::vComplement
          formalParameters
            #F12 _vComplement
              element: <testLibrary>::@setter::vComplement::@formalParameter::_vComplement
  topLevelVariables
    hasInitializer vNegateInt
      reference: <testLibrary>::@topLevelVariable::vNegateInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vNegateInt
      setter: <testLibrary>::@setter::vNegateInt
    hasInitializer vNegateDouble
      reference: <testLibrary>::@topLevelVariable::vNegateDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vNegateDouble
      setter: <testLibrary>::@setter::vNegateDouble
    hasInitializer vComplement
      reference: <testLibrary>::@topLevelVariable::vComplement
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vComplement
      setter: <testLibrary>::@setter::vComplement
  getters
    synthetic static vNegateInt
      reference: <testLibrary>::@getter::vNegateInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vNegateInt
    synthetic static vNegateDouble
      reference: <testLibrary>::@getter::vNegateDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vNegateDouble
    synthetic static vComplement
      reference: <testLibrary>::@getter::vComplement
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vComplement
  setters
    synthetic static vNegateInt
      reference: <testLibrary>::@setter::vNegateInt
      firstFragment: #F3
      formalParameters
        requiredPositional _vNegateInt
          firstFragment: #F10
          type: int
      returnType: void
    synthetic static vNegateDouble
      reference: <testLibrary>::@setter::vNegateDouble
      firstFragment: #F6
      formalParameters
        requiredPositional _vNegateDouble
          firstFragment: #F11
          type: double
      returnType: void
    synthetic static vComplement
      reference: <testLibrary>::@setter::vComplement
      firstFragment: #F9
      formalParameters
        requiredPositional _vComplement
          firstFragment: #F12
          type: int
      returnType: void
''');
  }

  test_initializer_referenceToFieldOfStaticField() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  static D d;
}
class D {
  int i;
}
final x = C.d.i;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 d @21
              element: <testLibrary>::@class::C::@field::d
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 synthetic d
              element: <testLibrary>::@class::C::@getter::d
              returnType: D
              variable: #F2
          setters
            #F4 synthetic d
              element: <testLibrary>::@class::C::@setter::d
              formalParameters
                #F6 _d
                  element: <testLibrary>::@class::C::@setter::d::@formalParameter::_d
        #F7 class D @32
          element: <testLibrary>::@class::D
          fields
            #F8 i @42
              element: <testLibrary>::@class::D::@field::i
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F9 synthetic i
              element: <testLibrary>::@class::D::@getter::i
              returnType: int
              variable: #F8
          setters
            #F10 synthetic i
              element: <testLibrary>::@class::D::@setter::i
              formalParameters
                #F12 _i
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::_i
      topLevelVariables
        #F13 hasInitializer x @53
          element: <testLibrary>::@topLevelVariable::x
          getter: #F14
      getters
        #F14 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F13
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static d
          reference: <testLibrary>::@class::C::@field::d
          firstFragment: #F2
          type: D
          getter: <testLibrary>::@class::C::@getter::d
          setter: <testLibrary>::@class::C::@setter::d
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        synthetic static d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F3
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
      setters
        synthetic static d
          reference: <testLibrary>::@class::C::@setter::d
          firstFragment: #F4
          formalParameters
            requiredPositional _d
              firstFragment: #F6
              type: D
          returnType: void
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      fields
        i
          reference: <testLibrary>::@class::D::@field::i
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::D::@getter::i
          setter: <testLibrary>::@class::D::@setter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F11
      getters
        synthetic i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        synthetic i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F10
          formalParameters
            requiredPositional _i
              firstFragment: #F12
              type: int
          returnType: void
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_initializer_referenceToFieldOfStaticGetter() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  static D get d => null;
}
class D {
  int i;
}
var x = C.d.i;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic d
              element: <testLibrary>::@class::C::@field::d
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 d @25
              element: <testLibrary>::@class::C::@getter::d
              returnType: D
              variable: #F2
        #F5 class D @44
          element: <testLibrary>::@class::D
          fields
            #F6 i @54
              element: <testLibrary>::@class::D::@field::i
              getter2: #F7
              setter2: #F8
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F7 synthetic i
              element: <testLibrary>::@class::D::@getter::i
              returnType: int
              variable: #F6
          setters
            #F8 synthetic i
              element: <testLibrary>::@class::D::@setter::i
              formalParameters
                #F10 _i
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::_i
      topLevelVariables
        #F11 hasInitializer x @63
          element: <testLibrary>::@topLevelVariable::x
          getter: #F12
          setter: #F13
      getters
        #F12 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F11
      setters
        #F13 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F14 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic static d
          reference: <testLibrary>::@class::C::@field::d
          firstFragment: #F2
          type: D
          getter: <testLibrary>::@class::C::@getter::d
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        static d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F3
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      fields
        i
          reference: <testLibrary>::@class::D::@field::i
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::D::@getter::i
          setter: <testLibrary>::@class::D::@setter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
      getters
        synthetic i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        synthetic i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F8
          formalParameters
            requiredPositional _i
              firstFragment: #F10
              type: int
          returnType: void
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F13
      formalParameters
        requiredPositional _x
          firstFragment: #F14
          type: int
      returnType: void
''');
  }

  test_initializer_relational() async {
    var library = await _encodeDecodeLibrary(r'''
var vLess = 1 < 2;
var vLessOrEqual = 1 <= 2;
var vGreater = 1 > 2;
var vGreaterOrEqual = 1 >= 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer vLess @4
          element: <testLibrary>::@topLevelVariable::vLess
          getter: #F2
          setter: #F3
        #F4 hasInitializer vLessOrEqual @23
          element: <testLibrary>::@topLevelVariable::vLessOrEqual
          getter: #F5
          setter: #F6
        #F7 hasInitializer vGreater @50
          element: <testLibrary>::@topLevelVariable::vGreater
          getter: #F8
          setter: #F9
        #F10 hasInitializer vGreaterOrEqual @72
          element: <testLibrary>::@topLevelVariable::vGreaterOrEqual
          getter: #F11
          setter: #F12
      getters
        #F2 synthetic vLess
          element: <testLibrary>::@getter::vLess
          returnType: bool
          variable: #F1
        #F5 synthetic vLessOrEqual
          element: <testLibrary>::@getter::vLessOrEqual
          returnType: bool
          variable: #F4
        #F8 synthetic vGreater
          element: <testLibrary>::@getter::vGreater
          returnType: bool
          variable: #F7
        #F11 synthetic vGreaterOrEqual
          element: <testLibrary>::@getter::vGreaterOrEqual
          returnType: bool
          variable: #F10
      setters
        #F3 synthetic vLess
          element: <testLibrary>::@setter::vLess
          formalParameters
            #F13 _vLess
              element: <testLibrary>::@setter::vLess::@formalParameter::_vLess
        #F6 synthetic vLessOrEqual
          element: <testLibrary>::@setter::vLessOrEqual
          formalParameters
            #F14 _vLessOrEqual
              element: <testLibrary>::@setter::vLessOrEqual::@formalParameter::_vLessOrEqual
        #F9 synthetic vGreater
          element: <testLibrary>::@setter::vGreater
          formalParameters
            #F15 _vGreater
              element: <testLibrary>::@setter::vGreater::@formalParameter::_vGreater
        #F12 synthetic vGreaterOrEqual
          element: <testLibrary>::@setter::vGreaterOrEqual
          formalParameters
            #F16 _vGreaterOrEqual
              element: <testLibrary>::@setter::vGreaterOrEqual::@formalParameter::_vGreaterOrEqual
  topLevelVariables
    hasInitializer vLess
      reference: <testLibrary>::@topLevelVariable::vLess
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vLess
      setter: <testLibrary>::@setter::vLess
    hasInitializer vLessOrEqual
      reference: <testLibrary>::@topLevelVariable::vLessOrEqual
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vLessOrEqual
      setter: <testLibrary>::@setter::vLessOrEqual
    hasInitializer vGreater
      reference: <testLibrary>::@topLevelVariable::vGreater
      firstFragment: #F7
      type: bool
      getter: <testLibrary>::@getter::vGreater
      setter: <testLibrary>::@setter::vGreater
    hasInitializer vGreaterOrEqual
      reference: <testLibrary>::@topLevelVariable::vGreaterOrEqual
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::vGreaterOrEqual
      setter: <testLibrary>::@setter::vGreaterOrEqual
  getters
    synthetic static vLess
      reference: <testLibrary>::@getter::vLess
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLess
    synthetic static vLessOrEqual
      reference: <testLibrary>::@getter::vLessOrEqual
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLessOrEqual
    synthetic static vGreater
      reference: <testLibrary>::@getter::vGreater
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreater
    synthetic static vGreaterOrEqual
      reference: <testLibrary>::@getter::vGreaterOrEqual
      firstFragment: #F11
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreaterOrEqual
  setters
    synthetic static vLess
      reference: <testLibrary>::@setter::vLess
      firstFragment: #F3
      formalParameters
        requiredPositional _vLess
          firstFragment: #F13
          type: bool
      returnType: void
    synthetic static vLessOrEqual
      reference: <testLibrary>::@setter::vLessOrEqual
      firstFragment: #F6
      formalParameters
        requiredPositional _vLessOrEqual
          firstFragment: #F14
          type: bool
      returnType: void
    synthetic static vGreater
      reference: <testLibrary>::@setter::vGreater
      firstFragment: #F9
      formalParameters
        requiredPositional _vGreater
          firstFragment: #F15
          type: bool
      returnType: void
    synthetic static vGreaterOrEqual
      reference: <testLibrary>::@setter::vGreaterOrEqual
      firstFragment: #F12
      formalParameters
        requiredPositional _vGreaterOrEqual
          firstFragment: #F16
          type: bool
      returnType: void
''');
  }

  @skippedTest
  test_initializer_throw() async {
    var library = await _encodeDecodeLibrary(r'''
var V = throw 42;
''');
    checkElementText(library, r'''
Null V;
''');
  }

  test_instanceField_error_noSetterParameter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int x;
}
class B implements A {
  set x() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 x @25
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
          setters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @36
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F9
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 x @59
              element: <testLibrary>::@class::B::@setter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional _x
              firstFragment: #F6
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: dynamic
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
      setters
        x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          returnType: void
''');
  }

  test_instanceField_fieldFormal() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  var f = 0;
  A([this.f = 'hello']);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer f @16
              element: <testLibrary>::@class::A::@field::f
              getter2: #F3
              setter2: #F4
          constructors
            #F5 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 25
              formalParameters
                #F6 default this.f @33
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
                  initializer: expression_0
                    SimpleStringLiteral
                      literal: 'hello' @37
          getters
            #F3 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
              variable: #F2
          setters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F7 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
          formalParameters
            optionalPositional final hasImplicitType f
              firstFragment: #F6
              type: int
              constantInitializer
                fragment: #F6
                expression: expression_0
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            requiredPositional _f
              firstFragment: #F7
              type: int
          returnType: void
''');
  }

  test_instanceField_fromField() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int x;
  int y;
  int z;
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 x @25
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
            #F5 y @34
              element: <testLibrary>::@class::A::@field::y
              getter2: #F6
              setter2: #F7
            #F8 z @43
              element: <testLibrary>::@class::A::@field::z
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
            #F6 synthetic y
              element: <testLibrary>::@class::A::@getter::y
              returnType: int
              variable: #F5
            #F9 synthetic z
              element: <testLibrary>::@class::A::@getter::z
              returnType: int
              variable: #F8
          setters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F12 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
            #F7 synthetic y
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F13 _y
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_y
            #F10 synthetic z
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F14 _z
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_z
        #F15 class B @54
          element: <testLibrary>::@class::B
          fields
            #F16 x @77
              element: <testLibrary>::@class::B::@field::x
              getter2: #F17
              setter2: #F18
            #F19 synthetic y
              element: <testLibrary>::@class::B::@field::y
              getter2: #F20
            #F21 synthetic z
              element: <testLibrary>::@class::B::@field::z
              setter2: #F22
          constructors
            #F23 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F17 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
              variable: #F16
            #F20 y @86
              element: <testLibrary>::@class::B::@getter::y
              returnType: int
              variable: #F19
          setters
            #F18 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F24 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F22 z @103
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F25 _ @105
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
        y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F11
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        synthetic y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        synthetic z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional _x
              firstFragment: #F12
              type: int
          returnType: void
        synthetic y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F7
          formalParameters
            requiredPositional _y
              firstFragment: #F13
              type: int
          returnType: void
        synthetic z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F10
          formalParameters
            requiredPositional _z
              firstFragment: #F14
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F15
      interfaces
        A
      fields
        x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F16
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F21
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F23
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F20
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F18
          formalParameters
            requiredPositional _x
              firstFragment: #F24
              type: int
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F22
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F25
              type: int
          returnType: void
''');
  }

  test_instanceField_fromField_explicitDynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  dynamic x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 x @29
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic
              variable: #F2
          setters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @40
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer x @63
              element: <testLibrary>::@class::B::@field::x
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic
              variable: #F8
          setters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional _x
              firstFragment: #F6
              type: dynamic
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        hasInitializer x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            requiredPositional _x
              firstFragment: #F12
              type: dynamic
          returnType: void
''');
  }

  test_instanceField_fromField_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<E> {
  E x;
  E y;
  E z;
}
class B<T> implements A<T> {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          typeParameters
            #F2 E @17
              element: #E0 E
          fields
            #F3 x @26
              element: <testLibrary>::@class::A::@field::x
              getter2: #F4
              setter2: #F5
            #F6 y @33
              element: <testLibrary>::@class::A::@field::y
              getter2: #F7
              setter2: #F8
            #F9 z @40
              element: <testLibrary>::@class::A::@field::z
              getter2: #F10
              setter2: #F11
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: E
              variable: #F3
            #F7 synthetic y
              element: <testLibrary>::@class::A::@getter::y
              returnType: E
              variable: #F6
            #F10 synthetic z
              element: <testLibrary>::@class::A::@getter::z
              returnType: E
              variable: #F9
          setters
            #F5 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F13 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
            #F8 synthetic y
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F14 _y
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_y
            #F11 synthetic z
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F15 _z
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_z
        #F16 class B @51
          element: <testLibrary>::@class::B
          typeParameters
            #F17 T @53
              element: #E1 T
          fields
            #F18 x @80
              element: <testLibrary>::@class::B::@field::x
              getter2: #F19
              setter2: #F20
            #F21 synthetic y
              element: <testLibrary>::@class::B::@field::y
              getter2: #F22
            #F23 synthetic z
              element: <testLibrary>::@class::B::@field::z
              setter2: #F24
          constructors
            #F25 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F19 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: T
              variable: #F18
            #F22 y @89
              element: <testLibrary>::@class::B::@getter::y
              returnType: T
              variable: #F21
          setters
            #F20 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F26 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F24 z @106
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F27 _ @108
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      fields
        x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
        y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F12
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        synthetic y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        synthetic z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _x
              firstFragment: #F13
              type: E
          returnType: void
        synthetic y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _y
              firstFragment: #F14
              type: E
          returnType: void
        synthetic z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _z
              firstFragment: #F15
              type: E
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F16
      typeParameters
        #E1 T
          firstFragment: #F17
      interfaces
        A<T>
      fields
        x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F18
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F21
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F23
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F25
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F19
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F22
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F20
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _x
              firstFragment: #F26
              type: T
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F24
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F27
              type: T
          returnType: void
''');
  }

  test_instanceField_fromField_implicitDynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  var x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 x @25
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic
              variable: #F2
          setters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @36
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer x @59
              element: <testLibrary>::@class::B::@field::x
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic
              variable: #F8
          setters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional _x
              firstFragment: #F6
              type: dynamic
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        hasInitializer x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            requiredPositional _x
              firstFragment: #F12
              type: dynamic
          returnType: void
''');
  }

  test_instanceField_fromField_narrowType() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 x @25
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: num
              variable: #F2
          setters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @36
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer x @59
              element: <testLibrary>::@class::B::@field::x
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: num
              variable: #F8
          setters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional _x
              firstFragment: #F6
              type: num
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        hasInitializer x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: num
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: num
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            requiredPositional _x
              firstFragment: #F12
              type: num
          returnType: void
''');
  }

  test_instanceField_fromGetter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
  int get y;
  int get z;
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
            #F4 synthetic y
              element: <testLibrary>::@class::A::@field::y
              getter2: #F5
            #F6 synthetic z
              element: <testLibrary>::@class::A::@field::z
              getter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
            #F5 y @42
              element: <testLibrary>::@class::A::@getter::y
              returnType: int
              variable: #F4
            #F7 z @55
              element: <testLibrary>::@class::A::@getter::z
              returnType: int
              variable: #F6
        #F9 class B @66
          element: <testLibrary>::@class::B
          fields
            #F10 x @89
              element: <testLibrary>::@class::B::@field::x
              getter2: #F11
              setter2: #F12
            #F13 synthetic y
              element: <testLibrary>::@class::B::@field::y
              getter2: #F14
            #F15 synthetic z
              element: <testLibrary>::@class::B::@field::z
              setter2: #F16
          constructors
            #F17 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F11 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
              variable: #F10
            #F14 y @98
              element: <testLibrary>::@class::B::@getter::y
              returnType: int
              variable: #F13
          setters
            #F12 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F18 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F16 z @115
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F19 _ @117
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
        synthetic y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::y
        synthetic z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F8
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        abstract y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        abstract z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F9
      interfaces
        A
      fields
        x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F15
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F17
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F12
          formalParameters
            requiredPositional _x
              firstFragment: #F18
              type: int
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F16
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F19
              type: int
          returnType: void
''');
  }

  test_instanceField_fromGetter_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<E> {
  E get x;
  E get y;
  E get z;
}
class B<T> implements A<T> {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          typeParameters
            #F2 E @17
              element: #E0 E
          fields
            #F3 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F4
            #F5 synthetic y
              element: <testLibrary>::@class::A::@field::y
              getter2: #F6
            #F7 synthetic z
              element: <testLibrary>::@class::A::@field::z
              getter2: #F8
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @30
              element: <testLibrary>::@class::A::@getter::x
              returnType: E
              variable: #F3
            #F6 y @41
              element: <testLibrary>::@class::A::@getter::y
              returnType: E
              variable: #F5
            #F8 z @52
              element: <testLibrary>::@class::A::@getter::z
              returnType: E
              variable: #F7
        #F10 class B @63
          element: <testLibrary>::@class::B
          typeParameters
            #F11 T @65
              element: #E1 T
          fields
            #F12 x @92
              element: <testLibrary>::@class::B::@field::x
              getter2: #F13
              setter2: #F14
            #F15 synthetic y
              element: <testLibrary>::@class::B::@field::y
              getter2: #F16
            #F17 synthetic z
              element: <testLibrary>::@class::B::@field::z
              setter2: #F18
          constructors
            #F19 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F13 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: T
              variable: #F12
            #F16 y @101
              element: <testLibrary>::@class::B::@getter::y
              returnType: T
              variable: #F15
          setters
            #F14 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F20 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F18 z @118
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F21 _ @120
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::x
        synthetic y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::y
        synthetic z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F9
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        abstract y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        abstract z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      interfaces
        A<T>
      fields
        x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F15
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F17
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F19
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F16
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F14
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _x
              firstFragment: #F20
              type: T
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F18
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F21
              type: T
          returnType: void
''');
  }

  test_instanceField_fromGetter_multiple_different() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  String get x;
}
class C implements A, B {
  get x => null;
}
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              getter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F7 x @66
              element: <testLibrary>::@class::B::@getter::x
              returnType: String
              variable: #F6
        #F9 class C @77
          element: <testLibrary>::@class::C
          fields
            #F10 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F11
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F11 x @103
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
              variable: #F10
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: String
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F7
          returnType: String
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F10
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F11
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromGetter_multiple_different_dynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  dynamic get x;
}
class C implements A, B {
  get x => null;
}
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              getter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F7 x @67
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic
              variable: #F6
        #F9 class C @78
          element: <testLibrary>::@class::C
          fields
            #F10 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F11
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F11 x @104
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
              variable: #F10
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F7
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromGetter_multiple_different_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<T> {
  T get x;
}
abstract class B<T> {
  T get x;
}
class C implements A<int>, B<String> {
  get x => null;
}
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @17
              element: #E0 T
          fields
            #F3 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @30
              element: <testLibrary>::@class::A::@getter::x
              returnType: T
              variable: #F3
        #F6 class B @50
          element: <testLibrary>::@class::B
          typeParameters
            #F7 T @52
              element: #E1 T
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
              getter2: #F9
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 x @65
              element: <testLibrary>::@class::B::@getter::x
              returnType: T
              variable: #F8
        #F11 class C @76
          element: <testLibrary>::@class::C
          fields
            #F12 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F13
          constructors
            #F14 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 x @115
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
              variable: #F12
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      interfaces
        A<int>
        B<String>
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F12
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromGetter_multiple_same() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  int get x;
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              getter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F7 x @63
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
              variable: #F6
        #F9 class C @74
          element: <testLibrary>::@class::C
          fields
            #F10 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F11
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F11 x @100
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
              variable: #F10
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromGetterSetter_different_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
  int get y;
}
abstract class B {
  void set x(String _);
  void set y(String _);
}
class C implements A, B {
  var x;
  final y;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
            #F4 synthetic y
              element: <testLibrary>::@class::A::@field::y
              getter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
            #F5 y @42
              element: <testLibrary>::@class::A::@getter::y
              returnType: int
              variable: #F4
        #F7 class B @62
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F9
            #F10 synthetic y
              element: <testLibrary>::@class::B::@field::y
              setter2: #F11
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 x @77
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F13 _ @86
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
            #F11 y @101
              element: <testLibrary>::@class::B::@setter::y
              formalParameters
                #F14 _ @110
                  element: <testLibrary>::@class::B::@setter::y::@formalParameter::_
        #F15 class C @122
          element: <testLibrary>::@class::C
          fields
            #F16 x @148
              element: <testLibrary>::@class::C::@field::x
              getter2: #F17
              setter2: #F18
            #F19 y @159
              element: <testLibrary>::@class::C::@field::y
              getter2: #F20
          constructors
            #F21 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F17 synthetic x
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
              variable: #F16
            #F20 synthetic y
              element: <testLibrary>::@class::C::@getter::y
              returnType: int
              variable: #F19
          setters
            #F18 synthetic x
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F22 _x
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
        synthetic y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        abstract y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: String
          setter: <testLibrary>::@class::B::@setter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F10
          type: String
          setter: <testLibrary>::@class::B::@setter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F12
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            requiredPositional _
              firstFragment: #F13
              type: String
          returnType: void
        abstract y
          reference: <testLibrary>::@class::B::@setter::y
          firstFragment: #F11
          formalParameters
            requiredPositional _
              firstFragment: #F14
              type: String
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F15
      interfaces
        A
        B
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F16
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
        final y
          reference: <testLibrary>::@class::C::@field::y
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@class::C::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F21
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F17
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
        synthetic y
          reference: <testLibrary>::@class::C::@getter::y
          firstFragment: #F20
          returnType: int
          variable: <testLibrary>::@class::C::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F18
          formalParameters
            requiredPositional _x
              firstFragment: #F22
              type: dynamic
          returnType: void
''');
  }

  test_instanceField_fromGetterSetter_different_getter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F7 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @73
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @85
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 x @111
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
              variable: #F11
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: String
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F7
          formalParameters
            requiredPositional _
              firstFragment: #F9
              type: String
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromGetterSetter_different_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  set x(_);
}
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F7 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @73
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @85
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
              setter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F12 x @111
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F14 _ @113
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: String
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F7
          formalParameters
            requiredPositional _
              firstFragment: #F9
              type: String
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: String
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      setters
        abstract x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F12
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F14
              type: String
          returnType: void
''');
  }

  test_instanceField_fromGetterSetter_same_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  var x;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F7 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @70
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @82
          element: <testLibrary>::@class::C
          fields
            #F11 x @108
              element: <testLibrary>::@class::C::@field::x
              getter2: #F12
              setter2: #F13
          constructors
            #F14 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 synthetic x
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
              variable: #F11
          setters
            #F13 synthetic x
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F15 _x
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F7
          formalParameters
            requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F13
          formalParameters
            requiredPositional _x
              firstFragment: #F15
              type: int
          returnType: void
''');
  }

  test_instanceField_fromGetterSetter_same_getter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F7 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @70
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @82
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 x @108
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
              variable: #F11
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F7
          formalParameters
            requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromGetterSetter_same_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  set x(_);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
              variable: #F2
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F7 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @70
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @82
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
              setter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F12 x @108
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F14 _ @110
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F7
          formalParameters
            requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      setters
        abstract x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F12
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F14
              type: int
          returnType: void
''');
  }

  test_instanceField_fromSetter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
  void set y(int _);
  void set z(int _);
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              setter2: #F3
            #F4 synthetic y
              element: <testLibrary>::@class::A::@field::y
              setter2: #F5
            #F6 synthetic z
              element: <testLibrary>::@class::A::@field::z
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F3 x @30
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F9 _ @36
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
            #F5 y @51
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F10 _ @57
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_
            #F7 z @72
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F11 _ @78
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_
        #F12 class B @90
          element: <testLibrary>::@class::B
          fields
            #F13 x @113
              element: <testLibrary>::@class::B::@field::x
              getter2: #F14
              setter2: #F15
            #F16 synthetic y
              element: <testLibrary>::@class::B::@field::y
              getter2: #F17
            #F18 synthetic z
              element: <testLibrary>::@class::B::@field::z
              setter2: #F19
          constructors
            #F20 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F14 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
              variable: #F13
            #F17 y @122
              element: <testLibrary>::@class::B::@getter::y
              returnType: int
              variable: #F16
          setters
            #F15 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F21 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F19 z @139
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F22 _ @141
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::x
        synthetic y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@class::A::@setter::y
        synthetic z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F3
          formalParameters
            requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
        abstract y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F5
          formalParameters
            requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
        abstract z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F7
          formalParameters
            requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F12
      interfaces
        A
      fields
        x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F16
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F18
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F20
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F15
          formalParameters
            requiredPositional _x
              firstFragment: #F21
              type: int
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F19
          formalParameters
            requiredPositional hasImplicitType _
              firstFragment: #F22
              type: int
          returnType: void
''');
  }

  test_instanceField_fromSetter_multiple_different() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              setter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F3 x @30
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 _ @36
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 class B @57
          element: <testLibrary>::@class::B
          fields
            #F7 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F8
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @72
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 _ @81
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F11 class C @93
          element: <testLibrary>::@class::C
          fields
            #F12 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F13
          constructors
            #F14 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 x @119
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
              variable: #F12
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F3
          formalParameters
            requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F7
          type: String
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            requiredPositional _
              firstFragment: #F10
              type: String
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F12
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_fromSetter_multiple_same() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              setter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F3 x @30
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 _ @36
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 class B @57
          element: <testLibrary>::@class::B
          fields
            #F7 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F8
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @72
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 _ @78
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F11 class C @90
          element: <testLibrary>::@class::C
          fields
            #F12 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F13
          constructors
            #F14 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 x @116
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
              variable: #F12
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F3
          formalParameters
            requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      interfaces
        A
        B
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_instanceField_functionTypeAlias_doesNotUseItsTypeParameter() async {
    var library = await _encodeDecodeLibrary(r'''
typedef F<T>();

class A<T> {
  F<T> get x => null;
  List<F<T>> get y => null;
}

class B extends A<int> {
  get x => null;
  get y => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @23
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @25
              element: #E0 T
          fields
            #F3 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F4
            #F5 synthetic y
              element: <testLibrary>::@class::A::@field::y
              getter2: #F6
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @41
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic Function()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    T
              variable: #F3
            #F6 y @69
              element: <testLibrary>::@class::A::@getter::y
              returnType: List<dynamic Function()>
              variable: #F5
        #F8 class B @89
          element: <testLibrary>::@class::B
          fields
            #F9 synthetic x
              element: <testLibrary>::@class::B::@field::x
              getter2: #F10
            #F11 synthetic y
              element: <testLibrary>::@class::B::@field::y
              getter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 x @114
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic Function()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    int
              variable: #F9
            #F12 y @131
              element: <testLibrary>::@class::B::@getter::y
              returnType: List<dynamic Function()>
              variable: #F11
      typeAliases
        #F14 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F15 T @10
              element: #E1 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          getter: <testLibrary>::@class::A::@getter::x
        synthetic y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F7
      getters
        x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          variable: <testLibrary>::@class::A::@field::x
        y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: List<dynamic Function()>
          variable: <testLibrary>::@class::A::@field::y
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F8
      supertype: A<int>
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F9
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
          getter: <testLibrary>::@class::B::@getter::x
        synthetic y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F11
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::B::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F13
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F12
          returnType: List<dynamic Function()>
          variable: <testLibrary>::@class::B::@field::y
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F14
      typeParameters
        #E1 T
          firstFragment: #F15
      aliasedType: dynamic Function()
''');
  }

  test_instanceField_inheritsCovariant_fromSetter_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  int x;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: num
              variable: #F2
          setters
            #F4 x @43
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _ @59
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B @71
          element: <testLibrary>::@class::B
          fields
            #F8 x @94
              element: <testLibrary>::@class::B::@field::x
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
              variable: #F8
          setters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional covariant _
              firstFragment: #F6
              type: num
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            requiredPositional covariant _x
              firstFragment: #F12
              type: int
          returnType: void
''');
  }

  test_instanceField_inheritsCovariant_fromSetter_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  set x(int _) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic x
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: num
              variable: #F2
          setters
            #F4 x @43
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _ @59
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B @71
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
              setter2: #F9
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 x @94
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F11 _ @100
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            requiredPositional covariant _
              firstFragment: #F6
              type: num
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        synthetic x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
      setters
        x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            requiredPositional covariant _
              firstFragment: #F11
              type: int
          returnType: void
''');
  }

  test_instanceField_initializer() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  var t1 = 1;
  var t2 = 2.0;
  var t3 = null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer t1 @16
              element: <testLibrary>::@class::A::@field::t1
              getter2: #F3
              setter2: #F4
            #F5 hasInitializer t2 @30
              element: <testLibrary>::@class::A::@field::t2
              getter2: #F6
              setter2: #F7
            #F8 hasInitializer t3 @46
              element: <testLibrary>::@class::A::@field::t3
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic t1
              element: <testLibrary>::@class::A::@getter::t1
              returnType: int
              variable: #F2
            #F6 synthetic t2
              element: <testLibrary>::@class::A::@getter::t2
              returnType: double
              variable: #F5
            #F9 synthetic t3
              element: <testLibrary>::@class::A::@getter::t3
              returnType: dynamic
              variable: #F8
          setters
            #F4 synthetic t1
              element: <testLibrary>::@class::A::@setter::t1
              formalParameters
                #F12 _t1
                  element: <testLibrary>::@class::A::@setter::t1::@formalParameter::_t1
            #F7 synthetic t2
              element: <testLibrary>::@class::A::@setter::t2
              formalParameters
                #F13 _t2
                  element: <testLibrary>::@class::A::@setter::t2::@formalParameter::_t2
            #F10 synthetic t3
              element: <testLibrary>::@class::A::@setter::t3
              formalParameters
                #F14 _t3
                  element: <testLibrary>::@class::A::@setter::t3::@formalParameter::_t3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer t1
          reference: <testLibrary>::@class::A::@field::t1
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::t1
          setter: <testLibrary>::@class::A::@setter::t1
        hasInitializer t2
          reference: <testLibrary>::@class::A::@field::t2
          firstFragment: #F5
          type: double
          getter: <testLibrary>::@class::A::@getter::t2
          setter: <testLibrary>::@class::A::@setter::t2
        hasInitializer t3
          reference: <testLibrary>::@class::A::@field::t3
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::t3
          setter: <testLibrary>::@class::A::@setter::t3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F11
      getters
        synthetic t1
          reference: <testLibrary>::@class::A::@getter::t1
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::t1
        synthetic t2
          reference: <testLibrary>::@class::A::@getter::t2
          firstFragment: #F6
          returnType: double
          variable: <testLibrary>::@class::A::@field::t2
        synthetic t3
          reference: <testLibrary>::@class::A::@getter::t3
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::t3
      setters
        synthetic t1
          reference: <testLibrary>::@class::A::@setter::t1
          firstFragment: #F4
          formalParameters
            requiredPositional _t1
              firstFragment: #F12
              type: int
          returnType: void
        synthetic t2
          reference: <testLibrary>::@class::A::@setter::t2
          firstFragment: #F7
          formalParameters
            requiredPositional _t2
              firstFragment: #F13
              type: double
          returnType: void
        synthetic t3
          reference: <testLibrary>::@class::A::@setter::t3
          firstFragment: #F10
          formalParameters
            requiredPositional _t3
              firstFragment: #F14
              type: dynamic
          returnType: void
''');
  }

  test_method_error_hasMethod_noParameter_required() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  void m(a, b) {}
}
''');
    // It's an error to add a new required parameter, but it is not a
    // top-level type inference error.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @23
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @37
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @58
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @60
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 b @63
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
            requiredPositional hasImplicitType b
              firstFragment: #F9
              type: dynamic
          returnType: void
''');
  }

  test_method_error_noCombinedSuperSignature1() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B {
  void m(String a) {}
}
class C extends A implements B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @23
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @37
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @48
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @57
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C @71
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 m @100
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 a @102
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional a
              firstFragment: #F8
              type: String
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      supertype: A
      interfaces
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F11
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F12
              type: dynamic
          returnType: dynamic
''');
  }

  test_method_error_noCombinedSuperSignature2() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int foo(int x);
}

abstract class B {
  double foo(int x);
}

abstract class C implements A, B {
  Never foo(x);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo @25
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 x @33
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
        #F5 class B @55
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 foo @68
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F8 x @76
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::x
        #F9 class C @98
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 foo @126
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F12 x @130
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        abstract foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          formalParameters
            requiredPositional x
              firstFragment: #F4
              type: int
          returnType: int
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        abstract foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F7
          formalParameters
            requiredPositional x
              firstFragment: #F8
              type: int
          returnType: double
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      interfaces
        A
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
      methods
        abstract foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F11
          formalParameters
            requiredPositional hasImplicitType x
              firstFragment: #F12
              type: dynamic
          returnType: Never
''');
  }

  test_method_error_noCombinedSuperSignature3() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int m() {}
}
class B {
  String m() {}
}
class C extends A implements B {
  m() {}
}
''');
    // TODO(scheglov): test for inference failure error
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @16
              element: <testLibrary>::@class::A::@method::m
        #F4 class B @31
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 m @44
              element: <testLibrary>::@class::B::@method::m
        #F7 class C @59
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F9 m @88
              element: <testLibrary>::@class::C::@method::m
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          returnType: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F6
          returnType: String
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      supertype: A
      interfaces
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F9
          returnType: dynamic
''');
  }

  test_method_error_noCombinedSuperSignature_generic1() async {
    var library = await _encodeDecodeLibrary(r'''
class A<T> {
  void m(T a) {}
}
class B<E> {
  void m(E a) {}
}
class C extends A<int> implements B<double> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 m @20
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F5 a @24
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F6 class B @38
          element: <testLibrary>::@class::B
          typeParameters
            #F7 E @40
              element: #E1 E
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 m @52
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 a @56
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F11 class C @70
          element: <testLibrary>::@class::C
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F13 m @112
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F14 a @114
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F5
              type: T
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 E
          firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F10
              type: E
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      supertype: A<int>
      interfaces
        B<double>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F13
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F14
              type: dynamic
          returnType: dynamic
''');
  }

  test_method_error_noCombinedSuperSignature_generic2() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<double> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @8
              element: #E0 K
            #F3 V @11
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @20
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @24
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B @38
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T @40
              element: #E2 T
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 m @49
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 a @55
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F12 class C @69
          element: <testLibrary>::@class::C
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F14 m @119
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F15 a @121
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F11
              type: int
          returnType: T
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F12
      supertype: A<int, String>
      interfaces
        B<double>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F14
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F15
              type: dynamic
          returnType: dynamic
''');
  }

  test_method_missing_hasMethod_noParameter_named() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, {b}) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @23
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @37
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @53
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @55
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 default b @59
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
            optionalNamed hasImplicitType b
              firstFragment: #F9
              type: dynamic
          returnType: void
''');
  }

  test_method_missing_hasMethod_noParameter_optional() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @23
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @37
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @53
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @55
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 default b @59
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
            optionalPositional hasImplicitType b
              firstFragment: #F9
              type: dynamic
          returnType: void
''');
  }

  test_method_missing_hasMethod_withoutTypes() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @12
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @14
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @28
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @44
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @46
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F4
              type: dynamic
          returnType: dynamic
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: dynamic
          returnType: dynamic
''');
  }

  test_method_missing_noMember() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int foo(String a) => null;
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo @16
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 a @27
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        #F5 class B @47
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @63
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @65
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: String
          returnType: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: dynamic
          returnType: dynamic
''');
  }

  test_method_missing_notMethod() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int m = 42;
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer m @16
              element: <testLibrary>::@class::A::@field::m
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic m
              element: <testLibrary>::@class::A::@getter::m
              returnType: int
              variable: #F2
          setters
            #F4 synthetic m
              element: <testLibrary>::@class::A::@setter::m
              formalParameters
                #F6 _m
                  element: <testLibrary>::@class::A::@setter::m::@formalParameter::_m
        #F7 class B @32
          element: <testLibrary>::@class::B
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 m @48
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 a @50
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer m
          reference: <testLibrary>::@class::A::@field::m
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::m
          setter: <testLibrary>::@class::A::@setter::m
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic m
          reference: <testLibrary>::@class::A::@getter::m
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::m
      setters
        synthetic m
          reference: <testLibrary>::@class::A::@setter::m
          firstFragment: #F4
          formalParameters
            requiredPositional _m
              firstFragment: #F6
              type: int
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F9
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F10
              type: dynamic
          returnType: dynamic
''');
  }

  test_method_OK_sequence_extendsExtends_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {}
class C extends B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @8
              element: #E0 K
            #F3 V @11
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @20
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @24
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B @38
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T @40
              element: #E2 T
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 class C @70
          element: <testLibrary>::@class::C
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F12 m @94
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F13 a @96
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      supertype: A<int, T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      supertype: B<String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F12
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F13
              type: int
          returnType: String
''');
  }

  test_method_OK_sequence_inferMiddle_extendsExtends() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @39
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @55
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @57
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C @71
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 m @87
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 a @89
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
          returnType: String
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      supertype: B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F11
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F12
              type: int
          returnType: String
''');
  }

  test_method_OK_sequence_inferMiddle_extendsImplements() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B implements A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @39
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @58
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @60
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C @74
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 m @90
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 a @92
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      interfaces
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
          returnType: String
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      supertype: B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F11
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F12
              type: int
          returnType: String
''');
  }

  test_method_OK_sequence_inferMiddle_extendsWith() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @39
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @67
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @69
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C @83
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 m @99
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 a @101
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: Object
      mixins
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
          returnType: String
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      supertype: B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F11
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F12
              type: int
          returnType: String
''');
  }

  test_method_OK_single_extends_direct_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a, double b) {}
}
class B extends A<int, String> {
  m(a, b) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @8
              element: #E0 K
            #F3 V @11
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @20
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @24
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F7 b @34
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F8 class B @48
          element: <testLibrary>::@class::B
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 m @77
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 a @79
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F12 b @82
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
            requiredPositional b
              firstFragment: #F7
              type: double
          returnType: V
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F8
      supertype: A<int, String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F10
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F11
              type: int
            requiredPositional hasImplicitType b
              firstFragment: #F12
              type: double
          returnType: String
''');
  }

  test_method_OK_single_extends_direct_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @39
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @55
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @57
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
          returnType: String
''');
  }

  test_method_OK_single_extends_direct_notGeneric_named() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a, {double b}) {}
}
class B extends A {
  m(a, {b}) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F5 default b @36
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F6 class B @51
          element: <testLibrary>::@class::B
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 m @67
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F9 a @69
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F10 default b @73
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
            optionalNamed b
              firstFragment: #F5
              type: double
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F8
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F9
              type: int
            optionalNamed hasImplicitType b
              firstFragment: #F10
              type: double
          returnType: String
''');
  }

  test_method_OK_single_extends_direct_notGeneric_positional() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a, [double b]) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F5 default b @36
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F6 class B @51
          element: <testLibrary>::@class::B
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 m @67
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F9 a @69
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F10 default b @73
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
            optionalPositional b
              firstFragment: #F5
              type: double
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F8
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F9
              type: int
            optionalPositional hasImplicitType b
              firstFragment: #F10
              type: double
          returnType: String
''');
  }

  test_method_OK_single_extends_indirect_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {}
class C extends B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @8
              element: #E0 K
            #F3 V @11
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @20
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @24
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B @38
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T @40
              element: #E2 T
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 class C @70
          element: <testLibrary>::@class::C
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F12 m @94
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F13 a @96
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      supertype: A<int, T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      supertype: B<String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F12
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F13
              type: int
          returnType: String
''');
  }

  test_method_OK_single_implements_direct_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<K, V> {
  V m(K a);
}
class B implements A<int, String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @17
              element: #E0 K
            #F3 V @20
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @29
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @33
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B @45
          element: <testLibrary>::@class::B
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 m @77
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 a @79
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        abstract m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A<int, String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F9
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F10
              type: int
          returnType: String
''');
  }

  test_method_OK_single_implements_direct_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  String m(int a);
}
class B implements A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @28
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @34
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @46
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @65
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @67
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        abstract m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      interfaces
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
          returnType: String
''');
  }

  test_method_OK_single_implements_indirect_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<K, V> {
  V m(K a);
}
abstract class B<T1, T2> extends A<T2, T1> {}
class C implements B<int, String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @15
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @17
              element: #E0 K
            #F3 V @20
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @29
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @33
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B @54
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T1 @56
              element: #E2 T1
            #F9 T2 @60
              element: #E3 T2
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F11 class C @91
          element: <testLibrary>::@class::C
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F13 m @123
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F14 a @125
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        abstract m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T1
          firstFragment: #F8
        #E3 T2
          firstFragment: #F9
      supertype: A<T2, T1>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      interfaces
        B<int, String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F13
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F14
              type: String
          returnType: int
''');
  }

  test_method_OK_single_private_linkThroughOtherLibraryOfCycle() async {
    newFile('$testPackageLibPath/other.dart', r'''
import 'test.dart';
class B extends A2 {}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'other.dart';
class A1 {
  int _foo() => 1;
}
class A2 extends A1 {
  _foo() => 2;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/other.dart
      classes
        #F1 class A1 @27
          element: <testLibrary>::@class::A1
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A1::@constructor::new
              typeName: A1
          methods
            #F3 _foo @38
              element: <testLibrary>::@class::A1::@method::_foo
        #F4 class A2 @59
          element: <testLibrary>::@class::A2
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A2::@constructor::new
              typeName: A2
          methods
            #F6 _foo @77
              element: <testLibrary>::@class::A2::@method::_foo
  classes
    class A1
      reference: <testLibrary>::@class::A1
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A1::@constructor::new
          firstFragment: #F2
      methods
        _foo
          reference: <testLibrary>::@class::A1::@method::_foo
          firstFragment: #F3
          returnType: int
    class A2
      reference: <testLibrary>::@class::A2
      firstFragment: #F4
      supertype: A1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A2::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::A1::@constructor::new
      methods
        _foo
          reference: <testLibrary>::@class::A2::@method::_foo
          firstFragment: #F6
          returnType: int
''');
  }

  test_method_OK_single_withExtends_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @39
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @67
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @69
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: Object
      mixins
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
          returnType: String
''');
  }

  test_method_OK_two_extendsImplements_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K @8
              element: #E0 K
            #F3 V @11
              element: #E1 V
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 m @20
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 a @24
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B @38
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T @40
              element: #E2 T
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 m @49
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 a @55
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F12 class C @69
          element: <testLibrary>::@class::C
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F14 m @119
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F15 a @121
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional a
              firstFragment: #F11
              type: int
          returnType: T
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F12
      supertype: A<int, String>
      interfaces
        B<String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F14
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F15
              type: int
          returnType: String
''');
  }

  test_method_OK_two_extendsImplements_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B {
  String m(int a) {}
}
class C extends A implements B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @19
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @25
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @39
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @52
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @58
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C @72
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 m @101
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 a @103
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            requiredPositional a
              firstFragment: #F4
              type: int
          returnType: String
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            requiredPositional a
              firstFragment: #F8
              type: int
          returnType: String
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      supertype: A
      interfaces
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F11
          formalParameters
            requiredPositional hasImplicitType a
              firstFragment: #F12
              type: int
          returnType: String
''');
  }

  Future<LibraryElementImpl> _encodeDecodeLibrary(String text) async {
    newFile(testFile.path, text);

    var analysisSession = contextFor(testFile).currentSession;
    var result = await analysisSession.getUnitElement(testFile.path);
    result as UnitElementResult;
    return result.fragment.element as LibraryElementImpl;
  }
}
