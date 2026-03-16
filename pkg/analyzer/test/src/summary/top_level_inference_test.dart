// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
      [error(diag.topLevelCycle, 4, 1), error(diag.topLevelCycle, 15, 1)],
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
          diag.invalidOverride,
          109,
          3,
          contextMessages: [message(testFile, 64, 3)],
        ),
        error(
          diag.invalidOverride,
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
      [error(diag.noCombinedSuperSignature, 116, 3)],
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
        #F1 hasInitializer isOriginDeclaration vPlusIntInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vPlusIntInt
        #F2 hasInitializer isOriginDeclaration vPlusIntDouble (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::vPlusIntDouble
        #F3 hasInitializer isOriginDeclaration vPlusDoubleInt (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::vPlusDoubleInt
        #F4 hasInitializer isOriginDeclaration vPlusDoubleDouble (nameOffset:89) (firstTokenOffset:89) (offset:89)
          element: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
        #F5 hasInitializer isOriginDeclaration vMinusIntInt (nameOffset:124) (firstTokenOffset:124) (offset:124)
          element: <testLibrary>::@topLevelVariable::vMinusIntInt
        #F6 hasInitializer isOriginDeclaration vMinusIntDouble (nameOffset:150) (firstTokenOffset:150) (offset:150)
          element: <testLibrary>::@topLevelVariable::vMinusIntDouble
        #F7 hasInitializer isOriginDeclaration vMinusDoubleInt (nameOffset:181) (firstTokenOffset:181) (offset:181)
          element: <testLibrary>::@topLevelVariable::vMinusDoubleInt
        #F8 hasInitializer isOriginDeclaration vMinusDoubleDouble (nameOffset:212) (firstTokenOffset:212) (offset:212)
          element: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
      getters
        #F9 isOriginVariable vPlusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vPlusIntInt
        #F10 isOriginVariable vPlusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::vPlusIntDouble
        #F11 isOriginVariable vPlusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::vPlusDoubleInt
        #F12 isOriginVariable vPlusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@getter::vPlusDoubleDouble
        #F13 isOriginVariable vMinusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
          element: <testLibrary>::@getter::vMinusIntInt
        #F14 isOriginVariable vMinusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:150)
          element: <testLibrary>::@getter::vMinusIntDouble
        #F15 isOriginVariable vMinusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
          element: <testLibrary>::@getter::vMinusDoubleInt
        #F16 isOriginVariable vMinusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:212)
          element: <testLibrary>::@getter::vMinusDoubleDouble
      setters
        #F17 isOriginVariable vPlusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vPlusIntInt
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vPlusIntInt::@formalParameter::value
        #F19 isOriginVariable vPlusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::vPlusIntDouble
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::vPlusIntDouble::@formalParameter::value
        #F21 isOriginVariable vPlusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::vPlusDoubleInt
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::vPlusDoubleInt::@formalParameter::value
        #F23 isOriginVariable vPlusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@setter::vPlusDoubleDouble
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@setter::vPlusDoubleDouble::@formalParameter::value
        #F25 isOriginVariable vMinusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
          element: <testLibrary>::@setter::vMinusIntInt
          formalParameters
            #F26 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
              element: <testLibrary>::@setter::vMinusIntInt::@formalParameter::value
        #F27 isOriginVariable vMinusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:150)
          element: <testLibrary>::@setter::vMinusIntDouble
          formalParameters
            #F28 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:150)
              element: <testLibrary>::@setter::vMinusIntDouble::@formalParameter::value
        #F29 isOriginVariable vMinusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
          element: <testLibrary>::@setter::vMinusDoubleInt
          formalParameters
            #F30 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
              element: <testLibrary>::@setter::vMinusDoubleInt::@formalParameter::value
        #F31 isOriginVariable vMinusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:212)
          element: <testLibrary>::@setter::vMinusDoubleDouble
          formalParameters
            #F32 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:212)
              element: <testLibrary>::@setter::vMinusDoubleDouble::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vPlusIntInt
      reference: <testLibrary>::@topLevelVariable::vPlusIntInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vPlusIntInt
      setter: <testLibrary>::@setter::vPlusIntInt
    hasImplicitType hasInitializer isOriginDeclaration vPlusIntDouble
      reference: <testLibrary>::@topLevelVariable::vPlusIntDouble
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vPlusIntDouble
      setter: <testLibrary>::@setter::vPlusIntDouble
    hasImplicitType hasInitializer isOriginDeclaration vPlusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleInt
      firstFragment: #F3
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleInt
      setter: <testLibrary>::@setter::vPlusDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration vPlusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleDouble
      setter: <testLibrary>::@setter::vPlusDoubleDouble
    hasImplicitType hasInitializer isOriginDeclaration vMinusIntInt
      reference: <testLibrary>::@topLevelVariable::vMinusIntInt
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::vMinusIntInt
      setter: <testLibrary>::@setter::vMinusIntInt
    hasImplicitType hasInitializer isOriginDeclaration vMinusIntDouble
      reference: <testLibrary>::@topLevelVariable::vMinusIntDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vMinusIntDouble
      setter: <testLibrary>::@setter::vMinusIntDouble
    hasImplicitType hasInitializer isOriginDeclaration vMinusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleInt
      firstFragment: #F7
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleInt
      setter: <testLibrary>::@setter::vMinusDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration vMinusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
      firstFragment: #F8
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleDouble
      setter: <testLibrary>::@setter::vMinusDoubleDouble
  getters
    static isOriginVariable vPlusIntInt
      reference: <testLibrary>::@getter::vPlusIntInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vPlusIntInt
    static isOriginVariable vPlusIntDouble
      reference: <testLibrary>::@getter::vPlusIntDouble
      firstFragment: #F10
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusIntDouble
    static isOriginVariable vPlusDoubleInt
      reference: <testLibrary>::@getter::vPlusDoubleInt
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleInt
    static isOriginVariable vPlusDoubleDouble
      reference: <testLibrary>::@getter::vPlusDoubleDouble
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
    static isOriginVariable vMinusIntInt
      reference: <testLibrary>::@getter::vMinusIntInt
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMinusIntInt
    static isOriginVariable vMinusIntDouble
      reference: <testLibrary>::@getter::vMinusIntDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusIntDouble
    static isOriginVariable vMinusDoubleInt
      reference: <testLibrary>::@getter::vMinusDoubleInt
      firstFragment: #F15
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleInt
    static isOriginVariable vMinusDoubleDouble
      reference: <testLibrary>::@getter::vMinusDoubleDouble
      firstFragment: #F16
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
  setters
    static isOriginVariable vPlusIntInt
      reference: <testLibrary>::@setter::vPlusIntInt
      firstFragment: #F17
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusIntInt
    static isOriginVariable vPlusIntDouble
      reference: <testLibrary>::@setter::vPlusIntDouble
      firstFragment: #F19
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusIntDouble
    static isOriginVariable vPlusDoubleInt
      reference: <testLibrary>::@setter::vPlusDoubleInt
      firstFragment: #F21
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F22
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleInt
    static isOriginVariable vPlusDoubleDouble
      reference: <testLibrary>::@setter::vPlusDoubleDouble
      firstFragment: #F23
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
    static isOriginVariable vMinusIntInt
      reference: <testLibrary>::@setter::vMinusIntInt
      firstFragment: #F25
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F26
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusIntInt
    static isOriginVariable vMinusIntDouble
      reference: <testLibrary>::@setter::vMinusIntDouble
      firstFragment: #F27
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F28
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusIntDouble
    static isOriginVariable vMinusDoubleInt
      reference: <testLibrary>::@setter::vMinusDoubleInt
      firstFragment: #F29
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F30
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleInt
    static isOriginVariable vMinusDoubleDouble
      reference: <testLibrary>::@setter::vMinusDoubleDouble
      firstFragment: #F31
      formalParameters
        #E7 requiredPositional value
          firstFragment: #F32
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
      setters
        #F3 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: num
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::V
  setters
    static isOriginVariable V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration t1 (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::t1
        #F3 hasInitializer isOriginDeclaration t2 (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F5 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::t1
        #F6 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@getter::t2
      setters
        #F7 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F9 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::t1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F11 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@setter::t2
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t2
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration t1 (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::t1
        #F3 hasInitializer isOriginDeclaration t2 (nameOffset:38) (firstTokenOffset:38) (offset:38)
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F5 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::t1
        #F6 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@getter::t2
      setters
        #F7 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F9 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::t1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F11 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@setter::t2
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t2
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration a (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::a
        #F8 hasInitializer isOriginDeclaration t1 (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::t1
        #F9 hasInitializer isOriginDeclaration t2 (nameOffset:62) (firstTokenOffset:62) (offset:62)
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F10 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::a
        #F11 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::t1
        #F12 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@getter::t2
      setters
        #F13 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::a
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F15 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::t1
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F17 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@setter::t2
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F8
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F9
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F10
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t2
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
        #F1 class I (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::I
          fields
            #F2 isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::I::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::I::@setter::f::@formalParameter::value
        #F7 class C (nameOffset:36) (firstTokenOffset:21) (offset:36)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 isOriginDeclaration c (nameOffset:56) (firstTokenOffset:56) (offset:56)
          element: <testLibrary>::@topLevelVariable::c
        #F10 hasInitializer isOriginDeclaration t1 (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::t1
        #F11 hasInitializer isOriginDeclaration t2 (nameOffset:83) (firstTokenOffset:83) (offset:83)
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F12 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
          element: <testLibrary>::@getter::c
        #F13 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::t1
        #F14 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
          element: <testLibrary>::@getter::t2
      setters
        #F15 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
          element: <testLibrary>::@setter::c
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F17 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@setter::t1
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F19 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
          element: <testLibrary>::@setter::t2
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  classes
    hasNonFinalField class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        isOriginDeclaration f
          reference: <testLibrary>::@class::I::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::I::@getter::f
          setter: <testLibrary>::@class::I::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::I::@field::f
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F9
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    static isOriginVariable c
      reference: <testLibrary>::@setter::c
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t2
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
        #F1 class I (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::I
          fields
            #F2 isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::I::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::I::@setter::f::@formalParameter::value
        #F7 class C (nameOffset:36) (firstTokenOffset:21) (offset:36)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 hasInitializer isOriginDeclaration t1 (nameOffset:76) (firstTokenOffset:76) (offset:76)
          element: <testLibrary>::@topLevelVariable::t1
        #F10 hasInitializer isOriginDeclaration t2 (nameOffset:101) (firstTokenOffset:101) (offset:101)
          element: <testLibrary>::@topLevelVariable::t2
      getters
        #F11 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@getter::t1
        #F12 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
          element: <testLibrary>::@getter::t2
      setters
        #F13 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@setter::t1
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F15 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
          element: <testLibrary>::@setter::t2
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@setter::t2::@formalParameter::value
      functions
        #F17 isOriginDeclaration getC (nameOffset:56) (firstTokenOffset:54) (offset:56)
          element: <testLibrary>::@function::getC
  classes
    hasNonFinalField class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        isOriginDeclaration f
          reference: <testLibrary>::@class::I::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::I::@getter::f
          setter: <testLibrary>::@class::I::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::I::@field::f
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F9
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    static isOriginVariable t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    static isOriginVariable t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    static isOriginVariable t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t2
  functions
    isOriginDeclaration getC
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
        #F1 hasInitializer isOriginDeclaration uValue (nameOffset:80) (firstTokenOffset:80) (offset:80)
          element: <testLibrary>::@topLevelVariable::uValue
        #F2 hasInitializer isOriginDeclaration uFuture (nameOffset:121) (firstTokenOffset:121) (offset:121)
          element: <testLibrary>::@topLevelVariable::uFuture
      getters
        #F3 isOriginVariable uValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
          element: <testLibrary>::@getter::uValue
        #F4 isOriginVariable uFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
          element: <testLibrary>::@getter::uFuture
      setters
        #F5 isOriginVariable uValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
          element: <testLibrary>::@setter::uValue
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@setter::uValue::@formalParameter::value
        #F7 isOriginVariable uFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
          element: <testLibrary>::@setter::uFuture
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
              element: <testLibrary>::@setter::uFuture::@formalParameter::value
      functions
        #F9 isOriginDeclaration fValue (nameOffset:25) (firstTokenOffset:21) (offset:25)
          element: <testLibrary>::@function::fValue
        #F10 isOriginDeclaration fFuture (nameOffset:53) (firstTokenOffset:41) (offset:53)
          element: <testLibrary>::@function::fFuture
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration uValue
      reference: <testLibrary>::@topLevelVariable::uValue
      firstFragment: #F1
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uValue
      setter: <testLibrary>::@setter::uValue
    hasImplicitType hasInitializer isOriginDeclaration uFuture
      reference: <testLibrary>::@topLevelVariable::uFuture
      firstFragment: #F2
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uFuture
      setter: <testLibrary>::@setter::uFuture
  getters
    static isOriginVariable uValue
      reference: <testLibrary>::@getter::uValue
      firstFragment: #F3
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uValue
    static isOriginVariable uFuture
      reference: <testLibrary>::@getter::uFuture
      firstFragment: #F4
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uFuture
  setters
    static isOriginVariable uValue
      reference: <testLibrary>::@setter::uValue
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::uValue
    static isOriginVariable uFuture
      reference: <testLibrary>::@setter::uFuture
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::uFuture
  functions
    isOriginDeclaration fValue
      reference: <testLibrary>::@function::fValue
      firstFragment: #F9
      returnType: int
    isOriginDeclaration fFuture
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
        #F1 hasInitializer isOriginDeclaration vBitXor (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vBitXor
        #F2 hasInitializer isOriginDeclaration vBitAnd (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::vBitAnd
        #F3 hasInitializer isOriginDeclaration vBitOr (nameOffset:46) (firstTokenOffset:46) (offset:46)
          element: <testLibrary>::@topLevelVariable::vBitOr
        #F4 hasInitializer isOriginDeclaration vBitShiftLeft (nameOffset:66) (firstTokenOffset:66) (offset:66)
          element: <testLibrary>::@topLevelVariable::vBitShiftLeft
        #F5 hasInitializer isOriginDeclaration vBitShiftRight (nameOffset:94) (firstTokenOffset:94) (offset:94)
          element: <testLibrary>::@topLevelVariable::vBitShiftRight
      getters
        #F6 isOriginVariable vBitXor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vBitXor
        #F7 isOriginVariable vBitAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::vBitAnd
        #F8 isOriginVariable vBitOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@getter::vBitOr
        #F9 isOriginVariable vBitShiftLeft (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@getter::vBitShiftLeft
        #F10 isOriginVariable vBitShiftRight (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
          element: <testLibrary>::@getter::vBitShiftRight
      setters
        #F11 isOriginVariable vBitXor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vBitXor
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vBitXor::@formalParameter::value
        #F13 isOriginVariable vBitAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::vBitAnd
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::vBitAnd::@formalParameter::value
        #F15 isOriginVariable vBitOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@setter::vBitOr
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@setter::vBitOr::@formalParameter::value
        #F17 isOriginVariable vBitShiftLeft (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@setter::vBitShiftLeft
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@setter::vBitShiftLeft::@formalParameter::value
        #F19 isOriginVariable vBitShiftRight (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
          element: <testLibrary>::@setter::vBitShiftRight
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@setter::vBitShiftRight::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vBitXor
      reference: <testLibrary>::@topLevelVariable::vBitXor
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vBitXor
      setter: <testLibrary>::@setter::vBitXor
    hasImplicitType hasInitializer isOriginDeclaration vBitAnd
      reference: <testLibrary>::@topLevelVariable::vBitAnd
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::vBitAnd
      setter: <testLibrary>::@setter::vBitAnd
    hasImplicitType hasInitializer isOriginDeclaration vBitOr
      reference: <testLibrary>::@topLevelVariable::vBitOr
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vBitOr
      setter: <testLibrary>::@setter::vBitOr
    hasImplicitType hasInitializer isOriginDeclaration vBitShiftLeft
      reference: <testLibrary>::@topLevelVariable::vBitShiftLeft
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vBitShiftLeft
      setter: <testLibrary>::@setter::vBitShiftLeft
    hasImplicitType hasInitializer isOriginDeclaration vBitShiftRight
      reference: <testLibrary>::@topLevelVariable::vBitShiftRight
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::vBitShiftRight
      setter: <testLibrary>::@setter::vBitShiftRight
  getters
    static isOriginVariable vBitXor
      reference: <testLibrary>::@getter::vBitXor
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitXor
    static isOriginVariable vBitAnd
      reference: <testLibrary>::@getter::vBitAnd
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    static isOriginVariable vBitOr
      reference: <testLibrary>::@getter::vBitOr
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitOr
    static isOriginVariable vBitShiftLeft
      reference: <testLibrary>::@getter::vBitShiftLeft
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    static isOriginVariable vBitShiftRight
      reference: <testLibrary>::@getter::vBitShiftRight
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftRight
  setters
    static isOriginVariable vBitXor
      reference: <testLibrary>::@setter::vBitXor
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitXor
    static isOriginVariable vBitAnd
      reference: <testLibrary>::@setter::vBitAnd
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    static isOriginVariable vBitOr
      reference: <testLibrary>::@setter::vBitOr
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitOr
    static isOriginVariable vBitShiftLeft
      reference: <testLibrary>::@setter::vBitShiftLeft
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    static isOriginVariable vBitShiftRight
      reference: <testLibrary>::@setter::vBitShiftRight
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitShiftRight
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration a (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::a
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::a
          setters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::value
          methods
            #F7 isOriginDeclaration m (nameOffset:26) (firstTokenOffset:21) (offset:26)
              element: <testLibrary>::@class::A::@method::m
      topLevelVariables
        #F8 hasInitializer isOriginDeclaration vSetField (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::vSetField
        #F9 hasInitializer isOriginDeclaration vInvokeMethod (nameOffset:71) (firstTokenOffset:71) (offset:71)
          element: <testLibrary>::@topLevelVariable::vInvokeMethod
        #F10 hasInitializer isOriginDeclaration vBoth (nameOffset:105) (firstTokenOffset:105) (offset:105)
          element: <testLibrary>::@topLevelVariable::vBoth
      getters
        #F11 isOriginVariable vSetField (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::vSetField
        #F12 isOriginVariable vInvokeMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@getter::vInvokeMethod
        #F13 isOriginVariable vBoth (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
          element: <testLibrary>::@getter::vBoth
      setters
        #F14 isOriginVariable vSetField (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::vSetField
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::vSetField::@formalParameter::value
        #F16 isOriginVariable vInvokeMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@setter::vInvokeMethod
          formalParameters
            #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@setter::vInvokeMethod::@formalParameter::value
        #F18 isOriginVariable vBoth (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
          element: <testLibrary>::@setter::vBoth
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
              element: <testLibrary>::@setter::vBoth::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F7
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vSetField
      reference: <testLibrary>::@topLevelVariable::vSetField
      firstFragment: #F8
      type: A
      getter: <testLibrary>::@getter::vSetField
      setter: <testLibrary>::@setter::vSetField
    hasImplicitType hasInitializer isOriginDeclaration vInvokeMethod
      reference: <testLibrary>::@topLevelVariable::vInvokeMethod
      firstFragment: #F9
      type: A
      getter: <testLibrary>::@getter::vInvokeMethod
      setter: <testLibrary>::@setter::vInvokeMethod
    hasImplicitType hasInitializer isOriginDeclaration vBoth
      reference: <testLibrary>::@topLevelVariable::vBoth
      firstFragment: #F10
      type: A
      getter: <testLibrary>::@getter::vBoth
      setter: <testLibrary>::@setter::vBoth
  getters
    static isOriginVariable vSetField
      reference: <testLibrary>::@getter::vSetField
      firstFragment: #F11
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vSetField
    static isOriginVariable vInvokeMethod
      reference: <testLibrary>::@getter::vInvokeMethod
      firstFragment: #F12
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vInvokeMethod
    static isOriginVariable vBoth
      reference: <testLibrary>::@getter::vBoth
      firstFragment: #F13
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vBoth
  setters
    static isOriginVariable vSetField
      reference: <testLibrary>::@setter::vSetField
      firstFragment: #F14
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F15
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vSetField
    static isOriginVariable vInvokeMethod
      reference: <testLibrary>::@setter::vInvokeMethod
      firstFragment: #F16
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F17
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInvokeMethod
    static isOriginVariable vBoth
      reference: <testLibrary>::@setter::vBoth
      firstFragment: #F18
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F19
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBoth
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
        #F7 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginDeclaration a (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@class::B::@field::a
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@getter::a
          setters
            #F11 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::value
        #F13 class C (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::C
          fields
            #F14 isOriginDeclaration b (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::C::@field::b
          constructors
            #F15 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F16 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::C::@getter::b
          setters
            #F17 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::C::@setter::b
              formalParameters
                #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::value
        #F19 class X (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::X
          fields
            #F20 hasInitializer isOriginDeclaration a (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::X::@field::a
            #F21 hasInitializer isOriginDeclaration b (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::X::@field::b
            #F22 hasInitializer isOriginDeclaration c (nameOffset:111) (firstTokenOffset:111) (offset:111)
              element: <testLibrary>::@class::X::@field::c
            #F23 hasInitializer isOriginDeclaration t01 (nameOffset:130) (firstTokenOffset:130) (offset:130)
              element: <testLibrary>::@class::X::@field::t01
            #F24 hasInitializer isOriginDeclaration t02 (nameOffset:147) (firstTokenOffset:147) (offset:147)
              element: <testLibrary>::@class::X::@field::t02
            #F25 hasInitializer isOriginDeclaration t03 (nameOffset:166) (firstTokenOffset:166) (offset:166)
              element: <testLibrary>::@class::X::@field::t03
            #F26 hasInitializer isOriginDeclaration t11 (nameOffset:187) (firstTokenOffset:187) (offset:187)
              element: <testLibrary>::@class::X::@field::t11
            #F27 hasInitializer isOriginDeclaration t12 (nameOffset:210) (firstTokenOffset:210) (offset:210)
              element: <testLibrary>::@class::X::@field::t12
            #F28 hasInitializer isOriginDeclaration t13 (nameOffset:235) (firstTokenOffset:235) (offset:235)
              element: <testLibrary>::@class::X::@field::t13
            #F29 hasInitializer isOriginDeclaration t21 (nameOffset:262) (firstTokenOffset:262) (offset:262)
              element: <testLibrary>::@class::X::@field::t21
            #F30 hasInitializer isOriginDeclaration t22 (nameOffset:284) (firstTokenOffset:284) (offset:284)
              element: <testLibrary>::@class::X::@field::t22
            #F31 hasInitializer isOriginDeclaration t23 (nameOffset:308) (firstTokenOffset:308) (offset:308)
              element: <testLibrary>::@class::X::@field::t23
          constructors
            #F32 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
          getters
            #F33 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::X::@getter::a
            #F34 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::X::@getter::b
            #F35 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@class::X::@getter::c
            #F36 isOriginVariable t01 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
              element: <testLibrary>::@class::X::@getter::t01
            #F37 isOriginVariable t02 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:147)
              element: <testLibrary>::@class::X::@getter::t02
            #F38 isOriginVariable t03 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:166)
              element: <testLibrary>::@class::X::@getter::t03
            #F39 isOriginVariable t11 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:187)
              element: <testLibrary>::@class::X::@getter::t11
            #F40 isOriginVariable t12 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:210)
              element: <testLibrary>::@class::X::@getter::t12
            #F41 isOriginVariable t13 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:235)
              element: <testLibrary>::@class::X::@getter::t13
            #F42 isOriginVariable t21 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:262)
              element: <testLibrary>::@class::X::@getter::t21
            #F43 isOriginVariable t22 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
              element: <testLibrary>::@class::X::@getter::t22
            #F44 isOriginVariable t23 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:308)
              element: <testLibrary>::@class::X::@getter::t23
          setters
            #F45 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::X::@setter::a
              formalParameters
                #F46 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
                  element: <testLibrary>::@class::X::@setter::a::@formalParameter::value
            #F47 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::X::@setter::b
              formalParameters
                #F48 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
                  element: <testLibrary>::@class::X::@setter::b::@formalParameter::value
            #F49 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@class::X::@setter::c
              formalParameters
                #F50 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
                  element: <testLibrary>::@class::X::@setter::c::@formalParameter::value
            #F51 isOriginVariable t01 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
              element: <testLibrary>::@class::X::@setter::t01
              formalParameters
                #F52 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
                  element: <testLibrary>::@class::X::@setter::t01::@formalParameter::value
            #F53 isOriginVariable t02 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:147)
              element: <testLibrary>::@class::X::@setter::t02
              formalParameters
                #F54 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:147)
                  element: <testLibrary>::@class::X::@setter::t02::@formalParameter::value
            #F55 isOriginVariable t03 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:166)
              element: <testLibrary>::@class::X::@setter::t03
              formalParameters
                #F56 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:166)
                  element: <testLibrary>::@class::X::@setter::t03::@formalParameter::value
            #F57 isOriginVariable t11 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:187)
              element: <testLibrary>::@class::X::@setter::t11
              formalParameters
                #F58 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:187)
                  element: <testLibrary>::@class::X::@setter::t11::@formalParameter::value
            #F59 isOriginVariable t12 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:210)
              element: <testLibrary>::@class::X::@setter::t12
              formalParameters
                #F60 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:210)
                  element: <testLibrary>::@class::X::@setter::t12::@formalParameter::value
            #F61 isOriginVariable t13 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:235)
              element: <testLibrary>::@class::X::@setter::t13
              formalParameters
                #F62 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:235)
                  element: <testLibrary>::@class::X::@setter::t13::@formalParameter::value
            #F63 isOriginVariable t21 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:262)
              element: <testLibrary>::@class::X::@setter::t21
              formalParameters
                #F64 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:262)
                  element: <testLibrary>::@class::X::@setter::t21::@formalParameter::value
            #F65 isOriginVariable t22 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
              element: <testLibrary>::@class::X::@setter::t22
              formalParameters
                #F66 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
                  element: <testLibrary>::@class::X::@setter::t22::@formalParameter::value
            #F67 isOriginVariable t23 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:308)
              element: <testLibrary>::@class::X::@setter::t23
              formalParameters
                #F68 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:308)
                  element: <testLibrary>::@class::X::@setter::t23::@formalParameter::value
      functions
        #F69 isOriginDeclaration newA (nameOffset:332) (firstTokenOffset:330) (offset:332)
          element: <testLibrary>::@function::newA
        #F70 isOriginDeclaration newB (nameOffset:353) (firstTokenOffset:351) (offset:353)
          element: <testLibrary>::@function::newB
        #F71 isOriginDeclaration newC (nameOffset:374) (firstTokenOffset:372) (offset:374)
          element: <testLibrary>::@function::newC
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        isOriginDeclaration a
          reference: <testLibrary>::@class::B::@field::a
          firstFragment: #F8
          type: A
          getter: <testLibrary>::@class::B::@getter::a
          setter: <testLibrary>::@class::B::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: A
          returnType: void
          variable: <testLibrary>::@class::B::@field::a
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      fields
        isOriginDeclaration b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F14
          type: B
          getter: <testLibrary>::@class::C::@getter::b
          setter: <testLibrary>::@class::C::@setter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F15
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F16
          returnType: B
          variable: <testLibrary>::@class::C::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F17
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F18
              type: B
          returnType: void
          variable: <testLibrary>::@class::C::@field::b
    hasNonFinalField class X
      reference: <testLibrary>::@class::X
      firstFragment: #F19
      fields
        hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@class::X::@field::a
          firstFragment: #F20
          type: A
          getter: <testLibrary>::@class::X::@getter::a
          setter: <testLibrary>::@class::X::@setter::a
        hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@class::X::@field::b
          firstFragment: #F21
          type: B
          getter: <testLibrary>::@class::X::@getter::b
          setter: <testLibrary>::@class::X::@setter::b
        hasInitializer isOriginDeclaration c
          reference: <testLibrary>::@class::X::@field::c
          firstFragment: #F22
          type: C
          getter: <testLibrary>::@class::X::@getter::c
          setter: <testLibrary>::@class::X::@setter::c
        hasImplicitType hasInitializer isOriginDeclaration t01
          reference: <testLibrary>::@class::X::@field::t01
          firstFragment: #F23
          type: int
          getter: <testLibrary>::@class::X::@getter::t01
          setter: <testLibrary>::@class::X::@setter::t01
        hasImplicitType hasInitializer isOriginDeclaration t02
          reference: <testLibrary>::@class::X::@field::t02
          firstFragment: #F24
          type: int
          getter: <testLibrary>::@class::X::@getter::t02
          setter: <testLibrary>::@class::X::@setter::t02
        hasImplicitType hasInitializer isOriginDeclaration t03
          reference: <testLibrary>::@class::X::@field::t03
          firstFragment: #F25
          type: int
          getter: <testLibrary>::@class::X::@getter::t03
          setter: <testLibrary>::@class::X::@setter::t03
        hasImplicitType hasInitializer isOriginDeclaration t11
          reference: <testLibrary>::@class::X::@field::t11
          firstFragment: #F26
          type: int
          getter: <testLibrary>::@class::X::@getter::t11
          setter: <testLibrary>::@class::X::@setter::t11
        hasImplicitType hasInitializer isOriginDeclaration t12
          reference: <testLibrary>::@class::X::@field::t12
          firstFragment: #F27
          type: int
          getter: <testLibrary>::@class::X::@getter::t12
          setter: <testLibrary>::@class::X::@setter::t12
        hasImplicitType hasInitializer isOriginDeclaration t13
          reference: <testLibrary>::@class::X::@field::t13
          firstFragment: #F28
          type: int
          getter: <testLibrary>::@class::X::@getter::t13
          setter: <testLibrary>::@class::X::@setter::t13
        hasImplicitType hasInitializer isOriginDeclaration t21
          reference: <testLibrary>::@class::X::@field::t21
          firstFragment: #F29
          type: int
          getter: <testLibrary>::@class::X::@getter::t21
          setter: <testLibrary>::@class::X::@setter::t21
        hasImplicitType hasInitializer isOriginDeclaration t22
          reference: <testLibrary>::@class::X::@field::t22
          firstFragment: #F30
          type: int
          getter: <testLibrary>::@class::X::@getter::t22
          setter: <testLibrary>::@class::X::@setter::t22
        hasImplicitType hasInitializer isOriginDeclaration t23
          reference: <testLibrary>::@class::X::@field::t23
          firstFragment: #F31
          type: int
          getter: <testLibrary>::@class::X::@getter::t23
          setter: <testLibrary>::@class::X::@setter::t23
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F32
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::X::@getter::a
          firstFragment: #F33
          returnType: A
          variable: <testLibrary>::@class::X::@field::a
        isOriginVariable b
          reference: <testLibrary>::@class::X::@getter::b
          firstFragment: #F34
          returnType: B
          variable: <testLibrary>::@class::X::@field::b
        isOriginVariable c
          reference: <testLibrary>::@class::X::@getter::c
          firstFragment: #F35
          returnType: C
          variable: <testLibrary>::@class::X::@field::c
        isOriginVariable t01
          reference: <testLibrary>::@class::X::@getter::t01
          firstFragment: #F36
          returnType: int
          variable: <testLibrary>::@class::X::@field::t01
        isOriginVariable t02
          reference: <testLibrary>::@class::X::@getter::t02
          firstFragment: #F37
          returnType: int
          variable: <testLibrary>::@class::X::@field::t02
        isOriginVariable t03
          reference: <testLibrary>::@class::X::@getter::t03
          firstFragment: #F38
          returnType: int
          variable: <testLibrary>::@class::X::@field::t03
        isOriginVariable t11
          reference: <testLibrary>::@class::X::@getter::t11
          firstFragment: #F39
          returnType: int
          variable: <testLibrary>::@class::X::@field::t11
        isOriginVariable t12
          reference: <testLibrary>::@class::X::@getter::t12
          firstFragment: #F40
          returnType: int
          variable: <testLibrary>::@class::X::@field::t12
        isOriginVariable t13
          reference: <testLibrary>::@class::X::@getter::t13
          firstFragment: #F41
          returnType: int
          variable: <testLibrary>::@class::X::@field::t13
        isOriginVariable t21
          reference: <testLibrary>::@class::X::@getter::t21
          firstFragment: #F42
          returnType: int
          variable: <testLibrary>::@class::X::@field::t21
        isOriginVariable t22
          reference: <testLibrary>::@class::X::@getter::t22
          firstFragment: #F43
          returnType: int
          variable: <testLibrary>::@class::X::@field::t22
        isOriginVariable t23
          reference: <testLibrary>::@class::X::@getter::t23
          firstFragment: #F44
          returnType: int
          variable: <testLibrary>::@class::X::@field::t23
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::X::@setter::a
          firstFragment: #F45
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F46
              type: A
          returnType: void
          variable: <testLibrary>::@class::X::@field::a
        isOriginVariable b
          reference: <testLibrary>::@class::X::@setter::b
          firstFragment: #F47
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F48
              type: B
          returnType: void
          variable: <testLibrary>::@class::X::@field::b
        isOriginVariable c
          reference: <testLibrary>::@class::X::@setter::c
          firstFragment: #F49
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F50
              type: C
          returnType: void
          variable: <testLibrary>::@class::X::@field::c
        isOriginVariable t01
          reference: <testLibrary>::@class::X::@setter::t01
          firstFragment: #F51
          formalParameters
            #E6 requiredPositional value
              firstFragment: #F52
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t01
        isOriginVariable t02
          reference: <testLibrary>::@class::X::@setter::t02
          firstFragment: #F53
          formalParameters
            #E7 requiredPositional value
              firstFragment: #F54
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t02
        isOriginVariable t03
          reference: <testLibrary>::@class::X::@setter::t03
          firstFragment: #F55
          formalParameters
            #E8 requiredPositional value
              firstFragment: #F56
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t03
        isOriginVariable t11
          reference: <testLibrary>::@class::X::@setter::t11
          firstFragment: #F57
          formalParameters
            #E9 requiredPositional value
              firstFragment: #F58
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t11
        isOriginVariable t12
          reference: <testLibrary>::@class::X::@setter::t12
          firstFragment: #F59
          formalParameters
            #E10 requiredPositional value
              firstFragment: #F60
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t12
        isOriginVariable t13
          reference: <testLibrary>::@class::X::@setter::t13
          firstFragment: #F61
          formalParameters
            #E11 requiredPositional value
              firstFragment: #F62
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t13
        isOriginVariable t21
          reference: <testLibrary>::@class::X::@setter::t21
          firstFragment: #F63
          formalParameters
            #E12 requiredPositional value
              firstFragment: #F64
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t21
        isOriginVariable t22
          reference: <testLibrary>::@class::X::@setter::t22
          firstFragment: #F65
          formalParameters
            #E13 requiredPositional value
              firstFragment: #F66
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t22
        isOriginVariable t23
          reference: <testLibrary>::@class::X::@setter::t23
          firstFragment: #F67
          formalParameters
            #E14 requiredPositional value
              firstFragment: #F68
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t23
  functions
    isOriginDeclaration newA
      reference: <testLibrary>::@function::newA
      firstFragment: #F69
      returnType: A
    isOriginDeclaration newB
      reference: <testLibrary>::@function::newB
      firstFragment: #F70
      returnType: B
    isOriginDeclaration newC
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
      setters
        #F3 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: num
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::V
  setters
    static isOriginVariable V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
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
        #F1 hasInitializer isOriginDeclaration vEq (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vEq
        #F2 hasInitializer isOriginDeclaration vNotEq (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::vNotEq
      getters
        #F3 isOriginVariable vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vEq
        #F4 isOriginVariable vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::vNotEq
      setters
        #F5 isOriginVariable vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vEq::@formalParameter::value
        #F7 isOriginVariable vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::vNotEq
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::vNotEq::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasImplicitType hasInitializer isOriginDeclaration vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    static isOriginVariable vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F3
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    static isOriginVariable vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F4
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    static isOriginVariable vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vEq
    static isOriginVariable vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNotEq
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration b (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::b
      setters
        #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F7 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::b
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::b::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@setter::b
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F2 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
      setters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a]
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration b0 (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b0
        #F3 hasInitializer isOriginDeclaration b1 (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::b1
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F5 isOriginVariable b0 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b0
        #F6 isOriginVariable b1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::b1
      setters
        #F7 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F9 isOriginVariable b0 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::b0
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::b0::@formalParameter::value
        #F11 isOriginVariable b1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::b1
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::b1::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<num>
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration b0
      reference: <testLibrary>::@topLevelVariable::b0
      firstFragment: #F2
      type: num
      getter: <testLibrary>::@getter::b0
      setter: <testLibrary>::@setter::b0
    hasImplicitType hasInitializer isOriginDeclaration b1
      reference: <testLibrary>::@topLevelVariable::b1
      firstFragment: #F3
      type: num
      getter: <testLibrary>::@getter::b1
      setter: <testLibrary>::@setter::b1
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b0
      reference: <testLibrary>::@getter::b0
      firstFragment: #F5
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b0
    static isOriginVariable b1
      reference: <testLibrary>::@getter::b1
      firstFragment: #F6
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b1
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b0
      reference: <testLibrary>::@setter::b0
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b0
    static isOriginVariable b1
      reference: <testLibrary>::@setter::b1
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b1
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration x (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F8 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::x
      setters
        #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::x
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration x (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F8 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::x
      setters
        #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::x
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
          setters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
        #F7 class B (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer isOriginDeclaration t (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@class::B::@field::t
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::B::@getter::t
          setters
            #F11 isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::B::@setter::t
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
                  element: <testLibrary>::@class::B::@setter::t::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        static hasImplicitType hasInitializer isOriginDeclaration t
          reference: <testLibrary>::@class::B::@field::t
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::t
          setter: <testLibrary>::@class::B::@setter::t
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        static isOriginVariable t
          reference: <testLibrary>::@class::B::@getter::t
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::B::@field::t
      setters
        static isOriginVariable t
          reference: <testLibrary>::@class::B::@setter::t
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::t
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginDeclaration b (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@field::b
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@getter::b
          setters
            #F5 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@setter::b
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::value
      topLevelVariables
        #F7 isOriginDeclaration c (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::c
        #F8 hasInitializer isOriginDeclaration x (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F9 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::c
        #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::x
      setters
        #F11 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::c
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F13 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::x
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginDeclaration b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::C::@getter::b
          setter: <testLibrary>::@class::C::@setter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F4
          returnType: bool
          variable: <testLibrary>::@class::C::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: bool
          returnType: void
          variable: <testLibrary>::@class::C::@field::b
  topLevelVariables
    isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F7
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F8
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F9
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable c
      reference: <testLibrary>::@setter::c
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 class I (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::I
          fields
            #F2 isOriginDeclaration b (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::I::@field::b
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@getter::b
          setters
            #F5 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@setter::b
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::I::@setter::b::@formalParameter::value
        #F7 class C (nameOffset:37) (firstTokenOffset:22) (offset:37)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 isOriginDeclaration c (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::c
        #F10 hasInitializer isOriginDeclaration x (nameOffset:64) (firstTokenOffset:64) (offset:64)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F11 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::c
        #F12 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@getter::x
      setters
        #F13 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@setter::c
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F15 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@setter::x
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        isOriginDeclaration b
          reference: <testLibrary>::@class::I::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::I::@getter::b
          setter: <testLibrary>::@class::I::@setter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F4
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: bool
          returnType: void
          variable: <testLibrary>::@class::I::@field::b
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F9
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 class I (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::I
          fields
            #F2 isOriginDeclaration b (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::I::@field::b
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@getter::b
          setters
            #F5 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@setter::b
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::I::@setter::b::@formalParameter::value
        #F7 class C (nameOffset:37) (firstTokenOffset:22) (offset:37)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 hasInitializer isOriginDeclaration x (nameOffset:74) (firstTokenOffset:74) (offset:74)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@getter::x
      setters
        #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@setter::x::@formalParameter::value
      functions
        #F13 isOriginDeclaration f (nameOffset:57) (firstTokenOffset:55) (offset:57)
          element: <testLibrary>::@function::f
  classes
    hasNonFinalField class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      fields
        isOriginDeclaration b
          reference: <testLibrary>::@class::I::@field::b
          firstFragment: #F2
          type: bool
          getter: <testLibrary>::@class::I::@getter::b
          setter: <testLibrary>::@class::I::@setter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F4
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: bool
          returnType: void
          variable: <testLibrary>::@class::I::@field::b
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F9
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
  functions
    isOriginDeclaration f
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::foo
        #F4 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 isOriginDeclaration foo (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@class::B::@method::foo
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration x (nameOffset:70) (firstTokenOffset:70) (offset:70)
          element: <testLibrary>::@topLevelVariable::x
        #F8 hasInitializer isOriginDeclaration y (nameOffset:89) (firstTokenOffset:89) (offset:89)
          element: <testLibrary>::@topLevelVariable::y
      getters
        #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@getter::x
        #F10 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@getter::y
      setters
        #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F13 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@setter::y
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@setter::y::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          returnType: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F6
          returnType: int
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasImplicitType hasInitializer isOriginDeclaration y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F8
      type: int
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
    static isOriginVariable y
      reference: <testLibrary>::@getter::y
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::y
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    static isOriginVariable y
      reference: <testLibrary>::@setter::y
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
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
        #F1 hasInitializer isOriginDeclaration vFuture (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::vFuture
        #F2 hasInitializer isOriginDeclaration v_noParameters_inferredReturnType (nameOffset:60) (firstTokenOffset:60) (offset:60)
          element: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
        #F3 hasInitializer isOriginDeclaration v_hasParameter_withType_inferredReturnType (nameOffset:110) (firstTokenOffset:110) (offset:110)
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
        #F4 hasInitializer isOriginDeclaration v_hasParameter_withType_returnParameter (nameOffset:177) (firstTokenOffset:177) (offset:177)
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
        #F5 hasInitializer isOriginDeclaration v_async_returnValue (nameOffset:240) (firstTokenOffset:240) (offset:240)
          element: <testLibrary>::@topLevelVariable::v_async_returnValue
        #F6 hasInitializer isOriginDeclaration v_async_returnFuture (nameOffset:282) (firstTokenOffset:282) (offset:282)
          element: <testLibrary>::@topLevelVariable::v_async_returnFuture
      getters
        #F7 isOriginVariable vFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::vFuture
        #F8 isOriginVariable v_noParameters_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@getter::v_noParameters_inferredReturnType
        #F9 isOriginVariable v_hasParameter_withType_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
          element: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
        #F10 isOriginVariable v_hasParameter_withType_returnParameter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:177)
          element: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
        #F11 isOriginVariable v_async_returnValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:240)
          element: <testLibrary>::@getter::v_async_returnValue
        #F12 isOriginVariable v_async_returnFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:282)
          element: <testLibrary>::@getter::v_async_returnFuture
      setters
        #F13 isOriginVariable vFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::vFuture
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::vFuture::@formalParameter::value
        #F15 isOriginVariable v_noParameters_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@setter::v_noParameters_inferredReturnType
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@setter::v_noParameters_inferredReturnType::@formalParameter::value
        #F17 isOriginVariable v_hasParameter_withType_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
          element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
              element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType::@formalParameter::value
        #F19 isOriginVariable v_hasParameter_withType_returnParameter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:177)
          element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:177)
              element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter::@formalParameter::value
        #F21 isOriginVariable v_async_returnValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:240)
          element: <testLibrary>::@setter::v_async_returnValue
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:240)
              element: <testLibrary>::@setter::v_async_returnValue::@formalParameter::value
        #F23 isOriginVariable v_async_returnFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:282)
          element: <testLibrary>::@setter::v_async_returnFuture
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:282)
              element: <testLibrary>::@setter::v_async_returnFuture::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vFuture
      reference: <testLibrary>::@topLevelVariable::vFuture
      firstFragment: #F1
      type: Future<int>
      getter: <testLibrary>::@getter::vFuture
      setter: <testLibrary>::@setter::vFuture
    hasImplicitType hasInitializer isOriginDeclaration v_noParameters_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
      firstFragment: #F2
      type: int Function()
      getter: <testLibrary>::@getter::v_noParameters_inferredReturnType
      setter: <testLibrary>::@setter::v_noParameters_inferredReturnType
    hasImplicitType hasInitializer isOriginDeclaration v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
      firstFragment: #F3
      type: int Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      setter: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
    hasImplicitType hasInitializer isOriginDeclaration v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
      firstFragment: #F4
      type: String Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      setter: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
    hasImplicitType hasInitializer isOriginDeclaration v_async_returnValue
      reference: <testLibrary>::@topLevelVariable::v_async_returnValue
      firstFragment: #F5
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnValue
      setter: <testLibrary>::@setter::v_async_returnValue
    hasImplicitType hasInitializer isOriginDeclaration v_async_returnFuture
      reference: <testLibrary>::@topLevelVariable::v_async_returnFuture
      firstFragment: #F6
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnFuture
      setter: <testLibrary>::@setter::v_async_returnFuture
  getters
    static isOriginVariable vFuture
      reference: <testLibrary>::@getter::vFuture
      firstFragment: #F7
      returnType: Future<int>
      variable: <testLibrary>::@topLevelVariable::vFuture
    static isOriginVariable v_noParameters_inferredReturnType
      reference: <testLibrary>::@getter::v_noParameters_inferredReturnType
      firstFragment: #F8
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
    static isOriginVariable v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F9
      returnType: int Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
    static isOriginVariable v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      firstFragment: #F10
      returnType: String Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
    static isOriginVariable v_async_returnValue
      reference: <testLibrary>::@getter::v_async_returnValue
      firstFragment: #F11
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnValue
    static isOriginVariable v_async_returnFuture
      reference: <testLibrary>::@getter::v_async_returnFuture
      firstFragment: #F12
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnFuture
  setters
    static isOriginVariable vFuture
      reference: <testLibrary>::@setter::vFuture
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F14
          type: Future<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vFuture
    static isOriginVariable v_noParameters_inferredReturnType
      reference: <testLibrary>::@setter::v_noParameters_inferredReturnType
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: int Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
    static isOriginVariable v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int Function(String)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
    static isOriginVariable v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F20
          type: String Function(String)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
    static isOriginVariable v_async_returnValue
      reference: <testLibrary>::@setter::v_async_returnValue
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F22
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_async_returnValue
    static isOriginVariable v_async_returnFuture
      reference: <testLibrary>::@setter::v_async_returnFuture
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_async_returnFuture
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
      setters
        #F3 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    static isOriginVariable v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
        #F1 hasInitializer isOriginDeclaration vHasTypeArgument (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::vHasTypeArgument
        #F2 hasInitializer isOriginDeclaration vNoTypeArgument (nameOffset:55) (firstTokenOffset:55) (offset:55)
          element: <testLibrary>::@topLevelVariable::vNoTypeArgument
      getters
        #F3 isOriginVariable vHasTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::vHasTypeArgument
        #F4 isOriginVariable vNoTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@getter::vNoTypeArgument
      setters
        #F5 isOriginVariable vHasTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::vHasTypeArgument
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::vHasTypeArgument::@formalParameter::value
        #F7 isOriginVariable vNoTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@setter::vNoTypeArgument
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@setter::vNoTypeArgument::@formalParameter::value
      functions
        #F9 isOriginDeclaration f (nameOffset:2) (firstTokenOffset:0) (offset:2)
          element: <testLibrary>::@function::f
          typeParameters
            #F10 T (nameOffset:4) (firstTokenOffset:4) (offset:4)
              element: #E0 T
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vHasTypeArgument
      reference: <testLibrary>::@topLevelVariable::vHasTypeArgument
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vHasTypeArgument
      setter: <testLibrary>::@setter::vHasTypeArgument
    hasImplicitType hasInitializer isOriginDeclaration vNoTypeArgument
      reference: <testLibrary>::@topLevelVariable::vNoTypeArgument
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::vNoTypeArgument
      setter: <testLibrary>::@setter::vNoTypeArgument
  getters
    static isOriginVariable vHasTypeArgument
      reference: <testLibrary>::@getter::vHasTypeArgument
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vHasTypeArgument
    static isOriginVariable vNoTypeArgument
      reference: <testLibrary>::@getter::vNoTypeArgument
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::vNoTypeArgument
  setters
    static isOriginVariable vHasTypeArgument
      reference: <testLibrary>::@setter::vHasTypeArgument
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vHasTypeArgument
    static isOriginVariable vNoTypeArgument
      reference: <testLibrary>::@setter::vNoTypeArgument
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F8
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNoTypeArgument
  functions
    isOriginDeclaration f
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
        #F1 hasInitializer isOriginDeclaration vOkArgumentType (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::vOkArgumentType
        #F2 hasInitializer isOriginDeclaration vWrongArgumentType (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::vWrongArgumentType
      getters
        #F3 isOriginVariable vOkArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::vOkArgumentType
        #F4 isOriginVariable vWrongArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::vWrongArgumentType
      setters
        #F5 isOriginVariable vOkArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::vOkArgumentType
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::vOkArgumentType::@formalParameter::value
        #F7 isOriginVariable vWrongArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@setter::vWrongArgumentType
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@setter::vWrongArgumentType::@formalParameter::value
      functions
        #F9 isOriginDeclaration f (nameOffset:7) (firstTokenOffset:0) (offset:7)
          element: <testLibrary>::@function::f
          formalParameters
            #F10 requiredPositional p (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::f::@formalParameter::p
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vOkArgumentType
      reference: <testLibrary>::@topLevelVariable::vOkArgumentType
      firstFragment: #F1
      type: String
      getter: <testLibrary>::@getter::vOkArgumentType
      setter: <testLibrary>::@setter::vOkArgumentType
    hasImplicitType hasInitializer isOriginDeclaration vWrongArgumentType
      reference: <testLibrary>::@topLevelVariable::vWrongArgumentType
      firstFragment: #F2
      type: String
      getter: <testLibrary>::@getter::vWrongArgumentType
      setter: <testLibrary>::@setter::vWrongArgumentType
  getters
    static isOriginVariable vOkArgumentType
      reference: <testLibrary>::@getter::vOkArgumentType
      firstFragment: #F3
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vOkArgumentType
    static isOriginVariable vWrongArgumentType
      reference: <testLibrary>::@getter::vWrongArgumentType
      firstFragment: #F4
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vWrongArgumentType
  setters
    static isOriginVariable vOkArgumentType
      reference: <testLibrary>::@setter::vOkArgumentType
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vOkArgumentType
    static isOriginVariable vWrongArgumentType
      reference: <testLibrary>::@setter::vWrongArgumentType
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vWrongArgumentType
  functions
    isOriginDeclaration f
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
        #F1 class A (nameOffset:101) (firstTokenOffset:95) (offset:101)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration staticClassVariable (nameOffset:118) (firstTokenOffset:118) (offset:118)
              element: <testLibrary>::@class::A::@field::staticClassVariable
            #F3 isOriginGetterSetter staticGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@class::A::@field::staticGetter
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 isOriginVariable staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::A::@getter::staticClassVariable
            #F6 isOriginDeclaration staticGetter (nameOffset:160) (firstTokenOffset:145) (offset:160)
              element: <testLibrary>::@class::A::@getter::staticGetter
          setters
            #F7 isOriginVariable staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::A::@setter::staticClassVariable
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::A::@setter::staticClassVariable::@formalParameter::value
          methods
            #F9 isOriginDeclaration staticClassMethod (nameOffset:195) (firstTokenOffset:181) (offset:195)
              element: <testLibrary>::@class::A::@method::staticClassMethod
              formalParameters
                #F10 requiredPositional p (nameOffset:217) (firstTokenOffset:213) (offset:217)
                  element: <testLibrary>::@class::A::@method::staticClassMethod::@formalParameter::p
            #F11 isOriginDeclaration instanceClassMethod (nameOffset:238) (firstTokenOffset:231) (offset:238)
              element: <testLibrary>::@class::A::@method::instanceClassMethod
              formalParameters
                #F12 requiredPositional p (nameOffset:262) (firstTokenOffset:258) (offset:262)
                  element: <testLibrary>::@class::A::@method::instanceClassMethod::@formalParameter::p
      topLevelVariables
        #F13 hasInitializer isOriginDeclaration topLevelVariable (nameOffset:44) (firstTokenOffset:44) (offset:44)
          element: <testLibrary>::@topLevelVariable::topLevelVariable
        #F14 isOriginGetterSetter topLevelGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@topLevelVariable::topLevelGetter
        #F15 hasInitializer isOriginDeclaration r_topLevelFunction (nameOffset:280) (firstTokenOffset:280) (offset:280)
          element: <testLibrary>::@topLevelVariable::r_topLevelFunction
        #F16 hasInitializer isOriginDeclaration r_topLevelVariable (nameOffset:323) (firstTokenOffset:323) (offset:323)
          element: <testLibrary>::@topLevelVariable::r_topLevelVariable
        #F17 hasInitializer isOriginDeclaration r_topLevelGetter (nameOffset:366) (firstTokenOffset:366) (offset:366)
          element: <testLibrary>::@topLevelVariable::r_topLevelGetter
        #F18 hasInitializer isOriginDeclaration r_staticClassVariable (nameOffset:405) (firstTokenOffset:405) (offset:405)
          element: <testLibrary>::@topLevelVariable::r_staticClassVariable
        #F19 hasInitializer isOriginDeclaration r_staticGetter (nameOffset:456) (firstTokenOffset:456) (offset:456)
          element: <testLibrary>::@topLevelVariable::r_staticGetter
        #F20 hasInitializer isOriginDeclaration r_staticClassMethod (nameOffset:493) (firstTokenOffset:493) (offset:493)
          element: <testLibrary>::@topLevelVariable::r_staticClassMethod
        #F21 hasInitializer isOriginDeclaration instanceOfA (nameOffset:540) (firstTokenOffset:540) (offset:540)
          element: <testLibrary>::@topLevelVariable::instanceOfA
        #F22 hasInitializer isOriginDeclaration r_instanceClassMethod (nameOffset:567) (firstTokenOffset:567) (offset:567)
          element: <testLibrary>::@topLevelVariable::r_instanceClassMethod
      getters
        #F23 isOriginVariable topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@getter::topLevelVariable
        #F24 isOriginDeclaration topLevelGetter (nameOffset:74) (firstTokenOffset:66) (offset:74)
          element: <testLibrary>::@getter::topLevelGetter
        #F25 isOriginVariable r_topLevelFunction (nameOffset:<null>) (firstTokenOffset:<null>) (offset:280)
          element: <testLibrary>::@getter::r_topLevelFunction
        #F26 isOriginVariable r_topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:323)
          element: <testLibrary>::@getter::r_topLevelVariable
        #F27 isOriginVariable r_topLevelGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:366)
          element: <testLibrary>::@getter::r_topLevelGetter
        #F28 isOriginVariable r_staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:405)
          element: <testLibrary>::@getter::r_staticClassVariable
        #F29 isOriginVariable r_staticGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:456)
          element: <testLibrary>::@getter::r_staticGetter
        #F30 isOriginVariable r_staticClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:493)
          element: <testLibrary>::@getter::r_staticClassMethod
        #F31 isOriginVariable instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:540)
          element: <testLibrary>::@getter::instanceOfA
        #F32 isOriginVariable r_instanceClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:567)
          element: <testLibrary>::@getter::r_instanceClassMethod
      setters
        #F33 isOriginVariable topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@setter::topLevelVariable
          formalParameters
            #F34 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@setter::topLevelVariable::@formalParameter::value
        #F35 isOriginVariable r_topLevelFunction (nameOffset:<null>) (firstTokenOffset:<null>) (offset:280)
          element: <testLibrary>::@setter::r_topLevelFunction
          formalParameters
            #F36 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:280)
              element: <testLibrary>::@setter::r_topLevelFunction::@formalParameter::value
        #F37 isOriginVariable r_topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:323)
          element: <testLibrary>::@setter::r_topLevelVariable
          formalParameters
            #F38 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:323)
              element: <testLibrary>::@setter::r_topLevelVariable::@formalParameter::value
        #F39 isOriginVariable r_topLevelGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:366)
          element: <testLibrary>::@setter::r_topLevelGetter
          formalParameters
            #F40 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:366)
              element: <testLibrary>::@setter::r_topLevelGetter::@formalParameter::value
        #F41 isOriginVariable r_staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:405)
          element: <testLibrary>::@setter::r_staticClassVariable
          formalParameters
            #F42 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:405)
              element: <testLibrary>::@setter::r_staticClassVariable::@formalParameter::value
        #F43 isOriginVariable r_staticGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:456)
          element: <testLibrary>::@setter::r_staticGetter
          formalParameters
            #F44 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:456)
              element: <testLibrary>::@setter::r_staticGetter::@formalParameter::value
        #F45 isOriginVariable r_staticClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:493)
          element: <testLibrary>::@setter::r_staticClassMethod
          formalParameters
            #F46 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:493)
              element: <testLibrary>::@setter::r_staticClassMethod::@formalParameter::value
        #F47 isOriginVariable instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:540)
          element: <testLibrary>::@setter::instanceOfA
          formalParameters
            #F48 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:540)
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::value
        #F49 isOriginVariable r_instanceClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:567)
          element: <testLibrary>::@setter::r_instanceClassMethod
          formalParameters
            #F50 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:567)
              element: <testLibrary>::@setter::r_instanceClassMethod::@formalParameter::value
      functions
        #F51 isOriginDeclaration topLevelFunction (nameOffset:7) (firstTokenOffset:0) (offset:7)
          element: <testLibrary>::@function::topLevelFunction
          formalParameters
            #F52 requiredPositional p (nameOffset:28) (firstTokenOffset:24) (offset:28)
              element: <testLibrary>::@function::topLevelFunction::@formalParameter::p
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasImplicitType hasInitializer isOriginDeclaration staticClassVariable
          reference: <testLibrary>::@class::A::@field::staticClassVariable
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::staticClassVariable
          setter: <testLibrary>::@class::A::@setter::staticClassVariable
        static isOriginGetterSetter staticGetter
          reference: <testLibrary>::@class::A::@field::staticGetter
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::staticGetter
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        static isOriginVariable staticClassVariable
          reference: <testLibrary>::@class::A::@getter::staticClassVariable
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::staticClassVariable
        static isOriginDeclaration staticGetter
          reference: <testLibrary>::@class::A::@getter::staticGetter
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::staticGetter
      setters
        static isOriginVariable staticClassVariable
          reference: <testLibrary>::@class::A::@setter::staticClassVariable
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::staticClassVariable
      methods
        static isOriginDeclaration staticClassMethod
          reference: <testLibrary>::@class::A::@method::staticClassMethod
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional p
              firstFragment: #F10
              type: int
          returnType: String
        isOriginDeclaration instanceClassMethod
          reference: <testLibrary>::@class::A::@method::instanceClassMethod
          firstFragment: #F11
          formalParameters
            #E2 requiredPositional p
              firstFragment: #F12
              type: int
          returnType: String
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration topLevelVariable
      reference: <testLibrary>::@topLevelVariable::topLevelVariable
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::topLevelVariable
      setter: <testLibrary>::@setter::topLevelVariable
    isOriginGetterSetter topLevelGetter
      reference: <testLibrary>::@topLevelVariable::topLevelGetter
      firstFragment: #F14
      type: int
      getter: <testLibrary>::@getter::topLevelGetter
    hasImplicitType hasInitializer isOriginDeclaration r_topLevelFunction
      reference: <testLibrary>::@topLevelVariable::r_topLevelFunction
      firstFragment: #F15
      type: String Function(int)
      getter: <testLibrary>::@getter::r_topLevelFunction
      setter: <testLibrary>::@setter::r_topLevelFunction
    hasImplicitType hasInitializer isOriginDeclaration r_topLevelVariable
      reference: <testLibrary>::@topLevelVariable::r_topLevelVariable
      firstFragment: #F16
      type: int
      getter: <testLibrary>::@getter::r_topLevelVariable
      setter: <testLibrary>::@setter::r_topLevelVariable
    hasImplicitType hasInitializer isOriginDeclaration r_topLevelGetter
      reference: <testLibrary>::@topLevelVariable::r_topLevelGetter
      firstFragment: #F17
      type: int
      getter: <testLibrary>::@getter::r_topLevelGetter
      setter: <testLibrary>::@setter::r_topLevelGetter
    hasImplicitType hasInitializer isOriginDeclaration r_staticClassVariable
      reference: <testLibrary>::@topLevelVariable::r_staticClassVariable
      firstFragment: #F18
      type: int
      getter: <testLibrary>::@getter::r_staticClassVariable
      setter: <testLibrary>::@setter::r_staticClassVariable
    hasImplicitType hasInitializer isOriginDeclaration r_staticGetter
      reference: <testLibrary>::@topLevelVariable::r_staticGetter
      firstFragment: #F19
      type: int
      getter: <testLibrary>::@getter::r_staticGetter
      setter: <testLibrary>::@setter::r_staticGetter
    hasImplicitType hasInitializer isOriginDeclaration r_staticClassMethod
      reference: <testLibrary>::@topLevelVariable::r_staticClassMethod
      firstFragment: #F20
      type: String Function(int)
      getter: <testLibrary>::@getter::r_staticClassMethod
      setter: <testLibrary>::@setter::r_staticClassMethod
    hasImplicitType hasInitializer isOriginDeclaration instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F21
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasImplicitType hasInitializer isOriginDeclaration r_instanceClassMethod
      reference: <testLibrary>::@topLevelVariable::r_instanceClassMethod
      firstFragment: #F22
      type: String Function(int)
      getter: <testLibrary>::@getter::r_instanceClassMethod
      setter: <testLibrary>::@setter::r_instanceClassMethod
  getters
    static isOriginVariable topLevelVariable
      reference: <testLibrary>::@getter::topLevelVariable
      firstFragment: #F23
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelVariable
    static isOriginDeclaration topLevelGetter
      reference: <testLibrary>::@getter::topLevelGetter
      firstFragment: #F24
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelGetter
    static isOriginVariable r_topLevelFunction
      reference: <testLibrary>::@getter::r_topLevelFunction
      firstFragment: #F25
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_topLevelFunction
    static isOriginVariable r_topLevelVariable
      reference: <testLibrary>::@getter::r_topLevelVariable
      firstFragment: #F26
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelVariable
    static isOriginVariable r_topLevelGetter
      reference: <testLibrary>::@getter::r_topLevelGetter
      firstFragment: #F27
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelGetter
    static isOriginVariable r_staticClassVariable
      reference: <testLibrary>::@getter::r_staticClassVariable
      firstFragment: #F28
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticClassVariable
    static isOriginVariable r_staticGetter
      reference: <testLibrary>::@getter::r_staticGetter
      firstFragment: #F29
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticGetter
    static isOriginVariable r_staticClassMethod
      reference: <testLibrary>::@getter::r_staticClassMethod
      firstFragment: #F30
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_staticClassMethod
    static isOriginVariable instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F31
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    static isOriginVariable r_instanceClassMethod
      reference: <testLibrary>::@getter::r_instanceClassMethod
      firstFragment: #F32
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_instanceClassMethod
  setters
    static isOriginVariable topLevelVariable
      reference: <testLibrary>::@setter::topLevelVariable
      firstFragment: #F33
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F34
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::topLevelVariable
    static isOriginVariable r_topLevelFunction
      reference: <testLibrary>::@setter::r_topLevelFunction
      firstFragment: #F35
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F36
          type: String Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_topLevelFunction
    static isOriginVariable r_topLevelVariable
      reference: <testLibrary>::@setter::r_topLevelVariable
      firstFragment: #F37
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F38
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_topLevelVariable
    static isOriginVariable r_topLevelGetter
      reference: <testLibrary>::@setter::r_topLevelGetter
      firstFragment: #F39
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F40
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_topLevelGetter
    static isOriginVariable r_staticClassVariable
      reference: <testLibrary>::@setter::r_staticClassVariable
      firstFragment: #F41
      formalParameters
        #E7 requiredPositional value
          firstFragment: #F42
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_staticClassVariable
    static isOriginVariable r_staticGetter
      reference: <testLibrary>::@setter::r_staticGetter
      firstFragment: #F43
      formalParameters
        #E8 requiredPositional value
          firstFragment: #F44
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_staticGetter
    static isOriginVariable r_staticClassMethod
      reference: <testLibrary>::@setter::r_staticClassMethod
      firstFragment: #F45
      formalParameters
        #E9 requiredPositional value
          firstFragment: #F46
          type: String Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_staticClassMethod
    static isOriginVariable instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F47
      formalParameters
        #E10 requiredPositional value
          firstFragment: #F48
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    static isOriginVariable r_instanceClassMethod
      reference: <testLibrary>::@setter::r_instanceClassMethod
      firstFragment: #F49
      formalParameters
        #E11 requiredPositional value
          firstFragment: #F50
          type: String Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_instanceClassMethod
  functions
    isOriginDeclaration topLevelFunction
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration a (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::A::@field::a
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@getter::a
          setters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::value
        #F7 class B (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer isOriginDeclaration b (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::B::@field::b
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@getter::b
          setters
            #F11 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@setter::b
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
                  element: <testLibrary>::@class::B::@setter::b::@formalParameter::value
      topLevelVariables
        #F13 hasInitializer isOriginDeclaration c (nameOffset:72) (firstTokenOffset:72) (offset:72)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F14 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@getter::c
      setters
        #F15 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@setter::c
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        static isOriginVariable a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        static hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@class::B::@field::b
          firstFragment: #F8
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::b
          setter: <testLibrary>::@class::B::@setter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        static isOriginVariable b
          reference: <testLibrary>::@class::B::@getter::b
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::b
      setters
        static isOriginVariable b
          reference: <testLibrary>::@class::B::@setter::b
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::B::@field::b
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F13
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    static isOriginVariable c
      reference: <testLibrary>::@setter::c
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration a (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::A::@field::a
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@getter::a
          setters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration b (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::b
        #F8 hasInitializer isOriginDeclaration c (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F9 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::b
        #F10 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::c
      setters
        #F11 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::b
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::b::@formalParameter::value
        #F13 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::c
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        static isOriginVariable a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F7
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasImplicitType hasInitializer isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F8
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F10
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    static isOriginVariable b
      reference: <testLibrary>::@setter::b
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginVariable c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer isOriginDeclaration c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
        #F4 hasInitializer isOriginDeclaration d (nameOffset:45) (firstTokenOffset:45) (offset:45)
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F6 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
        #F7 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
        #F8 isOriginVariable d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
          element: <testLibrary>::@getter::d
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasImplicitType hasInitializer isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::c
    final hasImplicitType hasInitializer isOriginDeclaration d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    static isOriginVariable d
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration a (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::a
      setters
        #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::a::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
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
        #F1 hasInitializer isOriginDeclaration s (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::s
        #F2 hasInitializer isOriginDeclaration h (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::h
      getters
        #F3 isOriginVariable s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::s
        #F4 isOriginVariable h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::h
      setters
        #F5 isOriginVariable s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::s
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::s::@formalParameter::value
        #F7 isOriginVariable h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::h
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::h::@formalParameter::value
      functions
        #F9 isOriginDeclaration f (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@function::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F1
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasImplicitType hasInitializer isOriginDeclaration h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    static isOriginVariable s
      reference: <testLibrary>::@getter::s
      firstFragment: #F3
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    static isOriginVariable h
      reference: <testLibrary>::@getter::h
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    static isOriginVariable s
      reference: <testLibrary>::@setter::s
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
    static isOriginVariable h
      reference: <testLibrary>::@setter::h
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::h
  functions
    isOriginDeclaration f
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
        #F1 isOriginDeclaration d (nameOffset:8) (firstTokenOffset:8) (offset:8)
          element: <testLibrary>::@topLevelVariable::d
        #F2 hasInitializer isOriginDeclaration s (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::s
        #F3 hasInitializer isOriginDeclaration h (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::h
      getters
        #F4 isOriginVariable d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@getter::d
        #F5 isOriginVariable s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::s
        #F6 isOriginVariable h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::h
      setters
        #F7 isOriginVariable d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@setter::d
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@setter::d::@formalParameter::value
        #F9 isOriginVariable s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::s
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::s::@formalParameter::value
        #F11 isOriginVariable h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::h
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::h::@formalParameter::value
  topLevelVariables
    isOriginDeclaration d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
    hasImplicitType hasInitializer isOriginDeclaration s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F2
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasImplicitType hasInitializer isOriginDeclaration h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    static isOriginVariable d
      reference: <testLibrary>::@getter::d
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
    static isOriginVariable s
      reference: <testLibrary>::@getter::s
      firstFragment: #F5
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    static isOriginVariable h
      reference: <testLibrary>::@getter::h
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    static isOriginVariable d
      reference: <testLibrary>::@setter::d
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
    static isOriginVariable s
      reference: <testLibrary>::@setter::s
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
    static isOriginVariable h
      reference: <testLibrary>::@setter::h
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::h
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration b (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::b
      setters
        #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F7 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::b
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::b::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: double
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: double
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@setter::b
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
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
        #F1 hasInitializer isOriginDeclaration vObject (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vObject
        #F2 hasInitializer isOriginDeclaration vNum (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::vNum
        #F3 hasInitializer isOriginDeclaration vNumEmpty (nameOffset:64) (firstTokenOffset:64) (offset:64)
          element: <testLibrary>::@topLevelVariable::vNumEmpty
        #F4 hasInitializer isOriginDeclaration vInt (nameOffset:89) (firstTokenOffset:89) (offset:89)
          element: <testLibrary>::@topLevelVariable::vInt
      getters
        #F5 isOriginVariable vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vObject
        #F6 isOriginVariable vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::vNum
        #F7 isOriginVariable vNumEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@getter::vNumEmpty
        #F8 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@getter::vInt
      setters
        #F9 isOriginVariable vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vObject
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vObject::@formalParameter::value
        #F11 isOriginVariable vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::vNum
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::vNum::@formalParameter::value
        #F13 isOriginVariable vNumEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@setter::vNumEmpty
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@setter::vNumEmpty::@formalParameter::value
        #F15 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F1
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
    hasImplicitType hasInitializer isOriginDeclaration vNum
      reference: <testLibrary>::@topLevelVariable::vNum
      firstFragment: #F2
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasImplicitType hasInitializer isOriginDeclaration vNumEmpty
      reference: <testLibrary>::@topLevelVariable::vNumEmpty
      firstFragment: #F3
      type: List<num>
      getter: <testLibrary>::@getter::vNumEmpty
      setter: <testLibrary>::@setter::vNumEmpty
    hasImplicitType hasInitializer isOriginDeclaration vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F4
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
  getters
    static isOriginVariable vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F5
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
    static isOriginVariable vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F6
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    static isOriginVariable vNumEmpty
      reference: <testLibrary>::@getter::vNumEmpty
      firstFragment: #F7
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNumEmpty
    static isOriginVariable vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F8
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
  setters
    static isOriginVariable vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: List<Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vObject
    static isOriginVariable vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNum
    static isOriginVariable vNumEmpty
      reference: <testLibrary>::@setter::vNumEmpty
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumEmpty
    static isOriginVariable vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F16
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
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
        #F1 hasInitializer isOriginDeclaration vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
        #F2 hasInitializer isOriginDeclaration vNum (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::vNum
        #F3 hasInitializer isOriginDeclaration vObject (nameOffset:47) (firstTokenOffset:47) (offset:47)
          element: <testLibrary>::@topLevelVariable::vObject
      getters
        #F4 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
        #F5 isOriginVariable vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::vNum
        #F6 isOriginVariable vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@getter::vObject
      setters
        #F7 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F9 isOriginVariable vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::vNum
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::vNum::@formalParameter::value
        #F11 isOriginVariable vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@setter::vObject
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@setter::vObject::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration vNum
      reference: <testLibrary>::@topLevelVariable::vNum
      firstFragment: #F2
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasImplicitType hasInitializer isOriginDeclaration vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F3
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
  getters
    static isOriginVariable vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F4
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F5
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    static isOriginVariable vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F6
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
  setters
    static isOriginVariable vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNum
    static isOriginVariable vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: List<Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vObject
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
        #F1 hasInitializer isOriginDeclaration vObjectObject (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vObjectObject
        #F2 hasInitializer isOriginDeclaration vComparableObject (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::vComparableObject
        #F3 hasInitializer isOriginDeclaration vNumString (nameOffset:109) (firstTokenOffset:109) (offset:109)
          element: <testLibrary>::@topLevelVariable::vNumString
        #F4 hasInitializer isOriginDeclaration vNumStringEmpty (nameOffset:149) (firstTokenOffset:149) (offset:149)
          element: <testLibrary>::@topLevelVariable::vNumStringEmpty
        #F5 hasInitializer isOriginDeclaration vIntString (nameOffset:188) (firstTokenOffset:188) (offset:188)
          element: <testLibrary>::@topLevelVariable::vIntString
      getters
        #F6 isOriginVariable vObjectObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vObjectObject
        #F7 isOriginVariable vComparableObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::vComparableObject
        #F8 isOriginVariable vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@getter::vNumString
        #F9 isOriginVariable vNumStringEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
          element: <testLibrary>::@getter::vNumStringEmpty
        #F10 isOriginVariable vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:188)
          element: <testLibrary>::@getter::vIntString
      setters
        #F11 isOriginVariable vObjectObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vObjectObject
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vObjectObject::@formalParameter::value
        #F13 isOriginVariable vComparableObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::vComparableObject
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::vComparableObject::@formalParameter::value
        #F15 isOriginVariable vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@setter::vNumString
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
              element: <testLibrary>::@setter::vNumString::@formalParameter::value
        #F17 isOriginVariable vNumStringEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
          element: <testLibrary>::@setter::vNumStringEmpty
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
              element: <testLibrary>::@setter::vNumStringEmpty::@formalParameter::value
        #F19 isOriginVariable vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:188)
          element: <testLibrary>::@setter::vIntString
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:188)
              element: <testLibrary>::@setter::vIntString::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vObjectObject
      reference: <testLibrary>::@topLevelVariable::vObjectObject
      firstFragment: #F1
      type: Map<Object, Object>
      getter: <testLibrary>::@getter::vObjectObject
      setter: <testLibrary>::@setter::vObjectObject
    hasImplicitType hasInitializer isOriginDeclaration vComparableObject
      reference: <testLibrary>::@topLevelVariable::vComparableObject
      firstFragment: #F2
      type: Map<Comparable<int>, Object>
      getter: <testLibrary>::@getter::vComparableObject
      setter: <testLibrary>::@setter::vComparableObject
    hasImplicitType hasInitializer isOriginDeclaration vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F3
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasImplicitType hasInitializer isOriginDeclaration vNumStringEmpty
      reference: <testLibrary>::@topLevelVariable::vNumStringEmpty
      firstFragment: #F4
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumStringEmpty
      setter: <testLibrary>::@setter::vNumStringEmpty
    hasImplicitType hasInitializer isOriginDeclaration vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F5
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
  getters
    static isOriginVariable vObjectObject
      reference: <testLibrary>::@getter::vObjectObject
      firstFragment: #F6
      returnType: Map<Object, Object>
      variable: <testLibrary>::@topLevelVariable::vObjectObject
    static isOriginVariable vComparableObject
      reference: <testLibrary>::@getter::vComparableObject
      firstFragment: #F7
      returnType: Map<Comparable<int>, Object>
      variable: <testLibrary>::@topLevelVariable::vComparableObject
    static isOriginVariable vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F8
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    static isOriginVariable vNumStringEmpty
      reference: <testLibrary>::@getter::vNumStringEmpty
      firstFragment: #F9
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumStringEmpty
    static isOriginVariable vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F10
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
  setters
    static isOriginVariable vObjectObject
      reference: <testLibrary>::@setter::vObjectObject
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F12
          type: Map<Object, Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vObjectObject
    static isOriginVariable vComparableObject
      reference: <testLibrary>::@setter::vComparableObject
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: Map<Comparable<int>, Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vComparableObject
    static isOriginVariable vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: Map<num, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumString
    static isOriginVariable vNumStringEmpty
      reference: <testLibrary>::@setter::vNumStringEmpty
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F18
          type: Map<num, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumStringEmpty
    static isOriginVariable vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F20
          type: Map<int, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIntString
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
        #F1 hasInitializer isOriginDeclaration vIntString (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vIntString
        #F2 hasInitializer isOriginDeclaration vNumString (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::vNumString
        #F3 hasInitializer isOriginDeclaration vIntObject (nameOffset:76) (firstTokenOffset:76) (offset:76)
          element: <testLibrary>::@topLevelVariable::vIntObject
      getters
        #F4 isOriginVariable vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vIntString
        #F5 isOriginVariable vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::vNumString
        #F6 isOriginVariable vIntObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@getter::vIntObject
      setters
        #F7 isOriginVariable vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vIntString
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vIntString::@formalParameter::value
        #F9 isOriginVariable vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::vNumString
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::vNumString::@formalParameter::value
        #F11 isOriginVariable vIntObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@setter::vIntObject
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@setter::vIntObject::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F1
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
    hasImplicitType hasInitializer isOriginDeclaration vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F2
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasImplicitType hasInitializer isOriginDeclaration vIntObject
      reference: <testLibrary>::@topLevelVariable::vIntObject
      firstFragment: #F3
      type: Map<int, Object>
      getter: <testLibrary>::@getter::vIntObject
      setter: <testLibrary>::@setter::vIntObject
  getters
    static isOriginVariable vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F4
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
    static isOriginVariable vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F5
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    static isOriginVariable vIntObject
      reference: <testLibrary>::@getter::vIntObject
      firstFragment: #F6
      returnType: Map<int, Object>
      variable: <testLibrary>::@topLevelVariable::vIntObject
  setters
    static isOriginVariable vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: Map<int, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIntString
    static isOriginVariable vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: Map<num, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumString
    static isOriginVariable vIntObject
      reference: <testLibrary>::@setter::vIntObject
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: Map<int, Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIntObject
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration b (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer isOriginDeclaration vEq (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::vEq
        #F4 hasInitializer isOriginDeclaration vAnd (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::vAnd
        #F5 hasInitializer isOriginDeclaration vOr (nameOffset:69) (firstTokenOffset:69) (offset:69)
          element: <testLibrary>::@topLevelVariable::vOr
      getters
        #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F7 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::b
        #F8 isOriginVariable vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::vEq
        #F9 isOriginVariable vAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::vAnd
        #F10 isOriginVariable vOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@getter::vOr
      setters
        #F11 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F13 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::b
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::b::@formalParameter::value
        #F15 isOriginVariable vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::vEq::@formalParameter::value
        #F17 isOriginVariable vAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::vAnd
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::vAnd::@formalParameter::value
        #F19 isOriginVariable vOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@setter::vOr
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@setter::vOr::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasImplicitType hasInitializer isOriginDeclaration vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F3
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasImplicitType hasInitializer isOriginDeclaration vAnd
      reference: <testLibrary>::@topLevelVariable::vAnd
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vAnd
      setter: <testLibrary>::@setter::vAnd
    hasImplicitType hasInitializer isOriginDeclaration vOr
      reference: <testLibrary>::@topLevelVariable::vOr
      firstFragment: #F5
      type: bool
      getter: <testLibrary>::@getter::vOr
      setter: <testLibrary>::@setter::vOr
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginVariable vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    static isOriginVariable vAnd
      reference: <testLibrary>::@getter::vAnd
      firstFragment: #F9
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vAnd
    static isOriginVariable vOr
      reference: <testLibrary>::@getter::vOr
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vOr
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F12
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@setter::b
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginVariable vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vEq
    static isOriginVariable vAnd
      reference: <testLibrary>::@setter::vAnd
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F18
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vAnd
    static isOriginVariable vOr
      reference: <testLibrary>::@setter::vOr
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F20
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vOr
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional p (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::p
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration instanceOfA (nameOffset:43) (firstTokenOffset:43) (offset:43)
          element: <testLibrary>::@topLevelVariable::instanceOfA
        #F6 hasInitializer isOriginDeclaration v1 (nameOffset:70) (firstTokenOffset:70) (offset:70)
          element: <testLibrary>::@topLevelVariable::v1
        #F7 hasInitializer isOriginDeclaration v2 (nameOffset:96) (firstTokenOffset:96) (offset:96)
          element: <testLibrary>::@topLevelVariable::v2
      getters
        #F8 isOriginVariable instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@getter::instanceOfA
        #F9 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@getter::v1
        #F10 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
          element: <testLibrary>::@getter::v2
      setters
        #F11 isOriginVariable instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@setter::instanceOfA
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::value
        #F13 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@setter::v1
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@setter::v1::@formalParameter::value
        #F15 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
          element: <testLibrary>::@setter::v2
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@setter::v2::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional p
              firstFragment: #F4
              type: int
          returnType: String
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F5
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasImplicitType hasInitializer isOriginDeclaration v1
      reference: <testLibrary>::@topLevelVariable::v1
      firstFragment: #F6
      type: String
      getter: <testLibrary>::@getter::v1
      setter: <testLibrary>::@setter::v1
    hasImplicitType hasInitializer isOriginDeclaration v2
      reference: <testLibrary>::@topLevelVariable::v2
      firstFragment: #F7
      type: String
      getter: <testLibrary>::@getter::v2
      setter: <testLibrary>::@setter::v2
  getters
    static isOriginVariable instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F8
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    static isOriginVariable v1
      reference: <testLibrary>::@getter::v1
      firstFragment: #F9
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v1
    static isOriginVariable v2
      reference: <testLibrary>::@getter::v2
      firstFragment: #F10
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v2
  setters
    static isOriginVariable instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    static isOriginVariable v1
      reference: <testLibrary>::@setter::v1
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v1
    static isOriginVariable v2
      reference: <testLibrary>::@setter::v2
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F16
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v2
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
        #F1 hasInitializer isOriginDeclaration vModuloIntInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vModuloIntInt
        #F2 hasInitializer isOriginDeclaration vModuloIntDouble (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::vModuloIntDouble
        #F3 hasInitializer isOriginDeclaration vMultiplyIntInt (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::vMultiplyIntInt
        #F4 hasInitializer isOriginDeclaration vMultiplyIntDouble (nameOffset:92) (firstTokenOffset:92) (offset:92)
          element: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
        #F5 hasInitializer isOriginDeclaration vMultiplyDoubleInt (nameOffset:126) (firstTokenOffset:126) (offset:126)
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
        #F6 hasInitializer isOriginDeclaration vMultiplyDoubleDouble (nameOffset:160) (firstTokenOffset:160) (offset:160)
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
        #F7 hasInitializer isOriginDeclaration vDivideIntInt (nameOffset:199) (firstTokenOffset:199) (offset:199)
          element: <testLibrary>::@topLevelVariable::vDivideIntInt
        #F8 hasInitializer isOriginDeclaration vDivideIntDouble (nameOffset:226) (firstTokenOffset:226) (offset:226)
          element: <testLibrary>::@topLevelVariable::vDivideIntDouble
        #F9 hasInitializer isOriginDeclaration vDivideDoubleInt (nameOffset:258) (firstTokenOffset:258) (offset:258)
          element: <testLibrary>::@topLevelVariable::vDivideDoubleInt
        #F10 hasInitializer isOriginDeclaration vDivideDoubleDouble (nameOffset:290) (firstTokenOffset:290) (offset:290)
          element: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
        #F11 hasInitializer isOriginDeclaration vFloorDivide (nameOffset:327) (firstTokenOffset:327) (offset:327)
          element: <testLibrary>::@topLevelVariable::vFloorDivide
      getters
        #F12 isOriginVariable vModuloIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vModuloIntInt
        #F13 isOriginVariable vModuloIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::vModuloIntDouble
        #F14 isOriginVariable vMultiplyIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::vMultiplyIntInt
        #F15 isOriginVariable vMultiplyIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
          element: <testLibrary>::@getter::vMultiplyIntDouble
        #F16 isOriginVariable vMultiplyDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
          element: <testLibrary>::@getter::vMultiplyDoubleInt
        #F17 isOriginVariable vMultiplyDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:160)
          element: <testLibrary>::@getter::vMultiplyDoubleDouble
        #F18 isOriginVariable vDivideIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:199)
          element: <testLibrary>::@getter::vDivideIntInt
        #F19 isOriginVariable vDivideIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:226)
          element: <testLibrary>::@getter::vDivideIntDouble
        #F20 isOriginVariable vDivideDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
          element: <testLibrary>::@getter::vDivideDoubleInt
        #F21 isOriginVariable vDivideDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:290)
          element: <testLibrary>::@getter::vDivideDoubleDouble
        #F22 isOriginVariable vFloorDivide (nameOffset:<null>) (firstTokenOffset:<null>) (offset:327)
          element: <testLibrary>::@getter::vFloorDivide
      setters
        #F23 isOriginVariable vModuloIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vModuloIntInt
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vModuloIntInt::@formalParameter::value
        #F25 isOriginVariable vModuloIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::vModuloIntDouble
          formalParameters
            #F26 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::vModuloIntDouble::@formalParameter::value
        #F27 isOriginVariable vMultiplyIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@setter::vMultiplyIntInt
          formalParameters
            #F28 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@setter::vMultiplyIntInt::@formalParameter::value
        #F29 isOriginVariable vMultiplyIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
          element: <testLibrary>::@setter::vMultiplyIntDouble
          formalParameters
            #F30 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@setter::vMultiplyIntDouble::@formalParameter::value
        #F31 isOriginVariable vMultiplyDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
          element: <testLibrary>::@setter::vMultiplyDoubleInt
          formalParameters
            #F32 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
              element: <testLibrary>::@setter::vMultiplyDoubleInt::@formalParameter::value
        #F33 isOriginVariable vMultiplyDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:160)
          element: <testLibrary>::@setter::vMultiplyDoubleDouble
          formalParameters
            #F34 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:160)
              element: <testLibrary>::@setter::vMultiplyDoubleDouble::@formalParameter::value
        #F35 isOriginVariable vDivideIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:199)
          element: <testLibrary>::@setter::vDivideIntInt
          formalParameters
            #F36 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:199)
              element: <testLibrary>::@setter::vDivideIntInt::@formalParameter::value
        #F37 isOriginVariable vDivideIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:226)
          element: <testLibrary>::@setter::vDivideIntDouble
          formalParameters
            #F38 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:226)
              element: <testLibrary>::@setter::vDivideIntDouble::@formalParameter::value
        #F39 isOriginVariable vDivideDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
          element: <testLibrary>::@setter::vDivideDoubleInt
          formalParameters
            #F40 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
              element: <testLibrary>::@setter::vDivideDoubleInt::@formalParameter::value
        #F41 isOriginVariable vDivideDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:290)
          element: <testLibrary>::@setter::vDivideDoubleDouble
          formalParameters
            #F42 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:290)
              element: <testLibrary>::@setter::vDivideDoubleDouble::@formalParameter::value
        #F43 isOriginVariable vFloorDivide (nameOffset:<null>) (firstTokenOffset:<null>) (offset:327)
          element: <testLibrary>::@setter::vFloorDivide
          formalParameters
            #F44 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:327)
              element: <testLibrary>::@setter::vFloorDivide::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vModuloIntInt
      reference: <testLibrary>::@topLevelVariable::vModuloIntInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vModuloIntInt
      setter: <testLibrary>::@setter::vModuloIntInt
    hasImplicitType hasInitializer isOriginDeclaration vModuloIntDouble
      reference: <testLibrary>::@topLevelVariable::vModuloIntDouble
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vModuloIntDouble
      setter: <testLibrary>::@setter::vModuloIntDouble
    hasImplicitType hasInitializer isOriginDeclaration vMultiplyIntInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vMultiplyIntInt
      setter: <testLibrary>::@setter::vMultiplyIntInt
    hasImplicitType hasInitializer isOriginDeclaration vMultiplyIntDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vMultiplyIntDouble
      setter: <testLibrary>::@setter::vMultiplyIntDouble
    hasImplicitType hasInitializer isOriginDeclaration vMultiplyDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleInt
      setter: <testLibrary>::@setter::vMultiplyDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration vMultiplyDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleDouble
      setter: <testLibrary>::@setter::vMultiplyDoubleDouble
    hasImplicitType hasInitializer isOriginDeclaration vDivideIntInt
      reference: <testLibrary>::@topLevelVariable::vDivideIntInt
      firstFragment: #F7
      type: double
      getter: <testLibrary>::@getter::vDivideIntInt
      setter: <testLibrary>::@setter::vDivideIntInt
    hasImplicitType hasInitializer isOriginDeclaration vDivideIntDouble
      reference: <testLibrary>::@topLevelVariable::vDivideIntDouble
      firstFragment: #F8
      type: double
      getter: <testLibrary>::@getter::vDivideIntDouble
      setter: <testLibrary>::@setter::vDivideIntDouble
    hasImplicitType hasInitializer isOriginDeclaration vDivideDoubleInt
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleInt
      firstFragment: #F9
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleInt
      setter: <testLibrary>::@setter::vDivideDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration vDivideDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleDouble
      setter: <testLibrary>::@setter::vDivideDoubleDouble
    hasImplicitType hasInitializer isOriginDeclaration vFloorDivide
      reference: <testLibrary>::@topLevelVariable::vFloorDivide
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::vFloorDivide
      setter: <testLibrary>::@setter::vFloorDivide
  getters
    static isOriginVariable vModuloIntInt
      reference: <testLibrary>::@getter::vModuloIntInt
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vModuloIntInt
    static isOriginVariable vModuloIntDouble
      reference: <testLibrary>::@getter::vModuloIntDouble
      firstFragment: #F13
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vModuloIntDouble
    static isOriginVariable vMultiplyIntInt
      reference: <testLibrary>::@getter::vMultiplyIntInt
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntInt
    static isOriginVariable vMultiplyIntDouble
      reference: <testLibrary>::@getter::vMultiplyIntDouble
      firstFragment: #F15
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
    static isOriginVariable vMultiplyDoubleInt
      reference: <testLibrary>::@getter::vMultiplyDoubleInt
      firstFragment: #F16
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
    static isOriginVariable vMultiplyDoubleDouble
      reference: <testLibrary>::@getter::vMultiplyDoubleDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
    static isOriginVariable vDivideIntInt
      reference: <testLibrary>::@getter::vDivideIntInt
      firstFragment: #F18
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntInt
    static isOriginVariable vDivideIntDouble
      reference: <testLibrary>::@getter::vDivideIntDouble
      firstFragment: #F19
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntDouble
    static isOriginVariable vDivideDoubleInt
      reference: <testLibrary>::@getter::vDivideDoubleInt
      firstFragment: #F20
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleInt
    static isOriginVariable vDivideDoubleDouble
      reference: <testLibrary>::@getter::vDivideDoubleDouble
      firstFragment: #F21
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
    static isOriginVariable vFloorDivide
      reference: <testLibrary>::@getter::vFloorDivide
      firstFragment: #F22
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vFloorDivide
  setters
    static isOriginVariable vModuloIntInt
      reference: <testLibrary>::@setter::vModuloIntInt
      firstFragment: #F23
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F24
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vModuloIntInt
    static isOriginVariable vModuloIntDouble
      reference: <testLibrary>::@setter::vModuloIntDouble
      firstFragment: #F25
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F26
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vModuloIntDouble
    static isOriginVariable vMultiplyIntInt
      reference: <testLibrary>::@setter::vMultiplyIntInt
      firstFragment: #F27
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F28
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntInt
    static isOriginVariable vMultiplyIntDouble
      reference: <testLibrary>::@setter::vMultiplyIntDouble
      firstFragment: #F29
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F30
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
    static isOriginVariable vMultiplyDoubleInt
      reference: <testLibrary>::@setter::vMultiplyDoubleInt
      firstFragment: #F31
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F32
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
    static isOriginVariable vMultiplyDoubleDouble
      reference: <testLibrary>::@setter::vMultiplyDoubleDouble
      firstFragment: #F33
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F34
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
    static isOriginVariable vDivideIntInt
      reference: <testLibrary>::@setter::vDivideIntInt
      firstFragment: #F35
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F36
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideIntInt
    static isOriginVariable vDivideIntDouble
      reference: <testLibrary>::@setter::vDivideIntDouble
      firstFragment: #F37
      formalParameters
        #E7 requiredPositional value
          firstFragment: #F38
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideIntDouble
    static isOriginVariable vDivideDoubleInt
      reference: <testLibrary>::@setter::vDivideDoubleInt
      firstFragment: #F39
      formalParameters
        #E8 requiredPositional value
          firstFragment: #F40
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleInt
    static isOriginVariable vDivideDoubleDouble
      reference: <testLibrary>::@setter::vDivideDoubleDouble
      firstFragment: #F41
      formalParameters
        #E9 requiredPositional value
          firstFragment: #F42
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
    static isOriginVariable vFloorDivide
      reference: <testLibrary>::@setter::vFloorDivide
      firstFragment: #F43
      formalParameters
        #E10 requiredPositional value
          firstFragment: #F44
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vFloorDivide
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer isOriginDeclaration vEq (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::vEq
        #F3 hasInitializer isOriginDeclaration vNotEq (nameOffset:46) (firstTokenOffset:46) (offset:46)
          element: <testLibrary>::@topLevelVariable::vNotEq
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F5 isOriginVariable vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::vEq
        #F6 isOriginVariable vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@getter::vNotEq
      setters
        #F7 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F9 isOriginVariable vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::vEq
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::vEq::@formalParameter::value
        #F11 isOriginVariable vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@setter::vNotEq
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@setter::vNotEq::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasImplicitType hasInitializer isOriginDeclaration vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F3
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    static isOriginVariable vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vEq
    static isOriginVariable vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNotEq
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
      setters
        #F3 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
  setters
    static isOriginVariable V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
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
        #F1 hasInitializer isOriginDeclaration vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
        #F2 hasInitializer isOriginDeclaration vDouble (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer isOriginDeclaration vIncInt (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer isOriginDeclaration vDecInt (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::vDecInt
        #F5 hasInitializer isOriginDeclaration vIncDouble (nameOffset:81) (firstTokenOffset:81) (offset:81)
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer isOriginDeclaration vDecDouble (nameOffset:109) (firstTokenOffset:109) (offset:109)
          element: <testLibrary>::@topLevelVariable::vDecDouble
      getters
        #F7 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
        #F8 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::vDouble
        #F9 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::vIncInt
        #F10 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::vDecInt
        #F11 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@getter::vIncDouble
        #F12 isOriginVariable vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@getter::vDecDouble
      setters
        #F13 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F15 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F17 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F19 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::vDecInt
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::vDecInt::@formalParameter::value
        #F21 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F23 isOriginVariable vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@setter::vDecDouble
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
              element: <testLibrary>::@setter::vDecDouble::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasImplicitType hasInitializer isOriginDeclaration vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    static isOriginVariable vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    static isOriginVariable vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F22
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecDouble
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
        #F1 hasInitializer isOriginDeclaration vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
        #F2 hasInitializer isOriginDeclaration vDouble (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer isOriginDeclaration vIncInt (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer isOriginDeclaration vDecInt (nameOffset:66) (firstTokenOffset:66) (offset:66)
          element: <testLibrary>::@topLevelVariable::vDecInt
        #F5 hasInitializer isOriginDeclaration vIncDouble (nameOffset:91) (firstTokenOffset:91) (offset:91)
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer isOriginDeclaration vDecDouble (nameOffset:122) (firstTokenOffset:122) (offset:122)
          element: <testLibrary>::@topLevelVariable::vDecDouble
      getters
        #F7 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
        #F8 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::vDouble
        #F9 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::vIncInt
        #F10 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@getter::vDecInt
        #F11 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@getter::vIncDouble
        #F12 isOriginVariable vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@getter::vDecDouble
      setters
        #F13 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F15 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F17 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F19 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@setter::vDecInt
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@setter::vDecInt::@formalParameter::value
        #F21 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F23 isOriginVariable vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@setter::vDecDouble
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@setter::vDecDouble::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F2
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasImplicitType hasInitializer isOriginDeclaration vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    static isOriginVariable vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    static isOriginVariable vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F14
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: List<double>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F22
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecDouble
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
        #F1 hasInitializer isOriginDeclaration vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
        #F2 hasInitializer isOriginDeclaration vDouble (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer isOriginDeclaration vIncInt (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer isOriginDeclaration vDecInt (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::0
        #F5 hasInitializer isOriginDeclaration vIncDouble (nameOffset:81) (firstTokenOffset:81) (offset:81)
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer isOriginDeclaration vDecInt (nameOffset:109) (firstTokenOffset:109) (offset:109)
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      getters
        #F7 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
        #F8 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::vDouble
        #F9 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::vIncInt
        #F10 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::vDecInt::@def::0
        #F11 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@getter::vIncDouble
        #F12 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@getter::vDecInt::@def::1
      setters
        #F13 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F15 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F17 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F19 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::vDecInt::@def::0
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::vDecInt::@def::0::@formalParameter::value
        #F21 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F23 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@setter::vDecInt::@def::1
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
              element: <testLibrary>::@setter::vDecInt::@def::1::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::0
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt::@def::0
      setter: <testLibrary>::@setter::vDecInt::@def::0
    hasImplicitType hasInitializer isOriginDeclaration vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecInt::@def::1
      setter: <testLibrary>::@setter::vDecInt::@def::1
  getters
    static isOriginVariable vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::0
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::1
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
  setters
    static isOriginVariable vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::0
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F22
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::1
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
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
        #F1 hasInitializer isOriginDeclaration vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
        #F2 hasInitializer isOriginDeclaration vDouble (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::vDouble
        #F3 hasInitializer isOriginDeclaration vIncInt (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::vIncInt
        #F4 hasInitializer isOriginDeclaration vDecInt (nameOffset:66) (firstTokenOffset:66) (offset:66)
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::0
        #F5 hasInitializer isOriginDeclaration vIncDouble (nameOffset:91) (firstTokenOffset:91) (offset:91)
          element: <testLibrary>::@topLevelVariable::vIncDouble
        #F6 hasInitializer isOriginDeclaration vDecInt (nameOffset:122) (firstTokenOffset:122) (offset:122)
          element: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      getters
        #F7 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
        #F8 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::vDouble
        #F9 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::vIncInt
        #F10 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@getter::vDecInt::@def::0
        #F11 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@getter::vIncDouble
        #F12 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@getter::vDecInt::@def::1
      setters
        #F13 isOriginVariable vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F15 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::vDouble
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F17 isOriginVariable vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::vIncInt
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F19 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@setter::vDecInt::@def::0
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@setter::vDecInt::@def::0::@formalParameter::value
        #F21 isOriginVariable vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@setter::vIncDouble
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F23 isOriginVariable vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@setter::vDecInt::@def::1
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@setter::vDecInt::@def::1::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F2
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::0
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vDecInt::@def::0
      setter: <testLibrary>::@setter::vDecInt::@def::0
    hasImplicitType hasInitializer isOriginDeclaration vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F5
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt::@def::1
      firstFragment: #F6
      type: double
      getter: <testLibrary>::@getter::vDecInt::@def::1
      setter: <testLibrary>::@setter::vDecInt::@def::1
  getters
    static isOriginVariable vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F7
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F8
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::0
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecInt
      reference: <testLibrary>::@getter::vDecInt::@def::1
      firstFragment: #F12
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
  setters
    static isOriginVariable vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F14
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    static isOriginVariable vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: List<double>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F17
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    static isOriginVariable vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::0
      firstFragment: #F19
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::0
    static isOriginVariable vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F21
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F22
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    static isOriginVariable vDecInt
      reference: <testLibrary>::@setter::vDecInt::@def::1
      firstFragment: #F23
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt::@def::1
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
        #F1 hasInitializer isOriginDeclaration vNot (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vNot
      getters
        #F2 isOriginVariable vNot (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vNot
      setters
        #F3 isOriginVariable vNot (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vNot
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vNot::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vNot
      reference: <testLibrary>::@topLevelVariable::vNot
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vNot
      setter: <testLibrary>::@setter::vNot
  getters
    static isOriginVariable vNot
      reference: <testLibrary>::@getter::vNot
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNot
  setters
    static isOriginVariable vNot
      reference: <testLibrary>::@setter::vNot
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNot
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
        #F1 hasInitializer isOriginDeclaration vNegateInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vNegateInt
        #F2 hasInitializer isOriginDeclaration vNegateDouble (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::vNegateDouble
        #F3 hasInitializer isOriginDeclaration vComplement (nameOffset:51) (firstTokenOffset:51) (offset:51)
          element: <testLibrary>::@topLevelVariable::vComplement
      getters
        #F4 isOriginVariable vNegateInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vNegateInt
        #F5 isOriginVariable vNegateDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::vNegateDouble
        #F6 isOriginVariable vComplement (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@getter::vComplement
      setters
        #F7 isOriginVariable vNegateInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vNegateInt
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vNegateInt::@formalParameter::value
        #F9 isOriginVariable vNegateDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::vNegateDouble
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::vNegateDouble::@formalParameter::value
        #F11 isOriginVariable vComplement (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@setter::vComplement
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@setter::vComplement::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vNegateInt
      reference: <testLibrary>::@topLevelVariable::vNegateInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vNegateInt
      setter: <testLibrary>::@setter::vNegateInt
    hasImplicitType hasInitializer isOriginDeclaration vNegateDouble
      reference: <testLibrary>::@topLevelVariable::vNegateDouble
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::vNegateDouble
      setter: <testLibrary>::@setter::vNegateDouble
    hasImplicitType hasInitializer isOriginDeclaration vComplement
      reference: <testLibrary>::@topLevelVariable::vComplement
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::vComplement
      setter: <testLibrary>::@setter::vComplement
  getters
    static isOriginVariable vNegateInt
      reference: <testLibrary>::@getter::vNegateInt
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vNegateInt
    static isOriginVariable vNegateDouble
      reference: <testLibrary>::@getter::vNegateDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vNegateDouble
    static isOriginVariable vComplement
      reference: <testLibrary>::@getter::vComplement
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vComplement
  setters
    static isOriginVariable vNegateInt
      reference: <testLibrary>::@setter::vNegateInt
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNegateInt
    static isOriginVariable vNegateDouble
      reference: <testLibrary>::@setter::vNegateDouble
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNegateDouble
    static isOriginVariable vComplement
      reference: <testLibrary>::@setter::vComplement
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vComplement
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginDeclaration d (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::d
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::d
          setters
            #F5 isOriginVariable d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@setter::d
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: <testLibrary>::@class::C::@setter::d::@formalParameter::value
        #F7 class D (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::D
          fields
            #F8 isOriginDeclaration i (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@class::D::@field::i
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F10 isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::D::@getter::i
          setters
            #F11 isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::D::@setter::i
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::value
      topLevelVariables
        #F13 hasInitializer isOriginDeclaration x (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F14 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static isOriginDeclaration d
          reference: <testLibrary>::@class::C::@field::d
          firstFragment: #F2
          type: D
          getter: <testLibrary>::@class::C::@getter::d
          setter: <testLibrary>::@class::C::@setter::d
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F4
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
      setters
        static isOriginVariable d
          reference: <testLibrary>::@class::C::@setter::d
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: D
          returnType: void
          variable: <testLibrary>::@class::C::@field::d
    hasNonFinalField class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      fields
        isOriginDeclaration i
          reference: <testLibrary>::@class::D::@field::i
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::D::@getter::i
          setter: <testLibrary>::@class::D::@setter::i
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::D::@field::i
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginGetterSetter d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::d
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginDeclaration d (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::C::@getter::d
        #F5 class D (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::D
          fields
            #F6 isOriginDeclaration i (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@class::D::@field::i
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F8 isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@getter::i
          setters
            #F9 isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@setter::i
              formalParameters
                #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::value
      topLevelVariables
        #F11 hasInitializer isOriginDeclaration x (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F12 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::x
      setters
        #F13 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@setter::x
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static isOriginGetterSetter d
          reference: <testLibrary>::@class::C::@field::d
          firstFragment: #F2
          type: D
          getter: <testLibrary>::@class::C::@getter::d
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static isOriginDeclaration d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F4
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
    hasNonFinalField class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      fields
        isOriginDeclaration i
          reference: <testLibrary>::@class::D::@field::i
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::D::@getter::i
          setter: <testLibrary>::@class::D::@setter::i
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
      getters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::D::@field::i
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration vLess (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vLess
        #F2 hasInitializer isOriginDeclaration vLessOrEqual (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::vLessOrEqual
        #F3 hasInitializer isOriginDeclaration vGreater (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::vGreater
        #F4 hasInitializer isOriginDeclaration vGreaterOrEqual (nameOffset:72) (firstTokenOffset:72) (offset:72)
          element: <testLibrary>::@topLevelVariable::vGreaterOrEqual
      getters
        #F5 isOriginVariable vLess (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vLess
        #F6 isOriginVariable vLessOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::vLessOrEqual
        #F7 isOriginVariable vGreater (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::vGreater
        #F8 isOriginVariable vGreaterOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@getter::vGreaterOrEqual
      setters
        #F9 isOriginVariable vLess (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vLess
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vLess::@formalParameter::value
        #F11 isOriginVariable vLessOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::vLessOrEqual
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::vLessOrEqual::@formalParameter::value
        #F13 isOriginVariable vGreater (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::vGreater
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::vGreater::@formalParameter::value
        #F15 isOriginVariable vGreaterOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@setter::vGreaterOrEqual
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@setter::vGreaterOrEqual::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration vLess
      reference: <testLibrary>::@topLevelVariable::vLess
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vLess
      setter: <testLibrary>::@setter::vLess
    hasImplicitType hasInitializer isOriginDeclaration vLessOrEqual
      reference: <testLibrary>::@topLevelVariable::vLessOrEqual
      firstFragment: #F2
      type: bool
      getter: <testLibrary>::@getter::vLessOrEqual
      setter: <testLibrary>::@setter::vLessOrEqual
    hasImplicitType hasInitializer isOriginDeclaration vGreater
      reference: <testLibrary>::@topLevelVariable::vGreater
      firstFragment: #F3
      type: bool
      getter: <testLibrary>::@getter::vGreater
      setter: <testLibrary>::@setter::vGreater
    hasImplicitType hasInitializer isOriginDeclaration vGreaterOrEqual
      reference: <testLibrary>::@topLevelVariable::vGreaterOrEqual
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vGreaterOrEqual
      setter: <testLibrary>::@setter::vGreaterOrEqual
  getters
    static isOriginVariable vLess
      reference: <testLibrary>::@getter::vLess
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLess
    static isOriginVariable vLessOrEqual
      reference: <testLibrary>::@getter::vLessOrEqual
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLessOrEqual
    static isOriginVariable vGreater
      reference: <testLibrary>::@getter::vGreater
      firstFragment: #F7
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreater
    static isOriginVariable vGreaterOrEqual
      reference: <testLibrary>::@getter::vGreaterOrEqual
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreaterOrEqual
  setters
    static isOriginVariable vLess
      reference: <testLibrary>::@setter::vLess
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vLess
    static isOriginVariable vLessOrEqual
      reference: <testLibrary>::@setter::vLessOrEqual
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vLessOrEqual
    static isOriginVariable vGreater
      reference: <testLibrary>::@setter::vGreater
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vGreater
    static isOriginVariable vGreaterOrEqual
      reference: <testLibrary>::@setter::vGreaterOrEqual
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F16
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vGreaterOrEqual
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F10 isOriginDeclaration x (nameOffset:59) (firstTokenOffset:55) (offset:59)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F11 requiredPositional <null-name> (nameOffset:<null>) (firstTokenOffset:61) (offset:61)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::<null-name>
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      setters
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional hasImplicitType <null-name>
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F3 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 25
              formalParameters
                #F4 optionalPositional final this.f (nameOffset:33) (firstTokenOffset:28) (offset:33)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
                  initializer: expression_0
                    SimpleStringLiteral
                      literal: 'hello' @37
          getters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
          setters
            #F6 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasDefaultValue hasImplicitType this.f
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@class::A::@field::f
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
            #F3 isOriginDeclaration y (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@class::A::@field::y
            #F4 isOriginDeclaration z (nameOffset:43) (firstTokenOffset:43) (offset:43)
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
            #F7 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@getter::y
            #F8 isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::A::@getter::z
          setters
            #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
            #F11 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::value
            #F13 isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::value
        #F15 class B (nameOffset:54) (firstTokenOffset:48) (offset:54)
          element: <testLibrary>::@class::B
          fields
            #F16 isOriginDeclaration x (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@field::x
            #F17 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@field::y
            #F18 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F19 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F20 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::B::@getter::x
            #F21 isOriginDeclaration y (nameOffset:86) (firstTokenOffset:82) (offset:86)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F22 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F24 isOriginDeclaration z (nameOffset:103) (firstTokenOffset:99) (offset:103)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F25 requiredPositional _ (nameOffset:105) (firstTokenOffset:105) (offset:105)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        isOriginDeclaration z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        isOriginVariable z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::y
        isOriginVariable z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F13
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F15
      interfaces
        A
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F16
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F17
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F18
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F19
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F20
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F21
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F22
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F23
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F24
          formalParameters
            #E4 requiredPositional hasImplicitType _
              firstFragment: #F25
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::z
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer isOriginDeclaration x (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@getter::x
          setters
            #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        hasImplicitType hasInitializer isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
''');
  }

  test_instanceField_fromField_finalFieldTyped_setterNotTyped() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int? foo;
}
class B implements A {
  final int foo;
  set foo(_) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F7 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginDeclaration foo (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: <testLibrary>::@class::B::@field::foo
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@class::B::@getter::foo
          setters
            #F11 isOriginDeclaration foo (nameOffset:79) (firstTokenOffset:75) (offset:79)
              element: <testLibrary>::@class::B::@setter::foo
              formalParameters
                #F12 requiredPositional _ (nameOffset:83) (firstTokenOffset:83) (offset:83)
                  element: <testLibrary>::@class::B::@setter::foo::@formalParameter::_
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int?
          variable: <testLibrary>::@class::A::@field::foo
      setters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int?
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        final isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@field::foo
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::foo
          setter: <testLibrary>::@class::B::@setter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::B::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::B::@field::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@setter::foo
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional hasImplicitType _
              firstFragment: #F12
              type: int?
          returnType: void
          variable: <testLibrary>::@class::B::@field::foo
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 E (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 E
          fields
            #F3 isOriginDeclaration x (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::x
            #F4 isOriginDeclaration y (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::A::@field::y
            #F5 isOriginDeclaration z (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::x
            #F8 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::A::@getter::y
            #F9 isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::A::@getter::z
          setters
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
            #F12 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::value
            #F14 isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::value
        #F16 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          typeParameters
            #F17 T (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: #E1 T
          fields
            #F18 isOriginDeclaration x (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: <testLibrary>::@class::B::@field::x
            #F19 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@field::y
            #F20 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F21 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F22 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::B::@getter::x
            #F23 isOriginDeclaration y (nameOffset:89) (firstTokenOffset:85) (offset:89)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F24 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F25 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F26 isOriginDeclaration z (nameOffset:106) (firstTokenOffset:102) (offset:106)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F27 requiredPositional _ (nameOffset:108) (firstTokenOffset:108) (offset:108)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        isOriginDeclaration z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        isOriginVariable z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F11
              type: E
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F13
              type: E
          returnType: void
          variable: <testLibrary>::@class::A::@field::y
        isOriginVariable z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F14
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F15
              type: E
          returnType: void
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F16
      typeParameters
        #E1 T
          firstFragment: #F17
      interfaces
        A<T>
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F18
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F19
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F20
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F21
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F22
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F23
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F24
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F25
              type: T
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F26
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E6 requiredPositional hasImplicitType _
              firstFragment: #F27
              type: T
          returnType: void
          variable: <testLibrary>::@class::B::@field::z
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer isOriginDeclaration x (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@getter::x
          setters
            #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        hasImplicitType hasInitializer isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          fields
            #F8 hasInitializer isOriginDeclaration x (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@getter::x
          setters
            #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    abstract hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        hasImplicitType hasInitializer isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: num
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: num
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: num
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
            #F3 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::y
            #F4 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
            #F7 isOriginDeclaration y (nameOffset:42) (firstTokenOffset:34) (offset:42)
              element: <testLibrary>::@class::A::@getter::y
            #F8 isOriginDeclaration z (nameOffset:55) (firstTokenOffset:47) (offset:55)
              element: <testLibrary>::@class::A::@getter::z
        #F9 class B (nameOffset:66) (firstTokenOffset:60) (offset:66)
          element: <testLibrary>::@class::B
          fields
            #F10 isOriginDeclaration x (nameOffset:89) (firstTokenOffset:89) (offset:89)
              element: <testLibrary>::@class::B::@field::x
            #F11 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@field::y
            #F12 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F14 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@getter::x
            #F15 isOriginDeclaration y (nameOffset:98) (firstTokenOffset:94) (offset:98)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F16 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F18 isOriginDeclaration z (nameOffset:115) (firstTokenOffset:111) (offset:115)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F19 requiredPositional _ (nameOffset:117) (firstTokenOffset:117) (offset:117)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        abstract isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        abstract isOriginDeclaration z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F9
      interfaces
        A
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F12
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F13
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F16
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F17
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F18
          formalParameters
            #E1 requiredPositional hasImplicitType _
              firstFragment: #F19
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::z
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 E (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 E
          fields
            #F3 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
            #F4 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::y
            #F5 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginDeclaration x (nameOffset:30) (firstTokenOffset:24) (offset:30)
              element: <testLibrary>::@class::A::@getter::x
            #F8 isOriginDeclaration y (nameOffset:41) (firstTokenOffset:35) (offset:41)
              element: <testLibrary>::@class::A::@getter::y
            #F9 isOriginDeclaration z (nameOffset:52) (firstTokenOffset:46) (offset:52)
              element: <testLibrary>::@class::A::@getter::z
        #F10 class B (nameOffset:63) (firstTokenOffset:57) (offset:63)
          element: <testLibrary>::@class::B
          typeParameters
            #F11 T (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: #E1 T
          fields
            #F12 isOriginDeclaration x (nameOffset:92) (firstTokenOffset:92) (offset:92)
              element: <testLibrary>::@class::B::@field::x
            #F13 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@field::y
            #F14 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F15 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F16 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@class::B::@getter::x
            #F17 isOriginDeclaration y (nameOffset:101) (firstTokenOffset:97) (offset:101)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F18 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F20 isOriginDeclaration z (nameOffset:118) (firstTokenOffset:114) (offset:118)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F21 requiredPositional _ (nameOffset:120) (firstTokenOffset:120) (offset:120)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: E
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        abstract isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        abstract isOriginDeclaration z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      interfaces
        A<T>
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F14
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F15
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F16
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F17
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F18
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F19
              type: T
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F20
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional hasImplicitType _
              firstFragment: #F21
              type: T
          returnType: void
          variable: <testLibrary>::@class::B::@field::z
''');
  }

  test_instanceField_fromGetter_hasGetterWithType_hasSetterNoType() async {
    configuration.withConstructors = false;
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get foo;
}
class B implements A {
  int get foo => 0;
  set foo(value) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F3 isOriginDeclaration foo (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::foo
        #F4 class B (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::B
          fields
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::B::@field::foo
          getters
            #F6 isOriginDeclaration foo (nameOffset:69) (firstTokenOffset:61) (offset:69)
              element: <testLibrary>::@class::B::@getter::foo
          setters
            #F7 isOriginDeclaration foo (nameOffset:85) (firstTokenOffset:81) (offset:85)
              element: <testLibrary>::@class::B::@setter::foo
              formalParameters
                #F8 requiredPositional value (nameOffset:89) (firstTokenOffset:89) (offset:89)
                  element: <testLibrary>::@class::B::@setter::foo::@formalParameter::value
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::foo
      getters
        abstract isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@class::A::@field::foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      interfaces
        A
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@class::B::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::B::@getter::foo
          setter: <testLibrary>::@class::B::@setter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::B::@field::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional hasImplicitType value
              firstFragment: #F8
              type: num
          returnType: void
          variable: <testLibrary>::@class::B::@field::foo
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 isOriginDeclaration x (nameOffset:66) (firstTokenOffset:55) (offset:66)
              element: <testLibrary>::@class::B::@getter::x
        #F9 class C (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::C
          fields
            #F10 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 isOriginDeclaration x (nameOffset:103) (firstTokenOffset:99) (offset:103)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: String
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      getters
        abstract isOriginDeclaration x
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
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F10
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 isOriginDeclaration x (nameOffset:67) (firstTokenOffset:55) (offset:67)
              element: <testLibrary>::@class::B::@getter::x
        #F9 class C (nameOffset:78) (firstTokenOffset:72) (offset:78)
          element: <testLibrary>::@class::C
          fields
            #F10 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 isOriginDeclaration x (nameOffset:104) (firstTokenOffset:100) (offset:104)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      getters
        abstract isOriginDeclaration x
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
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 isOriginDeclaration x (nameOffset:30) (firstTokenOffset:24) (offset:30)
              element: <testLibrary>::@class::A::@getter::x
        #F6 class B (nameOffset:50) (firstTokenOffset:35) (offset:50)
          element: <testLibrary>::@class::B
          typeParameters
            #F7 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E1 T
          fields
            #F8 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginDeclaration x (nameOffset:65) (firstTokenOffset:59) (offset:65)
              element: <testLibrary>::@class::B::@getter::x
        #F11 class C (nameOffset:76) (firstTokenOffset:70) (offset:76)
          element: <testLibrary>::@class::C
          fields
            #F12 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F14 isOriginDeclaration x (nameOffset:115) (firstTokenOffset:111) (offset:115)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract isOriginDeclaration x
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
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        abstract isOriginDeclaration x
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
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F12
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 isOriginDeclaration x (nameOffset:63) (firstTokenOffset:55) (offset:63)
              element: <testLibrary>::@class::B::@getter::x
        #F9 class C (nameOffset:74) (firstTokenOffset:68) (offset:74)
          element: <testLibrary>::@class::C
          fields
            #F10 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 isOriginDeclaration x (nameOffset:100) (firstTokenOffset:96) (offset:100)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      getters
        abstract isOriginDeclaration x
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
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
            #F3 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::y
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
            #F6 isOriginDeclaration y (nameOffset:42) (firstTokenOffset:34) (offset:42)
              element: <testLibrary>::@class::A::@getter::y
        #F7 class B (nameOffset:62) (firstTokenOffset:47) (offset:62)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::B::@field::x
            #F9 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::B::@field::y
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F11 isOriginDeclaration x (nameOffset:77) (firstTokenOffset:68) (offset:77)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 requiredPositional _ (nameOffset:86) (firstTokenOffset:79) (offset:86)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
            #F13 isOriginDeclaration y (nameOffset:101) (firstTokenOffset:92) (offset:101)
              element: <testLibrary>::@class::B::@setter::y
              formalParameters
                #F14 requiredPositional _ (nameOffset:110) (firstTokenOffset:103) (offset:110)
                  element: <testLibrary>::@class::B::@setter::y::@formalParameter::_
        #F15 class C (nameOffset:122) (firstTokenOffset:116) (offset:122)
          element: <testLibrary>::@class::C
          fields
            #F16 isOriginDeclaration x (nameOffset:148) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@class::C::@field::x
            #F17 isOriginDeclaration y (nameOffset:159) (firstTokenOffset:159) (offset:159)
              element: <testLibrary>::@class::C::@field::y
          constructors
            #F18 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F19 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@class::C::@getter::x
            #F20 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:159)
              element: <testLibrary>::@class::C::@getter::y
          setters
            #F21 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        abstract isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: String
          setter: <testLibrary>::@class::B::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F9
          type: String
          setter: <testLibrary>::@class::B::@setter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F12
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        abstract isOriginDeclaration y
          reference: <testLibrary>::@class::B::@setter::y
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F14
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::y
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F15
      interfaces
        A
        B
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F16
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
        final hasImplicitType isOriginDeclaration y
          reference: <testLibrary>::@class::C::@field::y
          firstFragment: #F17
          type: int
          getter: <testLibrary>::@class::C::@getter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F18
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F19
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::C::@getter::y
          firstFragment: #F20
          returnType: int
          variable: <testLibrary>::@class::C::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F21
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F22
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional _ (nameOffset:73) (firstTokenOffset:66) (offset:73)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C (nameOffset:85) (firstTokenOffset:79) (offset:85)
          element: <testLibrary>::@class::C
          fields
            #F11 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 isOriginDeclaration x (nameOffset:111) (firstTokenOffset:107) (offset:111)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: String
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional _ (nameOffset:73) (firstTokenOffset:66) (offset:73)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C (nameOffset:85) (firstTokenOffset:79) (offset:85)
          element: <testLibrary>::@class::C
          fields
            #F11 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F13 isOriginDeclaration x (nameOffset:111) (firstTokenOffset:107) (offset:111)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F14 requiredPositional _ (nameOffset:113) (firstTokenOffset:113) (offset:113)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: String
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: String
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional hasImplicitType _
              firstFragment: #F14
              type: String
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional _ (nameOffset:70) (firstTokenOffset:66) (offset:70)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C (nameOffset:82) (firstTokenOffset:76) (offset:82)
          element: <testLibrary>::@class::C
          fields
            #F11 isOriginDeclaration x (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F14 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F14
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional _ (nameOffset:70) (firstTokenOffset:66) (offset:70)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C (nameOffset:82) (firstTokenOffset:76) (offset:82)
          element: <testLibrary>::@class::C
          fields
            #F11 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 isOriginDeclaration x (nameOffset:108) (firstTokenOffset:104) (offset:108)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional _ (nameOffset:70) (firstTokenOffset:66) (offset:70)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C (nameOffset:82) (firstTokenOffset:76) (offset:82)
          element: <testLibrary>::@class::C
          fields
            #F11 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F13 isOriginDeclaration x (nameOffset:108) (firstTokenOffset:104) (offset:108)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F14 requiredPositional _ (nameOffset:110) (firstTokenOffset:110) (offset:110)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      interfaces
        A
        B
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F11
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional hasImplicitType _
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
            #F3 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::y
            #F4 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::z
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F6 isOriginDeclaration x (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F7 requiredPositional _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
            #F8 isOriginDeclaration y (nameOffset:51) (firstTokenOffset:42) (offset:51)
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F9 requiredPositional _ (nameOffset:57) (firstTokenOffset:53) (offset:57)
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_
            #F10 isOriginDeclaration z (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F11 requiredPositional _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_
        #F12 class B (nameOffset:90) (firstTokenOffset:84) (offset:90)
          element: <testLibrary>::@class::B
          fields
            #F13 isOriginDeclaration x (nameOffset:113) (firstTokenOffset:113) (offset:113)
              element: <testLibrary>::@class::B::@field::x
            #F14 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::B::@field::y
            #F15 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F16 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F17 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
              element: <testLibrary>::@class::B::@getter::x
            #F18 isOriginDeclaration y (nameOffset:122) (firstTokenOffset:118) (offset:122)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F19 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F21 isOriginDeclaration z (nameOffset:139) (firstTokenOffset:135) (offset:139)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F22 requiredPositional _ (nameOffset:141) (firstTokenOffset:141) (offset:141)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
        abstract isOriginDeclaration y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::y
        abstract isOriginDeclaration z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F10
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F12
      interfaces
        A
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F14
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F15
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F16
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F18
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F19
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F20
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F21
          formalParameters
            #E4 requiredPositional hasImplicitType _
              firstFragment: #F22
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::z
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 isOriginDeclaration x (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 requiredPositional _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 class B (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::B
          fields
            #F7 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 isOriginDeclaration x (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 requiredPositional _ (nameOffset:81) (firstTokenOffset:74) (offset:81)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F11 class C (nameOffset:93) (firstTokenOffset:87) (offset:93)
          element: <testLibrary>::@class::C
          fields
            #F12 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F14 isOriginDeclaration x (nameOffset:119) (firstTokenOffset:115) (offset:119)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F7
          type: String
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F10
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      interfaces
        A
        B
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F12
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 isOriginDeclaration x (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 requiredPositional _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 class B (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::B
          fields
            #F7 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 isOriginDeclaration x (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 requiredPositional _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F11 class C (nameOffset:90) (firstTokenOffset:84) (offset:90)
          element: <testLibrary>::@class::C
          fields
            #F12 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F14 isOriginDeclaration x (nameOffset:116) (firstTokenOffset:112) (offset:116)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      interfaces
        A
        B
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
      getters
        isOriginDeclaration x
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
        #F1 class A (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: #E0 T
          fields
            #F3 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@field::x
            #F4 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@field::y
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginDeclaration x (nameOffset:41) (firstTokenOffset:32) (offset:41)
              element: <testLibrary>::@class::A::@getter::x
            #F7 isOriginDeclaration y (nameOffset:69) (firstTokenOffset:54) (offset:69)
              element: <testLibrary>::@class::A::@getter::y
        #F8 class B (nameOffset:89) (firstTokenOffset:83) (offset:89)
          element: <testLibrary>::@class::B
          fields
            #F9 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@field::x
            #F10 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@field::y
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F12 isOriginDeclaration x (nameOffset:114) (firstTokenOffset:110) (offset:114)
              element: <testLibrary>::@class::B::@getter::x
            #F13 isOriginDeclaration y (nameOffset:131) (firstTokenOffset:127) (offset:131)
              element: <testLibrary>::@class::B::@getter::y
      typeAliases
        #F14 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F15 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          getter: <testLibrary>::@class::A::@getter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          variable: <testLibrary>::@class::A::@field::x
        isOriginDeclaration y
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
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F9
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
          getter: <testLibrary>::@class::B::@getter::x
        isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F10
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::B::@getter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
      getters
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F12
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isOriginDeclaration x (nameOffset:43) (firstTokenOffset:34) (offset:43)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional covariant _ (nameOffset:59) (firstTokenOffset:45) (offset:59)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginDeclaration x (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::B::@getter::x
          setters
            #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional covariant _
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional covariant value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isOriginDeclaration x (nameOffset:43) (firstTokenOffset:34) (offset:43)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional covariant _ (nameOffset:59) (firstTokenOffset:45) (offset:59)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F10 isOriginDeclaration x (nameOffset:94) (firstTokenOffset:90) (offset:94)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F11 requiredPositional _ (nameOffset:100) (firstTokenOffset:96) (offset:100)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        abstract isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional covariant _
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: int
          setter: <testLibrary>::@class::B::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      setters
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional covariant _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration t1 (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::t1
            #F3 hasInitializer isOriginDeclaration t2 (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@class::A::@field::t2
            #F4 hasInitializer isOriginDeclaration t3 (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@class::A::@field::t3
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::t1
            #F7 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@getter::t2
            #F8 isOriginVariable t3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::A::@getter::t3
          setters
            #F9 isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::t1
              formalParameters
                #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::t1::@formalParameter::value
            #F11 isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@setter::t2
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
                  element: <testLibrary>::@class::A::@setter::t2::@formalParameter::value
            #F13 isOriginVariable t3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::A::@setter::t3
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
                  element: <testLibrary>::@class::A::@setter::t3::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration t1
          reference: <testLibrary>::@class::A::@field::t1
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::t1
          setter: <testLibrary>::@class::A::@setter::t1
        hasImplicitType hasInitializer isOriginDeclaration t2
          reference: <testLibrary>::@class::A::@field::t2
          firstFragment: #F3
          type: double
          getter: <testLibrary>::@class::A::@getter::t2
          setter: <testLibrary>::@class::A::@setter::t2
        hasImplicitType hasInitializer isOriginDeclaration t3
          reference: <testLibrary>::@class::A::@field::t3
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::t3
          setter: <testLibrary>::@class::A::@setter::t3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable t1
          reference: <testLibrary>::@class::A::@getter::t1
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::t1
        isOriginVariable t2
          reference: <testLibrary>::@class::A::@getter::t2
          firstFragment: #F7
          returnType: double
          variable: <testLibrary>::@class::A::@field::t2
        isOriginVariable t3
          reference: <testLibrary>::@class::A::@getter::t3
          firstFragment: #F8
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::t3
      setters
        isOriginVariable t1
          reference: <testLibrary>::@class::A::@setter::t1
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::t1
        isOriginVariable t2
          reference: <testLibrary>::@class::A::@setter::t2
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: double
          returnType: void
          variable: <testLibrary>::@class::A::@field::t2
        isOriginVariable t3
          reference: <testLibrary>::@class::A::@setter::t3
          firstFragment: #F13
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F14
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::t3
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:60) (firstTokenOffset:60) (offset:60)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 requiredPositional b (nameOffset:63) (firstTokenOffset:63) (offset:63)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:48) (firstTokenOffset:43) (offset:48)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:57) (firstTokenOffset:50) (offset:57)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration m (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional a (nameOffset:102) (firstTokenOffset:102) (offset:102)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F11
          typeInferenceError: overrideNoCombinedSuperSignature
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:21) (offset:25)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 requiredPositional x (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
        #F5 class B (nameOffset:55) (firstTokenOffset:40) (offset:55)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration foo (nameOffset:68) (firstTokenOffset:61) (offset:68)
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F8 requiredPositional x (nameOffset:76) (firstTokenOffset:72) (offset:76)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::x
        #F9 class C (nameOffset:98) (firstTokenOffset:83) (offset:98)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration foo (nameOffset:126) (firstTokenOffset:120) (offset:126)
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F12 requiredPositional x (nameOffset:130) (firstTokenOffset:130) (offset:130)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::x
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        abstract isOriginDeclaration foo
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        abstract isOriginDeclaration foo
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
      methods
        abstract isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F11
          typeInferenceError: overrideNoCombinedSuperSignature
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::m
        #F4 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 isOriginDeclaration m (nameOffset:44) (firstTokenOffset:37) (offset:44)
              element: <testLibrary>::@class::B::@method::m
        #F7 class C (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F9 isOriginDeclaration m (nameOffset:88) (firstTokenOffset:88) (offset:88)
              element: <testLibrary>::@class::C::@method::m
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          returnType: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F9
          typeInferenceError: overrideNoCombinedSuperSignature
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 isOriginDeclaration m (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F5 requiredPositional a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F6 class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F7 E (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E1 E
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 isOriginDeclaration m (nameOffset:52) (firstTokenOffset:47) (offset:52)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 requiredPositional a (nameOffset:56) (firstTokenOffset:54) (offset:56)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F11 class C (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::C
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F13 isOriginDeclaration m (nameOffset:112) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F14 requiredPositional a (nameOffset:114) (firstTokenOffset:114) (offset:114)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F13
          typeInferenceError: overrideNoCombinedSuperSignature
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E2 T
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 isOriginDeclaration m (nameOffset:49) (firstTokenOffset:47) (offset:49)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 requiredPositional a (nameOffset:55) (firstTokenOffset:51) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F12 class C (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::C
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F14 isOriginDeclaration m (nameOffset:119) (firstTokenOffset:119) (offset:119)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F15 requiredPositional a (nameOffset:121) (firstTokenOffset:121) (offset:121)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: String}
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F14
          typeInferenceError: overrideNoCombinedSuperSignature
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:55) (firstTokenOffset:55) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 optionalNamed b (nameOffset:59) (firstTokenOffset:59) (offset:59)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:55) (firstTokenOffset:55) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 optionalPositional b (nameOffset:59) (firstTokenOffset:59) (offset:59)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:14) (firstTokenOffset:14) (offset:14)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:46) (firstTokenOffset:46) (offset:46)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 requiredPositional a (nameOffset:27) (firstTokenOffset:20) (offset:27)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        #F5 class B (nameOffset:47) (firstTokenOffset:41) (offset:47)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:65) (firstTokenOffset:65) (offset:65)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration foo
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isOriginDeclaration m (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::m
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::m
          setters
            #F5 isOriginVariable m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::m
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::m::@formalParameter::value
        #F7 class B (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::B
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 isOriginDeclaration m (nameOffset:48) (firstTokenOffset:48) (offset:48)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 requiredPositional a (nameOffset:50) (firstTokenOffset:50) (offset:50)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer isOriginDeclaration m
          reference: <testLibrary>::@class::A::@field::m
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::m
          setter: <testLibrary>::@class::A::@setter::m
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable m
          reference: <testLibrary>::@class::A::@getter::m
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::m
      setters
        isOriginVariable m
          reference: <testLibrary>::@class::A::@setter::m
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::m
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E2 T
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 class C (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::C
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F12 isOriginDeclaration m (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F13 requiredPositional a (nameOffset:96) (firstTokenOffset:96) (offset:96)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {T: String}
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:57) (firstTokenOffset:57) (offset:57)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration m (nameOffset:87) (firstTokenOffset:87) (offset:87)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional a (nameOffset:89) (firstTokenOffset:89) (offset:89)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:60) (firstTokenOffset:60) (offset:60)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C (nameOffset:74) (firstTokenOffset:68) (offset:74)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration m (nameOffset:90) (firstTokenOffset:90) (offset:90)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional a (nameOffset:92) (firstTokenOffset:92) (offset:92)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C (nameOffset:83) (firstTokenOffset:77) (offset:83)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration m (nameOffset:99) (firstTokenOffset:99) (offset:99)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional a (nameOffset:101) (firstTokenOffset:101) (offset:101)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::B::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F7 requiredPositional b (nameOffset:34) (firstTokenOffset:27) (offset:34)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F8 class B (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::B
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 isOriginDeclaration m (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 requiredPositional a (nameOffset:79) (firstTokenOffset:79) (offset:79)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F12 requiredPositional b (nameOffset:82) (firstTokenOffset:82) (offset:82)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: String}
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:57) (firstTokenOffset:57) (offset:57)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F5 optionalNamed b (nameOffset:36) (firstTokenOffset:29) (offset:36)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F6 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F9 requiredPositional a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F10 optionalNamed b (nameOffset:73) (firstTokenOffset:73) (offset:73)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F5 optionalPositional b (nameOffset:36) (firstTokenOffset:29) (offset:36)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F6 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F9 requiredPositional a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F10 optionalPositional b (nameOffset:73) (firstTokenOffset:73) (offset:73)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E2 T
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 class C (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::C
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F12 isOriginDeclaration m (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F13 requiredPositional a (nameOffset:96) (firstTokenOffset:96) (offset:96)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {T: String}
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 K
            #F3 V (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:29) (firstTokenOffset:27) (offset:29)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:33) (firstTokenOffset:31) (offset:33)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::B
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 isOriginDeclaration m (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 requiredPositional a (nameOffset:79) (firstTokenOffset:79) (offset:79)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        abstract isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:28) (firstTokenOffset:21) (offset:28)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:34) (firstTokenOffset:30) (offset:34)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:46) (firstTokenOffset:40) (offset:46)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:67) (firstTokenOffset:67) (offset:67)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        abstract isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 K
            #F3 V (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:29) (firstTokenOffset:27) (offset:29)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:33) (firstTokenOffset:31) (offset:33)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:54) (firstTokenOffset:39) (offset:54)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T1 (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E2 T1
            #F9 T2 (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: #E3 T2
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F11 class C (nameOffset:91) (firstTokenOffset:85) (offset:91)
          element: <testLibrary>::@class::C
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F13 isOriginDeclaration m (nameOffset:123) (firstTokenOffset:123) (offset:123)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F14 requiredPositional a (nameOffset:125) (firstTokenOffset:125) (offset:125)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        abstract isOriginDeclaration m
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
        isOriginImplicitDefault new
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      methods
        isOriginDeclaration m
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
        #F1 class A1 (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::A1
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::A1::@constructor::new
              typeName: A1
          methods
            #F3 isOriginDeclaration _foo (nameOffset:38) (firstTokenOffset:34) (offset:38)
              element: <testLibrary>::@class::A1::@method::_foo
        #F4 class A2 (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::A2
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::A2::@constructor::new
              typeName: A2
          methods
            #F6 isOriginDeclaration _foo (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::A2::@method::_foo
  classes
    class A1
      reference: <testLibrary>::@class::A1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A1::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration _foo
          reference: <testLibrary>::@class::A1::@method::_foo
          firstFragment: #F3
          returnType: int
    class A2
      reference: <testLibrary>::@class::A2
      firstFragment: #F4
      supertype: A1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A2::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::A1::@constructor::new
      methods
        isOriginDeclaration _foo
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E2 T
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 isOriginDeclaration m (nameOffset:49) (firstTokenOffset:47) (offset:49)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 requiredPositional a (nameOffset:55) (firstTokenOffset:51) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F12 class C (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::C
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F14 isOriginDeclaration m (nameOffset:119) (firstTokenOffset:119) (offset:119)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F15 requiredPositional a (nameOffset:121) (firstTokenOffset:121) (offset:121)
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: String}
      methods
        isOriginDeclaration m
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isOriginDeclaration m (nameOffset:52) (firstTokenOffset:45) (offset:52)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional a (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 class C (nameOffset:72) (firstTokenOffset:66) (offset:72)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration m (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional a (nameOffset:103) (firstTokenOffset:103) (offset:103)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration m
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
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        isOriginDeclaration m
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
