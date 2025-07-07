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
        #F2 hasInitializer vPlusIntDouble @29
          element: <testLibrary>::@topLevelVariable::vPlusIntDouble
        #F3 hasInitializer vPlusDoubleInt @59
          element: <testLibrary>::@topLevelVariable::vPlusDoubleInt
        #F4 hasInitializer vPlusDoubleDouble @89
          element: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
        #F5 hasInitializer vMinusIntInt @124
          element: <testLibrary>::@topLevelVariable::vMinusIntInt
        #F6 hasInitializer vMinusIntDouble @150
          element: <testLibrary>::@topLevelVariable::vMinusIntDouble
        #F7 hasInitializer vMinusDoubleInt @181
          element: <testLibrary>::@topLevelVariable::vMinusDoubleInt
        #F8 hasInitializer vMinusDoubleDouble @212
          element: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
      getters
        #F9 synthetic vPlusIntInt
          element: <testLibrary>::@getter::vPlusIntInt
          returnType: int
        #F10 synthetic vPlusIntDouble
          element: <testLibrary>::@getter::vPlusIntDouble
          returnType: double
        #F11 synthetic vPlusDoubleInt
          element: <testLibrary>::@getter::vPlusDoubleInt
          returnType: double
        #F12 synthetic vPlusDoubleDouble
          element: <testLibrary>::@getter::vPlusDoubleDouble
          returnType: double
        #F13 synthetic vMinusIntInt
          element: <testLibrary>::@getter::vMinusIntInt
          returnType: int
        #F14 synthetic vMinusIntDouble
          element: <testLibrary>::@getter::vMinusIntDouble
          returnType: double
        #F15 synthetic vMinusDoubleInt
          element: <testLibrary>::@getter::vMinusDoubleInt
          returnType: double
        #F16 synthetic vMinusDoubleDouble
          element: <testLibrary>::@getter::vMinusDoubleDouble
          returnType: double
      setters
        #F17 synthetic vPlusIntInt
          element: <testLibrary>::@setter::vPlusIntInt
          formalParameters
            #F18 _vPlusIntInt
              element: <testLibrary>::@setter::vPlusIntInt::@formalParameter::_vPlusIntInt
        #F19 synthetic vPlusIntDouble
          element: <testLibrary>::@setter::vPlusIntDouble
          formalParameters
            #F20 _vPlusIntDouble
              element: <testLibrary>::@setter::vPlusIntDouble::@formalParameter::_vPlusIntDouble
        #F21 synthetic vPlusDoubleInt
          element: <testLibrary>::@setter::vPlusDoubleInt
          formalParameters
            #F22 _vPlusDoubleInt
              element: <testLibrary>::@setter::vPlusDoubleInt::@formalParameter::_vPlusDoubleInt
        #F23 synthetic vPlusDoubleDouble
          element: <testLibrary>::@setter::vPlusDoubleDouble
          formalParameters
            #F24 _vPlusDoubleDouble
              element: <testLibrary>::@setter::vPlusDoubleDouble::@formalParameter::_vPlusDoubleDouble
        #F25 synthetic vMinusIntInt
          element: <testLibrary>::@setter::vMinusIntInt
          formalParameters
            #F26 _vMinusIntInt
              element: <testLibrary>::@setter::vMinusIntInt::@formalParameter::_vMinusIntInt
        #F27 synthetic vMinusIntDouble
          element: <testLibrary>::@setter::vMinusIntDouble
          formalParameters
            #F28 _vMinusIntDouble
              element: <testLibrary>::@setter::vMinusIntDouble::@formalParameter::_vMinusIntDouble
        #F29 synthetic vMinusDoubleInt
          element: <testLibrary>::@setter::vMinusDoubleInt
          formalParameters
            #F30 _vMinusDoubleInt
              element: <testLibrary>::@setter::vMinusDoubleInt::@formalParameter::_vMinusDoubleInt
        #F31 synthetic vMinusDoubleDouble
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
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vPlusIntDouble
      setter: <testLibrary>::@setter::vPlusIntDouble
    hasInitializer vPlusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleInt
      firstFragment: #F3
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleInt
      setter: <testLibrary>::@setter::vPlusDoubleInt
    hasInitializer vPlusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleDouble
      setter: <testLibrary>::@setter::vPlusDoubleDouble
    hasInitializer vMinusIntInt
      reference: <testLibrary>::@topLevelVariable::vMinusIntInt
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::vMinusIntInt
      setter: <testLibrary>::@setter::vMinusIntInt
    hasInitializer vMinusIntDouble
      reference: <testLibrary>::@topLevelVariable::vMinusIntDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vMinusIntDouble
      setter: <testLibrary>::@setter::vMinusIntDouble
    hasInitializer vMinusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleInt
      firstFragment: #F7
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleInt
      setter: <testLibrary>::@setter::vMinusDoubleInt
    hasInitializer vMinusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
      firstFragment: #F8
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleDouble
      setter: <testLibrary>::@setter::vMinusDoubleDouble
  getters
    synthetic static vPlusIntInt
      reference: <testLibrary>::@getter::vPlusIntInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vPlusIntInt
    synthetic static vPlusIntDouble
      reference: <testLibrary>::@getter::vPlusIntDouble
      firstFragment: #F10
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusIntDouble
    synthetic static vPlusDoubleInt
      reference: <testLibrary>::@getter::vPlusDoubleInt
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleInt
    synthetic static vPlusDoubleDouble
      reference: <testLibrary>::@getter::vPlusDoubleDouble
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
    synthetic static vMinusIntInt
      reference: <testLibrary>::@getter::vMinusIntInt
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMinusIntInt
    synthetic static vMinusIntDouble
      reference: <testLibrary>::@getter::vMinusIntDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusIntDouble
    synthetic static vMinusDoubleInt
      reference: <testLibrary>::@getter::vMinusDoubleInt
      firstFragment: #F15
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleInt
    synthetic static vMinusDoubleDouble
      reference: <testLibrary>::@getter::vMinusDoubleDouble
      firstFragment: #F16
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
  setters
    synthetic static vPlusIntInt
      reference: <testLibrary>::@setter::vPlusIntInt
      firstFragment: #F17
      formalParameters
        #E0 requiredPositional _vPlusIntInt
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vPlusIntDouble
      reference: <testLibrary>::@setter::vPlusIntDouble
      firstFragment: #F19
      formalParameters
        #E1 requiredPositional _vPlusIntDouble
          firstFragment: #F20
          type: double
      returnType: void
    synthetic static vPlusDoubleInt
      reference: <testLibrary>::@setter::vPlusDoubleInt
      firstFragment: #F21
      formalParameters
        #E2 requiredPositional _vPlusDoubleInt
          firstFragment: #F22
          type: double
      returnType: void
    synthetic static vPlusDoubleDouble
      reference: <testLibrary>::@setter::vPlusDoubleDouble
      firstFragment: #F23
      formalParameters
        #E3 requiredPositional _vPlusDoubleDouble
          firstFragment: #F24
          type: double
      returnType: void
    synthetic static vMinusIntInt
      reference: <testLibrary>::@setter::vMinusIntInt
      firstFragment: #F25
      formalParameters
        #E4 requiredPositional _vMinusIntInt
          firstFragment: #F26
          type: int
      returnType: void
    synthetic static vMinusIntDouble
      reference: <testLibrary>::@setter::vMinusIntDouble
      firstFragment: #F27
      formalParameters
        #E5 requiredPositional _vMinusIntDouble
          firstFragment: #F28
          type: double
      returnType: void
    synthetic static vMinusDoubleInt
      reference: <testLibrary>::@setter::vMinusDoubleInt
      firstFragment: #F29
      formalParameters
        #E6 requiredPositional _vMinusDoubleInt
          firstFragment: #F30
          type: double
      returnType: void
    synthetic static vMinusDoubleDouble
      reference: <testLibrary>::@setter::vMinusDoubleDouble
      firstFragment: #F31
      formalParameters
        #E7 requiredPositional _vMinusDoubleDouble
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
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: num
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
        #E0 requiredPositional _V
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
        #F2 hasInitializer t1 @15
          element: <testLibrary>::@topLevelVariable::t1
        #F3 hasInitializer t2 @33
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F4 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
        #F5 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
        #F6 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
      setters
        #F7 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F9 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F10 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F11 synthetic t2
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
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F8
          type: int
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _t1
          firstFragment: #F10
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _t2
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
        #F2 hasInitializer t1 @17
          element: <testLibrary>::@topLevelVariable::t1
        #F3 hasInitializer t2 @38
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F4 synthetic a
          element: <testLibrary>::@getter::a
          returnType: List<int>
        #F5 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
        #F6 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
      setters
        #F7 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F9 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F10 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F11 synthetic t2
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
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F8
          type: List<int>
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _t1
          firstFragment: #F10
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _t2
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
      topLevelVariables
        #F7 hasInitializer a @25
          element: <testLibrary>::@topLevelVariable::a
        #F8 hasInitializer t1 @42
          element: <testLibrary>::@topLevelVariable::t1
        #F9 hasInitializer t2 @62
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F10 synthetic a
          element: <testLibrary>::@getter::a
          returnType: A
        #F11 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
        #F12 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
      setters
        #F13 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F14 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F15 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F16 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F17 synthetic t2
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
      firstFragment: #F8
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F9
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F10
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _a
          firstFragment: #F14
          type: A
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional _t1
          firstFragment: #F16
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional _t2
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::I::@getter::f
              returnType: int
          setters
            #F5 synthetic f
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
        #F10 hasInitializer t1 @63
          element: <testLibrary>::@topLevelVariable::t1
        #F11 hasInitializer t2 @83
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F12 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
        #F13 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
        #F14 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
      setters
        #F15 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F16 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F17 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F18 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F19 synthetic t2
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional _c
          firstFragment: #F16
          type: C
      returnType: void
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional _t1
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional _t2
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::I::@getter::f
              returnType: int
          setters
            #F5 synthetic f
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
        #F10 hasInitializer t2 @101
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F11 synthetic t1
          element: <testLibrary>::@getter::t1
          returnType: int
        #F12 synthetic t2
          element: <testLibrary>::@getter::t2
          returnType: int
      setters
        #F13 synthetic t1
          element: <testLibrary>::@setter::t1
          formalParameters
            #F14 _t1
              element: <testLibrary>::@setter::t1::@formalParameter::_t1
        #F15 synthetic t2
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    synthetic static t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    synthetic static t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    synthetic static t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _t1
          firstFragment: #F14
          type: int
      returnType: void
    synthetic static t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional _t2
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
        #F2 hasInitializer uFuture @121
          element: <testLibrary>::@topLevelVariable::uFuture
      getters
        #F3 synthetic uValue
          element: <testLibrary>::@getter::uValue
          returnType: Future<int> Function()
        #F4 synthetic uFuture
          element: <testLibrary>::@getter::uFuture
          returnType: Future<int> Function()
      setters
        #F5 synthetic uValue
          element: <testLibrary>::@setter::uValue
          formalParameters
            #F6 _uValue
              element: <testLibrary>::@setter::uValue::@formalParameter::_uValue
        #F7 synthetic uFuture
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
      firstFragment: #F2
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uFuture
      setter: <testLibrary>::@setter::uFuture
  getters
    synthetic static uValue
      reference: <testLibrary>::@getter::uValue
      firstFragment: #F3
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uValue
    synthetic static uFuture
      reference: <testLibrary>::@getter::uFuture
      firstFragment: #F4
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uFuture
  setters
    synthetic static uValue
      reference: <testLibrary>::@setter::uValue
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _uValue
          firstFragment: #F6
          type: Future<int> Function()
      returnType: void
    synthetic static uFuture
      reference: <testLibrary>::@setter::uFuture
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional _uFuture
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
        #F2 hasInitializer vBitAnd @25
          element: <testLibrary>::@topLevelVariable::vBitAnd
        #F3 hasInitializer vBitOr @46
          element: <testLibrary>::@topLevelVariable::vBitOr
        #F4 hasInitializer vBitShiftLeft @66
          element: <testLibrary>::@topLevelVariable::vBitShiftLeft
        #F5 hasInitializer vBitShiftRight @94
          element: <testLibrary>::@topLevelVariable::vBitShiftRight
      getters
        #F6 synthetic vBitXor
          element: <testLibrary>::@getter::vBitXor
          returnType: int
        #F7 synthetic vBitAnd
          element: <testLibrary>::@getter::vBitAnd
          returnType: int
        #F8 synthetic vBitOr
          element: <testLibrary>::@getter::vBitOr
          returnType: int
        #F9 synthetic vBitShiftLeft
          element: <testLibrary>::@getter::vBitShiftLeft
          returnType: int
        #F10 synthetic vBitShiftRight
          element: <testLibrary>::@getter::vBitShiftRight
          returnType: int
      setters
        #F11 synthetic vBitXor
          element: <testLibrary>::@setter::vBitXor
          formalParameters
            #F12 _vBitXor
              element: <testLibrary>::@setter::vBitXor::@formalParameter::_vBitXor
        #F13 synthetic vBitAnd
          element: <testLibrary>::@setter::vBitAnd
          formalParameters
            #F14 _vBitAnd
              element: <testLibrary>::@setter::vBitAnd::@formalParameter::_vBitAnd
        #F15 synthetic vBitOr
          element: <testLibrary>::@setter::vBitOr
          formalParameters
            #F16 _vBitOr
              element: <testLibrary>::@setter::vBitOr::@formalParameter::_vBitOr
        #F17 synthetic vBitShiftLeft
          element: <testLibrary>::@setter::vBitShiftLeft
          formalParameters
            #F18 _vBitShiftLeft
              element: <testLibrary>::@setter::vBitShiftLeft::@formalParameter::_vBitShiftLeft
        #F19 synthetic vBitShiftRight
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
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::vBitAnd
      setter: <testLibrary>::@setter::vBitAnd
    hasInitializer vBitOr
      reference: <testLibrary>::@topLevelVariable::vBitOr
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vBitOr
      setter: <testLibrary>::@setter::vBitOr
    hasInitializer vBitShiftLeft
      reference: <testLibrary>::@topLevelVariable::vBitShiftLeft
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vBitShiftLeft
      setter: <testLibrary>::@setter::vBitShiftLeft
    hasInitializer vBitShiftRight
      reference: <testLibrary>::@topLevelVariable::vBitShiftRight
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::vBitShiftRight
      setter: <testLibrary>::@setter::vBitShiftRight
  getters
    synthetic static vBitXor
      reference: <testLibrary>::@getter::vBitXor
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitXor
    synthetic static vBitAnd
      reference: <testLibrary>::@getter::vBitAnd
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    synthetic static vBitOr
      reference: <testLibrary>::@getter::vBitOr
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitOr
    synthetic static vBitShiftLeft
      reference: <testLibrary>::@getter::vBitShiftLeft
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    synthetic static vBitShiftRight
      reference: <testLibrary>::@getter::vBitShiftRight
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftRight
  setters
    synthetic static vBitXor
      reference: <testLibrary>::@setter::vBitXor
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional _vBitXor
          firstFragment: #F12
          type: int
      returnType: void
    synthetic static vBitAnd
      reference: <testLibrary>::@setter::vBitAnd
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _vBitAnd
          firstFragment: #F14
          type: int
      returnType: void
    synthetic static vBitOr
      reference: <testLibrary>::@setter::vBitOr
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional _vBitOr
          firstFragment: #F16
          type: int
      returnType: void
    synthetic static vBitShiftLeft
      reference: <testLibrary>::@setter::vBitShiftLeft
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional _vBitShiftLeft
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vBitShiftRight
      reference: <testLibrary>::@setter::vBitShiftRight
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional _vBitShiftRight
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: int
          setters
            #F5 synthetic a
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
        #F9 hasInitializer vInvokeMethod @71
          element: <testLibrary>::@topLevelVariable::vInvokeMethod
        #F10 hasInitializer vBoth @105
          element: <testLibrary>::@topLevelVariable::vBoth
      getters
        #F11 synthetic vSetField
          element: <testLibrary>::@getter::vSetField
          returnType: A
        #F12 synthetic vInvokeMethod
          element: <testLibrary>::@getter::vInvokeMethod
          returnType: A
        #F13 synthetic vBoth
          element: <testLibrary>::@getter::vBoth
          returnType: A
      setters
        #F14 synthetic vSetField
          element: <testLibrary>::@setter::vSetField
          formalParameters
            #F15 _vSetField
              element: <testLibrary>::@setter::vSetField::@formalParameter::_vSetField
        #F16 synthetic vInvokeMethod
          element: <testLibrary>::@setter::vInvokeMethod
          formalParameters
            #F17 _vInvokeMethod
              element: <testLibrary>::@setter::vInvokeMethod::@formalParameter::_vInvokeMethod
        #F18 synthetic vBoth
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
          firstFragment: #F3
      getters
        synthetic a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _a
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
      firstFragment: #F9
      type: A
      getter: <testLibrary>::@getter::vInvokeMethod
      setter: <testLibrary>::@setter::vInvokeMethod
    hasInitializer vBoth
      reference: <testLibrary>::@topLevelVariable::vBoth
      firstFragment: #F10
      type: A
      getter: <testLibrary>::@getter::vBoth
      setter: <testLibrary>::@setter::vBoth
  getters
    synthetic static vSetField
      reference: <testLibrary>::@getter::vSetField
      firstFragment: #F11
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vSetField
    synthetic static vInvokeMethod
      reference: <testLibrary>::@getter::vInvokeMethod
      firstFragment: #F12
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vInvokeMethod
    synthetic static vBoth
      reference: <testLibrary>::@getter::vBoth
      firstFragment: #F13
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vBoth
  setters
    synthetic static vSetField
      reference: <testLibrary>::@setter::vSetField
      firstFragment: #F14
      formalParameters
        #E1 requiredPositional _vSetField
          firstFragment: #F15
          type: A
      returnType: void
    synthetic static vInvokeMethod
      reference: <testLibrary>::@setter::vInvokeMethod
      firstFragment: #F16
      formalParameters
        #E2 requiredPositional _vInvokeMethod
          firstFragment: #F17
          type: A
      returnType: void
    synthetic static vBoth
      reference: <testLibrary>::@setter::vBoth
      firstFragment: #F18
      formalParameters
        #E3 requiredPositional _vBoth
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
        #F7 class B @31
          element: <testLibrary>::@class::B
          fields
            #F8 a @39
              element: <testLibrary>::@class::B::@field::a
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic a
              element: <testLibrary>::@class::B::@getter::a
              returnType: A
          setters
            #F11 synthetic a
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F12 _a
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::_a
        #F13 class C @50
          element: <testLibrary>::@class::C
          fields
            #F14 b @58
              element: <testLibrary>::@class::C::@field::b
          constructors
            #F15 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F16 synthetic b
              element: <testLibrary>::@class::C::@getter::b
              returnType: B
          setters
            #F17 synthetic b
              element: <testLibrary>::@class::C::@setter::b
              formalParameters
                #F18 _b
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::_b
        #F19 class X @69
          element: <testLibrary>::@class::X
          fields
            #F20 hasInitializer a @77
              element: <testLibrary>::@class::X::@field::a
            #F21 hasInitializer b @94
              element: <testLibrary>::@class::X::@field::b
            #F22 hasInitializer c @111
              element: <testLibrary>::@class::X::@field::c
            #F23 hasInitializer t01 @130
              element: <testLibrary>::@class::X::@field::t01
            #F24 hasInitializer t02 @147
              element: <testLibrary>::@class::X::@field::t02
            #F25 hasInitializer t03 @166
              element: <testLibrary>::@class::X::@field::t03
            #F26 hasInitializer t11 @187
              element: <testLibrary>::@class::X::@field::t11
            #F27 hasInitializer t12 @210
              element: <testLibrary>::@class::X::@field::t12
            #F28 hasInitializer t13 @235
              element: <testLibrary>::@class::X::@field::t13
            #F29 hasInitializer t21 @262
              element: <testLibrary>::@class::X::@field::t21
            #F30 hasInitializer t22 @284
              element: <testLibrary>::@class::X::@field::t22
            #F31 hasInitializer t23 @308
              element: <testLibrary>::@class::X::@field::t23
          constructors
            #F32 synthetic new
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
          getters
            #F33 synthetic a
              element: <testLibrary>::@class::X::@getter::a
              returnType: A
            #F34 synthetic b
              element: <testLibrary>::@class::X::@getter::b
              returnType: B
            #F35 synthetic c
              element: <testLibrary>::@class::X::@getter::c
              returnType: C
            #F36 synthetic t01
              element: <testLibrary>::@class::X::@getter::t01
              returnType: int
            #F37 synthetic t02
              element: <testLibrary>::@class::X::@getter::t02
              returnType: int
            #F38 synthetic t03
              element: <testLibrary>::@class::X::@getter::t03
              returnType: int
            #F39 synthetic t11
              element: <testLibrary>::@class::X::@getter::t11
              returnType: int
            #F40 synthetic t12
              element: <testLibrary>::@class::X::@getter::t12
              returnType: int
            #F41 synthetic t13
              element: <testLibrary>::@class::X::@getter::t13
              returnType: int
            #F42 synthetic t21
              element: <testLibrary>::@class::X::@getter::t21
              returnType: int
            #F43 synthetic t22
              element: <testLibrary>::@class::X::@getter::t22
              returnType: int
            #F44 synthetic t23
              element: <testLibrary>::@class::X::@getter::t23
              returnType: int
          setters
            #F45 synthetic a
              element: <testLibrary>::@class::X::@setter::a
              formalParameters
                #F46 _a
                  element: <testLibrary>::@class::X::@setter::a::@formalParameter::_a
            #F47 synthetic b
              element: <testLibrary>::@class::X::@setter::b
              formalParameters
                #F48 _b
                  element: <testLibrary>::@class::X::@setter::b::@formalParameter::_b
            #F49 synthetic c
              element: <testLibrary>::@class::X::@setter::c
              formalParameters
                #F50 _c
                  element: <testLibrary>::@class::X::@setter::c::@formalParameter::_c
            #F51 synthetic t01
              element: <testLibrary>::@class::X::@setter::t01
              formalParameters
                #F52 _t01
                  element: <testLibrary>::@class::X::@setter::t01::@formalParameter::_t01
            #F53 synthetic t02
              element: <testLibrary>::@class::X::@setter::t02
              formalParameters
                #F54 _t02
                  element: <testLibrary>::@class::X::@setter::t02::@formalParameter::_t02
            #F55 synthetic t03
              element: <testLibrary>::@class::X::@setter::t03
              formalParameters
                #F56 _t03
                  element: <testLibrary>::@class::X::@setter::t03::@formalParameter::_t03
            #F57 synthetic t11
              element: <testLibrary>::@class::X::@setter::t11
              formalParameters
                #F58 _t11
                  element: <testLibrary>::@class::X::@setter::t11::@formalParameter::_t11
            #F59 synthetic t12
              element: <testLibrary>::@class::X::@setter::t12
              formalParameters
                #F60 _t12
                  element: <testLibrary>::@class::X::@setter::t12::@formalParameter::_t12
            #F61 synthetic t13
              element: <testLibrary>::@class::X::@setter::t13
              formalParameters
                #F62 _t13
                  element: <testLibrary>::@class::X::@setter::t13::@formalParameter::_t13
            #F63 synthetic t21
              element: <testLibrary>::@class::X::@setter::t21
              formalParameters
                #F64 _t21
                  element: <testLibrary>::@class::X::@setter::t21::@formalParameter::_t21
            #F65 synthetic t22
              element: <testLibrary>::@class::X::@setter::t22
              formalParameters
                #F66 _t22
                  element: <testLibrary>::@class::X::@setter::t22::@formalParameter::_t22
            #F67 synthetic t23
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
          firstFragment: #F9
      getters
        synthetic a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _a
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
          firstFragment: #F15
      getters
        synthetic b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F16
          returnType: B
          variable: <testLibrary>::@class::C::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F17
          formalParameters
            #E2 requiredPositional _b
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
          firstFragment: #F21
          type: B
          getter: <testLibrary>::@class::X::@getter::b
          setter: <testLibrary>::@class::X::@setter::b
        hasInitializer c
          reference: <testLibrary>::@class::X::@field::c
          firstFragment: #F22
          type: C
          getter: <testLibrary>::@class::X::@getter::c
          setter: <testLibrary>::@class::X::@setter::c
        hasInitializer t01
          reference: <testLibrary>::@class::X::@field::t01
          firstFragment: #F23
          type: int
          getter: <testLibrary>::@class::X::@getter::t01
          setter: <testLibrary>::@class::X::@setter::t01
        hasInitializer t02
          reference: <testLibrary>::@class::X::@field::t02
          firstFragment: #F24
          type: int
          getter: <testLibrary>::@class::X::@getter::t02
          setter: <testLibrary>::@class::X::@setter::t02
        hasInitializer t03
          reference: <testLibrary>::@class::X::@field::t03
          firstFragment: #F25
          type: int
          getter: <testLibrary>::@class::X::@getter::t03
          setter: <testLibrary>::@class::X::@setter::t03
        hasInitializer t11
          reference: <testLibrary>::@class::X::@field::t11
          firstFragment: #F26
          type: int
          getter: <testLibrary>::@class::X::@getter::t11
          setter: <testLibrary>::@class::X::@setter::t11
        hasInitializer t12
          reference: <testLibrary>::@class::X::@field::t12
          firstFragment: #F27
          type: int
          getter: <testLibrary>::@class::X::@getter::t12
          setter: <testLibrary>::@class::X::@setter::t12
        hasInitializer t13
          reference: <testLibrary>::@class::X::@field::t13
          firstFragment: #F28
          type: int
          getter: <testLibrary>::@class::X::@getter::t13
          setter: <testLibrary>::@class::X::@setter::t13
        hasInitializer t21
          reference: <testLibrary>::@class::X::@field::t21
          firstFragment: #F29
          type: int
          getter: <testLibrary>::@class::X::@getter::t21
          setter: <testLibrary>::@class::X::@setter::t21
        hasInitializer t22
          reference: <testLibrary>::@class::X::@field::t22
          firstFragment: #F30
          type: int
          getter: <testLibrary>::@class::X::@getter::t22
          setter: <testLibrary>::@class::X::@setter::t22
        hasInitializer t23
          reference: <testLibrary>::@class::X::@field::t23
          firstFragment: #F31
          type: int
          getter: <testLibrary>::@class::X::@getter::t23
          setter: <testLibrary>::@class::X::@setter::t23
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F32
      getters
        synthetic a
          reference: <testLibrary>::@class::X::@getter::a
          firstFragment: #F33
          returnType: A
          variable: <testLibrary>::@class::X::@field::a
        synthetic b
          reference: <testLibrary>::@class::X::@getter::b
          firstFragment: #F34
          returnType: B
          variable: <testLibrary>::@class::X::@field::b
        synthetic c
          reference: <testLibrary>::@class::X::@getter::c
          firstFragment: #F35
          returnType: C
          variable: <testLibrary>::@class::X::@field::c
        synthetic t01
          reference: <testLibrary>::@class::X::@getter::t01
          firstFragment: #F36
          returnType: int
          variable: <testLibrary>::@class::X::@field::t01
        synthetic t02
          reference: <testLibrary>::@class::X::@getter::t02
          firstFragment: #F37
          returnType: int
          variable: <testLibrary>::@class::X::@field::t02
        synthetic t03
          reference: <testLibrary>::@class::X::@getter::t03
          firstFragment: #F38
          returnType: int
          variable: <testLibrary>::@class::X::@field::t03
        synthetic t11
          reference: <testLibrary>::@class::X::@getter::t11
          firstFragment: #F39
          returnType: int
          variable: <testLibrary>::@class::X::@field::t11
        synthetic t12
          reference: <testLibrary>::@class::X::@getter::t12
          firstFragment: #F40
          returnType: int
          variable: <testLibrary>::@class::X::@field::t12
        synthetic t13
          reference: <testLibrary>::@class::X::@getter::t13
          firstFragment: #F41
          returnType: int
          variable: <testLibrary>::@class::X::@field::t13
        synthetic t21
          reference: <testLibrary>::@class::X::@getter::t21
          firstFragment: #F42
          returnType: int
          variable: <testLibrary>::@class::X::@field::t21
        synthetic t22
          reference: <testLibrary>::@class::X::@getter::t22
          firstFragment: #F43
          returnType: int
          variable: <testLibrary>::@class::X::@field::t22
        synthetic t23
          reference: <testLibrary>::@class::X::@getter::t23
          firstFragment: #F44
          returnType: int
          variable: <testLibrary>::@class::X::@field::t23
      setters
        synthetic a
          reference: <testLibrary>::@class::X::@setter::a
          firstFragment: #F45
          formalParameters
            #E3 requiredPositional _a
              firstFragment: #F46
              type: A
          returnType: void
        synthetic b
          reference: <testLibrary>::@class::X::@setter::b
          firstFragment: #F47
          formalParameters
            #E4 requiredPositional _b
              firstFragment: #F48
              type: B
          returnType: void
        synthetic c
          reference: <testLibrary>::@class::X::@setter::c
          firstFragment: #F49
          formalParameters
            #E5 requiredPositional _c
              firstFragment: #F50
              type: C
          returnType: void
        synthetic t01
          reference: <testLibrary>::@class::X::@setter::t01
          firstFragment: #F51
          formalParameters
            #E6 requiredPositional _t01
              firstFragment: #F52
              type: int
          returnType: void
        synthetic t02
          reference: <testLibrary>::@class::X::@setter::t02
          firstFragment: #F53
          formalParameters
            #E7 requiredPositional _t02
              firstFragment: #F54
              type: int
          returnType: void
        synthetic t03
          reference: <testLibrary>::@class::X::@setter::t03
          firstFragment: #F55
          formalParameters
            #E8 requiredPositional _t03
              firstFragment: #F56
              type: int
          returnType: void
        synthetic t11
          reference: <testLibrary>::@class::X::@setter::t11
          firstFragment: #F57
          formalParameters
            #E9 requiredPositional _t11
              firstFragment: #F58
              type: int
          returnType: void
        synthetic t12
          reference: <testLibrary>::@class::X::@setter::t12
          firstFragment: #F59
          formalParameters
            #E10 requiredPositional _t12
              firstFragment: #F60
              type: int
          returnType: void
        synthetic t13
          reference: <testLibrary>::@class::X::@setter::t13
          firstFragment: #F61
          formalParameters
            #E11 requiredPositional _t13
              firstFragment: #F62
              type: int
          returnType: void
        synthetic t21
          reference: <testLibrary>::@class::X::@setter::t21
          firstFragment: #F63
          formalParameters
            #E12 requiredPositional _t21
              firstFragment: #F64
              type: int
          returnType: void
        synthetic t22
          reference: <testLibrary>::@class::X::@setter::t22
          firstFragment: #F65
          formalParameters
            #E13 requiredPositional _t22
              firstFragment: #F66
              type: int
          returnType: void
        synthetic t23
          reference: <testLibrary>::@class::X::@setter::t23
          firstFragment: #F67
          formalParameters
            #E14 requiredPositional _t23
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
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: num
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
        #E0 requiredPositional _V
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
        #F2 hasInitializer vNotEq @22
          element: <testLibrary>::@topLevelVariable::vNotEq
      getters
        #F3 synthetic vEq
          element: <testLibrary>::@getter::vEq
          returnType: bool
        #F4 synthetic vNotEq
          element: <testLibrary>::@getter::vNotEq
          returnType: bool
      setters
        #F5 synthetic vEq
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F6 _vEq
              element: <testLibrary>::@setter::vEq::@formalParameter::_vEq
        #F7 synthetic vNotEq
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
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    synthetic static vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F3
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    synthetic static vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F4
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    synthetic static vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _vEq
          firstFragment: #F6
          type: bool
      returnType: void
    synthetic static vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional _vNotEq
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
        #F2 hasInitializer b @21
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
      setters
        #F5 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F7 synthetic b
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
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F6
          type: dynamic
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional _b
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
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
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
        #E0 requiredPositional _a
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
        #F2 hasInitializer b0 @22
          element: <testLibrary>::@topLevelVariable::b0
        #F3 hasInitializer b1 @37
          element: <testLibrary>::@topLevelVariable::b1
      getters
        #F4 synthetic a
          element: <testLibrary>::@getter::a
          returnType: List<num>
        #F5 synthetic b0
          element: <testLibrary>::@getter::b0
          returnType: num
        #F6 synthetic b1
          element: <testLibrary>::@getter::b1
          returnType: num
      setters
        #F7 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F9 synthetic b0
          element: <testLibrary>::@setter::b0
          formalParameters
            #F10 _b0
              element: <testLibrary>::@setter::b0::@formalParameter::_b0
        #F11 synthetic b1
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
      firstFragment: #F2
      type: num
      getter: <testLibrary>::@getter::b0
      setter: <testLibrary>::@setter::b0
    hasInitializer b1
      reference: <testLibrary>::@topLevelVariable::b1
      firstFragment: #F3
      type: num
      getter: <testLibrary>::@getter::b1
      setter: <testLibrary>::@setter::b1
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b0
      reference: <testLibrary>::@getter::b0
      firstFragment: #F5
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b0
    synthetic static b1
      reference: <testLibrary>::@getter::b1
      firstFragment: #F6
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b1
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F8
          type: List<num>
      returnType: void
    synthetic static b0
      reference: <testLibrary>::@setter::b0
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _b0
          firstFragment: #F10
          type: num
      returnType: void
    synthetic static b1
      reference: <testLibrary>::@setter::b1
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _b1
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
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
        #E0 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::C::@getter::f
              returnType: int
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::_f
      topLevelVariables
        #F7 hasInitializer x @29
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
        #E1 requiredPositional _x
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
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
        #E0 requiredPositional _x
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
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
        #E0 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::C::@getter::f
              returnType: int
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::_f
      topLevelVariables
        #F7 hasInitializer x @29
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
        #E1 requiredPositional _x
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
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
        #E0 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
        #F7 class B @27
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer t @44
              element: <testLibrary>::@class::B::@field::t
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic t
              element: <testLibrary>::@class::B::@getter::t
              returnType: int
          setters
            #F11 synthetic t
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
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _f
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
          firstFragment: #F9
      getters
        synthetic static t
          reference: <testLibrary>::@class::B::@getter::t
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::B::@field::t
      setters
        synthetic static t
          reference: <testLibrary>::@class::B::@setter::t
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _t
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic b
              element: <testLibrary>::@class::C::@getter::b
              returnType: bool
          setters
            #F5 synthetic b
              element: <testLibrary>::@class::C::@setter::b
              formalParameters
                #F6 _b
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::_b
      topLevelVariables
        #F7 c @24
          element: <testLibrary>::@topLevelVariable::c
        #F8 hasInitializer x @31
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F9 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
        #F10 synthetic x
          element: <testLibrary>::@getter::x
          returnType: bool
      setters
        #F11 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F12 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
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
        b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::C::@getter::b
          setter: <testLibrary>::@class::C::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F4
          returnType: bool
          variable: <testLibrary>::@class::C::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _b
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
      firstFragment: #F8
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F9
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional _c
          firstFragment: #F12
          type: C
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 synthetic b
              element: <testLibrary>::@class::I::@getter::b
              returnType: bool
          setters
            #F5 synthetic b
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
        #F10 hasInitializer x @64
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F11 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
        #F12 synthetic x
          element: <testLibrary>::@getter::x
          returnType: bool
      setters
        #F13 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F14 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F15 synthetic x
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
          firstFragment: #F3
      getters
        synthetic b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F4
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _b
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
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _c
          firstFragment: #F14
          type: C
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 synthetic b
              element: <testLibrary>::@class::I::@getter::b
              returnType: bool
          setters
            #F5 synthetic b
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
      getters
        #F10 synthetic x
          element: <testLibrary>::@getter::x
          returnType: bool
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
          firstFragment: #F3
      getters
        synthetic b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F4
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _b
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
        #E1 requiredPositional _x
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
        #F8 hasInitializer y @89
          element: <testLibrary>::@topLevelVariable::y
      getters
        #F9 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
        #F10 synthetic y
          element: <testLibrary>::@getter::y
          returnType: int
      setters
        #F11 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
        #F13 synthetic y
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
      firstFragment: #F8
      type: int
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::y
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional _x
          firstFragment: #F12
          type: int
      returnType: void
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _y
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
        #F2 hasInitializer v_noParameters_inferredReturnType @60
          element: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
        #F3 hasInitializer v_hasParameter_withType_inferredReturnType @110
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
        #F4 hasInitializer v_hasParameter_withType_returnParameter @177
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
        #F5 hasInitializer v_async_returnValue @240
          element: <testLibrary>::@topLevelVariable::v_async_returnValue
        #F6 hasInitializer v_async_returnFuture @282
          element: <testLibrary>::@topLevelVariable::v_async_returnFuture
      getters
        #F7 synthetic vFuture
          element: <testLibrary>::@getter::vFuture
          returnType: Future<int>
        #F8 synthetic v_noParameters_inferredReturnType
          element: <testLibrary>::@getter::v_noParameters_inferredReturnType
          returnType: int Function()
        #F9 synthetic v_hasParameter_withType_inferredReturnType
          element: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
          returnType: int Function(String)
        #F10 synthetic v_hasParameter_withType_returnParameter
          element: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
          returnType: String Function(String)
        #F11 synthetic v_async_returnValue
          element: <testLibrary>::@getter::v_async_returnValue
          returnType: Future<int> Function()
        #F12 synthetic v_async_returnFuture
          element: <testLibrary>::@getter::v_async_returnFuture
          returnType: Future<int> Function()
      setters
        #F13 synthetic vFuture
          element: <testLibrary>::@setter::vFuture
          formalParameters
            #F14 _vFuture
              element: <testLibrary>::@setter::vFuture::@formalParameter::_vFuture
        #F15 synthetic v_noParameters_inferredReturnType
          element: <testLibrary>::@setter::v_noParameters_inferredReturnType
          formalParameters
            #F16 _v_noParameters_inferredReturnType
              element: <testLibrary>::@setter::v_noParameters_inferredReturnType::@formalParameter::_v_noParameters_inferredReturnType
        #F17 synthetic v_hasParameter_withType_inferredReturnType
          element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
          formalParameters
            #F18 _v_hasParameter_withType_inferredReturnType
              element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType::@formalParameter::_v_hasParameter_withType_inferredReturnType
        #F19 synthetic v_hasParameter_withType_returnParameter
          element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
          formalParameters
            #F20 _v_hasParameter_withType_returnParameter
              element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter::@formalParameter::_v_hasParameter_withType_returnParameter
        #F21 synthetic v_async_returnValue
          element: <testLibrary>::@setter::v_async_returnValue
          formalParameters
            #F22 _v_async_returnValue
              element: <testLibrary>::@setter::v_async_returnValue::@formalParameter::_v_async_returnValue
        #F23 synthetic v_async_returnFuture
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
      firstFragment: #F2
      type: int Function()
      getter: <testLibrary>::@getter::v_noParameters_inferredReturnType
      setter: <testLibrary>::@setter::v_noParameters_inferredReturnType
    hasInitializer v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
      firstFragment: #F3
      type: int Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      setter: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
    hasInitializer v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
      firstFragment: #F4
      type: String Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      setter: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
    hasInitializer v_async_returnValue
      reference: <testLibrary>::@topLevelVariable::v_async_returnValue
      firstFragment: #F5
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnValue
      setter: <testLibrary>::@setter::v_async_returnValue
    hasInitializer v_async_returnFuture
      reference: <testLibrary>::@topLevelVariable::v_async_returnFuture
      firstFragment: #F6
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnFuture
      setter: <testLibrary>::@setter::v_async_returnFuture
  getters
    synthetic static vFuture
      reference: <testLibrary>::@getter::vFuture
      firstFragment: #F7
      returnType: Future<int>
      variable: <testLibrary>::@topLevelVariable::vFuture
    synthetic static v_noParameters_inferredReturnType
      reference: <testLibrary>::@getter::v_noParameters_inferredReturnType
      firstFragment: #F8
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
    synthetic static v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F9
      returnType: int Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
    synthetic static v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      firstFragment: #F10
      returnType: String Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
    synthetic static v_async_returnValue
      reference: <testLibrary>::@getter::v_async_returnValue
      firstFragment: #F11
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnValue
    synthetic static v_async_returnFuture
      reference: <testLibrary>::@getter::v_async_returnFuture
      firstFragment: #F12
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnFuture
  setters
    synthetic static vFuture
      reference: <testLibrary>::@setter::vFuture
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional _vFuture
          firstFragment: #F14
          type: Future<int>
      returnType: void
    synthetic static v_noParameters_inferredReturnType
      reference: <testLibrary>::@setter::v_noParameters_inferredReturnType
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional _v_noParameters_inferredReturnType
          firstFragment: #F16
          type: int Function()
      returnType: void
    synthetic static v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional _v_hasParameter_withType_inferredReturnType
          firstFragment: #F18
          type: int Function(String)
      returnType: void
    synthetic static v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional _v_hasParameter_withType_returnParameter
          firstFragment: #F20
          type: String Function(String)
      returnType: void
    synthetic static v_async_returnValue
      reference: <testLibrary>::@setter::v_async_returnValue
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional _v_async_returnValue
          firstFragment: #F22
          type: Future<int> Function()
      returnType: void
    synthetic static v_async_returnFuture
      reference: <testLibrary>::@setter::v_async_returnFuture
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional _v_async_returnFuture
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
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
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
        #E0 requiredPositional _v
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
        #F2 hasInitializer vNoTypeArgument @55
          element: <testLibrary>::@topLevelVariable::vNoTypeArgument
      getters
        #F3 synthetic vHasTypeArgument
          element: <testLibrary>::@getter::vHasTypeArgument
          returnType: int
        #F4 synthetic vNoTypeArgument
          element: <testLibrary>::@getter::vNoTypeArgument
          returnType: dynamic
      setters
        #F5 synthetic vHasTypeArgument
          element: <testLibrary>::@setter::vHasTypeArgument
          formalParameters
            #F6 _vHasTypeArgument
              element: <testLibrary>::@setter::vHasTypeArgument::@formalParameter::_vHasTypeArgument
        #F7 synthetic vNoTypeArgument
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
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::vNoTypeArgument
      setter: <testLibrary>::@setter::vNoTypeArgument
  getters
    synthetic static vHasTypeArgument
      reference: <testLibrary>::@getter::vHasTypeArgument
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vHasTypeArgument
    synthetic static vNoTypeArgument
      reference: <testLibrary>::@getter::vNoTypeArgument
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::vNoTypeArgument
  setters
    synthetic static vHasTypeArgument
      reference: <testLibrary>::@setter::vHasTypeArgument
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional _vHasTypeArgument
          firstFragment: #F6
          type: int
      returnType: void
    synthetic static vNoTypeArgument
      reference: <testLibrary>::@setter::vNoTypeArgument
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional _vNoTypeArgument
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
        #F2 hasInitializer vWrongArgumentType @57
          element: <testLibrary>::@topLevelVariable::vWrongArgumentType
      getters
        #F3 synthetic vOkArgumentType
          element: <testLibrary>::@getter::vOkArgumentType
          returnType: String
        #F4 synthetic vWrongArgumentType
          element: <testLibrary>::@getter::vWrongArgumentType
          returnType: String
      setters
        #F5 synthetic vOkArgumentType
          element: <testLibrary>::@setter::vOkArgumentType
          formalParameters
            #F6 _vOkArgumentType
              element: <testLibrary>::@setter::vOkArgumentType::@formalParameter::_vOkArgumentType
        #F7 synthetic vWrongArgumentType
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
      firstFragment: #F2
      type: String
      getter: <testLibrary>::@getter::vWrongArgumentType
      setter: <testLibrary>::@setter::vWrongArgumentType
  getters
    synthetic static vOkArgumentType
      reference: <testLibrary>::@getter::vOkArgumentType
      firstFragment: #F3
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vOkArgumentType
    synthetic static vWrongArgumentType
      reference: <testLibrary>::@getter::vWrongArgumentType
      firstFragment: #F4
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vWrongArgumentType
  setters
    synthetic static vOkArgumentType
      reference: <testLibrary>::@setter::vOkArgumentType
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _vOkArgumentType
          firstFragment: #F6
          type: String
      returnType: void
    synthetic static vWrongArgumentType
      reference: <testLibrary>::@setter::vWrongArgumentType
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional _vWrongArgumentType
          firstFragment: #F8
          type: String
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional p
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
            #F3 synthetic staticGetter
              element: <testLibrary>::@class::A::@field::staticGetter
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic staticClassVariable
              element: <testLibrary>::@class::A::@getter::staticClassVariable
              returnType: int
            #F6 staticGetter @160
              element: <testLibrary>::@class::A::@getter::staticGetter
              returnType: int
          setters
            #F7 synthetic staticClassVariable
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
        #F14 synthetic topLevelGetter (offset=-1)
          element: <testLibrary>::@topLevelVariable::topLevelGetter
        #F15 hasInitializer r_topLevelFunction @280
          element: <testLibrary>::@topLevelVariable::r_topLevelFunction
        #F16 hasInitializer r_topLevelVariable @323
          element: <testLibrary>::@topLevelVariable::r_topLevelVariable
        #F17 hasInitializer r_topLevelGetter @366
          element: <testLibrary>::@topLevelVariable::r_topLevelGetter
        #F18 hasInitializer r_staticClassVariable @405
          element: <testLibrary>::@topLevelVariable::r_staticClassVariable
        #F19 hasInitializer r_staticGetter @456
          element: <testLibrary>::@topLevelVariable::r_staticGetter
        #F20 hasInitializer r_staticClassMethod @493
          element: <testLibrary>::@topLevelVariable::r_staticClassMethod
        #F21 hasInitializer instanceOfA @540
          element: <testLibrary>::@topLevelVariable::instanceOfA
        #F22 hasInitializer r_instanceClassMethod @567
          element: <testLibrary>::@topLevelVariable::r_instanceClassMethod
      getters
        #F23 synthetic topLevelVariable
          element: <testLibrary>::@getter::topLevelVariable
          returnType: int
        #F24 topLevelGetter @74
          element: <testLibrary>::@getter::topLevelGetter
          returnType: int
        #F25 synthetic r_topLevelFunction
          element: <testLibrary>::@getter::r_topLevelFunction
          returnType: String Function(int)
        #F26 synthetic r_topLevelVariable
          element: <testLibrary>::@getter::r_topLevelVariable
          returnType: int
        #F27 synthetic r_topLevelGetter
          element: <testLibrary>::@getter::r_topLevelGetter
          returnType: int
        #F28 synthetic r_staticClassVariable
          element: <testLibrary>::@getter::r_staticClassVariable
          returnType: int
        #F29 synthetic r_staticGetter
          element: <testLibrary>::@getter::r_staticGetter
          returnType: int
        #F30 synthetic r_staticClassMethod
          element: <testLibrary>::@getter::r_staticClassMethod
          returnType: String Function(int)
        #F31 synthetic instanceOfA
          element: <testLibrary>::@getter::instanceOfA
          returnType: A
        #F32 synthetic r_instanceClassMethod
          element: <testLibrary>::@getter::r_instanceClassMethod
          returnType: String Function(int)
      setters
        #F33 synthetic topLevelVariable
          element: <testLibrary>::@setter::topLevelVariable
          formalParameters
            #F34 _topLevelVariable
              element: <testLibrary>::@setter::topLevelVariable::@formalParameter::_topLevelVariable
        #F35 synthetic r_topLevelFunction
          element: <testLibrary>::@setter::r_topLevelFunction
          formalParameters
            #F36 _r_topLevelFunction
              element: <testLibrary>::@setter::r_topLevelFunction::@formalParameter::_r_topLevelFunction
        #F37 synthetic r_topLevelVariable
          element: <testLibrary>::@setter::r_topLevelVariable
          formalParameters
            #F38 _r_topLevelVariable
              element: <testLibrary>::@setter::r_topLevelVariable::@formalParameter::_r_topLevelVariable
        #F39 synthetic r_topLevelGetter
          element: <testLibrary>::@setter::r_topLevelGetter
          formalParameters
            #F40 _r_topLevelGetter
              element: <testLibrary>::@setter::r_topLevelGetter::@formalParameter::_r_topLevelGetter
        #F41 synthetic r_staticClassVariable
          element: <testLibrary>::@setter::r_staticClassVariable
          formalParameters
            #F42 _r_staticClassVariable
              element: <testLibrary>::@setter::r_staticClassVariable::@formalParameter::_r_staticClassVariable
        #F43 synthetic r_staticGetter
          element: <testLibrary>::@setter::r_staticGetter
          formalParameters
            #F44 _r_staticGetter
              element: <testLibrary>::@setter::r_staticGetter::@formalParameter::_r_staticGetter
        #F45 synthetic r_staticClassMethod
          element: <testLibrary>::@setter::r_staticClassMethod
          formalParameters
            #F46 _r_staticClassMethod
              element: <testLibrary>::@setter::r_staticClassMethod::@formalParameter::_r_staticClassMethod
        #F47 synthetic instanceOfA
          element: <testLibrary>::@setter::instanceOfA
          formalParameters
            #F48 _instanceOfA
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::_instanceOfA
        #F49 synthetic r_instanceClassMethod
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
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::staticGetter
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic static staticClassVariable
          reference: <testLibrary>::@class::A::@getter::staticClassVariable
          firstFragment: #F5
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
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional _staticClassVariable
              firstFragment: #F8
              type: int
          returnType: void
      methods
        static staticClassMethod
          reference: <testLibrary>::@class::A::@method::staticClassMethod
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional p
              firstFragment: #F10
              type: int
          returnType: String
        instanceClassMethod
          reference: <testLibrary>::@class::A::@method::instanceClassMethod
          firstFragment: #F11
          formalParameters
            #E2 requiredPositional p
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
    synthetic topLevelGetter
      reference: <testLibrary>::@topLevelVariable::topLevelGetter
      firstFragment: #F14
      type: int
      getter: <testLibrary>::@getter::topLevelGetter
    hasInitializer r_topLevelFunction
      reference: <testLibrary>::@topLevelVariable::r_topLevelFunction
      firstFragment: #F15
      type: String Function(int)
      getter: <testLibrary>::@getter::r_topLevelFunction
      setter: <testLibrary>::@setter::r_topLevelFunction
    hasInitializer r_topLevelVariable
      reference: <testLibrary>::@topLevelVariable::r_topLevelVariable
      firstFragment: #F16
      type: int
      getter: <testLibrary>::@getter::r_topLevelVariable
      setter: <testLibrary>::@setter::r_topLevelVariable
    hasInitializer r_topLevelGetter
      reference: <testLibrary>::@topLevelVariable::r_topLevelGetter
      firstFragment: #F17
      type: int
      getter: <testLibrary>::@getter::r_topLevelGetter
      setter: <testLibrary>::@setter::r_topLevelGetter
    hasInitializer r_staticClassVariable
      reference: <testLibrary>::@topLevelVariable::r_staticClassVariable
      firstFragment: #F18
      type: int
      getter: <testLibrary>::@getter::r_staticClassVariable
      setter: <testLibrary>::@setter::r_staticClassVariable
    hasInitializer r_staticGetter
      reference: <testLibrary>::@topLevelVariable::r_staticGetter
      firstFragment: #F19
      type: int
      getter: <testLibrary>::@getter::r_staticGetter
      setter: <testLibrary>::@setter::r_staticGetter
    hasInitializer r_staticClassMethod
      reference: <testLibrary>::@topLevelVariable::r_staticClassMethod
      firstFragment: #F20
      type: String Function(int)
      getter: <testLibrary>::@getter::r_staticClassMethod
      setter: <testLibrary>::@setter::r_staticClassMethod
    hasInitializer instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F21
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasInitializer r_instanceClassMethod
      reference: <testLibrary>::@topLevelVariable::r_instanceClassMethod
      firstFragment: #F22
      type: String Function(int)
      getter: <testLibrary>::@getter::r_instanceClassMethod
      setter: <testLibrary>::@setter::r_instanceClassMethod
  getters
    synthetic static topLevelVariable
      reference: <testLibrary>::@getter::topLevelVariable
      firstFragment: #F23
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelVariable
    static topLevelGetter
      reference: <testLibrary>::@getter::topLevelGetter
      firstFragment: #F24
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelGetter
    synthetic static r_topLevelFunction
      reference: <testLibrary>::@getter::r_topLevelFunction
      firstFragment: #F25
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_topLevelFunction
    synthetic static r_topLevelVariable
      reference: <testLibrary>::@getter::r_topLevelVariable
      firstFragment: #F26
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelVariable
    synthetic static r_topLevelGetter
      reference: <testLibrary>::@getter::r_topLevelGetter
      firstFragment: #F27
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelGetter
    synthetic static r_staticClassVariable
      reference: <testLibrary>::@getter::r_staticClassVariable
      firstFragment: #F28
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticClassVariable
    synthetic static r_staticGetter
      reference: <testLibrary>::@getter::r_staticGetter
      firstFragment: #F29
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticGetter
    synthetic static r_staticClassMethod
      reference: <testLibrary>::@getter::r_staticClassMethod
      firstFragment: #F30
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_staticClassMethod
    synthetic static instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F31
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    synthetic static r_instanceClassMethod
      reference: <testLibrary>::@getter::r_instanceClassMethod
      firstFragment: #F32
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_instanceClassMethod
  setters
    synthetic static topLevelVariable
      reference: <testLibrary>::@setter::topLevelVariable
      firstFragment: #F33
      formalParameters
        #E3 requiredPositional _topLevelVariable
          firstFragment: #F34
          type: int
      returnType: void
    synthetic static r_topLevelFunction
      reference: <testLibrary>::@setter::r_topLevelFunction
      firstFragment: #F35
      formalParameters
        #E4 requiredPositional _r_topLevelFunction
          firstFragment: #F36
          type: String Function(int)
      returnType: void
    synthetic static r_topLevelVariable
      reference: <testLibrary>::@setter::r_topLevelVariable
      firstFragment: #F37
      formalParameters
        #E5 requiredPositional _r_topLevelVariable
          firstFragment: #F38
          type: int
      returnType: void
    synthetic static r_topLevelGetter
      reference: <testLibrary>::@setter::r_topLevelGetter
      firstFragment: #F39
      formalParameters
        #E6 requiredPositional _r_topLevelGetter
          firstFragment: #F40
          type: int
      returnType: void
    synthetic static r_staticClassVariable
      reference: <testLibrary>::@setter::r_staticClassVariable
      firstFragment: #F41
      formalParameters
        #E7 requiredPositional _r_staticClassVariable
          firstFragment: #F42
          type: int
      returnType: void
    synthetic static r_staticGetter
      reference: <testLibrary>::@setter::r_staticGetter
      firstFragment: #F43
      formalParameters
        #E8 requiredPositional _r_staticGetter
          firstFragment: #F44
          type: int
      returnType: void
    synthetic static r_staticClassMethod
      reference: <testLibrary>::@setter::r_staticClassMethod
      firstFragment: #F45
      formalParameters
        #E9 requiredPositional _r_staticClassMethod
          firstFragment: #F46
          type: String Function(int)
      returnType: void
    synthetic static instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F47
      formalParameters
        #E10 requiredPositional _instanceOfA
          firstFragment: #F48
          type: A
      returnType: void
    synthetic static r_instanceClassMethod
      reference: <testLibrary>::@setter::r_instanceClassMethod
      firstFragment: #F49
      formalParameters
        #E11 requiredPositional _r_instanceClassMethod
          firstFragment: #F50
          type: String Function(int)
      returnType: void
  functions
    topLevelFunction
      reference: <testLibrary>::@function::topLevelFunction
      firstFragment: #F51
      formalParameters
        #E12 requiredPositional p
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: dynamic
          setters
            #F5 synthetic a
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 _a
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_a
        #F7 class B @40
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer b @57
              element: <testLibrary>::@class::B::@field::b
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic b
              element: <testLibrary>::@class::B::@getter::b
              returnType: dynamic
          setters
            #F11 synthetic b
              element: <testLibrary>::@class::B::@setter::b
              formalParameters
                #F12 _b
                  element: <testLibrary>::@class::B::@setter::b::@formalParameter::_b
      topLevelVariables
        #F13 hasInitializer c @72
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F14 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
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
          firstFragment: #F3
      getters
        synthetic static a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        synthetic static a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _a
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
          firstFragment: #F9
      getters
        synthetic static b
          reference: <testLibrary>::@class::B::@getter::b
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::b
      setters
        synthetic static b
          reference: <testLibrary>::@class::B::@setter::b
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _b
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
        #E2 requiredPositional _c
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: dynamic
          setters
            #F5 synthetic a
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 _a
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_a
      topLevelVariables
        #F7 hasInitializer b @36
          element: <testLibrary>::@topLevelVariable::b
        #F8 hasInitializer c @49
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F9 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
        #F10 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
      setters
        #F11 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F12 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
        #F13 synthetic c
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
          firstFragment: #F3
      getters
        synthetic static a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        synthetic static a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _a
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
      firstFragment: #F8
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F10
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional _b
          firstFragment: #F12
          type: dynamic
      returnType: void
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional _c
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
        #F2 hasInitializer b @19
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer c @32
          element: <testLibrary>::@topLevelVariable::c
        #F4 hasInitializer d @45
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F5 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
        #F6 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
        #F7 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
        #F8 synthetic d
          element: <testLibrary>::@getter::d
          returnType: dynamic
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::c
    final hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
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
      getters
        #F4 synthetic a
          element: <testLibrary>::@getter::a
          returnType: A
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
        #E0 requiredPositional _a
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
        #F2 hasInitializer h @49
          element: <testLibrary>::@topLevelVariable::h
      getters
        #F3 synthetic s
          element: <testLibrary>::@getter::s
          returnType: String
        #F4 synthetic h
          element: <testLibrary>::@getter::h
          returnType: int
      setters
        #F5 synthetic s
          element: <testLibrary>::@setter::s
          formalParameters
            #F6 _s
              element: <testLibrary>::@setter::s::@formalParameter::_s
        #F7 synthetic h
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
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    synthetic static s
      reference: <testLibrary>::@getter::s
      firstFragment: #F3
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    synthetic static h
      reference: <testLibrary>::@getter::h
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    synthetic static s
      reference: <testLibrary>::@setter::s
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _s
          firstFragment: #F6
          type: String
      returnType: void
    synthetic static h
      reference: <testLibrary>::@setter::h
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional _h
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
        #F2 hasInitializer s @15
          element: <testLibrary>::@topLevelVariable::s
        #F3 hasInitializer h @37
          element: <testLibrary>::@topLevelVariable::h
      getters
        #F4 synthetic d
          element: <testLibrary>::@getter::d
          returnType: dynamic
        #F5 synthetic s
          element: <testLibrary>::@getter::s
          returnType: String
        #F6 synthetic h
          element: <testLibrary>::@getter::h
          returnType: int
      setters
        #F7 synthetic d
          element: <testLibrary>::@setter::d
          formalParameters
            #F8 _d
              element: <testLibrary>::@setter::d::@formalParameter::_d
        #F9 synthetic s
          element: <testLibrary>::@setter::s
          formalParameters
            #F10 _s
              element: <testLibrary>::@setter::s::@formalParameter::_s
        #F11 synthetic h
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
      firstFragment: #F2
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasInitializer h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
    synthetic static s
      reference: <testLibrary>::@getter::s
      firstFragment: #F5
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    synthetic static h
      reference: <testLibrary>::@getter::h
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    synthetic static d
      reference: <testLibrary>::@setter::d
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _d
          firstFragment: #F8
          type: dynamic
      returnType: void
    synthetic static s
      reference: <testLibrary>::@setter::s
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _s
          firstFragment: #F10
          type: String
      returnType: void
    synthetic static h
      reference: <testLibrary>::@setter::h
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _h
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
        #F2 hasInitializer b @17
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 synthetic a
          element: <testLibrary>::@getter::a
          returnType: double
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: bool
      setters
        #F5 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F7 synthetic b
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
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: double
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F6
          type: double
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional _b
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
        #F2 hasInitializer vNum @37
          element: <testLibrary>::@topLevelVariable::vNum
        #F3 hasInitializer vNumEmpty @64
          element: <testLibrary>::@topLevelVariable::vNumEmpty
        #F4 hasInitializer vInt @89
          element: <testLibrary>::@topLevelVariable::vInt
      getters
        #F5 synthetic vObject
          element: <testLibrary>::@getter::vObject
          returnType: List<Object>
        #F6 synthetic vNum
          element: <testLibrary>::@getter::vNum
          returnType: List<num>
        #F7 synthetic vNumEmpty
          element: <testLibrary>::@getter::vNumEmpty
          returnType: List<num>
        #F8 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
      setters
        #F9 synthetic vObject
          element: <testLibrary>::@setter::vObject
          formalParameters
            #F10 _vObject
              element: <testLibrary>::@setter::vObject::@formalParameter::_vObject
        #F11 synthetic vNum
          element: <testLibrary>::@setter::vNum
          formalParameters
            #F12 _vNum
              element: <testLibrary>::@setter::vNum::@formalParameter::_vNum
        #F13 synthetic vNumEmpty
          element: <testLibrary>::@setter::vNumEmpty
          formalParameters
            #F14 _vNumEmpty
              element: <testLibrary>::@setter::vNumEmpty::@formalParameter::_vNumEmpty
        #F15 synthetic vInt
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
      firstFragment: #F2
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasInitializer vNumEmpty
      reference: <testLibrary>::@topLevelVariable::vNumEmpty
      firstFragment: #F3
      type: List<num>
      getter: <testLibrary>::@getter::vNumEmpty
      setter: <testLibrary>::@setter::vNumEmpty
    hasInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F4
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
  getters
    synthetic static vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F5
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
    synthetic static vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F6
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    synthetic static vNumEmpty
      reference: <testLibrary>::@getter::vNumEmpty
      firstFragment: #F7
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNumEmpty
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F8
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
  setters
    synthetic static vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional _vObject
          firstFragment: #F10
          type: List<Object>
      returnType: void
    synthetic static vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional _vNum
          firstFragment: #F12
          type: List<num>
      returnType: void
    synthetic static vNumEmpty
      reference: <testLibrary>::@setter::vNumEmpty
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional _vNumEmpty
          firstFragment: #F14
          type: List<num>
      returnType: void
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional _vInt
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
        #F2 hasInitializer vNum @26
          element: <testLibrary>::@topLevelVariable::vNum
        #F3 hasInitializer vObject @47
          element: <testLibrary>::@topLevelVariable::vObject
      getters
        #F4 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
        #F5 synthetic vNum
          element: <testLibrary>::@getter::vNum
          returnType: List<num>
        #F6 synthetic vObject
          element: <testLibrary>::@getter::vObject
          returnType: List<Object>
      setters
        #F7 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F8 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F9 synthetic vNum
          element: <testLibrary>::@setter::vNum
          formalParameters
            #F10 _vNum
              element: <testLibrary>::@setter::vNum::@formalParameter::_vNum
        #F11 synthetic vObject
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
      firstFragment: #F2
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasInitializer vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F3
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F4
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F5
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    synthetic static vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F6
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _vInt
          firstFragment: #F8
          type: List<int>
      returnType: void
    synthetic static vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _vNum
          firstFragment: #F10
          type: List<num>
      returnType: void
    synthetic static vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _vObject
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
        #F2 hasInitializer vComparableObject @50
          element: <testLibrary>::@topLevelVariable::vComparableObject
        #F3 hasInitializer vNumString @109
          element: <testLibrary>::@topLevelVariable::vNumString
        #F4 hasInitializer vNumStringEmpty @149
          element: <testLibrary>::@topLevelVariable::vNumStringEmpty
        #F5 hasInitializer vIntString @188
          element: <testLibrary>::@topLevelVariable::vIntString
      getters
        #F6 synthetic vObjectObject
          element: <testLibrary>::@getter::vObjectObject
          returnType: Map<Object, Object>
        #F7 synthetic vComparableObject
          element: <testLibrary>::@getter::vComparableObject
          returnType: Map<Comparable<int>, Object>
        #F8 synthetic vNumString
          element: <testLibrary>::@getter::vNumString
          returnType: Map<num, String>
        #F9 synthetic vNumStringEmpty
          element: <testLibrary>::@getter::vNumStringEmpty
          returnType: Map<num, String>
        #F10 synthetic vIntString
          element: <testLibrary>::@getter::vIntString
          returnType: Map<int, String>
      setters
        #F11 synthetic vObjectObject
          element: <testLibrary>::@setter::vObjectObject
          formalParameters
            #F12 _vObjectObject
              element: <testLibrary>::@setter::vObjectObject::@formalParameter::_vObjectObject
        #F13 synthetic vComparableObject
          element: <testLibrary>::@setter::vComparableObject
          formalParameters
            #F14 _vComparableObject
              element: <testLibrary>::@setter::vComparableObject::@formalParameter::_vComparableObject
        #F15 synthetic vNumString
          element: <testLibrary>::@setter::vNumString
          formalParameters
            #F16 _vNumString
              element: <testLibrary>::@setter::vNumString::@formalParameter::_vNumString
        #F17 synthetic vNumStringEmpty
          element: <testLibrary>::@setter::vNumStringEmpty
          formalParameters
            #F18 _vNumStringEmpty
              element: <testLibrary>::@setter::vNumStringEmpty::@formalParameter::_vNumStringEmpty
        #F19 synthetic vIntString
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
      firstFragment: #F2
      type: Map<Comparable<int>, Object>
      getter: <testLibrary>::@getter::vComparableObject
      setter: <testLibrary>::@setter::vComparableObject
    hasInitializer vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F3
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasInitializer vNumStringEmpty
      reference: <testLibrary>::@topLevelVariable::vNumStringEmpty
      firstFragment: #F4
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumStringEmpty
      setter: <testLibrary>::@setter::vNumStringEmpty
    hasInitializer vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F5
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
  getters
    synthetic static vObjectObject
      reference: <testLibrary>::@getter::vObjectObject
      firstFragment: #F6
      returnType: Map<Object, Object>
      variable: <testLibrary>::@topLevelVariable::vObjectObject
    synthetic static vComparableObject
      reference: <testLibrary>::@getter::vComparableObject
      firstFragment: #F7
      returnType: Map<Comparable<int>, Object>
      variable: <testLibrary>::@topLevelVariable::vComparableObject
    synthetic static vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F8
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    synthetic static vNumStringEmpty
      reference: <testLibrary>::@getter::vNumStringEmpty
      firstFragment: #F9
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumStringEmpty
    synthetic static vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F10
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
  setters
    synthetic static vObjectObject
      reference: <testLibrary>::@setter::vObjectObject
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional _vObjectObject
          firstFragment: #F12
          type: Map<Object, Object>
      returnType: void
    synthetic static vComparableObject
      reference: <testLibrary>::@setter::vComparableObject
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _vComparableObject
          firstFragment: #F14
          type: Map<Comparable<int>, Object>
      returnType: void
    synthetic static vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional _vNumString
          firstFragment: #F16
          type: Map<num, String>
      returnType: void
    synthetic static vNumStringEmpty
      reference: <testLibrary>::@setter::vNumStringEmpty
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional _vNumStringEmpty
          firstFragment: #F18
          type: Map<num, String>
      returnType: void
    synthetic static vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional _vIntString
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
        #F2 hasInitializer vNumString @39
          element: <testLibrary>::@topLevelVariable::vNumString
        #F3 hasInitializer vIntObject @76
          element: <testLibrary>::@topLevelVariable::vIntObject
      getters
        #F4 synthetic vIntString
          element: <testLibrary>::@getter::vIntString
          returnType: Map<int, String>
        #F5 synthetic vNumString
          element: <testLibrary>::@getter::vNumString
          returnType: Map<num, String>
        #F6 synthetic vIntObject
          element: <testLibrary>::@getter::vIntObject
          returnType: Map<int, Object>
      setters
        #F7 synthetic vIntString
          element: <testLibrary>::@setter::vIntString
          formalParameters
            #F8 _vIntString
              element: <testLibrary>::@setter::vIntString::@formalParameter::_vIntString
        #F9 synthetic vNumString
          element: <testLibrary>::@setter::vNumString
          formalParameters
            #F10 _vNumString
              element: <testLibrary>::@setter::vNumString::@formalParameter::_vNumString
        #F11 synthetic vIntObject
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
      firstFragment: #F2
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasInitializer vIntObject
      reference: <testLibrary>::@topLevelVariable::vIntObject
      firstFragment: #F3
      type: Map<int, Object>
      getter: <testLibrary>::@getter::vIntObject
      setter: <testLibrary>::@setter::vIntObject
  getters
    synthetic static vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F4
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
    synthetic static vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F5
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    synthetic static vIntObject
      reference: <testLibrary>::@getter::vIntObject
      firstFragment: #F6
      returnType: Map<int, Object>
      variable: <testLibrary>::@topLevelVariable::vIntObject
  setters
    synthetic static vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _vIntString
          firstFragment: #F8
          type: Map<int, String>
      returnType: void
    synthetic static vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _vNumString
          firstFragment: #F10
          type: Map<num, String>
      returnType: void
    synthetic static vIntObject
      reference: <testLibrary>::@setter::vIntObject
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _vIntObject
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
        #F2 hasInitializer b @18
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer vEq @32
          element: <testLibrary>::@topLevelVariable::vEq
        #F4 hasInitializer vAnd @50
          element: <testLibrary>::@topLevelVariable::vAnd
        #F5 hasInitializer vOr @69
          element: <testLibrary>::@topLevelVariable::vOr
      getters
        #F6 synthetic a
          element: <testLibrary>::@getter::a
          returnType: bool
        #F7 synthetic b
          element: <testLibrary>::@getter::b
          returnType: bool
        #F8 synthetic vEq
          element: <testLibrary>::@getter::vEq
          returnType: bool
        #F9 synthetic vAnd
          element: <testLibrary>::@getter::vAnd
          returnType: bool
        #F10 synthetic vOr
          element: <testLibrary>::@getter::vOr
          returnType: bool
      setters
        #F11 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F12 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F13 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F14 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
        #F15 synthetic vEq
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F16 _vEq
              element: <testLibrary>::@setter::vEq::@formalParameter::_vEq
        #F17 synthetic vAnd
          element: <testLibrary>::@setter::vAnd
          formalParameters
            #F18 _vAnd
              element: <testLibrary>::@setter::vAnd::@formalParameter::_vAnd
        #F19 synthetic vOr
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
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F3
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasInitializer vAnd
      reference: <testLibrary>::@topLevelVariable::vAnd
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vAnd
      setter: <testLibrary>::@setter::vAnd
    hasInitializer vOr
      reference: <testLibrary>::@topLevelVariable::vOr
      firstFragment: #F5
      type: bool
      getter: <testLibrary>::@getter::vOr
      setter: <testLibrary>::@setter::vOr
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    synthetic static vAnd
      reference: <testLibrary>::@getter::vAnd
      firstFragment: #F9
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vAnd
    synthetic static vOr
      reference: <testLibrary>::@getter::vOr
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vOr
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F12
          type: bool
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional _b
          firstFragment: #F14
          type: bool
      returnType: void
    synthetic static vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional _vEq
          firstFragment: #F16
          type: bool
      returnType: void
    synthetic static vAnd
      reference: <testLibrary>::@setter::vAnd
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional _vAnd
          firstFragment: #F18
          type: bool
      returnType: void
    synthetic static vOr
      reference: <testLibrary>::@setter::vOr
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional _vOr
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
        #F6 hasInitializer v1 @70
          element: <testLibrary>::@topLevelVariable::v1
        #F7 hasInitializer v2 @96
          element: <testLibrary>::@topLevelVariable::v2
      getters
        #F8 synthetic instanceOfA
          element: <testLibrary>::@getter::instanceOfA
          returnType: A
        #F9 synthetic v1
          element: <testLibrary>::@getter::v1
          returnType: String
        #F10 synthetic v2
          element: <testLibrary>::@getter::v2
          returnType: String
      setters
        #F11 synthetic instanceOfA
          element: <testLibrary>::@setter::instanceOfA
          formalParameters
            #F12 _instanceOfA
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::_instanceOfA
        #F13 synthetic v1
          element: <testLibrary>::@setter::v1
          formalParameters
            #F14 _v1
              element: <testLibrary>::@setter::v1::@formalParameter::_v1
        #F15 synthetic v2
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
            #E0 requiredPositional p
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
      firstFragment: #F6
      type: String
      getter: <testLibrary>::@getter::v1
      setter: <testLibrary>::@setter::v1
    hasInitializer v2
      reference: <testLibrary>::@topLevelVariable::v2
      firstFragment: #F7
      type: String
      getter: <testLibrary>::@getter::v2
      setter: <testLibrary>::@setter::v2
  getters
    synthetic static instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F8
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    synthetic static v1
      reference: <testLibrary>::@getter::v1
      firstFragment: #F9
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v1
    synthetic static v2
      reference: <testLibrary>::@getter::v2
      firstFragment: #F10
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v2
  setters
    synthetic static instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional _instanceOfA
          firstFragment: #F12
          type: A
      returnType: void
    synthetic static v1
      reference: <testLibrary>::@setter::v1
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional _v1
          firstFragment: #F14
          type: String
      returnType: void
    synthetic static v2
      reference: <testLibrary>::@setter::v2
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional _v2
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
        #F2 hasInitializer vModuloIntDouble @31
          element: <testLibrary>::@topLevelVariable::vModuloIntDouble
        #F3 hasInitializer vMultiplyIntInt @63
          element: <testLibrary>::@topLevelVariable::vMultiplyIntInt
        #F4 hasInitializer vMultiplyIntDouble @92
          element: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
        #F5 hasInitializer vMultiplyDoubleInt @126
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
        #F6 hasInitializer vMultiplyDoubleDouble @160
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
        #F7 hasInitializer vDivideIntInt @199
          element: <testLibrary>::@topLevelVariable::vDivideIntInt
        #F8 hasInitializer vDivideIntDouble @226
          element: <testLibrary>::@topLevelVariable::vDivideIntDouble
        #F9 hasInitializer vDivideDoubleInt @258
          element: <testLibrary>::@topLevelVariable::vDivideDoubleInt
        #F10 hasInitializer vDivideDoubleDouble @290
          element: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
        #F11 hasInitializer vFloorDivide @327
          element: <testLibrary>::@topLevelVariable::vFloorDivide
      getters
        #F12 synthetic vModuloIntInt
          element: <testLibrary>::@getter::vModuloIntInt
          returnType: int
        #F13 synthetic vModuloIntDouble
          element: <testLibrary>::@getter::vModuloIntDouble
          returnType: double
        #F14 synthetic vMultiplyIntInt
          element: <testLibrary>::@getter::vMultiplyIntInt
          returnType: int
        #F15 synthetic vMultiplyIntDouble
          element: <testLibrary>::@getter::vMultiplyIntDouble
          returnType: double
        #F16 synthetic vMultiplyDoubleInt
          element: <testLibrary>::@getter::vMultiplyDoubleInt
          returnType: double
        #F17 synthetic vMultiplyDoubleDouble
          element: <testLibrary>::@getter::vMultiplyDoubleDouble
          returnType: double
        #F18 synthetic vDivideIntInt
          element: <testLibrary>::@getter::vDivideIntInt
          returnType: double
        #F19 synthetic vDivideIntDouble
          element: <testLibrary>::@getter::vDivideIntDouble
          returnType: double
        #F20 synthetic vDivideDoubleInt
          element: <testLibrary>::@getter::vDivideDoubleInt
          returnType: double
        #F21 synthetic vDivideDoubleDouble
          element: <testLibrary>::@getter::vDivideDoubleDouble
          returnType: double
        #F22 synthetic vFloorDivide
          element: <testLibrary>::@getter::vFloorDivide
          returnType: int
      setters
        #F23 synthetic vModuloIntInt
          element: <testLibrary>::@setter::vModuloIntInt
          formalParameters
            #F24 _vModuloIntInt
              element: <testLibrary>::@setter::vModuloIntInt::@formalParameter::_vModuloIntInt
        #F25 synthetic vModuloIntDouble
          element: <testLibrary>::@setter::vModuloIntDouble
          formalParameters
            #F26 _vModuloIntDouble
              element: <testLibrary>::@setter::vModuloIntDouble::@formalParameter::_vModuloIntDouble
        #F27 synthetic vMultiplyIntInt
          element: <testLibrary>::@setter::vMultiplyIntInt
          formalParameters
            #F28 _vMultiplyIntInt
              element: <testLibrary>::@setter::vMultiplyIntInt::@formalParameter::_vMultiplyIntInt
        #F29 synthetic vMultiplyIntDouble
          element: <testLibrary>::@setter::vMultiplyIntDouble
          formalParameters
            #F30 _vMultiplyIntDouble
              element: <testLibrary>::@setter::vMultiplyIntDouble::@formalParameter::_vMultiplyIntDouble
        #F31 synthetic vMultiplyDoubleInt
          element: <testLibrary>::@setter::vMultiplyDoubleInt
          formalParameters
            #F32 _vMultiplyDoubleInt
              element: <testLibrary>::@setter::vMultiplyDoubleInt::@formalParameter::_vMultiplyDoubleInt
        #F33 synthetic vMultiplyDoubleDouble
          element: <testLibrary>::@setter::vMultiplyDoubleDouble
          formalParameters
            #F34 _vMultiplyDoubleDouble
              element: <testLibrary>::@setter::vMultiplyDoubleDouble::@formalParameter::_vMultiplyDoubleDouble
        #F35 synthetic vDivideIntInt
          element: <testLibrary>::@setter::vDivideIntInt
          formalParameters
            #F36 _vDivideIntInt
              element: <testLibrary>::@setter::vDivideIntInt::@formalParameter::_vDivideIntInt
        #F37 synthetic vDivideIntDouble
          element: <testLibrary>::@setter::vDivideIntDouble
          formalParameters
            #F38 _vDivideIntDouble
              element: <testLibrary>::@setter::vDivideIntDouble::@formalParameter::_vDivideIntDouble
        #F39 synthetic vDivideDoubleInt
          element: <testLibrary>::@setter::vDivideDoubleInt
          formalParameters
            #F40 _vDivideDoubleInt
              element: <testLibrary>::@setter::vDivideDoubleInt::@formalParameter::_vDivideDoubleInt
        #F41 synthetic vDivideDoubleDouble
          element: <testLibrary>::@setter::vDivideDoubleDouble
          formalParameters
            #F42 _vDivideDoubleDouble
              element: <testLibrary>::@setter::vDivideDoubleDouble::@formalParameter::_vDivideDoubleDouble
        #F43 synthetic vFloorDivide
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
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vModuloIntDouble
      setter: <testLibrary>::@setter::vModuloIntDouble
    hasInitializer vMultiplyIntInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vMultiplyIntInt
      setter: <testLibrary>::@setter::vMultiplyIntInt
    hasInitializer vMultiplyIntDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vMultiplyIntDouble
      setter: <testLibrary>::@setter::vMultiplyIntDouble
    hasInitializer vMultiplyDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleInt
      setter: <testLibrary>::@setter::vMultiplyDoubleInt
    hasInitializer vMultiplyDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleDouble
      setter: <testLibrary>::@setter::vMultiplyDoubleDouble
    hasInitializer vDivideIntInt
      reference: <testLibrary>::@topLevelVariable::vDivideIntInt
      firstFragment: #F7
      type: double
      getter: <testLibrary>::@getter::vDivideIntInt
      setter: <testLibrary>::@setter::vDivideIntInt
    hasInitializer vDivideIntDouble
      reference: <testLibrary>::@topLevelVariable::vDivideIntDouble
      firstFragment: #F8
      type: double
      getter: <testLibrary>::@getter::vDivideIntDouble
      setter: <testLibrary>::@setter::vDivideIntDouble
    hasInitializer vDivideDoubleInt
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleInt
      firstFragment: #F9
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleInt
      setter: <testLibrary>::@setter::vDivideDoubleInt
    hasInitializer vDivideDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleDouble
      setter: <testLibrary>::@setter::vDivideDoubleDouble
    hasInitializer vFloorDivide
      reference: <testLibrary>::@topLevelVariable::vFloorDivide
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::vFloorDivide
      setter: <testLibrary>::@setter::vFloorDivide
  getters
    synthetic static vModuloIntInt
      reference: <testLibrary>::@getter::vModuloIntInt
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vModuloIntInt
    synthetic static vModuloIntDouble
      reference: <testLibrary>::@getter::vModuloIntDouble
      firstFragment: #F13
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vModuloIntDouble
    synthetic static vMultiplyIntInt
      reference: <testLibrary>::@getter::vMultiplyIntInt
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntInt
    synthetic static vMultiplyIntDouble
      reference: <testLibrary>::@getter::vMultiplyIntDouble
      firstFragment: #F15
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
    synthetic static vMultiplyDoubleInt
      reference: <testLibrary>::@getter::vMultiplyDoubleInt
      firstFragment: #F16
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
    synthetic static vMultiplyDoubleDouble
      reference: <testLibrary>::@getter::vMultiplyDoubleDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
    synthetic static vDivideIntInt
      reference: <testLibrary>::@getter::vDivideIntInt
      firstFragment: #F18
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntInt
    synthetic static vDivideIntDouble
      reference: <testLibrary>::@getter::vDivideIntDouble
      firstFragment: #F19
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntDouble
    synthetic static vDivideDoubleInt
      reference: <testLibrary>::@getter::vDivideDoubleInt
      firstFragment: #F20
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleInt
    synthetic static vDivideDoubleDouble
      reference: <testLibrary>::@getter::vDivideDoubleDouble
      firstFragment: #F21
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
    synthetic static vFloorDivide
      reference: <testLibrary>::@getter::vFloorDivide
      firstFragment: #F22
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vFloorDivide
  setters
    synthetic static vModuloIntInt
      reference: <testLibrary>::@setter::vModuloIntInt
      firstFragment: #F23
      formalParameters
        #E0 requiredPositional _vModuloIntInt
          firstFragment: #F24
          type: int
      returnType: void
    synthetic static vModuloIntDouble
      reference: <testLibrary>::@setter::vModuloIntDouble
      firstFragment: #F25
      formalParameters
        #E1 requiredPositional _vModuloIntDouble
          firstFragment: #F26
          type: double
      returnType: void
    synthetic static vMultiplyIntInt
      reference: <testLibrary>::@setter::vMultiplyIntInt
      firstFragment: #F27
      formalParameters
        #E2 requiredPositional _vMultiplyIntInt
          firstFragment: #F28
          type: int
      returnType: void
    synthetic static vMultiplyIntDouble
      reference: <testLibrary>::@setter::vMultiplyIntDouble
      firstFragment: #F29
      formalParameters
        #E3 requiredPositional _vMultiplyIntDouble
          firstFragment: #F30
          type: double
      returnType: void
    synthetic static vMultiplyDoubleInt
      reference: <testLibrary>::@setter::vMultiplyDoubleInt
      firstFragment: #F31
      formalParameters
        #E4 requiredPositional _vMultiplyDoubleInt
          firstFragment: #F32
          type: double
      returnType: void
    synthetic static vMultiplyDoubleDouble
      reference: <testLibrary>::@setter::vMultiplyDoubleDouble
      firstFragment: #F33
      formalParameters
        #E5 requiredPositional _vMultiplyDoubleDouble
          firstFragment: #F34
          type: double
      returnType: void
    synthetic static vDivideIntInt
      reference: <testLibrary>::@setter::vDivideIntInt
      firstFragment: #F35
      formalParameters
        #E6 requiredPositional _vDivideIntInt
          firstFragment: #F36
          type: double
      returnType: void
    synthetic static vDivideIntDouble
      reference: <testLibrary>::@setter::vDivideIntDouble
      firstFragment: #F37
      formalParameters
        #E7 requiredPositional _vDivideIntDouble
          firstFragment: #F38
          type: double
      returnType: void
    synthetic static vDivideDoubleInt
      reference: <testLibrary>::@setter::vDivideDoubleInt
      firstFragment: #F39
      formalParameters
        #E8 requiredPositional _vDivideDoubleInt
          firstFragment: #F40
          type: double
      returnType: void
    synthetic static vDivideDoubleDouble
      reference: <testLibrary>::@setter::vDivideDoubleDouble
      firstFragment: #F41
      formalParameters
        #E9 requiredPositional _vDivideDoubleDouble
          firstFragment: #F42
          type: double
      returnType: void
    synthetic static vFloorDivide
      reference: <testLibrary>::@setter::vFloorDivide
      firstFragment: #F43
      formalParameters
        #E10 requiredPositional _vFloorDivide
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
        #F2 hasInitializer vEq @15
          element: <testLibrary>::@topLevelVariable::vEq
        #F3 hasInitializer vNotEq @46
          element: <testLibrary>::@topLevelVariable::vNotEq
      getters
        #F4 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
        #F5 synthetic vEq
          element: <testLibrary>::@getter::vEq
          returnType: bool
        #F6 synthetic vNotEq
          element: <testLibrary>::@getter::vNotEq
          returnType: bool
      setters
        #F7 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F9 synthetic vEq
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F10 _vEq
              element: <testLibrary>::@setter::vEq::@formalParameter::_vEq
        #F11 synthetic vNotEq
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
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasInitializer vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F3
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    synthetic static vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _a
          firstFragment: #F8
          type: int
      returnType: void
    synthetic static vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _vEq
          firstFragment: #F10
          type: bool
      returnType: void
    synthetic static vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _vNotEq
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
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: int
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
        #E0 requiredPositional _V
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
        #F2 hasInitializer vDouble @18
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer vIncInt @37
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer vDecInt @59
          element: <testLibrary>::@topLevelVariable::vDecInt
        #F5 hasInitializer vIncDouble @81
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer vDecDouble @109
          element: <testLibrary>::@topLevelVariable::vDecDouble
      getters
        #F7 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: int
        #F8 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: double
        #F9 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
        #F10 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt
          returnType: int
        #F11 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
        #F12 synthetic vDecDouble
          element: <testLibrary>::@getter::vDecDouble
          returnType: double
      setters
        #F13 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F15 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F17 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F19 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt
          formalParameters
            #F20 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@formalParameter::_vDecInt
        #F21 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F23 synthetic vDecDouble
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
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional _vInt
          firstFragment: #F14
          type: int
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional _vDouble
          firstFragment: #F16
          type: double
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional _vIncInt
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional _vDecInt
          firstFragment: #F20
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional _vIncDouble
          firstFragment: #F22
          type: double
      returnType: void
    synthetic static vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional _vDecDouble
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
        #F2 hasInitializer vDouble @20
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer vIncInt @41
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer vDecInt @66
          element: <testLibrary>::@topLevelVariable::vDecInt
        #F5 hasInitializer vIncDouble @91
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer vDecDouble @122
          element: <testLibrary>::@topLevelVariable::vDecDouble
      getters
        #F7 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
        #F8 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: List<double>
        #F9 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
        #F10 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt
          returnType: int
        #F11 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
        #F12 synthetic vDecDouble
          element: <testLibrary>::@getter::vDecDouble
          returnType: double
      setters
        #F13 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F15 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F17 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F19 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt
          formalParameters
            #F20 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@formalParameter::_vDecInt
        #F21 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F23 synthetic vDecDouble
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
      firstFragment: #F2
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional _vInt
          firstFragment: #F14
          type: List<int>
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional _vDouble
          firstFragment: #F16
          type: List<double>
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional _vIncInt
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional _vDecInt
          firstFragment: #F20
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional _vIncDouble
          firstFragment: #F22
          type: double
      returnType: void
    synthetic static vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional _vDecDouble
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
        #F2 hasInitializer vDouble @18
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer vIncInt @37
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer vDecInt @59
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::0
        #F5 hasInitializer vIncDouble @81
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer vDecInt @109
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      getters
        #F7 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: int
        #F8 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: double
        #F9 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
        #F10 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::0
          returnType: int
        #F11 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
        #F12 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::1
          returnType: double
      setters
        #F13 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F15 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F17 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F19 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt::@def::0
          formalParameters
            #F20 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@def::0::@formalParameter::_vDecInt
        #F21 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F23 synthetic vDecInt
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
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::0
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt::@def::0
      setter: <testLibrary>::@setter::vDecInt::@def::0
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecInt::@def::1
      setter: <testLibrary>::@setter::vDecInt::@def::1
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::0
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::1
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional _vInt
          firstFragment: #F14
          type: int
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional _vDouble
          firstFragment: #F16
          type: double
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional _vIncInt
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::0
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional _vDecInt
          firstFragment: #F20
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional _vIncDouble
          firstFragment: #F22
          type: double
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::1
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional _vDecInt
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
        #F2 hasInitializer vDouble @20
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer vIncInt @41
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer vDecInt @66
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::0
        #F5 hasInitializer vIncDouble @91
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer vDecInt @122
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      getters
        #F7 synthetic vInt
          element: <testLibrary>::@getter::vInt
          returnType: List<int>
        #F8 synthetic vDouble
          element: <testLibrary>::@getter::vDouble
          returnType: List<double>
        #F9 synthetic vIncInt
          element: <testLibrary>::@getter::vIncInt
          returnType: int
        #F10 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::0
          returnType: int
        #F11 synthetic vIncDouble
          element: <testLibrary>::@getter::vIncDouble
          returnType: double
        #F12 synthetic vDecInt
          element: <testLibrary>::@getter::vDecInt::@def::1
          returnType: double
      setters
        #F13 synthetic vInt
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 _vInt
              element: <testLibrary>::@setter::vInt::@formalParameter::_vInt
        #F15 synthetic vDouble
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 _vDouble
              element: <testLibrary>::@setter::vDouble::@formalParameter::_vDouble
        #F17 synthetic vIncInt
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 _vIncInt
              element: <testLibrary>::@setter::vIncInt::@formalParameter::_vIncInt
        #F19 synthetic vDecInt
          element: <testLibrary>::@setter::vDecInt::@def::0
          formalParameters
            #F20 _vDecInt
              element: <testLibrary>::@setter::vDecInt::@def::0::@formalParameter::_vDecInt
        #F21 synthetic vIncDouble
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 _vIncDouble
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::_vIncDouble
        #F23 synthetic vDecInt
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
      firstFragment: #F2
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::0
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt::@def::0
      setter: <testLibrary>::@setter::vDecInt::@def::0
    hasInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecInt::@def::1
      setter: <testLibrary>::@setter::vDecInt::@def::1
  getters
    synthetic static vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    synthetic static vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    synthetic static vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::0
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    synthetic static vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    synthetic static vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::1
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
  setters
    synthetic static vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional _vInt
          firstFragment: #F14
          type: List<int>
      returnType: void
    synthetic static vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional _vDouble
          firstFragment: #F16
          type: List<double>
      returnType: void
    synthetic static vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional _vIncInt
          firstFragment: #F18
          type: int
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::0
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional _vDecInt
          firstFragment: #F20
          type: int
      returnType: void
    synthetic static vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional _vIncDouble
          firstFragment: #F22
          type: double
      returnType: void
    synthetic static vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::1
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional _vDecInt
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
      getters
        #F2 synthetic vNot
          element: <testLibrary>::@getter::vNot
          returnType: bool
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
        #E0 requiredPositional _vNot
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
        #F2 hasInitializer vNegateDouble @25
          element: <testLibrary>::@topLevelVariable::vNegateDouble
        #F3 hasInitializer vComplement @51
          element: <testLibrary>::@topLevelVariable::vComplement
      getters
        #F4 synthetic vNegateInt
          element: <testLibrary>::@getter::vNegateInt
          returnType: int
        #F5 synthetic vNegateDouble
          element: <testLibrary>::@getter::vNegateDouble
          returnType: double
        #F6 synthetic vComplement
          element: <testLibrary>::@getter::vComplement
          returnType: int
      setters
        #F7 synthetic vNegateInt
          element: <testLibrary>::@setter::vNegateInt
          formalParameters
            #F8 _vNegateInt
              element: <testLibrary>::@setter::vNegateInt::@formalParameter::_vNegateInt
        #F9 synthetic vNegateDouble
          element: <testLibrary>::@setter::vNegateDouble
          formalParameters
            #F10 _vNegateDouble
              element: <testLibrary>::@setter::vNegateDouble::@formalParameter::_vNegateDouble
        #F11 synthetic vComplement
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
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vNegateDouble
      setter: <testLibrary>::@setter::vNegateDouble
    hasInitializer vComplement
      reference: <testLibrary>::@topLevelVariable::vComplement
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vComplement
      setter: <testLibrary>::@setter::vComplement
  getters
    synthetic static vNegateInt
      reference: <testLibrary>::@getter::vNegateInt
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vNegateInt
    synthetic static vNegateDouble
      reference: <testLibrary>::@getter::vNegateDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vNegateDouble
    synthetic static vComplement
      reference: <testLibrary>::@getter::vComplement
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vComplement
  setters
    synthetic static vNegateInt
      reference: <testLibrary>::@setter::vNegateInt
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional _vNegateInt
          firstFragment: #F8
          type: int
      returnType: void
    synthetic static vNegateDouble
      reference: <testLibrary>::@setter::vNegateDouble
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional _vNegateDouble
          firstFragment: #F10
          type: double
      returnType: void
    synthetic static vComplement
      reference: <testLibrary>::@setter::vComplement
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional _vComplement
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic d
              element: <testLibrary>::@class::C::@getter::d
              returnType: D
          setters
            #F5 synthetic d
              element: <testLibrary>::@class::C::@setter::d
              formalParameters
                #F6 _d
                  element: <testLibrary>::@class::C::@setter::d::@formalParameter::_d
        #F7 class D @32
          element: <testLibrary>::@class::D
          fields
            #F8 i @42
              element: <testLibrary>::@class::D::@field::i
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F10 synthetic i
              element: <testLibrary>::@class::D::@getter::i
              returnType: int
          setters
            #F11 synthetic i
              element: <testLibrary>::@class::D::@setter::i
              formalParameters
                #F12 _i
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::_i
      topLevelVariables
        #F13 hasInitializer x @53
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F14 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
          firstFragment: #F3
      getters
        synthetic static d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F4
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
      setters
        synthetic static d
          reference: <testLibrary>::@class::C::@setter::d
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _d
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
          firstFragment: #F9
      getters
        synthetic i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        synthetic i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _i
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 d @25
              element: <testLibrary>::@class::C::@getter::d
              returnType: D
        #F5 class D @44
          element: <testLibrary>::@class::D
          fields
            #F6 i @54
              element: <testLibrary>::@class::D::@field::i
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F8 synthetic i
              element: <testLibrary>::@class::D::@getter::i
              returnType: int
          setters
            #F9 synthetic i
              element: <testLibrary>::@class::D::@setter::i
              formalParameters
                #F10 _i
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::_i
      topLevelVariables
        #F11 hasInitializer x @63
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F12 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
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
          firstFragment: #F3
      getters
        static d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F4
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
          firstFragment: #F7
      getters
        synthetic i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        synthetic i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional _i
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
        #E1 requiredPositional _x
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
        #F2 hasInitializer vLessOrEqual @23
          element: <testLibrary>::@topLevelVariable::vLessOrEqual
        #F3 hasInitializer vGreater @50
          element: <testLibrary>::@topLevelVariable::vGreater
        #F4 hasInitializer vGreaterOrEqual @72
          element: <testLibrary>::@topLevelVariable::vGreaterOrEqual
      getters
        #F5 synthetic vLess
          element: <testLibrary>::@getter::vLess
          returnType: bool
        #F6 synthetic vLessOrEqual
          element: <testLibrary>::@getter::vLessOrEqual
          returnType: bool
        #F7 synthetic vGreater
          element: <testLibrary>::@getter::vGreater
          returnType: bool
        #F8 synthetic vGreaterOrEqual
          element: <testLibrary>::@getter::vGreaterOrEqual
          returnType: bool
      setters
        #F9 synthetic vLess
          element: <testLibrary>::@setter::vLess
          formalParameters
            #F10 _vLess
              element: <testLibrary>::@setter::vLess::@formalParameter::_vLess
        #F11 synthetic vLessOrEqual
          element: <testLibrary>::@setter::vLessOrEqual
          formalParameters
            #F12 _vLessOrEqual
              element: <testLibrary>::@setter::vLessOrEqual::@formalParameter::_vLessOrEqual
        #F13 synthetic vGreater
          element: <testLibrary>::@setter::vGreater
          formalParameters
            #F14 _vGreater
              element: <testLibrary>::@setter::vGreater::@formalParameter::_vGreater
        #F15 synthetic vGreaterOrEqual
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
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::vLessOrEqual
      setter: <testLibrary>::@setter::vLessOrEqual
    hasInitializer vGreater
      reference: <testLibrary>::@topLevelVariable::vGreater
      firstFragment: #F3
      type: bool
      getter: <testLibrary>::@getter::vGreater
      setter: <testLibrary>::@setter::vGreater
    hasInitializer vGreaterOrEqual
      reference: <testLibrary>::@topLevelVariable::vGreaterOrEqual
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vGreaterOrEqual
      setter: <testLibrary>::@setter::vGreaterOrEqual
  getters
    synthetic static vLess
      reference: <testLibrary>::@getter::vLess
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLess
    synthetic static vLessOrEqual
      reference: <testLibrary>::@getter::vLessOrEqual
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLessOrEqual
    synthetic static vGreater
      reference: <testLibrary>::@getter::vGreater
      firstFragment: #F7
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreater
    synthetic static vGreaterOrEqual
      reference: <testLibrary>::@getter::vGreaterOrEqual
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreaterOrEqual
  setters
    synthetic static vLess
      reference: <testLibrary>::@setter::vLess
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional _vLess
          firstFragment: #F10
          type: bool
      returnType: void
    synthetic static vLessOrEqual
      reference: <testLibrary>::@setter::vLessOrEqual
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional _vLessOrEqual
          firstFragment: #F12
          type: bool
      returnType: void
    synthetic static vGreater
      reference: <testLibrary>::@setter::vGreater
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional _vGreater
          firstFragment: #F14
          type: bool
      returnType: void
    synthetic static vGreaterOrEqual
      reference: <testLibrary>::@setter::vGreaterOrEqual
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional _vGreaterOrEqual
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
          setters
            #F5 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @36
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F10 x @59
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
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _x
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
          type: InvalidType
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      setters
        x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
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
          constructors
            #F3 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 25
              formalParameters
                #F4 this.f @33
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
                  initializer: expression_0
                    SimpleStringLiteral
                      literal: 'hello' @37
          getters
            #F5 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
          setters
            #F6 synthetic f
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
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasImplicitType f
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional _f
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
            #F3 y @34
              element: <testLibrary>::@class::A::@field::y
            #F4 z @43
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
            #F7 synthetic y
              element: <testLibrary>::@class::A::@getter::y
              returnType: int
            #F8 synthetic z
              element: <testLibrary>::@class::A::@getter::z
              returnType: int
          setters
            #F9 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F10 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
            #F11 synthetic y
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F12 _y
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_y
            #F13 synthetic z
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F14 _z
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_z
        #F15 class B @54
          element: <testLibrary>::@class::B
          fields
            #F16 x @77
              element: <testLibrary>::@class::B::@field::x
            #F17 synthetic y
              element: <testLibrary>::@class::B::@field::y
            #F18 synthetic z
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F19 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F20 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
            #F21 y @86
              element: <testLibrary>::@class::B::@getter::y
              returnType: int
          setters
            #F22 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F23 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F24 z @103
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
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        synthetic y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        synthetic z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional _x
              firstFragment: #F10
              type: int
          returnType: void
        synthetic y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _y
              firstFragment: #F12
              type: int
          returnType: void
        synthetic z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F13
          formalParameters
            #E2 requiredPositional _z
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
          firstFragment: #F17
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
          firstFragment: #F19
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F20
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F21
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F22
          formalParameters
            #E3 requiredPositional _x
              firstFragment: #F23
              type: int
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F24
          formalParameters
            #E4 requiredPositional hasImplicitType _
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic
          setters
            #F5 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @40
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer x @63
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic
          setters
            #F11 synthetic x
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
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _x
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
          firstFragment: #F9
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _x
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
            #F4 y @33
              element: <testLibrary>::@class::A::@field::y
            #F5 z @40
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F7 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: E
            #F8 synthetic y
              element: <testLibrary>::@class::A::@getter::y
              returnType: E
            #F9 synthetic z
              element: <testLibrary>::@class::A::@getter::z
              returnType: E
          setters
            #F10 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F11 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
            #F12 synthetic y
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F13 _y
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_y
            #F14 synthetic z
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
            #F19 synthetic y
              element: <testLibrary>::@class::B::@field::y
            #F20 synthetic z
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F21 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F22 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: T
            #F23 y @89
              element: <testLibrary>::@class::B::@getter::y
              returnType: T
          setters
            #F24 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F25 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F26 z @106
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
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        synthetic y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        synthetic z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional _x
              firstFragment: #F11
              type: E
          returnType: void
        synthetic y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional _y
              firstFragment: #F13
              type: E
          returnType: void
        synthetic z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F14
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E4 requiredPositional _z
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
          firstFragment: #F19
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F20
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F21
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F22
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F23
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F24
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E5 requiredPositional _x
              firstFragment: #F25
              type: T
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F26
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E6 requiredPositional hasImplicitType _
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic
          setters
            #F5 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @36
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer x @59
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic
          setters
            #F11 synthetic x
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
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _x
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
          firstFragment: #F9
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: num
          setters
            #F5 synthetic x
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_x
        #F7 class B @36
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer x @59
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: num
          setters
            #F11 synthetic x
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
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _x
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
          firstFragment: #F9
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: num
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _x
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
            #F3 synthetic y
              element: <testLibrary>::@class::A::@field::y
            #F4 synthetic z
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
            #F7 y @42
              element: <testLibrary>::@class::A::@getter::y
              returnType: int
            #F8 z @55
              element: <testLibrary>::@class::A::@getter::z
              returnType: int
        #F9 class B @66
          element: <testLibrary>::@class::B
          fields
            #F10 x @89
              element: <testLibrary>::@class::B::@field::x
            #F11 synthetic y
              element: <testLibrary>::@class::B::@field::y
            #F12 synthetic z
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F14 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
            #F15 y @98
              element: <testLibrary>::@class::B::@getter::y
              returnType: int
          setters
            #F16 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F17 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F18 z @115
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
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::y
        synthetic z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        abstract y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        abstract z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F8
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
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F12
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F13
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F16
          formalParameters
            #E0 requiredPositional _x
              firstFragment: #F17
              type: int
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F18
          formalParameters
            #E1 requiredPositional hasImplicitType _
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
            #F4 synthetic y
              element: <testLibrary>::@class::A::@field::y
            #F5 synthetic z
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F7 x @30
              element: <testLibrary>::@class::A::@getter::x
              returnType: E
            #F8 y @41
              element: <testLibrary>::@class::A::@getter::y
              returnType: E
            #F9 z @52
              element: <testLibrary>::@class::A::@getter::z
              returnType: E
        #F10 class B @63
          element: <testLibrary>::@class::B
          typeParameters
            #F11 T @65
              element: #E1 T
          fields
            #F12 x @92
              element: <testLibrary>::@class::B::@field::x
            #F13 synthetic y
              element: <testLibrary>::@class::B::@field::y
            #F14 synthetic z
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F15 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F16 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: T
            #F17 y @101
              element: <testLibrary>::@class::B::@getter::y
              returnType: T
          setters
            #F18 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F19 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F20 z @118
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
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::y
        synthetic z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        abstract y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        abstract z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
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
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        synthetic z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F14
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F15
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F16
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F17
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F18
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional _x
              firstFragment: #F19
              type: T
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F20
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional hasImplicitType _
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 x @66
              element: <testLibrary>::@class::B::@getter::x
              returnType: String
        #F9 class C @77
          element: <testLibrary>::@class::C
          fields
            #F10 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 x @103
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F8
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
          firstFragment: #F11
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 x @67
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic
        #F9 class C @78
          element: <testLibrary>::@class::C
          fields
            #F10 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 x @104
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F8
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
          firstFragment: #F11
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
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
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 x @30
              element: <testLibrary>::@class::A::@getter::x
              returnType: T
        #F6 class B @50
          element: <testLibrary>::@class::B
          typeParameters
            #F7 T @52
              element: #E1 T
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 x @65
              element: <testLibrary>::@class::B::@getter::x
              returnType: T
        #F11 class C @76
          element: <testLibrary>::@class::C
          fields
            #F12 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F14 x @115
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
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
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F5
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
          firstFragment: #F9
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
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
          firstFragment: #F13
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F14
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 x @63
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
        #F9 class C @74
          element: <testLibrary>::@class::C
          fields
            #F10 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 x @100
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      getters
        abstract x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F8
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
          firstFragment: #F11
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
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
            #F3 synthetic y
              element: <testLibrary>::@class::A::@field::y
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
            #F6 y @42
              element: <testLibrary>::@class::A::@getter::y
              returnType: int
        #F7 class B @62
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
            #F9 synthetic y
              element: <testLibrary>::@class::B::@field::y
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F11 x @77
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 _ @86
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
            #F13 y @101
              element: <testLibrary>::@class::B::@setter::y
              formalParameters
                #F14 _ @110
                  element: <testLibrary>::@class::B::@setter::y::@formalParameter::_
        #F15 class C @122
          element: <testLibrary>::@class::C
          fields
            #F16 x @148
              element: <testLibrary>::@class::C::@field::x
            #F17 y @159
              element: <testLibrary>::@class::C::@field::y
          constructors
            #F18 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F19 synthetic x
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
            #F20 synthetic y
              element: <testLibrary>::@class::C::@getter::y
              returnType: int
          setters
            #F21 synthetic x
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
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        abstract y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
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
          firstFragment: #F9
          type: String
          setter: <testLibrary>::@class::B::@setter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F12
              type: String
          returnType: void
        abstract y
          reference: <testLibrary>::@class::B::@setter::y
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional _
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
          firstFragment: #F17
          type: int
          getter: <testLibrary>::@class::C::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F18
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F19
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
          firstFragment: #F21
          formalParameters
            #E2 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @73
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @85
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 x @111
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F12
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @73
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @85
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F13 x @111
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F12
      setters
        abstract x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional hasImplicitType _
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @70
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @82
          element: <testLibrary>::@class::C
          fields
            #F11 x @108
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 synthetic x
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
          setters
            #F14 synthetic x
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F12
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F14
          formalParameters
            #E1 requiredPositional _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @70
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @82
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 x @108
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F12
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: int
        #F5 class B @49
          element: <testLibrary>::@class::B
          fields
            #F6 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 x @64
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 _ @70
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C @82
          element: <testLibrary>::@class::C
          fields
            #F11 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F13 x @108
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
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
          firstFragment: #F7
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F12
      setters
        abstract x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional hasImplicitType _
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
            #F3 synthetic y
              element: <testLibrary>::@class::A::@field::y
            #F4 synthetic z
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F6 x @30
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F7 _ @36
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
            #F8 y @51
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F9 _ @57
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_
            #F10 z @72
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F11 _ @78
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_
        #F12 class B @90
          element: <testLibrary>::@class::B
          fields
            #F13 x @113
              element: <testLibrary>::@class::B::@field::x
            #F14 synthetic y
              element: <testLibrary>::@class::B::@field::y
            #F15 synthetic z
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F16 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F17 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
            #F18 y @122
              element: <testLibrary>::@class::B::@getter::y
              returnType: int
          setters
            #F19 synthetic x
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F20 _x
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_x
            #F21 z @139
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
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::y
        synthetic z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
        abstract y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
        abstract z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F10
          formalParameters
            #E2 requiredPositional _
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
          firstFragment: #F14
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
          firstFragment: #F16
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F18
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F19
          formalParameters
            #E3 requiredPositional _x
              firstFragment: #F20
              type: int
          returnType: void
        z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F21
          formalParameters
            #E4 requiredPositional hasImplicitType _
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 x @30
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 _ @36
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 class B @57
          element: <testLibrary>::@class::B
          fields
            #F7 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 x @72
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 _ @81
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F11 class C @93
          element: <testLibrary>::@class::C
          fields
            #F12 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F14 x @119
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
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
          firstFragment: #F3
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
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
          firstFragment: #F13
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F14
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 x @30
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 _ @36
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 class B @57
          element: <testLibrary>::@class::B
          fields
            #F7 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 x @72
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 _ @78
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F11 class C @90
          element: <testLibrary>::@class::C
          fields
            #F12 synthetic x
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F14 x @116
              element: <testLibrary>::@class::C::@getter::x
              returnType: int
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
          firstFragment: #F3
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
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
          firstFragment: #F8
      setters
        abstract x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
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
          firstFragment: #F13
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F14
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
            #F4 synthetic y
              element: <testLibrary>::@class::A::@field::y
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 x @41
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic Function()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    T
            #F7 y @69
              element: <testLibrary>::@class::A::@getter::y
              returnType: List<dynamic Function()>
        #F8 class B @89
          element: <testLibrary>::@class::B
          fields
            #F9 synthetic x
              element: <testLibrary>::@class::B::@field::x
            #F10 synthetic y
              element: <testLibrary>::@class::B::@field::y
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F12 x @114
              element: <testLibrary>::@class::B::@getter::x
              returnType: dynamic Function()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    int
            #F13 y @131
              element: <testLibrary>::@class::B::@getter::y
              returnType: List<dynamic Function()>
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
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          variable: <testLibrary>::@class::A::@field::x
        y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
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
          firstFragment: #F10
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::B::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
      getters
        x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F12
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
          variable: <testLibrary>::@class::B::@field::x
        y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F13
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: num
          setters
            #F5 x @43
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _ @59
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B @71
          element: <testLibrary>::@class::B
          fields
            #F8 x @94
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic x
              element: <testLibrary>::@class::B::@getter::x
              returnType: int
          setters
            #F11 synthetic x
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional covariant _
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
          firstFragment: #F9
      getters
        synthetic x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional covariant _x
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 x @29
              element: <testLibrary>::@class::A::@getter::x
              returnType: num
          setters
            #F5 x @43
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 _ @59
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B @71
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic x
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F10 x @94
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
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        abstract x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional covariant _
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
          firstFragment: #F9
      setters
        x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional covariant _
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
            #F3 hasInitializer t2 @30
              element: <testLibrary>::@class::A::@field::t2
            #F4 hasInitializer t3 @46
              element: <testLibrary>::@class::A::@field::t3
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic t1
              element: <testLibrary>::@class::A::@getter::t1
              returnType: int
            #F7 synthetic t2
              element: <testLibrary>::@class::A::@getter::t2
              returnType: double
            #F8 synthetic t3
              element: <testLibrary>::@class::A::@getter::t3
              returnType: dynamic
          setters
            #F9 synthetic t1
              element: <testLibrary>::@class::A::@setter::t1
              formalParameters
                #F10 _t1
                  element: <testLibrary>::@class::A::@setter::t1::@formalParameter::_t1
            #F11 synthetic t2
              element: <testLibrary>::@class::A::@setter::t2
              formalParameters
                #F12 _t2
                  element: <testLibrary>::@class::A::@setter::t2::@formalParameter::_t2
            #F13 synthetic t3
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
          firstFragment: #F3
          type: double
          getter: <testLibrary>::@class::A::@getter::t2
          setter: <testLibrary>::@class::A::@setter::t2
        hasInitializer t3
          reference: <testLibrary>::@class::A::@field::t3
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::t3
          setter: <testLibrary>::@class::A::@setter::t3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic t1
          reference: <testLibrary>::@class::A::@getter::t1
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::t1
        synthetic t2
          reference: <testLibrary>::@class::A::@getter::t2
          firstFragment: #F7
          returnType: double
          variable: <testLibrary>::@class::A::@field::t2
        synthetic t3
          reference: <testLibrary>::@class::A::@getter::t3
          firstFragment: #F8
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::t3
      setters
        synthetic t1
          reference: <testLibrary>::@class::A::@setter::t1
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional _t1
              firstFragment: #F10
              type: int
          returnType: void
        synthetic t2
          reference: <testLibrary>::@class::A::@setter::t2
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _t2
              firstFragment: #F12
              type: double
          returnType: void
        synthetic t3
          reference: <testLibrary>::@class::A::@setter::t3
          firstFragment: #F13
          formalParameters
            #E2 requiredPositional _t3
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
            #E2 requiredPositional hasImplicitType b
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
            #E0 requiredPositional a
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
            #E1 requiredPositional a
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
            #E2 requiredPositional hasImplicitType a
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
            #E0 requiredPositional x
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
            #E1 requiredPositional x
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
            #E2 requiredPositional hasImplicitType x
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
            #E2 requiredPositional a
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
            #E3 requiredPositional a
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F13
          formalParameters
            #E4 requiredPositional hasImplicitType a
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
            #E3 requiredPositional a
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
            #E4 requiredPositional a
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: String}
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F14
          formalParameters
            #E5 requiredPositional hasImplicitType a
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
                #F9 b @59
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
            #E2 optionalNamed hasImplicitType b
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
                #F9 b @59
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F8
              type: int
            #E2 optionalPositional hasImplicitType b
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
            #E0 requiredPositional hasImplicitType a
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
            #E1 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic m
              element: <testLibrary>::@class::A::@getter::m
              returnType: int
          setters
            #F5 synthetic m
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
          firstFragment: #F3
      getters
        synthetic m
          reference: <testLibrary>::@class::A::@getter::m
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::m
      setters
        synthetic m
          reference: <testLibrary>::@class::A::@setter::m
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _m
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
            #E1 requiredPositional hasImplicitType a
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
            #E3 requiredPositional a
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: T}
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      supertype: B<String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {T: String}
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F12
          formalParameters
            #E4 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
            #E2 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
            #E2 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
            #E2 requiredPositional hasImplicitType a
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
            #E2 requiredPositional a
              firstFragment: #F6
              type: K
            #E3 requiredPositional b
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: String}
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F10
          formalParameters
            #E4 requiredPositional hasImplicitType a
              firstFragment: #F11
              type: int
            #E5 requiredPositional hasImplicitType b
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
                #F5 b @36
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
                #F10 b @73
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
            #E0 requiredPositional a
              firstFragment: #F4
              type: int
            #E1 optionalNamed b
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
            #E2 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: int
            #E3 optionalNamed hasImplicitType b
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
                #F5 b @36
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
                #F10 b @73
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
            #E0 requiredPositional a
              firstFragment: #F4
              type: int
            #E1 optionalPositional b
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
            #E2 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: int
            #E3 optionalPositional hasImplicitType b
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
            #E3 requiredPositional a
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: T}
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      supertype: B<String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {T: String}
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F12
          formalParameters
            #E4 requiredPositional hasImplicitType a
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
            #E2 requiredPositional a
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
            #E3 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
            #E4 requiredPositional a
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: T2, V: T1}
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
            #E5 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional hasImplicitType a
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
            #E3 requiredPositional a
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
            #E4 requiredPositional a
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: String}
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F14
          formalParameters
            #E5 requiredPositional hasImplicitType a
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
            #E0 requiredPositional a
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
            #E1 requiredPositional a
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
            #E2 requiredPositional hasImplicitType a
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
