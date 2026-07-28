// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/element/element.dart';
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
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t1 = a += 1;
var t2 = a = 2;
''');
  }

  test_initializer_binary_onlyLeft() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t = (a = 1) + (a = 2);
''');
  }

  test_initializer_bitwise() async {
    await _assertErrorOnlyLeft(['&', '|', '^']);
  }

  test_initializer_boolean() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t1 = ((a = 1) == 0) || ((a = 2) == 0);
var t2 = ((a = 1) == 0) && ((a = 2) == 0);
var t3 = !((a = 1) == 0);
''');
  }

  test_initializer_cascade() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var t = (a = 1)..isEven;
''');
  }

  test_initializer_classField_instance_instanceCreation() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {}
class B {
  var t1 = new A<int>();
  var t2 = new A();
}
''');
  }

  test_initializer_classField_static_instanceCreation() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {}
class B {
  static var t1 = 1;
  static var t2 = new A();
}
''');
  }

  test_initializer_conditional() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var b = true;
var t = b
    ? (a = 1)
    : (a = 2);
''');
  }

  test_initializer_dependencyCycle() async {
    await resolveTestCodeWithDiagnostics('''
var a = b;
//  ^
// [diag.topLevelCycle] The type of 'a' can't be inferred because it depends on itself through the cycle: a, b.
var b = a;
//  ^
// [diag.topLevelCycle] The type of 'b' can't be inferred because it depends on itself through the cycle: a, b.
''');
  }

  test_initializer_equality() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t1 = ((a = 1) == 0) == ((a = 2) == 0);
var t2 = ((a = 1) == 0) != ((a = 2) == 0);
''');
  }

  test_initializer_extractIndex() async {
    await resolveTestCodeWithDiagnostics('''
var a = [0, 1.2];
var b0 = a[0];
var b1 = a[1];
''');
  }

  test_initializer_functionLiteral_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var t = (int p) {};
''');
    assertType(result.findElement.topVar('t').type, 'Null Function(int)');
  }

  test_initializer_functionLiteral_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = 0;
var t = (int p) => (a = 1);
''');
    assertType(result.findElement.topVar('t').type, 'int Function(int)');
  }

  test_initializer_functionLiteral_parameters_withoutType() async {
    var result = await resolveTestCodeWithDiagnostics('''
var t = (int a, b,int c, d) => 0;
''');
    assertType(
      result.findElement.topVar('t').type,
      'int Function(int, dynamic, int, dynamic)',
    );
  }

  test_initializer_hasTypeAnnotation() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
int t = (a = 1);
''');
  }

  test_initializer_identifier() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var b = (a = 1);
var c = b;
''');
  }

  test_initializer_ifNull() async {
    await resolveTestCodeWithDiagnostics('''
int? a = 1;
var t = a ?? 2;
''');
  }

  test_initializer_instanceCreation_withoutTypeParameters() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
var t = new A();
''');
  }

  test_initializer_instanceCreation_withTypeParameters() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {}
var t1 = new A<int>();
var t2 = new A();
''');
  }

  test_initializer_instanceGetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int f = 1;
}
var a = new A().f;
''');
  }

  test_initializer_methodInvocation_function() async {
    await resolveTestCodeWithDiagnostics('''
int f1() => 0;
T f2<T>() => throw 0;
var t1 = f1();
var t2 = f2();
var t3 = f2<int>();
''');
  }

  test_initializer_methodInvocation_method() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t1 = a++;
var t2 = a--;
''');
  }

  test_initializer_prefixIncDec() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t = <int>[a = 1];
''');
  }

  test_initializer_typedMap() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t = <int, int>{(a = 1) : (a = 2)};
''');
  }

  test_initializer_untypedList() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t = [
    a = 1,
    2,
    3,
];
''');
  }

  test_initializer_untypedMap() async {
    await resolveTestCodeWithDiagnostics('''
var a = 1;
var t = {
    (a = 1) :
        (a = 2),
};
''');
  }

  test_override_conflictFieldType() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int aaa = 0;
//    ^^^
// [context 1] The member being overridden.
}
abstract class B {
  String aaa = '0';
//       ^^^
// [context 2] The member being overridden.
}
class C implements A, B {
  var aaa;
//    ^^^
// [diag.invalidOverride][context 1] 'C.aaa' ('dynamic Function()') isn't a valid override of 'A.aaa' ('int Function()').
// [diag.invalidOverride][context 2] 'C.aaa' ('dynamic Function()') isn't a valid override of 'B.aaa' ('String Function()').
}
''');
  }

  test_override_conflictParameterType_method() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  void mmm(int a);
}
abstract class B {
  void mmm(String a);
}
class C implements A, B {
  void mmm(a) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.mmm (void Function(int)), B.mmm (void Function(String)).
}
''');
  }

  Future<void> _assertErrorOnlyLeft(List<String> operators) async {
    String code = 'var a = 1;\n';
    for (var i = 0; i < operators.length; i++) {
      String operator = operators[i];
      code += 'var t$i = (a = 1) $operator (a = 2);\n';
    }
    await resolveTestCodeWithDiagnostics(code);
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vPlusIntInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vPlusIntInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vPlusIntDouble (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::vPlusIntDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vPlusDoubleInt (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::vPlusDoubleInt
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vPlusDoubleDouble (nameOffset:89) (firstTokenOffset:89) (offset:89)
          element: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vMinusIntInt (nameOffset:124) (firstTokenOffset:124) (offset:124)
          element: <testLibrary>::@topLevelVariable::vMinusIntInt
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic vMinusIntDouble (nameOffset:150) (firstTokenOffset:150) (offset:150)
          element: <testLibrary>::@topLevelVariable::vMinusIntDouble
          inducedGetter: #F17
          inducedSetter: #F18
        #F19 hasImplicitType hasInitializer isOriginDeclaration isStatic vMinusDoubleInt (nameOffset:181) (firstTokenOffset:181) (offset:181)
          element: <testLibrary>::@topLevelVariable::vMinusDoubleInt
          inducedGetter: #F20
          inducedSetter: #F21
        #F22 hasImplicitType hasInitializer isOriginDeclaration isStatic vMinusDoubleDouble (nameOffset:212) (firstTokenOffset:212) (offset:212)
          element: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
          inducedGetter: #F23
          inducedSetter: #F24
      getters
        #F2 isComplete isOriginVariable isStatic vPlusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vPlusIntInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vPlusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::vPlusIntDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vPlusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::vPlusDoubleInt
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vPlusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@getter::vPlusDoubleDouble
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vMinusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
          element: <testLibrary>::@getter::vMinusIntInt
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic vMinusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:150)
          element: <testLibrary>::@getter::vMinusIntDouble
          inducingVariable: #F16
        #F20 isComplete isOriginVariable isStatic vMinusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
          element: <testLibrary>::@getter::vMinusDoubleInt
          inducingVariable: #F19
        #F23 isComplete isOriginVariable isStatic vMinusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:212)
          element: <testLibrary>::@getter::vMinusDoubleDouble
          inducingVariable: #F22
      setters
        #F3 isComplete isOriginVariable isStatic vPlusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vPlusIntInt
          inducingVariable: #F1
          formalParameters
            #F25 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vPlusIntInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vPlusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::vPlusIntDouble
          inducingVariable: #F4
          formalParameters
            #F26 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::vPlusIntDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vPlusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::vPlusDoubleInt
          inducingVariable: #F7
          formalParameters
            #F27 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::vPlusDoubleInt::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vPlusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@setter::vPlusDoubleDouble
          inducingVariable: #F10
          formalParameters
            #F28 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@setter::vPlusDoubleDouble::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vMinusIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
          element: <testLibrary>::@setter::vMinusIntInt
          inducingVariable: #F13
          formalParameters
            #F29 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
              element: <testLibrary>::@setter::vMinusIntInt::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic vMinusIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:150)
          element: <testLibrary>::@setter::vMinusIntDouble
          inducingVariable: #F16
          formalParameters
            #F30 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:150)
              element: <testLibrary>::@setter::vMinusIntDouble::@formalParameter::value
        #F21 isComplete isOriginVariable isStatic vMinusDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
          element: <testLibrary>::@setter::vMinusDoubleInt
          inducingVariable: #F19
          formalParameters
            #F31 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
              element: <testLibrary>::@setter::vMinusDoubleInt::@formalParameter::value
        #F24 isComplete isOriginVariable isStatic vMinusDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:212)
          element: <testLibrary>::@setter::vMinusDoubleDouble
          inducingVariable: #F22
          formalParameters
            #F32 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:212)
              element: <testLibrary>::@setter::vMinusDoubleDouble::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vPlusIntInt
      reference: <testLibrary>::@topLevelVariable::vPlusIntInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vPlusIntInt
      setter: <testLibrary>::@setter::vPlusIntInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vPlusIntDouble
      reference: <testLibrary>::@topLevelVariable::vPlusIntDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vPlusIntDouble
      setter: <testLibrary>::@setter::vPlusIntDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vPlusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleInt
      firstFragment: #F7
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleInt
      setter: <testLibrary>::@setter::vPlusDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vPlusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::vPlusDoubleDouble
      setter: <testLibrary>::@setter::vPlusDoubleDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMinusIntInt
      reference: <testLibrary>::@topLevelVariable::vMinusIntInt
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::vMinusIntInt
      setter: <testLibrary>::@setter::vMinusIntInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMinusIntDouble
      reference: <testLibrary>::@topLevelVariable::vMinusIntDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vMinusIntDouble
      setter: <testLibrary>::@setter::vMinusIntDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMinusDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleInt
      firstFragment: #F19
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleInt
      setter: <testLibrary>::@setter::vMinusDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMinusDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
      firstFragment: #F22
      type: double
      getter: <testLibrary>::@getter::vMinusDoubleDouble
      setter: <testLibrary>::@setter::vMinusDoubleDouble
  getters
    isOriginVariable isStatic vPlusIntInt
      reference: <testLibrary>::@getter::vPlusIntInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vPlusIntInt
    isOriginVariable isStatic vPlusIntDouble
      reference: <testLibrary>::@getter::vPlusIntDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusIntDouble
    isOriginVariable isStatic vPlusDoubleInt
      reference: <testLibrary>::@getter::vPlusDoubleInt
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleInt
    isOriginVariable isStatic vPlusDoubleDouble
      reference: <testLibrary>::@getter::vPlusDoubleDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
    isOriginVariable isStatic vMinusIntInt
      reference: <testLibrary>::@getter::vMinusIntInt
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMinusIntInt
    isOriginVariable isStatic vMinusIntDouble
      reference: <testLibrary>::@getter::vMinusIntDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusIntDouble
    isOriginVariable isStatic vMinusDoubleInt
      reference: <testLibrary>::@getter::vMinusDoubleInt
      firstFragment: #F20
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleInt
    isOriginVariable isStatic vMinusDoubleDouble
      reference: <testLibrary>::@getter::vMinusDoubleDouble
      firstFragment: #F23
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleDouble
  setters
    isOriginVariable isStatic vPlusIntInt
      reference: <testLibrary>::@setter::vPlusIntInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F25
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusIntInt
    isOriginVariable isStatic vPlusIntDouble
      reference: <testLibrary>::@setter::vPlusIntDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F26
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusIntDouble
    isOriginVariable isStatic vPlusDoubleInt
      reference: <testLibrary>::@setter::vPlusDoubleInt
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F27
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleInt
    isOriginVariable isStatic vPlusDoubleDouble
      reference: <testLibrary>::@setter::vPlusDoubleDouble
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F28
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vPlusDoubleDouble
    isOriginVariable isStatic vMinusIntInt
      reference: <testLibrary>::@setter::vMinusIntInt
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F29
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusIntInt
    isOriginVariable isStatic vMinusIntDouble
      reference: <testLibrary>::@setter::vMinusIntDouble
      firstFragment: #F18
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F30
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusIntDouble
    isOriginVariable isStatic vMinusDoubleInt
      reference: <testLibrary>::@setter::vMinusDoubleInt
      firstFragment: #F21
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F31
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMinusDoubleInt
    isOriginVariable isStatic vMinusDoubleDouble
      reference: <testLibrary>::@setter::vMinusDoubleDouble
      firstFragment: #F24
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: num
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    isOriginVariable isStatic V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::V
  setters
    isOriginVariable isStatic V
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic t1 (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::t1
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic t2 (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@topLevelVariable::t2
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::t1
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@getter::t2
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::t1
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@setter::t2
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F9
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic t1 (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::t1
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic t2 (nameOffset:38) (firstTokenOffset:38) (offset:38)
          element: <testLibrary>::@topLevelVariable::t2
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::t1
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@getter::t2
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::t1
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@setter::t2
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F9
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic t1 (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::t1
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic t2 (nameOffset:62) (firstTokenOffset:62) (offset:62)
          element: <testLibrary>::@topLevelVariable::t2
          inducedGetter: #F14
          inducedSetter: #F15
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::t1
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@getter::t2
          inducingVariable: #F13
      setters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::a
          inducingVariable: #F7
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::t1
          inducingVariable: #F10
          formalParameters
            #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@setter::t2
          inducingVariable: #F13
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F16
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F12
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F17
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F15
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::I::@setter::f::@formalParameter::value
        #F7 isAbstract class C (nameOffset:36) (firstTokenOffset:21) (offset:36)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 isOriginDeclaration isStatic c (nameOffset:56) (firstTokenOffset:56) (offset:56)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F10
          inducedSetter: #F11
        #F12 hasImplicitType hasInitializer isOriginDeclaration isStatic t1 (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::t1
          inducedGetter: #F13
          inducedSetter: #F14
        #F15 hasImplicitType hasInitializer isOriginDeclaration isStatic t2 (nameOffset:83) (firstTokenOffset:83) (offset:83)
          element: <testLibrary>::@topLevelVariable::t2
          inducedGetter: #F16
          inducedSetter: #F17
      getters
        #F10 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
          element: <testLibrary>::@getter::c
          inducingVariable: #F9
        #F13 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::t1
          inducingVariable: #F12
        #F16 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
          element: <testLibrary>::@getter::t2
          inducingVariable: #F15
      setters
        #F11 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
          element: <testLibrary>::@setter::c
          inducingVariable: #F9
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F14 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@setter::t1
          inducingVariable: #F12
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F17 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
          element: <testLibrary>::@setter::t2
          inducingVariable: #F15
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
              element: <testLibrary>::@setter::t2::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class I
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
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::I::@field::f
    isAbstract isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F9
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F12
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F15
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F10
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F16
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F18
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F14
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F19
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F17
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::I::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::I::@setter::f::@formalParameter::value
        #F7 isAbstract class C (nameOffset:36) (firstTokenOffset:21) (offset:36)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 hasImplicitType hasInitializer isOriginDeclaration isStatic t1 (nameOffset:76) (firstTokenOffset:76) (offset:76)
          element: <testLibrary>::@topLevelVariable::t1
          inducedGetter: #F10
          inducedSetter: #F11
        #F12 hasImplicitType hasInitializer isOriginDeclaration isStatic t2 (nameOffset:101) (firstTokenOffset:101) (offset:101)
          element: <testLibrary>::@topLevelVariable::t2
          inducedGetter: #F13
          inducedSetter: #F14
      getters
        #F10 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@getter::t1
          inducingVariable: #F9
        #F13 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
          element: <testLibrary>::@getter::t2
          inducingVariable: #F12
      setters
        #F11 isComplete isOriginVariable isStatic t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@setter::t1
          inducingVariable: #F9
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@setter::t1::@formalParameter::value
        #F14 isComplete isOriginVariable isStatic t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
          element: <testLibrary>::@setter::t2
          inducingVariable: #F12
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@setter::t2::@formalParameter::value
      functions
        #F17 isComplete isOriginDeclaration isStatic getC (nameOffset:56) (firstTokenOffset:54) (offset:56)
          element: <testLibrary>::@function::getC
  classes
    hasNonFinalField isSimplyBounded class I
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
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::I::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::I::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::I::@field::f
    isAbstract isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t1
      reference: <testLibrary>::@topLevelVariable::t1
      firstFragment: #F9
      type: int
      getter: <testLibrary>::@getter::t1
      setter: <testLibrary>::@setter::t1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t2
      reference: <testLibrary>::@topLevelVariable::t2
      firstFragment: #F12
      type: int
      getter: <testLibrary>::@getter::t2
      setter: <testLibrary>::@setter::t2
  getters
    isOriginVariable isStatic t1
      reference: <testLibrary>::@getter::t1
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@getter::t2
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::t2
  setters
    isOriginVariable isStatic t1
      reference: <testLibrary>::@setter::t1
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F15
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t1
    isOriginVariable isStatic t2
      reference: <testLibrary>::@setter::t2
      firstFragment: #F14
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::t2
  functions
    isOriginDeclaration isStatic getC
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic uValue (nameOffset:80) (firstTokenOffset:80) (offset:80)
          element: <testLibrary>::@topLevelVariable::uValue
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic uFuture (nameOffset:121) (firstTokenOffset:121) (offset:121)
          element: <testLibrary>::@topLevelVariable::uFuture
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic uValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
          element: <testLibrary>::@getter::uValue
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic uFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
          element: <testLibrary>::@getter::uFuture
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic uValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
          element: <testLibrary>::@setter::uValue
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@setter::uValue::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic uFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
          element: <testLibrary>::@setter::uFuture
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
              element: <testLibrary>::@setter::uFuture::@formalParameter::value
      functions
        #F9 isComplete isOriginDeclaration isStatic fValue (nameOffset:25) (firstTokenOffset:21) (offset:25)
          element: <testLibrary>::@function::fValue
        #F10 isAsynchronous isComplete isOriginDeclaration isStatic fFuture (nameOffset:53) (firstTokenOffset:41) (offset:53)
          element: <testLibrary>::@function::fFuture
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer uValue
      reference: <testLibrary>::@topLevelVariable::uValue
      firstFragment: #F1
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uValue
      setter: <testLibrary>::@setter::uValue
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer uFuture
      reference: <testLibrary>::@topLevelVariable::uFuture
      firstFragment: #F4
      type: Future<int> Function()
      getter: <testLibrary>::@getter::uFuture
      setter: <testLibrary>::@setter::uFuture
  getters
    isOriginVariable isStatic uValue
      reference: <testLibrary>::@getter::uValue
      firstFragment: #F2
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uValue
    isOriginVariable isStatic uFuture
      reference: <testLibrary>::@getter::uFuture
      firstFragment: #F5
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::uFuture
  setters
    isOriginVariable isStatic uValue
      reference: <testLibrary>::@setter::uValue
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::uValue
    isOriginVariable isStatic uFuture
      reference: <testLibrary>::@setter::uFuture
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::uFuture
  functions
    isOriginDeclaration isStatic fValue
      reference: <testLibrary>::@function::fValue
      firstFragment: #F9
      returnType: int
    isOriginDeclaration isStatic fFuture
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vBitXor (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vBitXor
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vBitAnd (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::vBitAnd
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vBitOr (nameOffset:46) (firstTokenOffset:46) (offset:46)
          element: <testLibrary>::@topLevelVariable::vBitOr
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vBitShiftLeft (nameOffset:66) (firstTokenOffset:66) (offset:66)
          element: <testLibrary>::@topLevelVariable::vBitShiftLeft
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vBitShiftRight (nameOffset:94) (firstTokenOffset:94) (offset:94)
          element: <testLibrary>::@topLevelVariable::vBitShiftRight
          inducedGetter: #F14
          inducedSetter: #F15
      getters
        #F2 isComplete isOriginVariable isStatic vBitXor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vBitXor
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vBitAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::vBitAnd
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vBitOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@getter::vBitOr
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vBitShiftLeft (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@getter::vBitShiftLeft
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vBitShiftRight (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
          element: <testLibrary>::@getter::vBitShiftRight
          inducingVariable: #F13
      setters
        #F3 isComplete isOriginVariable isStatic vBitXor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vBitXor
          inducingVariable: #F1
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vBitXor::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vBitAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::vBitAnd
          inducingVariable: #F4
          formalParameters
            #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::vBitAnd::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vBitOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@setter::vBitOr
          inducingVariable: #F7
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@setter::vBitOr::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vBitShiftLeft (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@setter::vBitShiftLeft
          inducingVariable: #F10
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@setter::vBitShiftLeft::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vBitShiftRight (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
          element: <testLibrary>::@setter::vBitShiftRight
          inducingVariable: #F13
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@setter::vBitShiftRight::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vBitXor
      reference: <testLibrary>::@topLevelVariable::vBitXor
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vBitXor
      setter: <testLibrary>::@setter::vBitXor
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vBitAnd
      reference: <testLibrary>::@topLevelVariable::vBitAnd
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::vBitAnd
      setter: <testLibrary>::@setter::vBitAnd
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vBitOr
      reference: <testLibrary>::@topLevelVariable::vBitOr
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vBitOr
      setter: <testLibrary>::@setter::vBitOr
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vBitShiftLeft
      reference: <testLibrary>::@topLevelVariable::vBitShiftLeft
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vBitShiftLeft
      setter: <testLibrary>::@setter::vBitShiftLeft
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vBitShiftRight
      reference: <testLibrary>::@topLevelVariable::vBitShiftRight
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::vBitShiftRight
      setter: <testLibrary>::@setter::vBitShiftRight
  getters
    isOriginVariable isStatic vBitXor
      reference: <testLibrary>::@getter::vBitXor
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitXor
    isOriginVariable isStatic vBitAnd
      reference: <testLibrary>::@getter::vBitAnd
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    isOriginVariable isStatic vBitOr
      reference: <testLibrary>::@getter::vBitOr
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitOr
    isOriginVariable isStatic vBitShiftLeft
      reference: <testLibrary>::@getter::vBitShiftLeft
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    isOriginVariable isStatic vBitShiftRight
      reference: <testLibrary>::@getter::vBitShiftRight
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftRight
  setters
    isOriginVariable isStatic vBitXor
      reference: <testLibrary>::@setter::vBitXor
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitXor
    isOriginVariable isStatic vBitAnd
      reference: <testLibrary>::@setter::vBitAnd
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F17
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    isOriginVariable isStatic vBitOr
      reference: <testLibrary>::@setter::vBitOr
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitOr
    isOriginVariable isStatic vBitShiftLeft
      reference: <testLibrary>::@setter::vBitShiftLeft
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F19
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    isOriginVariable isStatic vBitShiftRight
      reference: <testLibrary>::@setter::vBitShiftRight
      firstFragment: #F15
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::a
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::a
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::value
          methods
            #F7 isComplete isOriginDeclaration m (nameOffset:26) (firstTokenOffset:21) (offset:26)
              element: <testLibrary>::@class::A::@method::m
      topLevelVariables
        #F8 hasImplicitType hasInitializer isOriginDeclaration isStatic vSetField (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::vSetField
          inducedGetter: #F9
          inducedSetter: #F10
        #F11 hasImplicitType hasInitializer isOriginDeclaration isStatic vInvokeMethod (nameOffset:71) (firstTokenOffset:71) (offset:71)
          element: <testLibrary>::@topLevelVariable::vInvokeMethod
          inducedGetter: #F12
          inducedSetter: #F13
        #F14 hasImplicitType hasInitializer isOriginDeclaration isStatic vBoth (nameOffset:105) (firstTokenOffset:105) (offset:105)
          element: <testLibrary>::@topLevelVariable::vBoth
          inducedGetter: #F15
          inducedSetter: #F16
      getters
        #F9 isComplete isOriginVariable isStatic vSetField (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::vSetField
          inducingVariable: #F8
        #F12 isComplete isOriginVariable isStatic vInvokeMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@getter::vInvokeMethod
          inducingVariable: #F11
        #F15 isComplete isOriginVariable isStatic vBoth (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
          element: <testLibrary>::@getter::vBoth
          inducingVariable: #F14
      setters
        #F10 isComplete isOriginVariable isStatic vSetField (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::vSetField
          inducingVariable: #F8
          formalParameters
            #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::vSetField::@formalParameter::value
        #F13 isComplete isOriginVariable isStatic vInvokeMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@setter::vInvokeMethod
          inducingVariable: #F11
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@setter::vInvokeMethod::@formalParameter::value
        #F16 isComplete isOriginVariable isStatic vBoth (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
          element: <testLibrary>::@setter::vBoth
          inducingVariable: #F14
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
              element: <testLibrary>::@setter::vBoth::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F4
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
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vSetField
      reference: <testLibrary>::@topLevelVariable::vSetField
      firstFragment: #F8
      type: A
      getter: <testLibrary>::@getter::vSetField
      setter: <testLibrary>::@setter::vSetField
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInvokeMethod
      reference: <testLibrary>::@topLevelVariable::vInvokeMethod
      firstFragment: #F11
      type: A
      getter: <testLibrary>::@getter::vInvokeMethod
      setter: <testLibrary>::@setter::vInvokeMethod
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vBoth
      reference: <testLibrary>::@topLevelVariable::vBoth
      firstFragment: #F14
      type: A
      getter: <testLibrary>::@getter::vBoth
      setter: <testLibrary>::@setter::vBoth
  getters
    isOriginVariable isStatic vSetField
      reference: <testLibrary>::@getter::vSetField
      firstFragment: #F9
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vSetField
    isOriginVariable isStatic vInvokeMethod
      reference: <testLibrary>::@getter::vInvokeMethod
      firstFragment: #F12
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vInvokeMethod
    isOriginVariable isStatic vBoth
      reference: <testLibrary>::@getter::vBoth
      firstFragment: #F15
      returnType: A
      variable: <testLibrary>::@topLevelVariable::vBoth
  setters
    isOriginVariable isStatic vSetField
      reference: <testLibrary>::@setter::vSetField
      firstFragment: #F10
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F17
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vSetField
    isOriginVariable isStatic vInvokeMethod
      reference: <testLibrary>::@setter::vInvokeMethod
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInvokeMethod
    isOriginVariable isStatic vBoth
      reference: <testLibrary>::@setter::vBoth
      firstFragment: #F16
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
        #F7 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginDeclaration a (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@class::B::@field::a
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@getter::a
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@setter::a
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::value
        #F13 class C (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::C
          fields
            #F14 isOriginDeclaration b (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::C::@field::b
              inducedGetter: #F15
              inducedSetter: #F16
          constructors
            #F17 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F15 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::C::@getter::b
              inducingVariable: #F14
          setters
            #F16 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::C::@setter::b
              inducingVariable: #F14
              formalParameters
                #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::value
        #F19 class X (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::X
          fields
            #F20 hasInitializer isOriginDeclaration a (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::X::@field::a
              inducedGetter: #F21
              inducedSetter: #F22
            #F23 hasInitializer isOriginDeclaration b (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::X::@field::b
              inducedGetter: #F24
              inducedSetter: #F25
            #F26 hasInitializer isOriginDeclaration c (nameOffset:111) (firstTokenOffset:111) (offset:111)
              element: <testLibrary>::@class::X::@field::c
              inducedGetter: #F27
              inducedSetter: #F28
            #F29 hasImplicitType hasInitializer isOriginDeclaration t01 (nameOffset:130) (firstTokenOffset:130) (offset:130)
              element: <testLibrary>::@class::X::@field::t01
              inducedGetter: #F30
              inducedSetter: #F31
            #F32 hasImplicitType hasInitializer isOriginDeclaration t02 (nameOffset:147) (firstTokenOffset:147) (offset:147)
              element: <testLibrary>::@class::X::@field::t02
              inducedGetter: #F33
              inducedSetter: #F34
            #F35 hasImplicitType hasInitializer isOriginDeclaration t03 (nameOffset:166) (firstTokenOffset:166) (offset:166)
              element: <testLibrary>::@class::X::@field::t03
              inducedGetter: #F36
              inducedSetter: #F37
            #F38 hasImplicitType hasInitializer isOriginDeclaration t11 (nameOffset:187) (firstTokenOffset:187) (offset:187)
              element: <testLibrary>::@class::X::@field::t11
              inducedGetter: #F39
              inducedSetter: #F40
            #F41 hasImplicitType hasInitializer isOriginDeclaration t12 (nameOffset:210) (firstTokenOffset:210) (offset:210)
              element: <testLibrary>::@class::X::@field::t12
              inducedGetter: #F42
              inducedSetter: #F43
            #F44 hasImplicitType hasInitializer isOriginDeclaration t13 (nameOffset:235) (firstTokenOffset:235) (offset:235)
              element: <testLibrary>::@class::X::@field::t13
              inducedGetter: #F45
              inducedSetter: #F46
            #F47 hasImplicitType hasInitializer isOriginDeclaration t21 (nameOffset:262) (firstTokenOffset:262) (offset:262)
              element: <testLibrary>::@class::X::@field::t21
              inducedGetter: #F48
              inducedSetter: #F49
            #F50 hasImplicitType hasInitializer isOriginDeclaration t22 (nameOffset:284) (firstTokenOffset:284) (offset:284)
              element: <testLibrary>::@class::X::@field::t22
              inducedGetter: #F51
              inducedSetter: #F52
            #F53 hasImplicitType hasInitializer isOriginDeclaration t23 (nameOffset:308) (firstTokenOffset:308) (offset:308)
              element: <testLibrary>::@class::X::@field::t23
              inducedGetter: #F54
              inducedSetter: #F55
          constructors
            #F56 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
          getters
            #F21 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::X::@getter::a
              inducingVariable: #F20
            #F24 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::X::@getter::b
              inducingVariable: #F23
            #F27 isComplete isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@class::X::@getter::c
              inducingVariable: #F26
            #F30 isComplete isOriginVariable t01 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
              element: <testLibrary>::@class::X::@getter::t01
              inducingVariable: #F29
            #F33 isComplete isOriginVariable t02 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:147)
              element: <testLibrary>::@class::X::@getter::t02
              inducingVariable: #F32
            #F36 isComplete isOriginVariable t03 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:166)
              element: <testLibrary>::@class::X::@getter::t03
              inducingVariable: #F35
            #F39 isComplete isOriginVariable t11 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:187)
              element: <testLibrary>::@class::X::@getter::t11
              inducingVariable: #F38
            #F42 isComplete isOriginVariable t12 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:210)
              element: <testLibrary>::@class::X::@getter::t12
              inducingVariable: #F41
            #F45 isComplete isOriginVariable t13 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:235)
              element: <testLibrary>::@class::X::@getter::t13
              inducingVariable: #F44
            #F48 isComplete isOriginVariable t21 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:262)
              element: <testLibrary>::@class::X::@getter::t21
              inducingVariable: #F47
            #F51 isComplete isOriginVariable t22 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
              element: <testLibrary>::@class::X::@getter::t22
              inducingVariable: #F50
            #F54 isComplete isOriginVariable t23 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:308)
              element: <testLibrary>::@class::X::@getter::t23
              inducingVariable: #F53
          setters
            #F22 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::X::@setter::a
              inducingVariable: #F20
              formalParameters
                #F57 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
                  element: <testLibrary>::@class::X::@setter::a::@formalParameter::value
            #F25 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::X::@setter::b
              inducingVariable: #F23
              formalParameters
                #F58 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
                  element: <testLibrary>::@class::X::@setter::b::@formalParameter::value
            #F28 isComplete isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@class::X::@setter::c
              inducingVariable: #F26
              formalParameters
                #F59 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
                  element: <testLibrary>::@class::X::@setter::c::@formalParameter::value
            #F31 isComplete isOriginVariable t01 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
              element: <testLibrary>::@class::X::@setter::t01
              inducingVariable: #F29
              formalParameters
                #F60 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
                  element: <testLibrary>::@class::X::@setter::t01::@formalParameter::value
            #F34 isComplete isOriginVariable t02 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:147)
              element: <testLibrary>::@class::X::@setter::t02
              inducingVariable: #F32
              formalParameters
                #F61 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:147)
                  element: <testLibrary>::@class::X::@setter::t02::@formalParameter::value
            #F37 isComplete isOriginVariable t03 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:166)
              element: <testLibrary>::@class::X::@setter::t03
              inducingVariable: #F35
              formalParameters
                #F62 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:166)
                  element: <testLibrary>::@class::X::@setter::t03::@formalParameter::value
            #F40 isComplete isOriginVariable t11 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:187)
              element: <testLibrary>::@class::X::@setter::t11
              inducingVariable: #F38
              formalParameters
                #F63 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:187)
                  element: <testLibrary>::@class::X::@setter::t11::@formalParameter::value
            #F43 isComplete isOriginVariable t12 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:210)
              element: <testLibrary>::@class::X::@setter::t12
              inducingVariable: #F41
              formalParameters
                #F64 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:210)
                  element: <testLibrary>::@class::X::@setter::t12::@formalParameter::value
            #F46 isComplete isOriginVariable t13 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:235)
              element: <testLibrary>::@class::X::@setter::t13
              inducingVariable: #F44
              formalParameters
                #F65 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:235)
                  element: <testLibrary>::@class::X::@setter::t13::@formalParameter::value
            #F49 isComplete isOriginVariable t21 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:262)
              element: <testLibrary>::@class::X::@setter::t21
              inducingVariable: #F47
              formalParameters
                #F66 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:262)
                  element: <testLibrary>::@class::X::@setter::t21::@formalParameter::value
            #F52 isComplete isOriginVariable t22 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
              element: <testLibrary>::@class::X::@setter::t22
              inducingVariable: #F50
              formalParameters
                #F67 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
                  element: <testLibrary>::@class::X::@setter::t22::@formalParameter::value
            #F55 isComplete isOriginVariable t23 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:308)
              element: <testLibrary>::@class::X::@setter::t23
              inducingVariable: #F53
              formalParameters
                #F68 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:308)
                  element: <testLibrary>::@class::X::@setter::t23::@formalParameter::value
      functions
        #F69 isComplete isOriginDeclaration isStatic newA (nameOffset:332) (firstTokenOffset:330) (offset:332)
          element: <testLibrary>::@function::newA
        #F70 isComplete isOriginDeclaration isStatic newB (nameOffset:353) (firstTokenOffset:351) (offset:353)
          element: <testLibrary>::@function::newB
        #F71 isComplete isOriginDeclaration isStatic newC (nameOffset:374) (firstTokenOffset:372) (offset:374)
          element: <testLibrary>::@function::newC
  classes
    hasNonFinalField isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F11
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: A
          returnType: void
          variable: <testLibrary>::@class::B::@field::a
    hasNonFinalField isSimplyBounded class C
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
          firstFragment: #F17
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F15
          returnType: B
          variable: <testLibrary>::@class::C::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F16
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F18
              type: B
          returnType: void
          variable: <testLibrary>::@class::C::@field::b
    hasNonFinalField isSimplyBounded class X
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
          firstFragment: #F23
          type: B
          getter: <testLibrary>::@class::X::@getter::b
          setter: <testLibrary>::@class::X::@setter::b
        hasInitializer isOriginDeclaration c
          reference: <testLibrary>::@class::X::@field::c
          firstFragment: #F26
          type: C
          getter: <testLibrary>::@class::X::@getter::c
          setter: <testLibrary>::@class::X::@setter::c
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t01
          reference: <testLibrary>::@class::X::@field::t01
          firstFragment: #F29
          type: int
          getter: <testLibrary>::@class::X::@getter::t01
          setter: <testLibrary>::@class::X::@setter::t01
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t02
          reference: <testLibrary>::@class::X::@field::t02
          firstFragment: #F32
          type: int
          getter: <testLibrary>::@class::X::@getter::t02
          setter: <testLibrary>::@class::X::@setter::t02
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t03
          reference: <testLibrary>::@class::X::@field::t03
          firstFragment: #F35
          type: int
          getter: <testLibrary>::@class::X::@getter::t03
          setter: <testLibrary>::@class::X::@setter::t03
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t11
          reference: <testLibrary>::@class::X::@field::t11
          firstFragment: #F38
          type: int
          getter: <testLibrary>::@class::X::@getter::t11
          setter: <testLibrary>::@class::X::@setter::t11
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t12
          reference: <testLibrary>::@class::X::@field::t12
          firstFragment: #F41
          type: int
          getter: <testLibrary>::@class::X::@getter::t12
          setter: <testLibrary>::@class::X::@setter::t12
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t13
          reference: <testLibrary>::@class::X::@field::t13
          firstFragment: #F44
          type: int
          getter: <testLibrary>::@class::X::@getter::t13
          setter: <testLibrary>::@class::X::@setter::t13
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t21
          reference: <testLibrary>::@class::X::@field::t21
          firstFragment: #F47
          type: int
          getter: <testLibrary>::@class::X::@getter::t21
          setter: <testLibrary>::@class::X::@setter::t21
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t22
          reference: <testLibrary>::@class::X::@field::t22
          firstFragment: #F50
          type: int
          getter: <testLibrary>::@class::X::@getter::t22
          setter: <testLibrary>::@class::X::@setter::t22
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t23
          reference: <testLibrary>::@class::X::@field::t23
          firstFragment: #F53
          type: int
          getter: <testLibrary>::@class::X::@getter::t23
          setter: <testLibrary>::@class::X::@setter::t23
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F56
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::X::@getter::a
          firstFragment: #F21
          returnType: A
          variable: <testLibrary>::@class::X::@field::a
        isOriginVariable b
          reference: <testLibrary>::@class::X::@getter::b
          firstFragment: #F24
          returnType: B
          variable: <testLibrary>::@class::X::@field::b
        isOriginVariable c
          reference: <testLibrary>::@class::X::@getter::c
          firstFragment: #F27
          returnType: C
          variable: <testLibrary>::@class::X::@field::c
        isOriginVariable t01
          reference: <testLibrary>::@class::X::@getter::t01
          firstFragment: #F30
          returnType: int
          variable: <testLibrary>::@class::X::@field::t01
        isOriginVariable t02
          reference: <testLibrary>::@class::X::@getter::t02
          firstFragment: #F33
          returnType: int
          variable: <testLibrary>::@class::X::@field::t02
        isOriginVariable t03
          reference: <testLibrary>::@class::X::@getter::t03
          firstFragment: #F36
          returnType: int
          variable: <testLibrary>::@class::X::@field::t03
        isOriginVariable t11
          reference: <testLibrary>::@class::X::@getter::t11
          firstFragment: #F39
          returnType: int
          variable: <testLibrary>::@class::X::@field::t11
        isOriginVariable t12
          reference: <testLibrary>::@class::X::@getter::t12
          firstFragment: #F42
          returnType: int
          variable: <testLibrary>::@class::X::@field::t12
        isOriginVariable t13
          reference: <testLibrary>::@class::X::@getter::t13
          firstFragment: #F45
          returnType: int
          variable: <testLibrary>::@class::X::@field::t13
        isOriginVariable t21
          reference: <testLibrary>::@class::X::@getter::t21
          firstFragment: #F48
          returnType: int
          variable: <testLibrary>::@class::X::@field::t21
        isOriginVariable t22
          reference: <testLibrary>::@class::X::@getter::t22
          firstFragment: #F51
          returnType: int
          variable: <testLibrary>::@class::X::@field::t22
        isOriginVariable t23
          reference: <testLibrary>::@class::X::@getter::t23
          firstFragment: #F54
          returnType: int
          variable: <testLibrary>::@class::X::@field::t23
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::X::@setter::a
          firstFragment: #F22
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F57
              type: A
          returnType: void
          variable: <testLibrary>::@class::X::@field::a
        isOriginVariable b
          reference: <testLibrary>::@class::X::@setter::b
          firstFragment: #F25
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F58
              type: B
          returnType: void
          variable: <testLibrary>::@class::X::@field::b
        isOriginVariable c
          reference: <testLibrary>::@class::X::@setter::c
          firstFragment: #F28
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F59
              type: C
          returnType: void
          variable: <testLibrary>::@class::X::@field::c
        isOriginVariable t01
          reference: <testLibrary>::@class::X::@setter::t01
          firstFragment: #F31
          formalParameters
            #E6 requiredPositional value
              firstFragment: #F60
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t01
        isOriginVariable t02
          reference: <testLibrary>::@class::X::@setter::t02
          firstFragment: #F34
          formalParameters
            #E7 requiredPositional value
              firstFragment: #F61
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t02
        isOriginVariable t03
          reference: <testLibrary>::@class::X::@setter::t03
          firstFragment: #F37
          formalParameters
            #E8 requiredPositional value
              firstFragment: #F62
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t03
        isOriginVariable t11
          reference: <testLibrary>::@class::X::@setter::t11
          firstFragment: #F40
          formalParameters
            #E9 requiredPositional value
              firstFragment: #F63
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t11
        isOriginVariable t12
          reference: <testLibrary>::@class::X::@setter::t12
          firstFragment: #F43
          formalParameters
            #E10 requiredPositional value
              firstFragment: #F64
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t12
        isOriginVariable t13
          reference: <testLibrary>::@class::X::@setter::t13
          firstFragment: #F46
          formalParameters
            #E11 requiredPositional value
              firstFragment: #F65
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t13
        isOriginVariable t21
          reference: <testLibrary>::@class::X::@setter::t21
          firstFragment: #F49
          formalParameters
            #E12 requiredPositional value
              firstFragment: #F66
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t21
        isOriginVariable t22
          reference: <testLibrary>::@class::X::@setter::t22
          firstFragment: #F52
          formalParameters
            #E13 requiredPositional value
              firstFragment: #F67
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t22
        isOriginVariable t23
          reference: <testLibrary>::@class::X::@setter::t23
          firstFragment: #F55
          formalParameters
            #E14 requiredPositional value
              firstFragment: #F68
              type: int
          returnType: void
          variable: <testLibrary>::@class::X::@field::t23
  functions
    isOriginDeclaration isStatic newA
      reference: <testLibrary>::@function::newA
      firstFragment: #F69
      returnType: A
    isOriginDeclaration isStatic newB
      reference: <testLibrary>::@function::newB
      firstFragment: #F70
      returnType: B
    isOriginDeclaration isStatic newC
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: num
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    isOriginVariable isStatic V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::V
  setters
    isOriginVariable isStatic V
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vEq (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vEq
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vNotEq (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::vNotEq
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vEq
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::vNotEq
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vEq
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vEq::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::vNotEq
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::vNotEq::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    isOriginVariable isStatic vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    isOriginVariable isStatic vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    isOriginVariable isStatic vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vEq
    isOriginVariable isStatic vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F6
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::b
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::b::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a]
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    isOriginVariable isStatic a
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic b0 (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b0
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic b1 (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::b1
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic b0 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b0
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic b1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::b1
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic b0 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::b0
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::b0::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic b1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::b1
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::b1::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<num>
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer b0
      reference: <testLibrary>::@topLevelVariable::b0
      firstFragment: #F4
      type: num
      getter: <testLibrary>::@getter::b0
      setter: <testLibrary>::@setter::b0
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer b1
      reference: <testLibrary>::@topLevelVariable::b1
      firstFragment: #F7
      type: num
      getter: <testLibrary>::@getter::b1
      setter: <testLibrary>::@setter::b1
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b0
      reference: <testLibrary>::@getter::b0
      firstFragment: #F5
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b0
    isOriginVariable isStatic b1
      reference: <testLibrary>::@getter::b1
      firstFragment: #F8
      returnType: num
      variable: <testLibrary>::@topLevelVariable::b1
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b0
      reference: <testLibrary>::@setter::b0
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b0
    isOriginVariable isStatic b1
      reference: <testLibrary>::@setter::b1
      firstFragment: #F9
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F8 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::x
          inducingVariable: #F7
      setters
        #F9 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::x
          inducingVariable: #F7
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
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
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
            #F2 hasImplicitType hasInitializer isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::f
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F8 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::x
          inducingVariable: #F7
      setters
        #F9 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::x
          inducingVariable: #F7
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
        #F7 class B (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::B
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration isStatic t (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@class::B::@field::t
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable isStatic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::B::@getter::t
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable isStatic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::B::@setter::t
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
                  element: <testLibrary>::@class::B::@setter::t::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer t
          reference: <testLibrary>::@class::B::@field::t
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::t
          setter: <testLibrary>::@class::B::@setter::t
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        isOriginVariable isStatic t
          reference: <testLibrary>::@class::B::@getter::t
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::B::@field::t
      setters
        isOriginVariable isStatic t
          reference: <testLibrary>::@class::B::@setter::t
          firstFragment: #F10
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@getter::b
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@setter::b
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::C::@setter::b::@formalParameter::value
      topLevelVariables
        #F7 isOriginDeclaration isStatic c (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F8 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::c
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::x
          inducingVariable: #F10
      setters
        #F9 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::c
          inducingVariable: #F7
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::x
          inducingVariable: #F10
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
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
          firstFragment: #F5
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F3
          returnType: bool
          variable: <testLibrary>::@class::C::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::C::@setter::b
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: bool
          returnType: void
          variable: <testLibrary>::@class::C::@field::b
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F7
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F8
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F11
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F13
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F12
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@getter::b
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@setter::b
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::I::@setter::b::@formalParameter::value
        #F7 isAbstract class C (nameOffset:37) (firstTokenOffset:22) (offset:37)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 isOriginDeclaration isStatic c (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F10
          inducedSetter: #F11
        #F12 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:64) (firstTokenOffset:64) (offset:64)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F13
          inducedSetter: #F14
      getters
        #F10 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::c
          inducingVariable: #F9
        #F13 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@getter::x
          inducingVariable: #F12
      setters
        #F11 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@setter::c
          inducingVariable: #F9
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F14 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@setter::x
          inducingVariable: #F12
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class I
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
          firstFragment: #F5
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F3
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: bool
          returnType: void
          variable: <testLibrary>::@class::I::@field::b
    isAbstract isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F9
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F12
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F10
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F13
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F15
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F14
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
          getters
            #F3 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@getter::b
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::I::@setter::b
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::I::@setter::b::@formalParameter::value
        #F7 isAbstract class C (nameOffset:37) (firstTokenOffset:22) (offset:37)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F9 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:74) (firstTokenOffset:74) (offset:74)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F10
          inducedSetter: #F11
      getters
        #F10 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@getter::x
          inducingVariable: #F9
      setters
        #F11 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@setter::x
          inducingVariable: #F9
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@setter::x::@formalParameter::value
      functions
        #F13 isComplete isOriginDeclaration isStatic f (nameOffset:57) (firstTokenOffset:55) (offset:57)
          element: <testLibrary>::@function::f
  classes
    hasNonFinalField isSimplyBounded class I
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
          firstFragment: #F5
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@getter::b
          firstFragment: #F3
          returnType: bool
          variable: <testLibrary>::@class::I::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::I::@setter::b
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: bool
          returnType: void
          variable: <testLibrary>::@class::I::@field::b
    isAbstract isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        I
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F9
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F10
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
  functions
    isOriginDeclaration isStatic f
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
            #F3 isComplete isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::foo
        #F4 hasExtendsClause class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@class::B::@method::foo
      topLevelVariables
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:70) (firstTokenOffset:70) (offset:70)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic y (nameOffset:89) (firstTokenOffset:89) (offset:89)
          element: <testLibrary>::@topLevelVariable::y
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F8 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@getter::x
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@getter::y
          inducingVariable: #F10
      setters
        #F9 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@setter::x
          inducingVariable: #F7
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@setter::y
          inducingVariable: #F10
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@setter::y::@formalParameter::value
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic y
      reference: <testLibrary>::@getter::y
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::y
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F13
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic y
      reference: <testLibrary>::@setter::y
      firstFragment: #F12
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vFuture (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::vFuture
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic v_noParameters_inferredReturnType (nameOffset:60) (firstTokenOffset:60) (offset:60)
          element: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic v_hasParameter_withType_inferredReturnType (nameOffset:110) (firstTokenOffset:110) (offset:110)
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic v_hasParameter_withType_returnParameter (nameOffset:177) (firstTokenOffset:177) (offset:177)
          element: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic v_async_returnValue (nameOffset:240) (firstTokenOffset:240) (offset:240)
          element: <testLibrary>::@topLevelVariable::v_async_returnValue
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic v_async_returnFuture (nameOffset:282) (firstTokenOffset:282) (offset:282)
          element: <testLibrary>::@topLevelVariable::v_async_returnFuture
          inducedGetter: #F17
          inducedSetter: #F18
      getters
        #F2 isComplete isOriginVariable isStatic vFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::vFuture
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic v_noParameters_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@getter::v_noParameters_inferredReturnType
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic v_hasParameter_withType_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
          element: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic v_hasParameter_withType_returnParameter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:177)
          element: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic v_async_returnValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:240)
          element: <testLibrary>::@getter::v_async_returnValue
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic v_async_returnFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:282)
          element: <testLibrary>::@getter::v_async_returnFuture
          inducingVariable: #F16
      setters
        #F3 isComplete isOriginVariable isStatic vFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::vFuture
          inducingVariable: #F1
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::vFuture::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic v_noParameters_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@setter::v_noParameters_inferredReturnType
          inducingVariable: #F4
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@setter::v_noParameters_inferredReturnType::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic v_hasParameter_withType_inferredReturnType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
          element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
          inducingVariable: #F7
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
              element: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic v_hasParameter_withType_returnParameter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:177)
          element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
          inducingVariable: #F10
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:177)
              element: <testLibrary>::@setter::v_hasParameter_withType_returnParameter::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic v_async_returnValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:240)
          element: <testLibrary>::@setter::v_async_returnValue
          inducingVariable: #F13
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:240)
              element: <testLibrary>::@setter::v_async_returnValue::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic v_async_returnFuture (nameOffset:<null>) (firstTokenOffset:<null>) (offset:282)
          element: <testLibrary>::@setter::v_async_returnFuture
          inducingVariable: #F16
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:282)
              element: <testLibrary>::@setter::v_async_returnFuture::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vFuture
      reference: <testLibrary>::@topLevelVariable::vFuture
      firstFragment: #F1
      type: Future<int>
      getter: <testLibrary>::@getter::vFuture
      setter: <testLibrary>::@setter::vFuture
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v_noParameters_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
      firstFragment: #F4
      type: int Function()
      getter: <testLibrary>::@getter::v_noParameters_inferredReturnType
      setter: <testLibrary>::@setter::v_noParameters_inferredReturnType
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
      firstFragment: #F7
      type: int Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      setter: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
      firstFragment: #F10
      type: String Function(String)
      getter: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      setter: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v_async_returnValue
      reference: <testLibrary>::@topLevelVariable::v_async_returnValue
      firstFragment: #F13
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnValue
      setter: <testLibrary>::@setter::v_async_returnValue
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v_async_returnFuture
      reference: <testLibrary>::@topLevelVariable::v_async_returnFuture
      firstFragment: #F16
      type: Future<int> Function()
      getter: <testLibrary>::@getter::v_async_returnFuture
      setter: <testLibrary>::@setter::v_async_returnFuture
  getters
    isOriginVariable isStatic vFuture
      reference: <testLibrary>::@getter::vFuture
      firstFragment: #F2
      returnType: Future<int>
      variable: <testLibrary>::@topLevelVariable::vFuture
    isOriginVariable isStatic v_noParameters_inferredReturnType
      reference: <testLibrary>::@getter::v_noParameters_inferredReturnType
      firstFragment: #F5
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
    isOriginVariable isStatic v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@getter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F8
      returnType: int Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
    isOriginVariable isStatic v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@getter::v_hasParameter_withType_returnParameter
      firstFragment: #F11
      returnType: String Function(String)
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
    isOriginVariable isStatic v_async_returnValue
      reference: <testLibrary>::@getter::v_async_returnValue
      firstFragment: #F14
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnValue
    isOriginVariable isStatic v_async_returnFuture
      reference: <testLibrary>::@getter::v_async_returnFuture
      firstFragment: #F17
      returnType: Future<int> Function()
      variable: <testLibrary>::@topLevelVariable::v_async_returnFuture
  setters
    isOriginVariable isStatic vFuture
      reference: <testLibrary>::@setter::vFuture
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: Future<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vFuture
    isOriginVariable isStatic v_noParameters_inferredReturnType
      reference: <testLibrary>::@setter::v_noParameters_inferredReturnType
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: int Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_noParameters_inferredReturnType
    isOriginVariable isStatic v_hasParameter_withType_inferredReturnType
      reference: <testLibrary>::@setter::v_hasParameter_withType_inferredReturnType
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F21
          type: int Function(String)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_inferredReturnType
    isOriginVariable isStatic v_hasParameter_withType_returnParameter
      reference: <testLibrary>::@setter::v_hasParameter_withType_returnParameter
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F22
          type: String Function(String)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_hasParameter_withType_returnParameter
    isOriginVariable isStatic v_async_returnValue
      reference: <testLibrary>::@setter::v_async_returnValue
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F23
          type: Future<int> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v_async_returnValue
    isOriginVariable isStatic v_async_returnFuture
      reference: <testLibrary>::@setter::v_async_returnFuture
      firstFragment: #F18
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vHasTypeArgument (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::vHasTypeArgument
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vNoTypeArgument (nameOffset:55) (firstTokenOffset:55) (offset:55)
          element: <testLibrary>::@topLevelVariable::vNoTypeArgument
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic vHasTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::vHasTypeArgument
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vNoTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@getter::vNoTypeArgument
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic vHasTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::vHasTypeArgument
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::vHasTypeArgument::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vNoTypeArgument (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@setter::vNoTypeArgument
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@setter::vNoTypeArgument::@formalParameter::value
      functions
        #F9 isComplete isOriginDeclaration isStatic f (nameOffset:2) (firstTokenOffset:0) (offset:2)
          element: <testLibrary>::@function::f
          typeParameters
            #F10 T (nameOffset:4) (firstTokenOffset:4) (offset:4)
              element: #E0 T
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vHasTypeArgument
      reference: <testLibrary>::@topLevelVariable::vHasTypeArgument
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vHasTypeArgument
      setter: <testLibrary>::@setter::vHasTypeArgument
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNoTypeArgument
      reference: <testLibrary>::@topLevelVariable::vNoTypeArgument
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::vNoTypeArgument
      setter: <testLibrary>::@setter::vNoTypeArgument
  getters
    isOriginVariable isStatic vHasTypeArgument
      reference: <testLibrary>::@getter::vHasTypeArgument
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vHasTypeArgument
    isOriginVariable isStatic vNoTypeArgument
      reference: <testLibrary>::@getter::vNoTypeArgument
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::vNoTypeArgument
  setters
    isOriginVariable isStatic vHasTypeArgument
      reference: <testLibrary>::@setter::vHasTypeArgument
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F7
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vHasTypeArgument
    isOriginVariable isStatic vNoTypeArgument
      reference: <testLibrary>::@setter::vNoTypeArgument
      firstFragment: #F6
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F8
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNoTypeArgument
  functions
    isOriginDeclaration isStatic f
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vOkArgumentType (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::vOkArgumentType
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vWrongArgumentType (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::vWrongArgumentType
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic vOkArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::vOkArgumentType
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vWrongArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::vWrongArgumentType
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic vOkArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::vOkArgumentType
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::vOkArgumentType::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vWrongArgumentType (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@setter::vWrongArgumentType
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@setter::vWrongArgumentType::@formalParameter::value
      functions
        #F9 isComplete isOriginDeclaration isStatic f (nameOffset:7) (firstTokenOffset:0) (offset:7)
          element: <testLibrary>::@function::f
          formalParameters
            #F10 requiredPositional isOriginDeclaration p (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::f::@formalParameter::p
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vOkArgumentType
      reference: <testLibrary>::@topLevelVariable::vOkArgumentType
      firstFragment: #F1
      type: String
      getter: <testLibrary>::@getter::vOkArgumentType
      setter: <testLibrary>::@setter::vOkArgumentType
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vWrongArgumentType
      reference: <testLibrary>::@topLevelVariable::vWrongArgumentType
      firstFragment: #F4
      type: String
      getter: <testLibrary>::@getter::vWrongArgumentType
      setter: <testLibrary>::@setter::vWrongArgumentType
  getters
    isOriginVariable isStatic vOkArgumentType
      reference: <testLibrary>::@getter::vOkArgumentType
      firstFragment: #F2
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vOkArgumentType
    isOriginVariable isStatic vWrongArgumentType
      reference: <testLibrary>::@getter::vWrongArgumentType
      firstFragment: #F5
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vWrongArgumentType
  setters
    isOriginVariable isStatic vOkArgumentType
      reference: <testLibrary>::@setter::vOkArgumentType
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vOkArgumentType
    isOriginVariable isStatic vWrongArgumentType
      reference: <testLibrary>::@setter::vWrongArgumentType
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vWrongArgumentType
  functions
    isOriginDeclaration isStatic f
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
            #F2 hasImplicitType hasInitializer isOriginDeclaration isStatic staticClassVariable (nameOffset:118) (firstTokenOffset:118) (offset:118)
              element: <testLibrary>::@class::A::@field::staticClassVariable
              inducedGetter: #F3
              inducedSetter: #F4
            #F5 isOriginGetterSetter isStatic staticGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@class::A::@field::staticGetter
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::A::@getter::staticClassVariable
              inducingVariable: #F2
            #F7 isComplete isOriginDeclaration isStatic staticGetter (nameOffset:160) (firstTokenOffset:145) (offset:160)
              element: <testLibrary>::@class::A::@getter::staticGetter
          setters
            #F4 isComplete isOriginVariable isStatic staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::A::@setter::staticClassVariable
              inducingVariable: #F2
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::A::@setter::staticClassVariable::@formalParameter::value
          methods
            #F9 isComplete isOriginDeclaration isStatic staticClassMethod (nameOffset:195) (firstTokenOffset:181) (offset:195)
              element: <testLibrary>::@class::A::@method::staticClassMethod
              formalParameters
                #F10 requiredPositional isOriginDeclaration p (nameOffset:217) (firstTokenOffset:213) (offset:217)
                  element: <testLibrary>::@class::A::@method::staticClassMethod::@formalParameter::p
            #F11 isComplete isOriginDeclaration instanceClassMethod (nameOffset:238) (firstTokenOffset:231) (offset:238)
              element: <testLibrary>::@class::A::@method::instanceClassMethod
              formalParameters
                #F12 requiredPositional isOriginDeclaration p (nameOffset:262) (firstTokenOffset:258) (offset:262)
                  element: <testLibrary>::@class::A::@method::instanceClassMethod::@formalParameter::p
      topLevelVariables
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic topLevelVariable (nameOffset:44) (firstTokenOffset:44) (offset:44)
          element: <testLibrary>::@topLevelVariable::topLevelVariable
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 isOriginGetterSetter isStatic topLevelGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@topLevelVariable::topLevelGetter
        #F17 hasImplicitType hasInitializer isOriginDeclaration isStatic r_topLevelFunction (nameOffset:280) (firstTokenOffset:280) (offset:280)
          element: <testLibrary>::@topLevelVariable::r_topLevelFunction
          inducedGetter: #F18
          inducedSetter: #F19
        #F20 hasImplicitType hasInitializer isOriginDeclaration isStatic r_topLevelVariable (nameOffset:323) (firstTokenOffset:323) (offset:323)
          element: <testLibrary>::@topLevelVariable::r_topLevelVariable
          inducedGetter: #F21
          inducedSetter: #F22
        #F23 hasImplicitType hasInitializer isOriginDeclaration isStatic r_topLevelGetter (nameOffset:366) (firstTokenOffset:366) (offset:366)
          element: <testLibrary>::@topLevelVariable::r_topLevelGetter
          inducedGetter: #F24
          inducedSetter: #F25
        #F26 hasImplicitType hasInitializer isOriginDeclaration isStatic r_staticClassVariable (nameOffset:405) (firstTokenOffset:405) (offset:405)
          element: <testLibrary>::@topLevelVariable::r_staticClassVariable
          inducedGetter: #F27
          inducedSetter: #F28
        #F29 hasImplicitType hasInitializer isOriginDeclaration isStatic r_staticGetter (nameOffset:456) (firstTokenOffset:456) (offset:456)
          element: <testLibrary>::@topLevelVariable::r_staticGetter
          inducedGetter: #F30
          inducedSetter: #F31
        #F32 hasImplicitType hasInitializer isOriginDeclaration isStatic r_staticClassMethod (nameOffset:493) (firstTokenOffset:493) (offset:493)
          element: <testLibrary>::@topLevelVariable::r_staticClassMethod
          inducedGetter: #F33
          inducedSetter: #F34
        #F35 hasImplicitType hasInitializer isOriginDeclaration isStatic instanceOfA (nameOffset:540) (firstTokenOffset:540) (offset:540)
          element: <testLibrary>::@topLevelVariable::instanceOfA
          inducedGetter: #F36
          inducedSetter: #F37
        #F38 hasImplicitType hasInitializer isOriginDeclaration isStatic r_instanceClassMethod (nameOffset:567) (firstTokenOffset:567) (offset:567)
          element: <testLibrary>::@topLevelVariable::r_instanceClassMethod
          inducedGetter: #F39
          inducedSetter: #F40
      getters
        #F14 isComplete isOriginVariable isStatic topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@getter::topLevelVariable
          inducingVariable: #F13
        #F41 isComplete isOriginDeclaration isStatic topLevelGetter (nameOffset:74) (firstTokenOffset:66) (offset:74)
          element: <testLibrary>::@getter::topLevelGetter
        #F18 isComplete isOriginVariable isStatic r_topLevelFunction (nameOffset:<null>) (firstTokenOffset:<null>) (offset:280)
          element: <testLibrary>::@getter::r_topLevelFunction
          inducingVariable: #F17
        #F21 isComplete isOriginVariable isStatic r_topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:323)
          element: <testLibrary>::@getter::r_topLevelVariable
          inducingVariable: #F20
        #F24 isComplete isOriginVariable isStatic r_topLevelGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:366)
          element: <testLibrary>::@getter::r_topLevelGetter
          inducingVariable: #F23
        #F27 isComplete isOriginVariable isStatic r_staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:405)
          element: <testLibrary>::@getter::r_staticClassVariable
          inducingVariable: #F26
        #F30 isComplete isOriginVariable isStatic r_staticGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:456)
          element: <testLibrary>::@getter::r_staticGetter
          inducingVariable: #F29
        #F33 isComplete isOriginVariable isStatic r_staticClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:493)
          element: <testLibrary>::@getter::r_staticClassMethod
          inducingVariable: #F32
        #F36 isComplete isOriginVariable isStatic instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:540)
          element: <testLibrary>::@getter::instanceOfA
          inducingVariable: #F35
        #F39 isComplete isOriginVariable isStatic r_instanceClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:567)
          element: <testLibrary>::@getter::r_instanceClassMethod
          inducingVariable: #F38
      setters
        #F15 isComplete isOriginVariable isStatic topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@setter::topLevelVariable
          inducingVariable: #F13
          formalParameters
            #F42 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@setter::topLevelVariable::@formalParameter::value
        #F19 isComplete isOriginVariable isStatic r_topLevelFunction (nameOffset:<null>) (firstTokenOffset:<null>) (offset:280)
          element: <testLibrary>::@setter::r_topLevelFunction
          inducingVariable: #F17
          formalParameters
            #F43 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:280)
              element: <testLibrary>::@setter::r_topLevelFunction::@formalParameter::value
        #F22 isComplete isOriginVariable isStatic r_topLevelVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:323)
          element: <testLibrary>::@setter::r_topLevelVariable
          inducingVariable: #F20
          formalParameters
            #F44 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:323)
              element: <testLibrary>::@setter::r_topLevelVariable::@formalParameter::value
        #F25 isComplete isOriginVariable isStatic r_topLevelGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:366)
          element: <testLibrary>::@setter::r_topLevelGetter
          inducingVariable: #F23
          formalParameters
            #F45 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:366)
              element: <testLibrary>::@setter::r_topLevelGetter::@formalParameter::value
        #F28 isComplete isOriginVariable isStatic r_staticClassVariable (nameOffset:<null>) (firstTokenOffset:<null>) (offset:405)
          element: <testLibrary>::@setter::r_staticClassVariable
          inducingVariable: #F26
          formalParameters
            #F46 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:405)
              element: <testLibrary>::@setter::r_staticClassVariable::@formalParameter::value
        #F31 isComplete isOriginVariable isStatic r_staticGetter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:456)
          element: <testLibrary>::@setter::r_staticGetter
          inducingVariable: #F29
          formalParameters
            #F47 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:456)
              element: <testLibrary>::@setter::r_staticGetter::@formalParameter::value
        #F34 isComplete isOriginVariable isStatic r_staticClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:493)
          element: <testLibrary>::@setter::r_staticClassMethod
          inducingVariable: #F32
          formalParameters
            #F48 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:493)
              element: <testLibrary>::@setter::r_staticClassMethod::@formalParameter::value
        #F37 isComplete isOriginVariable isStatic instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:540)
          element: <testLibrary>::@setter::instanceOfA
          inducingVariable: #F35
          formalParameters
            #F49 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:540)
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::value
        #F40 isComplete isOriginVariable isStatic r_instanceClassMethod (nameOffset:<null>) (firstTokenOffset:<null>) (offset:567)
          element: <testLibrary>::@setter::r_instanceClassMethod
          inducingVariable: #F38
          formalParameters
            #F50 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:567)
              element: <testLibrary>::@setter::r_instanceClassMethod::@formalParameter::value
      functions
        #F51 isComplete isOriginDeclaration isStatic topLevelFunction (nameOffset:7) (firstTokenOffset:0) (offset:7)
          element: <testLibrary>::@function::topLevelFunction
          formalParameters
            #F52 requiredPositional isOriginDeclaration p (nameOffset:28) (firstTokenOffset:24) (offset:28)
              element: <testLibrary>::@function::topLevelFunction::@formalParameter::p
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer staticClassVariable
          reference: <testLibrary>::@class::A::@field::staticClassVariable
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::staticClassVariable
          setter: <testLibrary>::@class::A::@setter::staticClassVariable
        isOriginGetterSetter isStatic staticGetter
          reference: <testLibrary>::@class::A::@field::staticGetter
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::staticGetter
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        isOriginVariable isStatic staticClassVariable
          reference: <testLibrary>::@class::A::@getter::staticClassVariable
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::staticClassVariable
        isOriginDeclaration isStatic staticGetter
          reference: <testLibrary>::@class::A::@getter::staticGetter
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::staticGetter
      setters
        isOriginVariable isStatic staticClassVariable
          reference: <testLibrary>::@class::A::@setter::staticClassVariable
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::staticClassVariable
      methods
        isOriginDeclaration isStatic staticClassMethod
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
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer topLevelVariable
      reference: <testLibrary>::@topLevelVariable::topLevelVariable
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::topLevelVariable
      setter: <testLibrary>::@setter::topLevelVariable
    isOriginGetterSetter isStatic topLevelGetter
      reference: <testLibrary>::@topLevelVariable::topLevelGetter
      firstFragment: #F16
      type: int
      getter: <testLibrary>::@getter::topLevelGetter
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_topLevelFunction
      reference: <testLibrary>::@topLevelVariable::r_topLevelFunction
      firstFragment: #F17
      type: String Function(int)
      getter: <testLibrary>::@getter::r_topLevelFunction
      setter: <testLibrary>::@setter::r_topLevelFunction
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_topLevelVariable
      reference: <testLibrary>::@topLevelVariable::r_topLevelVariable
      firstFragment: #F20
      type: int
      getter: <testLibrary>::@getter::r_topLevelVariable
      setter: <testLibrary>::@setter::r_topLevelVariable
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_topLevelGetter
      reference: <testLibrary>::@topLevelVariable::r_topLevelGetter
      firstFragment: #F23
      type: int
      getter: <testLibrary>::@getter::r_topLevelGetter
      setter: <testLibrary>::@setter::r_topLevelGetter
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_staticClassVariable
      reference: <testLibrary>::@topLevelVariable::r_staticClassVariable
      firstFragment: #F26
      type: int
      getter: <testLibrary>::@getter::r_staticClassVariable
      setter: <testLibrary>::@setter::r_staticClassVariable
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_staticGetter
      reference: <testLibrary>::@topLevelVariable::r_staticGetter
      firstFragment: #F29
      type: int
      getter: <testLibrary>::@getter::r_staticGetter
      setter: <testLibrary>::@setter::r_staticGetter
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_staticClassMethod
      reference: <testLibrary>::@topLevelVariable::r_staticClassMethod
      firstFragment: #F32
      type: String Function(int)
      getter: <testLibrary>::@getter::r_staticClassMethod
      setter: <testLibrary>::@setter::r_staticClassMethod
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F35
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer r_instanceClassMethod
      reference: <testLibrary>::@topLevelVariable::r_instanceClassMethod
      firstFragment: #F38
      type: String Function(int)
      getter: <testLibrary>::@getter::r_instanceClassMethod
      setter: <testLibrary>::@setter::r_instanceClassMethod
  getters
    isOriginVariable isStatic topLevelVariable
      reference: <testLibrary>::@getter::topLevelVariable
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelVariable
    isOriginDeclaration isStatic topLevelGetter
      reference: <testLibrary>::@getter::topLevelGetter
      firstFragment: #F41
      returnType: int
      variable: <testLibrary>::@topLevelVariable::topLevelGetter
    isOriginVariable isStatic r_topLevelFunction
      reference: <testLibrary>::@getter::r_topLevelFunction
      firstFragment: #F18
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_topLevelFunction
    isOriginVariable isStatic r_topLevelVariable
      reference: <testLibrary>::@getter::r_topLevelVariable
      firstFragment: #F21
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelVariable
    isOriginVariable isStatic r_topLevelGetter
      reference: <testLibrary>::@getter::r_topLevelGetter
      firstFragment: #F24
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_topLevelGetter
    isOriginVariable isStatic r_staticClassVariable
      reference: <testLibrary>::@getter::r_staticClassVariable
      firstFragment: #F27
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticClassVariable
    isOriginVariable isStatic r_staticGetter
      reference: <testLibrary>::@getter::r_staticGetter
      firstFragment: #F30
      returnType: int
      variable: <testLibrary>::@topLevelVariable::r_staticGetter
    isOriginVariable isStatic r_staticClassMethod
      reference: <testLibrary>::@getter::r_staticClassMethod
      firstFragment: #F33
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_staticClassMethod
    isOriginVariable isStatic instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F36
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    isOriginVariable isStatic r_instanceClassMethod
      reference: <testLibrary>::@getter::r_instanceClassMethod
      firstFragment: #F39
      returnType: String Function(int)
      variable: <testLibrary>::@topLevelVariable::r_instanceClassMethod
  setters
    isOriginVariable isStatic topLevelVariable
      reference: <testLibrary>::@setter::topLevelVariable
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F42
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::topLevelVariable
    isOriginVariable isStatic r_topLevelFunction
      reference: <testLibrary>::@setter::r_topLevelFunction
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F43
          type: String Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_topLevelFunction
    isOriginVariable isStatic r_topLevelVariable
      reference: <testLibrary>::@setter::r_topLevelVariable
      firstFragment: #F22
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F44
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_topLevelVariable
    isOriginVariable isStatic r_topLevelGetter
      reference: <testLibrary>::@setter::r_topLevelGetter
      firstFragment: #F25
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F45
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_topLevelGetter
    isOriginVariable isStatic r_staticClassVariable
      reference: <testLibrary>::@setter::r_staticClassVariable
      firstFragment: #F28
      formalParameters
        #E7 requiredPositional value
          firstFragment: #F46
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_staticClassVariable
    isOriginVariable isStatic r_staticGetter
      reference: <testLibrary>::@setter::r_staticGetter
      firstFragment: #F31
      formalParameters
        #E8 requiredPositional value
          firstFragment: #F47
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_staticGetter
    isOriginVariable isStatic r_staticClassMethod
      reference: <testLibrary>::@setter::r_staticClassMethod
      firstFragment: #F34
      formalParameters
        #E9 requiredPositional value
          firstFragment: #F48
          type: String Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_staticClassMethod
    isOriginVariable isStatic instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F37
      formalParameters
        #E10 requiredPositional value
          firstFragment: #F49
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    isOriginVariable isStatic r_instanceClassMethod
      reference: <testLibrary>::@setter::r_instanceClassMethod
      firstFragment: #F40
      formalParameters
        #E11 requiredPositional value
          firstFragment: #F50
          type: String Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::r_instanceClassMethod
  functions
    isOriginDeclaration isStatic topLevelFunction
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
            #F2 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::A::@field::a
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@getter::a
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@setter::a
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::value
        #F7 class B (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::B
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::B::@field::b
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@getter::b
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@setter::b
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
                  element: <testLibrary>::@class::B::@setter::b::@formalParameter::value
      topLevelVariables
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic c (nameOffset:72) (firstTokenOffset:72) (offset:72)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F14
          inducedSetter: #F15
      getters
        #F14 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@getter::c
          inducingVariable: #F13
      setters
        #F15 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@setter::c
          inducingVariable: #F13
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic a
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
          firstFragment: #F5
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        isOriginVariable isStatic a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic b
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
          firstFragment: #F11
      getters
        isOriginVariable isStatic b
          reference: <testLibrary>::@class::B::@getter::b
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::b
      setters
        isOriginVariable isStatic b
          reference: <testLibrary>::@class::B::@setter::b
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::B::@field::b
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F13
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
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
            #F2 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::A::@field::a
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@getter::a
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@setter::a
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic c (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F8 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::b
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::c
          inducingVariable: #F10
      setters
        #F9 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::b
          inducingVariable: #F7
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::b::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::c
          inducingVariable: #F10
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic a
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
          firstFragment: #F5
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
      setters
        isOriginVariable isStatic a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F7
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic b
      reference: <testLibrary>::@setter::b
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F13
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F12
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
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
        #F7 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic d (nameOffset:45) (firstTokenOffset:45) (offset:45)
          element: <testLibrary>::@topLevelVariable::d
          inducedGetter: #F8
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
        #F8 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
          element: <testLibrary>::@getter::d
          inducingVariable: #F7
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::b
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::c
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F7
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic d
      reference: <testLibrary>::@getter::d
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_initializer_identifier_formalParameter() async {
    // TODO(scheglov): I don't understand this yet
  }

  @failingTest
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
        #F3 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F4
          inducedSetter: #F5
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
      setters
        #F5 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::a
          inducingVariable: #F3
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::a::@formalParameter::value
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
  setters
    isOriginVariable isStatic a
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic s (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::s
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic h (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::h
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::s
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::h
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::s
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::s::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::h
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::h::@formalParameter::value
      functions
        #F9 isComplete isOriginDeclaration isStatic f (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@function::f
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F1
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    isOriginVariable isStatic s
      reference: <testLibrary>::@getter::s
      firstFragment: #F2
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    isOriginVariable isStatic h
      reference: <testLibrary>::@getter::h
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    isOriginVariable isStatic s
      reference: <testLibrary>::@setter::s
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
    isOriginVariable isStatic h
      reference: <testLibrary>::@setter::h
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::h
  functions
    isOriginDeclaration isStatic f
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
        #F1 isOriginDeclaration isStatic d (nameOffset:8) (firstTokenOffset:8) (offset:8)
          element: <testLibrary>::@topLevelVariable::d
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic s (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::s
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic h (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::h
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@getter::d
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::s
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::h
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@setter::d
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@setter::d::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::s
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::s::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic h (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::h
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::h::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F4
      type: String
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer h
      reference: <testLibrary>::@topLevelVariable::h
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::h
      setter: <testLibrary>::@setter::h
  getters
    isOriginVariable isStatic d
      reference: <testLibrary>::@getter::d
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
    isOriginVariable isStatic s
      reference: <testLibrary>::@getter::s
      firstFragment: #F5
      returnType: String
      variable: <testLibrary>::@topLevelVariable::s
    isOriginVariable isStatic h
      reference: <testLibrary>::@getter::h
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::h
  setters
    isOriginVariable isStatic d
      reference: <testLibrary>::@setter::d
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
    isOriginVariable isStatic s
      reference: <testLibrary>::@setter::s
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
    isOriginVariable isStatic h
      reference: <testLibrary>::@setter::h
      firstFragment: #F9
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::b
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::b::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: double
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: double
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  @failingTest
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vObject (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vObject
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vNum (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::vNum
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vNumEmpty (nameOffset:64) (firstTokenOffset:64) (offset:64)
          element: <testLibrary>::@topLevelVariable::vNumEmpty
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vInt (nameOffset:89) (firstTokenOffset:89) (offset:89)
          element: <testLibrary>::@topLevelVariable::vInt
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F2 isComplete isOriginVariable isStatic vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vObject
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::vNum
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vNumEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@getter::vNumEmpty
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@getter::vInt
          inducingVariable: #F10
      setters
        #F3 isComplete isOriginVariable isStatic vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vObject
          inducingVariable: #F1
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vObject::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::vNum
          inducingVariable: #F4
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::vNum::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vNumEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@setter::vNumEmpty
          inducingVariable: #F7
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@setter::vNumEmpty::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
          element: <testLibrary>::@setter::vInt
          inducingVariable: #F10
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F1
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNum
      reference: <testLibrary>::@topLevelVariable::vNum
      firstFragment: #F4
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNumEmpty
      reference: <testLibrary>::@topLevelVariable::vNumEmpty
      firstFragment: #F7
      type: List<num>
      getter: <testLibrary>::@getter::vNumEmpty
      setter: <testLibrary>::@setter::vNumEmpty
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F10
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
  getters
    isOriginVariable isStatic vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F2
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
    isOriginVariable isStatic vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F5
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    isOriginVariable isStatic vNumEmpty
      reference: <testLibrary>::@getter::vNumEmpty
      firstFragment: #F8
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNumEmpty
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F11
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
  setters
    isOriginVariable isStatic vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F13
          type: List<Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vObject
    isOriginVariable isStatic vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNum
    isOriginVariable isStatic vNumEmpty
      reference: <testLibrary>::@setter::vNumEmpty
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F15
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumEmpty
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F12
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vNum (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::vNum
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vObject (nameOffset:47) (firstTokenOffset:47) (offset:47)
          element: <testLibrary>::@topLevelVariable::vObject
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::vNum
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@getter::vObject
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vNum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::vNum
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::vNum::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@setter::vObject
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@setter::vObject::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNum
      reference: <testLibrary>::@topLevelVariable::vNum
      firstFragment: #F4
      type: List<num>
      getter: <testLibrary>::@getter::vNum
      setter: <testLibrary>::@setter::vNum
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F7
      type: List<Object>
      getter: <testLibrary>::@getter::vObject
      setter: <testLibrary>::@setter::vObject
  getters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vNum
      reference: <testLibrary>::@getter::vNum
      firstFragment: #F5
      returnType: List<num>
      variable: <testLibrary>::@topLevelVariable::vNum
    isOriginVariable isStatic vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F8
      returnType: List<Object>
      variable: <testLibrary>::@topLevelVariable::vObject
  setters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vNum
      reference: <testLibrary>::@setter::vNum
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: List<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNum
    isOriginVariable isStatic vObject
      reference: <testLibrary>::@setter::vObject
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: List<Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vObject
''');
  }

  @failingTest
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vObjectObject (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vObjectObject
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vComparableObject (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::vComparableObject
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vNumString (nameOffset:109) (firstTokenOffset:109) (offset:109)
          element: <testLibrary>::@topLevelVariable::vNumString
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vNumStringEmpty (nameOffset:149) (firstTokenOffset:149) (offset:149)
          element: <testLibrary>::@topLevelVariable::vNumStringEmpty
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vIntString (nameOffset:188) (firstTokenOffset:188) (offset:188)
          element: <testLibrary>::@topLevelVariable::vIntString
          inducedGetter: #F14
          inducedSetter: #F15
      getters
        #F2 isComplete isOriginVariable isStatic vObjectObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vObjectObject
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vComparableObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::vComparableObject
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@getter::vNumString
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vNumStringEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
          element: <testLibrary>::@getter::vNumStringEmpty
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:188)
          element: <testLibrary>::@getter::vIntString
          inducingVariable: #F13
      setters
        #F3 isComplete isOriginVariable isStatic vObjectObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vObjectObject
          inducingVariable: #F1
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vObjectObject::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vComparableObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::vComparableObject
          inducingVariable: #F4
          formalParameters
            #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::vComparableObject::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@setter::vNumString
          inducingVariable: #F7
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
              element: <testLibrary>::@setter::vNumString::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vNumStringEmpty (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
          element: <testLibrary>::@setter::vNumStringEmpty
          inducingVariable: #F10
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
              element: <testLibrary>::@setter::vNumStringEmpty::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:188)
          element: <testLibrary>::@setter::vIntString
          inducingVariable: #F13
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:188)
              element: <testLibrary>::@setter::vIntString::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vObjectObject
      reference: <testLibrary>::@topLevelVariable::vObjectObject
      firstFragment: #F1
      type: Map<Object, Object>
      getter: <testLibrary>::@getter::vObjectObject
      setter: <testLibrary>::@setter::vObjectObject
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vComparableObject
      reference: <testLibrary>::@topLevelVariable::vComparableObject
      firstFragment: #F4
      type: Map<Comparable<int>, Object>
      getter: <testLibrary>::@getter::vComparableObject
      setter: <testLibrary>::@setter::vComparableObject
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F7
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNumStringEmpty
      reference: <testLibrary>::@topLevelVariable::vNumStringEmpty
      firstFragment: #F10
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumStringEmpty
      setter: <testLibrary>::@setter::vNumStringEmpty
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F13
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
  getters
    isOriginVariable isStatic vObjectObject
      reference: <testLibrary>::@getter::vObjectObject
      firstFragment: #F2
      returnType: Map<Object, Object>
      variable: <testLibrary>::@topLevelVariable::vObjectObject
    isOriginVariable isStatic vComparableObject
      reference: <testLibrary>::@getter::vComparableObject
      firstFragment: #F5
      returnType: Map<Comparable<int>, Object>
      variable: <testLibrary>::@topLevelVariable::vComparableObject
    isOriginVariable isStatic vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F8
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    isOriginVariable isStatic vNumStringEmpty
      reference: <testLibrary>::@getter::vNumStringEmpty
      firstFragment: #F11
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumStringEmpty
    isOriginVariable isStatic vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F14
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
  setters
    isOriginVariable isStatic vObjectObject
      reference: <testLibrary>::@setter::vObjectObject
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F16
          type: Map<Object, Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vObjectObject
    isOriginVariable isStatic vComparableObject
      reference: <testLibrary>::@setter::vComparableObject
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F17
          type: Map<Comparable<int>, Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vComparableObject
    isOriginVariable isStatic vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: Map<num, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumString
    isOriginVariable isStatic vNumStringEmpty
      reference: <testLibrary>::@setter::vNumStringEmpty
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F19
          type: Map<num, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumStringEmpty
    isOriginVariable isStatic vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F15
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vIntString (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vIntString
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vNumString (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::vNumString
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vIntObject (nameOffset:76) (firstTokenOffset:76) (offset:76)
          element: <testLibrary>::@topLevelVariable::vIntObject
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vIntString
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::vNumString
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vIntObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@getter::vIntObject
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic vIntString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vIntString
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vIntString::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vNumString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::vNumString
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::vNumString::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vIntObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@setter::vIntObject
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@setter::vIntObject::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIntString
      reference: <testLibrary>::@topLevelVariable::vIntString
      firstFragment: #F1
      type: Map<int, String>
      getter: <testLibrary>::@getter::vIntString
      setter: <testLibrary>::@setter::vIntString
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNumString
      reference: <testLibrary>::@topLevelVariable::vNumString
      firstFragment: #F4
      type: Map<num, String>
      getter: <testLibrary>::@getter::vNumString
      setter: <testLibrary>::@setter::vNumString
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIntObject
      reference: <testLibrary>::@topLevelVariable::vIntObject
      firstFragment: #F7
      type: Map<int, Object>
      getter: <testLibrary>::@getter::vIntObject
      setter: <testLibrary>::@setter::vIntObject
  getters
    isOriginVariable isStatic vIntString
      reference: <testLibrary>::@getter::vIntString
      firstFragment: #F2
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vIntString
    isOriginVariable isStatic vNumString
      reference: <testLibrary>::@getter::vNumString
      firstFragment: #F5
      returnType: Map<num, String>
      variable: <testLibrary>::@topLevelVariable::vNumString
    isOriginVariable isStatic vIntObject
      reference: <testLibrary>::@getter::vIntObject
      firstFragment: #F8
      returnType: Map<int, Object>
      variable: <testLibrary>::@topLevelVariable::vIntObject
  setters
    isOriginVariable isStatic vIntString
      reference: <testLibrary>::@setter::vIntString
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: Map<int, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIntString
    isOriginVariable isStatic vNumString
      reference: <testLibrary>::@setter::vNumString
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: Map<num, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNumString
    isOriginVariable isStatic vIntObject
      reference: <testLibrary>::@setter::vIntObject
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: Map<int, Object>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIntObject
''');
  }

  @failingTest
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vEq (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::vEq
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vAnd (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::vAnd
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vOr (nameOffset:69) (firstTokenOffset:69) (offset:69)
          element: <testLibrary>::@topLevelVariable::vOr
          inducedGetter: #F14
          inducedSetter: #F15
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::vEq
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::vAnd
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@getter::vOr
          inducingVariable: #F13
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::b
          inducingVariable: #F4
          formalParameters
            #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::b::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::vEq
          inducingVariable: #F7
          formalParameters
            #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::vEq::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::vAnd
          inducingVariable: #F10
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::vAnd::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@setter::vOr
          inducingVariable: #F13
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@setter::vOr::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F7
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vAnd
      reference: <testLibrary>::@topLevelVariable::vAnd
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::vAnd
      setter: <testLibrary>::@setter::vAnd
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vOr
      reference: <testLibrary>::@topLevelVariable::vOr
      firstFragment: #F13
      type: bool
      getter: <testLibrary>::@getter::vOr
      setter: <testLibrary>::@setter::vOr
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    isOriginVariable isStatic vAnd
      reference: <testLibrary>::@getter::vAnd
      firstFragment: #F11
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vAnd
    isOriginVariable isStatic vOr
      reference: <testLibrary>::@getter::vOr
      firstFragment: #F14
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vOr
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F16
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F17
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F18
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vEq
    isOriginVariable isStatic vAnd
      reference: <testLibrary>::@setter::vAnd
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F19
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vAnd
    isOriginVariable isStatic vOr
      reference: <testLibrary>::@setter::vOr
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F20
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vOr
''');
  }

  @failingTest
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration p (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::p
      topLevelVariables
        #F5 hasImplicitType hasInitializer isOriginDeclaration isStatic instanceOfA (nameOffset:43) (firstTokenOffset:43) (offset:43)
          element: <testLibrary>::@topLevelVariable::instanceOfA
          inducedGetter: #F6
          inducedSetter: #F7
        #F8 hasImplicitType hasInitializer isOriginDeclaration isStatic v1 (nameOffset:70) (firstTokenOffset:70) (offset:70)
          element: <testLibrary>::@topLevelVariable::v1
          inducedGetter: #F9
          inducedSetter: #F10
        #F11 hasImplicitType hasInitializer isOriginDeclaration isStatic v2 (nameOffset:96) (firstTokenOffset:96) (offset:96)
          element: <testLibrary>::@topLevelVariable::v2
          inducedGetter: #F12
          inducedSetter: #F13
      getters
        #F6 isComplete isOriginVariable isStatic instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@getter::instanceOfA
          inducingVariable: #F5
        #F9 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@getter::v1
          inducingVariable: #F8
        #F12 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
          element: <testLibrary>::@getter::v2
          inducingVariable: #F11
      setters
        #F7 isComplete isOriginVariable isStatic instanceOfA (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@setter::instanceOfA
          inducingVariable: #F5
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@setter::instanceOfA::@formalParameter::value
        #F10 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
          element: <testLibrary>::@setter::v1
          inducingVariable: #F8
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@setter::v1::@formalParameter::value
        #F13 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
          element: <testLibrary>::@setter::v2
          inducingVariable: #F11
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@setter::v2::@formalParameter::value
  classes
    isSimplyBounded class A
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
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer instanceOfA
      reference: <testLibrary>::@topLevelVariable::instanceOfA
      firstFragment: #F5
      type: A
      getter: <testLibrary>::@getter::instanceOfA
      setter: <testLibrary>::@setter::instanceOfA
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v1
      reference: <testLibrary>::@topLevelVariable::v1
      firstFragment: #F8
      type: String
      getter: <testLibrary>::@getter::v1
      setter: <testLibrary>::@setter::v1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v2
      reference: <testLibrary>::@topLevelVariable::v2
      firstFragment: #F11
      type: String
      getter: <testLibrary>::@getter::v2
      setter: <testLibrary>::@setter::v2
  getters
    isOriginVariable isStatic instanceOfA
      reference: <testLibrary>::@getter::instanceOfA
      firstFragment: #F6
      returnType: A
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    isOriginVariable isStatic v1
      reference: <testLibrary>::@getter::v1
      firstFragment: #F9
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v1
    isOriginVariable isStatic v2
      reference: <testLibrary>::@getter::v2
      firstFragment: #F12
      returnType: String
      variable: <testLibrary>::@topLevelVariable::v2
  setters
    isOriginVariable isStatic instanceOfA
      reference: <testLibrary>::@setter::instanceOfA
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::instanceOfA
    isOriginVariable isStatic v1
      reference: <testLibrary>::@setter::v1
      firstFragment: #F10
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F15
          type: String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v1
    isOriginVariable isStatic v2
      reference: <testLibrary>::@setter::v2
      firstFragment: #F13
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vModuloIntInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vModuloIntInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vModuloIntDouble (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::vModuloIntDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vMultiplyIntInt (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::vMultiplyIntInt
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vMultiplyIntDouble (nameOffset:92) (firstTokenOffset:92) (offset:92)
          element: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vMultiplyDoubleInt (nameOffset:126) (firstTokenOffset:126) (offset:126)
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic vMultiplyDoubleDouble (nameOffset:160) (firstTokenOffset:160) (offset:160)
          element: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
          inducedGetter: #F17
          inducedSetter: #F18
        #F19 hasImplicitType hasInitializer isOriginDeclaration isStatic vDivideIntInt (nameOffset:199) (firstTokenOffset:199) (offset:199)
          element: <testLibrary>::@topLevelVariable::vDivideIntInt
          inducedGetter: #F20
          inducedSetter: #F21
        #F22 hasImplicitType hasInitializer isOriginDeclaration isStatic vDivideIntDouble (nameOffset:226) (firstTokenOffset:226) (offset:226)
          element: <testLibrary>::@topLevelVariable::vDivideIntDouble
          inducedGetter: #F23
          inducedSetter: #F24
        #F25 hasImplicitType hasInitializer isOriginDeclaration isStatic vDivideDoubleInt (nameOffset:258) (firstTokenOffset:258) (offset:258)
          element: <testLibrary>::@topLevelVariable::vDivideDoubleInt
          inducedGetter: #F26
          inducedSetter: #F27
        #F28 hasImplicitType hasInitializer isOriginDeclaration isStatic vDivideDoubleDouble (nameOffset:290) (firstTokenOffset:290) (offset:290)
          element: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
          inducedGetter: #F29
          inducedSetter: #F30
        #F31 hasImplicitType hasInitializer isOriginDeclaration isStatic vFloorDivide (nameOffset:327) (firstTokenOffset:327) (offset:327)
          element: <testLibrary>::@topLevelVariable::vFloorDivide
          inducedGetter: #F32
          inducedSetter: #F33
      getters
        #F2 isComplete isOriginVariable isStatic vModuloIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vModuloIntInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vModuloIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::vModuloIntDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vMultiplyIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::vMultiplyIntInt
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vMultiplyIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
          element: <testLibrary>::@getter::vMultiplyIntDouble
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vMultiplyDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
          element: <testLibrary>::@getter::vMultiplyDoubleInt
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic vMultiplyDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:160)
          element: <testLibrary>::@getter::vMultiplyDoubleDouble
          inducingVariable: #F16
        #F20 isComplete isOriginVariable isStatic vDivideIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:199)
          element: <testLibrary>::@getter::vDivideIntInt
          inducingVariable: #F19
        #F23 isComplete isOriginVariable isStatic vDivideIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:226)
          element: <testLibrary>::@getter::vDivideIntDouble
          inducingVariable: #F22
        #F26 isComplete isOriginVariable isStatic vDivideDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
          element: <testLibrary>::@getter::vDivideDoubleInt
          inducingVariable: #F25
        #F29 isComplete isOriginVariable isStatic vDivideDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:290)
          element: <testLibrary>::@getter::vDivideDoubleDouble
          inducingVariable: #F28
        #F32 isComplete isOriginVariable isStatic vFloorDivide (nameOffset:<null>) (firstTokenOffset:<null>) (offset:327)
          element: <testLibrary>::@getter::vFloorDivide
          inducingVariable: #F31
      setters
        #F3 isComplete isOriginVariable isStatic vModuloIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vModuloIntInt
          inducingVariable: #F1
          formalParameters
            #F34 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vModuloIntInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vModuloIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::vModuloIntDouble
          inducingVariable: #F4
          formalParameters
            #F35 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::vModuloIntDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vMultiplyIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@setter::vMultiplyIntInt
          inducingVariable: #F7
          formalParameters
            #F36 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@setter::vMultiplyIntInt::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vMultiplyIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
          element: <testLibrary>::@setter::vMultiplyIntDouble
          inducingVariable: #F10
          formalParameters
            #F37 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@setter::vMultiplyIntDouble::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vMultiplyDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
          element: <testLibrary>::@setter::vMultiplyDoubleInt
          inducingVariable: #F13
          formalParameters
            #F38 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
              element: <testLibrary>::@setter::vMultiplyDoubleInt::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic vMultiplyDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:160)
          element: <testLibrary>::@setter::vMultiplyDoubleDouble
          inducingVariable: #F16
          formalParameters
            #F39 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:160)
              element: <testLibrary>::@setter::vMultiplyDoubleDouble::@formalParameter::value
        #F21 isComplete isOriginVariable isStatic vDivideIntInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:199)
          element: <testLibrary>::@setter::vDivideIntInt
          inducingVariable: #F19
          formalParameters
            #F40 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:199)
              element: <testLibrary>::@setter::vDivideIntInt::@formalParameter::value
        #F24 isComplete isOriginVariable isStatic vDivideIntDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:226)
          element: <testLibrary>::@setter::vDivideIntDouble
          inducingVariable: #F22
          formalParameters
            #F41 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:226)
              element: <testLibrary>::@setter::vDivideIntDouble::@formalParameter::value
        #F27 isComplete isOriginVariable isStatic vDivideDoubleInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
          element: <testLibrary>::@setter::vDivideDoubleInt
          inducingVariable: #F25
          formalParameters
            #F42 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
              element: <testLibrary>::@setter::vDivideDoubleInt::@formalParameter::value
        #F30 isComplete isOriginVariable isStatic vDivideDoubleDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:290)
          element: <testLibrary>::@setter::vDivideDoubleDouble
          inducingVariable: #F28
          formalParameters
            #F43 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:290)
              element: <testLibrary>::@setter::vDivideDoubleDouble::@formalParameter::value
        #F33 isComplete isOriginVariable isStatic vFloorDivide (nameOffset:<null>) (firstTokenOffset:<null>) (offset:327)
          element: <testLibrary>::@setter::vFloorDivide
          inducingVariable: #F31
          formalParameters
            #F44 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:327)
              element: <testLibrary>::@setter::vFloorDivide::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vModuloIntInt
      reference: <testLibrary>::@topLevelVariable::vModuloIntInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vModuloIntInt
      setter: <testLibrary>::@setter::vModuloIntInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vModuloIntDouble
      reference: <testLibrary>::@topLevelVariable::vModuloIntDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vModuloIntDouble
      setter: <testLibrary>::@setter::vModuloIntDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMultiplyIntInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vMultiplyIntInt
      setter: <testLibrary>::@setter::vMultiplyIntInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMultiplyIntDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::vMultiplyIntDouble
      setter: <testLibrary>::@setter::vMultiplyIntDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMultiplyDoubleInt
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleInt
      setter: <testLibrary>::@setter::vMultiplyDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vMultiplyDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vMultiplyDoubleDouble
      setter: <testLibrary>::@setter::vMultiplyDoubleDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDivideIntInt
      reference: <testLibrary>::@topLevelVariable::vDivideIntInt
      firstFragment: #F19
      type: double
      getter: <testLibrary>::@getter::vDivideIntInt
      setter: <testLibrary>::@setter::vDivideIntInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDivideIntDouble
      reference: <testLibrary>::@topLevelVariable::vDivideIntDouble
      firstFragment: #F22
      type: double
      getter: <testLibrary>::@getter::vDivideIntDouble
      setter: <testLibrary>::@setter::vDivideIntDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDivideDoubleInt
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleInt
      firstFragment: #F25
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleInt
      setter: <testLibrary>::@setter::vDivideDoubleInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDivideDoubleDouble
      reference: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
      firstFragment: #F28
      type: double
      getter: <testLibrary>::@getter::vDivideDoubleDouble
      setter: <testLibrary>::@setter::vDivideDoubleDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vFloorDivide
      reference: <testLibrary>::@topLevelVariable::vFloorDivide
      firstFragment: #F31
      type: int
      getter: <testLibrary>::@getter::vFloorDivide
      setter: <testLibrary>::@setter::vFloorDivide
  getters
    isOriginVariable isStatic vModuloIntInt
      reference: <testLibrary>::@getter::vModuloIntInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vModuloIntInt
    isOriginVariable isStatic vModuloIntDouble
      reference: <testLibrary>::@getter::vModuloIntDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vModuloIntDouble
    isOriginVariable isStatic vMultiplyIntInt
      reference: <testLibrary>::@getter::vMultiplyIntInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntInt
    isOriginVariable isStatic vMultiplyIntDouble
      reference: <testLibrary>::@getter::vMultiplyIntDouble
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
    isOriginVariable isStatic vMultiplyDoubleInt
      reference: <testLibrary>::@getter::vMultiplyDoubleInt
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
    isOriginVariable isStatic vMultiplyDoubleDouble
      reference: <testLibrary>::@getter::vMultiplyDoubleDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
    isOriginVariable isStatic vDivideIntInt
      reference: <testLibrary>::@getter::vDivideIntInt
      firstFragment: #F20
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntInt
    isOriginVariable isStatic vDivideIntDouble
      reference: <testLibrary>::@getter::vDivideIntDouble
      firstFragment: #F23
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideIntDouble
    isOriginVariable isStatic vDivideDoubleInt
      reference: <testLibrary>::@getter::vDivideDoubleInt
      firstFragment: #F26
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleInt
    isOriginVariable isStatic vDivideDoubleDouble
      reference: <testLibrary>::@getter::vDivideDoubleDouble
      firstFragment: #F29
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
    isOriginVariable isStatic vFloorDivide
      reference: <testLibrary>::@getter::vFloorDivide
      firstFragment: #F32
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vFloorDivide
  setters
    isOriginVariable isStatic vModuloIntInt
      reference: <testLibrary>::@setter::vModuloIntInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F34
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vModuloIntInt
    isOriginVariable isStatic vModuloIntDouble
      reference: <testLibrary>::@setter::vModuloIntDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F35
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vModuloIntDouble
    isOriginVariable isStatic vMultiplyIntInt
      reference: <testLibrary>::@setter::vMultiplyIntInt
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F36
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntInt
    isOriginVariable isStatic vMultiplyIntDouble
      reference: <testLibrary>::@setter::vMultiplyIntDouble
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F37
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyIntDouble
    isOriginVariable isStatic vMultiplyDoubleInt
      reference: <testLibrary>::@setter::vMultiplyDoubleInt
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F38
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleInt
    isOriginVariable isStatic vMultiplyDoubleDouble
      reference: <testLibrary>::@setter::vMultiplyDoubleDouble
      firstFragment: #F18
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F39
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vMultiplyDoubleDouble
    isOriginVariable isStatic vDivideIntInt
      reference: <testLibrary>::@setter::vDivideIntInt
      firstFragment: #F21
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F40
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideIntInt
    isOriginVariable isStatic vDivideIntDouble
      reference: <testLibrary>::@setter::vDivideIntDouble
      firstFragment: #F24
      formalParameters
        #E7 requiredPositional value
          firstFragment: #F41
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideIntDouble
    isOriginVariable isStatic vDivideDoubleInt
      reference: <testLibrary>::@setter::vDivideDoubleInt
      firstFragment: #F27
      formalParameters
        #E8 requiredPositional value
          firstFragment: #F42
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleInt
    isOriginVariable isStatic vDivideDoubleDouble
      reference: <testLibrary>::@setter::vDivideDoubleDouble
      firstFragment: #F30
      formalParameters
        #E9 requiredPositional value
          firstFragment: #F43
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDivideDoubleDouble
    isOriginVariable isStatic vFloorDivide
      reference: <testLibrary>::@setter::vFloorDivide
      firstFragment: #F33
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vEq (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::vEq
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vNotEq (nameOffset:46) (firstTokenOffset:46) (offset:46)
          element: <testLibrary>::@topLevelVariable::vNotEq
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::vEq
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@getter::vNotEq
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::vEq
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::vEq::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vNotEq (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@setter::vNotEq
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@setter::vNotEq::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vEq
      reference: <testLibrary>::@topLevelVariable::vEq
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vEq
      setter: <testLibrary>::@setter::vEq
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNotEq
      reference: <testLibrary>::@topLevelVariable::vNotEq
      firstFragment: #F7
      type: bool
      getter: <testLibrary>::@getter::vNotEq
      setter: <testLibrary>::@setter::vNotEq
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic vEq
      reference: <testLibrary>::@getter::vEq
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEq
    isOriginVariable isStatic vNotEq
      reference: <testLibrary>::@getter::vNotEq
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEq
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic vEq
      reference: <testLibrary>::@setter::vEq
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vEq
    isOriginVariable isStatic vNotEq
      reference: <testLibrary>::@setter::vNotEq
      firstFragment: #F9
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    isOriginVariable isStatic V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
  setters
    isOriginVariable isStatic V
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vDouble (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::vDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncInt (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::vIncInt
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecInt (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::vDecInt
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncDouble (nameOffset:81) (firstTokenOffset:81) (offset:81)
          element: <testLibrary>::@topLevelVariable::vIncDouble
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecDouble (nameOffset:109) (firstTokenOffset:109) (offset:109)
          element: <testLibrary>::@topLevelVariable::vDecDouble
          inducedGetter: #F17
          inducedSetter: #F18
      getters
        #F2 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::vDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::vIncInt
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::vDecInt
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@getter::vIncDouble
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@getter::vDecDouble
          inducingVariable: #F16
      setters
        #F3 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          inducingVariable: #F1
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::vDouble
          inducingVariable: #F4
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::vIncInt
          inducingVariable: #F7
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::vDecInt
          inducingVariable: #F10
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::vDecInt::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@setter::vIncDouble
          inducingVariable: #F13
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@setter::vDecDouble
          inducingVariable: #F16
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
              element: <testLibrary>::@setter::vDecDouble::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F21
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F22
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F23
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F18
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vDouble (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::vDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncInt (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::vIncInt
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecInt (nameOffset:66) (firstTokenOffset:66) (offset:66)
          element: <testLibrary>::@topLevelVariable::vDecInt
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncDouble (nameOffset:91) (firstTokenOffset:91) (offset:91)
          element: <testLibrary>::@topLevelVariable::vIncDouble
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecDouble (nameOffset:122) (firstTokenOffset:122) (offset:122)
          element: <testLibrary>::@topLevelVariable::vDecDouble
          inducedGetter: #F17
          inducedSetter: #F18
      getters
        #F2 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::vDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::vIncInt
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@getter::vDecInt
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@getter::vIncDouble
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@getter::vDecDouble
          inducingVariable: #F16
      setters
        #F3 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          inducingVariable: #F1
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::vDouble
          inducingVariable: #F4
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::vIncInt
          inducingVariable: #F7
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@setter::vDecInt
          inducingVariable: #F10
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@setter::vDecInt::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@setter::vIncDouble
          inducingVariable: #F13
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic vDecDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@setter::vDecDouble
          inducingVariable: #F16
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@setter::vDecDouble::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecDouble
      reference: <testLibrary>::@topLevelVariable::vDecDouble
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecDouble
      setter: <testLibrary>::@setter::vDecDouble
  getters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecDouble
      reference: <testLibrary>::@getter::vDecDouble
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecDouble
  setters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: List<double>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F21
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F22
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F23
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecDouble
      reference: <testLibrary>::@setter::vDecDouble
      firstFragment: #F18
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vDouble (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::vDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncInt (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::vIncInt
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecInt (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::vDecInt
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncDouble (nameOffset:81) (firstTokenOffset:81) (offset:81)
          element: <testLibrary>::@topLevelVariable::vIncDouble
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecInt (nameOffset:109) (firstTokenOffset:109) (offset:109)
          element: <testLibrary>::@topLevelVariable::vDecInt#1
          inducedGetter: #F17
          inducedSetter: #F18
      getters
        #F2 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::vDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::vIncInt
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::vDecInt
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@getter::vIncDouble
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@getter::vDecInt#1
          inducingVariable: #F16
      setters
        #F3 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          inducingVariable: #F1
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::vDouble
          inducingVariable: #F4
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::vIncInt
          inducingVariable: #F7
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::vDecInt
          inducingVariable: #F10
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::vDecInt::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
          element: <testLibrary>::@setter::vIncDouble
          inducingVariable: #F13
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
          element: <testLibrary>::@setter::vDecInt#1
          inducingVariable: #F16
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:109)
              element: <testLibrary>::@setter::vDecInt#1::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt#1
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecInt#1
      setter: <testLibrary>::@setter::vDecInt#1
  getters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@getter::vDecInt#1
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt#1
  setters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F21
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F22
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F23
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@setter::vDecInt#1
      firstFragment: #F18
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt#1
''');
  }

  @failingTest
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vDouble (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::vDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncInt (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::vIncInt
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecInt (nameOffset:66) (firstTokenOffset:66) (offset:66)
          element: <testLibrary>::@topLevelVariable::vDecInt
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 hasImplicitType hasInitializer isOriginDeclaration isStatic vIncDouble (nameOffset:91) (firstTokenOffset:91) (offset:91)
          element: <testLibrary>::@topLevelVariable::vIncDouble
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 hasImplicitType hasInitializer isOriginDeclaration isStatic vDecInt (nameOffset:122) (firstTokenOffset:122) (offset:122)
          element: <testLibrary>::@topLevelVariable::vDecInt#1
          inducedGetter: #F17
          inducedSetter: #F18
      getters
        #F2 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::vDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::vIncInt
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@getter::vDecInt
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@getter::vIncDouble
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@getter::vDecInt#1
          inducingVariable: #F16
      setters
        #F3 isComplete isOriginVariable isStatic vInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vInt
          inducingVariable: #F1
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::vDouble
          inducingVariable: #F4
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::vDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vIncInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::vIncInt
          inducingVariable: #F7
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::vIncInt::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
          element: <testLibrary>::@setter::vDecInt
          inducingVariable: #F10
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@setter::vDecInt::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic vIncDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@setter::vIncDouble
          inducingVariable: #F13
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@setter::vIncDouble::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic vDecInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@setter::vDecInt#1
          inducingVariable: #F16
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@setter::vDecInt#1::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vInt
      reference: <testLibrary>::@topLevelVariable::vInt
      firstFragment: #F1
      type: List<int>
      getter: <testLibrary>::@getter::vInt
      setter: <testLibrary>::@setter::vInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F4
      type: List<double>
      getter: <testLibrary>::@getter::vDouble
      setter: <testLibrary>::@setter::vDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncInt
      reference: <testLibrary>::@topLevelVariable::vIncInt
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vIncInt
      setter: <testLibrary>::@setter::vIncInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::vDecInt
      setter: <testLibrary>::@setter::vDecInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vIncDouble
      reference: <testLibrary>::@topLevelVariable::vIncDouble
      firstFragment: #F13
      type: double
      getter: <testLibrary>::@getter::vIncDouble
      setter: <testLibrary>::@setter::vIncDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vDecInt
      reference: <testLibrary>::@topLevelVariable::vDecInt#1
      firstFragment: #F16
      type: double
      getter: <testLibrary>::@getter::vDecInt#1
      setter: <testLibrary>::@setter::vDecInt#1
  getters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@getter::vInt
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F5
      returnType: List<double>
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@getter::vIncInt
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@getter::vDecInt
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@getter::vIncDouble
      firstFragment: #F14
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@getter::vDecInt#1
      firstFragment: #F17
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDecInt#1
  setters
    isOriginVariable isStatic vInt
      reference: <testLibrary>::@setter::vInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vInt
    isOriginVariable isStatic vDouble
      reference: <testLibrary>::@setter::vDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: List<double>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDouble
    isOriginVariable isStatic vIncInt
      reference: <testLibrary>::@setter::vIncInt
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F21
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncInt
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@setter::vDecInt
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F22
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt
    isOriginVariable isStatic vIncDouble
      reference: <testLibrary>::@setter::vIncDouble
      firstFragment: #F15
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F23
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vIncDouble
    isOriginVariable isStatic vDecInt
      reference: <testLibrary>::@setter::vDecInt#1
      firstFragment: #F18
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F24
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vDecInt#1
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vNot (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vNot
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic vNot (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vNot
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic vNot (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vNot
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vNot::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNot
      reference: <testLibrary>::@topLevelVariable::vNot
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vNot
      setter: <testLibrary>::@setter::vNot
  getters
    isOriginVariable isStatic vNot
      reference: <testLibrary>::@getter::vNot
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNot
  setters
    isOriginVariable isStatic vNot
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vNegateInt (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vNegateInt
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vNegateDouble (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::vNegateDouble
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vComplement (nameOffset:51) (firstTokenOffset:51) (offset:51)
          element: <testLibrary>::@topLevelVariable::vComplement
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic vNegateInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vNegateInt
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vNegateDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::vNegateDouble
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vComplement (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@getter::vComplement
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic vNegateInt (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vNegateInt
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vNegateInt::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vNegateDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::vNegateDouble
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::vNegateDouble::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vComplement (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@setter::vComplement
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@setter::vComplement::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNegateInt
      reference: <testLibrary>::@topLevelVariable::vNegateInt
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::vNegateInt
      setter: <testLibrary>::@setter::vNegateInt
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vNegateDouble
      reference: <testLibrary>::@topLevelVariable::vNegateDouble
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::vNegateDouble
      setter: <testLibrary>::@setter::vNegateDouble
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vComplement
      reference: <testLibrary>::@topLevelVariable::vComplement
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::vComplement
      setter: <testLibrary>::@setter::vComplement
  getters
    isOriginVariable isStatic vNegateInt
      reference: <testLibrary>::@getter::vNegateInt
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vNegateInt
    isOriginVariable isStatic vNegateDouble
      reference: <testLibrary>::@getter::vNegateDouble
      firstFragment: #F5
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vNegateDouble
    isOriginVariable isStatic vComplement
      reference: <testLibrary>::@getter::vComplement
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vComplement
  setters
    isOriginVariable isStatic vNegateInt
      reference: <testLibrary>::@setter::vNegateInt
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNegateInt
    isOriginVariable isStatic vNegateDouble
      reference: <testLibrary>::@setter::vNegateDouble
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vNegateDouble
    isOriginVariable isStatic vComplement
      reference: <testLibrary>::@setter::vComplement
      firstFragment: #F9
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
            #F2 isOriginDeclaration isStatic d (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::d
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::d
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@setter::d
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: <testLibrary>::@class::C::@setter::d::@formalParameter::value
        #F7 class D (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::D
          fields
            #F8 isOriginDeclaration i (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@class::D::@field::i
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F9 isComplete isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::D::@getter::i
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::D::@setter::i
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::value
      topLevelVariables
        #F13 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic x (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F14
      getters
        #F14 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::x
          inducingVariable: #F13
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginDeclaration isStatic d
          reference: <testLibrary>::@class::C::@field::d
          firstFragment: #F2
          type: D
          getter: <testLibrary>::@class::C::@getter::d
          setter: <testLibrary>::@class::C::@setter::d
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable isStatic d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F3
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
      setters
        isOriginVariable isStatic d
          reference: <testLibrary>::@class::C::@setter::d
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: D
          returnType: void
          variable: <testLibrary>::@class::C::@field::d
    hasNonFinalField isSimplyBounded class D
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
          firstFragment: #F11
      getters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::D::@field::i
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::x
  getters
    isOriginVariable isStatic x
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
            #F2 isOriginGetterSetter isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::d
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isComplete isOriginDeclaration isStatic d (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::C::@getter::d
        #F5 class D (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::D
          fields
            #F6 isOriginDeclaration i (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@class::D::@field::i
              inducedGetter: #F7
              inducedSetter: #F8
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F7 isComplete isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@getter::i
              inducingVariable: #F6
          setters
            #F8 isComplete isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@setter::i
              inducingVariable: #F6
              formalParameters
                #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
                  element: <testLibrary>::@class::D::@setter::i::@formalParameter::value
      topLevelVariables
        #F11 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F12
          inducedSetter: #F13
      getters
        #F12 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::x
          inducingVariable: #F11
      setters
        #F13 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@setter::x
          inducingVariable: #F11
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginGetterSetter isStatic d
          reference: <testLibrary>::@class::C::@field::d
          firstFragment: #F2
          type: D
          getter: <testLibrary>::@class::C::@getter::d
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginDeclaration isStatic d
          reference: <testLibrary>::@class::C::@getter::d
          firstFragment: #F4
          returnType: D
          variable: <testLibrary>::@class::C::@field::d
    hasNonFinalField isSimplyBounded class D
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
          firstFragment: #F9
      getters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@getter::i
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::D::@field::i
      setters
        isOriginVariable i
          reference: <testLibrary>::@class::D::@setter::i
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::D::@field::i
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F11
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
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
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic vLess (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::vLess
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic vLessOrEqual (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::vLessOrEqual
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic vGreater (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::vGreater
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic vGreaterOrEqual (nameOffset:72) (firstTokenOffset:72) (offset:72)
          element: <testLibrary>::@topLevelVariable::vGreaterOrEqual
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F2 isComplete isOriginVariable isStatic vLess (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::vLess
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic vLessOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::vLessOrEqual
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic vGreater (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::vGreater
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic vGreaterOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@getter::vGreaterOrEqual
          inducingVariable: #F10
      setters
        #F3 isComplete isOriginVariable isStatic vLess (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::vLess
          inducingVariable: #F1
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::vLess::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic vLessOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::vLessOrEqual
          inducingVariable: #F4
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::vLessOrEqual::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic vGreater (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::vGreater
          inducingVariable: #F7
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::vGreater::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic vGreaterOrEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@setter::vGreaterOrEqual
          inducingVariable: #F10
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@setter::vGreaterOrEqual::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vLess
      reference: <testLibrary>::@topLevelVariable::vLess
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::vLess
      setter: <testLibrary>::@setter::vLess
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vLessOrEqual
      reference: <testLibrary>::@topLevelVariable::vLessOrEqual
      firstFragment: #F4
      type: bool
      getter: <testLibrary>::@getter::vLessOrEqual
      setter: <testLibrary>::@setter::vLessOrEqual
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vGreater
      reference: <testLibrary>::@topLevelVariable::vGreater
      firstFragment: #F7
      type: bool
      getter: <testLibrary>::@getter::vGreater
      setter: <testLibrary>::@setter::vGreater
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer vGreaterOrEqual
      reference: <testLibrary>::@topLevelVariable::vGreaterOrEqual
      firstFragment: #F10
      type: bool
      getter: <testLibrary>::@getter::vGreaterOrEqual
      setter: <testLibrary>::@setter::vGreaterOrEqual
  getters
    isOriginVariable isStatic vLess
      reference: <testLibrary>::@getter::vLess
      firstFragment: #F2
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLess
    isOriginVariable isStatic vLessOrEqual
      reference: <testLibrary>::@getter::vLessOrEqual
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLessOrEqual
    isOriginVariable isStatic vGreater
      reference: <testLibrary>::@getter::vGreater
      firstFragment: #F8
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreater
    isOriginVariable isStatic vGreaterOrEqual
      reference: <testLibrary>::@getter::vGreaterOrEqual
      firstFragment: #F11
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreaterOrEqual
  setters
    isOriginVariable isStatic vLess
      reference: <testLibrary>::@setter::vLess
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F13
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vLess
    isOriginVariable isStatic vLessOrEqual
      reference: <testLibrary>::@setter::vLessOrEqual
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vLessOrEqual
    isOriginVariable isStatic vGreater
      reference: <testLibrary>::@setter::vGreater
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F15
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vGreater
    isOriginVariable isStatic vGreaterOrEqual
      reference: <testLibrary>::@setter::vGreaterOrEqual
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F16
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::vGreaterOrEqual
''');
  }

  @failingTest
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              inducingVariable: #F2
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
            #F10 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:59) (firstTokenOffset:55) (offset:59)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F11 requiredPositional hasImplicitType isOriginDeclaration <null-name> (nameOffset:<null>) (firstTokenOffset:61) (offset:61)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::<null-name>
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    isSimplyBounded class B
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
            #F2 hasImplicitType hasInitializer isOriginDeclaration f (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::f
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 25
              formalParameters
                #F6 optionalPositional hasImplicitType isFinal isOriginDeclaration this.f (nameOffset:33) (firstTokenOffset:28) (offset:33)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
                  initializer: expression_0
                    SimpleStringLiteral
                      literal: 'hello' @37
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::f
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::f
              inducingVariable: #F2
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 optionalPositional hasDefaultValue hasImplicitType isFinal this.f
              firstFragment: #F6
              type: int
              constantInitializer
                fragment: #F6
                expression: expression_0
              field: <testLibrary>::@class::A::@field::f
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F4
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
            #F5 isOriginDeclaration y (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@class::A::@field::y
              inducedGetter: #F6
              inducedSetter: #F7
            #F8 isOriginDeclaration z (nameOffset:43) (firstTokenOffset:43) (offset:43)
              element: <testLibrary>::@class::A::@field::z
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
            #F6 isComplete isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@getter::y
              inducingVariable: #F5
            #F9 isComplete isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::A::@getter::z
              inducingVariable: #F8
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              inducingVariable: #F2
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
            #F7 isComplete isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@setter::y
              inducingVariable: #F5
              formalParameters
                #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::value
            #F10 isComplete isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::A::@setter::z
              inducingVariable: #F8
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::value
        #F15 class B (nameOffset:54) (firstTokenOffset:48) (offset:54)
          element: <testLibrary>::@class::B
          fields
            #F16 hasImplicitType isOriginDeclaration x (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F17
              inducedSetter: #F18
            #F19 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@field::y
            #F20 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F21 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F17 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F16
            #F22 hasImplicitReturnType isComplete isOriginDeclaration y (nameOffset:86) (firstTokenOffset:82) (offset:86)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F18 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F16
              formalParameters
                #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F24 hasImplicitReturnType isComplete isOriginDeclaration z (nameOffset:103) (firstTokenOffset:99) (offset:103)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F25 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:105) (firstTokenOffset:105) (offset:105)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
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
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        isOriginDeclaration z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F11
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        isOriginVariable z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::y
        isOriginVariable z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F10
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F20
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F21
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F22
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F18
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::A::@setter::x
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::B
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration x (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F11
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::foo
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::foo
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@setter::foo
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F7 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          fields
            #F8 isFinal isOriginDeclaration foo (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: <testLibrary>::@class::B::@field::foo
              inducedGetter: #F9
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@class::B::@getter::foo
              inducingVariable: #F8
          setters
            #F11 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:79) (firstTokenOffset:75) (offset:79)
              element: <testLibrary>::@class::B::@setter::foo
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:83) (firstTokenOffset:83) (offset:83)
                  element: <testLibrary>::@class::B::@setter::foo::@formalParameter::_
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@class::A::@field::foo
      setters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int?
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      interfaces
        A
      fields
        isFinal isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@field::foo
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::B::@getter::foo
          setter: <testLibrary>::@class::B::@setter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::B::@getter::foo
          firstFragment: #F9
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 E (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 E
          fields
            #F3 isOriginDeclaration x (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F4
              inducedSetter: #F5
            #F6 isOriginDeclaration y (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::A::@field::y
              inducedGetter: #F7
              inducedSetter: #F8
            #F9 isOriginDeclaration z (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@class::A::@field::z
              inducedGetter: #F10
              inducedSetter: #F11
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F3
            #F7 isComplete isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::A::@getter::y
              inducingVariable: #F6
            #F10 isComplete isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::A::@getter::z
              inducingVariable: #F9
          setters
            #F5 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@setter::x
              inducingVariable: #F3
              formalParameters
                #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
            #F8 isComplete isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::A::@setter::y
              inducingVariable: #F6
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::value
            #F11 isComplete isOriginVariable z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::A::@setter::z
              inducingVariable: #F9
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::value
        #F16 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          typeParameters
            #F17 T (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: #E1 T
          fields
            #F18 hasImplicitType isOriginDeclaration x (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F19
              inducedSetter: #F20
            #F21 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@field::y
            #F22 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F23 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F19 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F18
            #F24 hasImplicitReturnType isComplete isOriginDeclaration y (nameOffset:89) (firstTokenOffset:85) (offset:89)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F20 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F18
              formalParameters
                #F25 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F26 hasImplicitReturnType isComplete isOriginDeclaration z (nameOffset:106) (firstTokenOffset:102) (offset:106)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F27 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:108) (firstTokenOffset:108) (offset:108)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginDeclaration x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          type: E
          getter: <testLibrary>::@class::A::@getter::x
          setter: <testLibrary>::@class::A::@setter::x
        hasEnclosingTypeParameterReference isOriginDeclaration y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F6
          type: E
          getter: <testLibrary>::@class::A::@getter::y
          setter: <testLibrary>::@class::A::@setter::y
        hasEnclosingTypeParameterReference isOriginDeclaration z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F9
          type: E
          getter: <testLibrary>::@class::A::@getter::z
          setter: <testLibrary>::@class::A::@setter::z
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F12
      getters
        hasEnclosingTypeParameterReference isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        hasEnclosingTypeParameterReference isOriginVariable y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        hasEnclosingTypeParameterReference isOriginVariable z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F10
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
      setters
        hasEnclosingTypeParameterReference isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F13
              type: E
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
        hasEnclosingTypeParameterReference isOriginVariable y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F8
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F14
              type: E
          returnType: void
          variable: <testLibrary>::@class::A::@field::y
        hasEnclosingTypeParameterReference isOriginVariable z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F11
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F15
              type: E
          returnType: void
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F16
      typeParameters
        #E1 T
          firstFragment: #F17
      interfaces
        A<T>
      fields
        hasEnclosingTypeParameterReference hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F18
          type: T
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        hasEnclosingTypeParameterReference isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F21
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        hasEnclosingTypeParameterReference isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F22
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F23
      getters
        hasEnclosingTypeParameterReference isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F19
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        hasEnclosingTypeParameterReference isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F24
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        hasEnclosingTypeParameterReference isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F20
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F25
              type: T
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        hasEnclosingTypeParameterReference isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F26
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 hasImplicitType isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration x (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F11
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@setter::x
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::value
        #F7 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration x (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isAbstract isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F11
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: num
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F6 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
            #F7 isAbstract isOriginDeclaration y (nameOffset:42) (firstTokenOffset:34) (offset:42)
              element: <testLibrary>::@class::A::@getter::y
            #F8 isAbstract isOriginDeclaration z (nameOffset:55) (firstTokenOffset:47) (offset:55)
              element: <testLibrary>::@class::A::@getter::z
        #F9 class B (nameOffset:66) (firstTokenOffset:60) (offset:66)
          element: <testLibrary>::@class::B
          fields
            #F10 hasImplicitType isOriginDeclaration x (nameOffset:89) (firstTokenOffset:89) (offset:89)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F11
              inducedSetter: #F12
            #F13 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@field::y
            #F14 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F15 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F11 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F10
            #F16 hasImplicitReturnType isComplete isOriginDeclaration y (nameOffset:98) (firstTokenOffset:94) (offset:98)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F12 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F10
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F18 hasImplicitReturnType isComplete isOriginDeclaration z (nameOffset:115) (firstTokenOffset:111) (offset:115)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F19 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:117) (firstTokenOffset:117) (offset:117)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
        isOriginDeclaration z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F14
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F15
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F16
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F12
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F7 isAbstract isOriginDeclaration x (nameOffset:30) (firstTokenOffset:24) (offset:30)
              element: <testLibrary>::@class::A::@getter::x
            #F8 isAbstract isOriginDeclaration y (nameOffset:41) (firstTokenOffset:35) (offset:41)
              element: <testLibrary>::@class::A::@getter::y
            #F9 isAbstract isOriginDeclaration z (nameOffset:52) (firstTokenOffset:46) (offset:52)
              element: <testLibrary>::@class::A::@getter::z
        #F10 class B (nameOffset:63) (firstTokenOffset:57) (offset:63)
          element: <testLibrary>::@class::B
          typeParameters
            #F11 T (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: #E1 T
          fields
            #F12 hasImplicitType isOriginDeclaration x (nameOffset:92) (firstTokenOffset:92) (offset:92)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F13
              inducedSetter: #F14
            #F15 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@field::y
            #F16 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F17 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F13 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F12
            #F18 hasImplicitReturnType isComplete isOriginDeclaration y (nameOffset:101) (firstTokenOffset:97) (offset:101)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F14 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F12
              formalParameters
                #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F20 hasImplicitReturnType isComplete isOriginDeclaration z (nameOffset:118) (firstTokenOffset:114) (offset:118)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F21 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:120) (firstTokenOffset:120) (offset:120)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          type: E
          getter: <testLibrary>::@class::A::@getter::x
        hasEnclosingTypeParameterReference isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          type: E
          getter: <testLibrary>::@class::A::@getter::y
        hasEnclosingTypeParameterReference isOriginGetterSetter z
          reference: <testLibrary>::@class::A::@field::z
          firstFragment: #F5
          type: E
          getter: <testLibrary>::@class::A::@getter::z
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        hasEnclosingTypeParameterReference isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@class::A::@field::x
        hasEnclosingTypeParameterReference isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@class::A::@field::y
        hasEnclosingTypeParameterReference isOriginDeclaration z
          reference: <testLibrary>::@class::A::@getter::z
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      interfaces
        A<T>
      fields
        hasEnclosingTypeParameterReference hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F12
          type: T
          getter: <testLibrary>::@class::B::@getter::x
          setter: <testLibrary>::@class::B::@setter::x
        hasEnclosingTypeParameterReference isOriginGetterSetter y
          reference: <testLibrary>::@class::B::@field::y
          firstFragment: #F15
          type: T
          getter: <testLibrary>::@class::B::@getter::y
        hasEnclosingTypeParameterReference isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F16
          type: T
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F17
      getters
        hasEnclosingTypeParameterReference isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F13
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
        hasEnclosingTypeParameterReference isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F18
          returnType: T
          variable: <testLibrary>::@class::B::@field::y
      setters
        hasEnclosingTypeParameterReference isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F14
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F19
              type: T
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        hasEnclosingTypeParameterReference isOriginDeclaration z
          reference: <testLibrary>::@class::B::@setter::z
          firstFragment: #F20
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F3 isAbstract isOriginDeclaration foo (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::foo
        #F4 class B (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::B
          fields
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::B::@field::foo
          getters
            #F6 isComplete isOriginDeclaration foo (nameOffset:69) (firstTokenOffset:61) (offset:69)
              element: <testLibrary>::@class::B::@getter::foo
          setters
            #F7 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:85) (firstTokenOffset:81) (offset:85)
              element: <testLibrary>::@class::B::@setter::foo
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration value (nameOffset:89) (firstTokenOffset:89) (offset:89)
                  element: <testLibrary>::@class::B::@setter::foo::@formalParameter::value
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::A::@getter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@class::A::@field::foo
    isSimplyBounded class B
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 isAbstract isOriginDeclaration x (nameOffset:66) (firstTokenOffset:55) (offset:66)
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
            #F12 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:103) (firstTokenOffset:99) (offset:103)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F8
          returnType: String
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 isAbstract isOriginDeclaration x (nameOffset:67) (firstTokenOffset:55) (offset:67)
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
            #F12 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:104) (firstTokenOffset:100) (offset:104)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F8
          returnType: dynamic
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F5 isAbstract isOriginDeclaration x (nameOffset:30) (firstTokenOffset:24) (offset:30)
              element: <testLibrary>::@class::A::@getter::x
        #F6 isAbstract class B (nameOffset:50) (firstTokenOffset:35) (offset:50)
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
            #F10 isAbstract isOriginDeclaration x (nameOffset:65) (firstTokenOffset:59) (offset:65)
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
            #F14 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:115) (firstTokenOffset:111) (offset:115)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          type: T
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        hasEnclosingTypeParameterReference isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F5
          returnType: T
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
      fields
        hasEnclosingTypeParameterReference isOriginGetterSetter x
          reference: <testLibrary>::@class::B::@field::x
          firstFragment: #F8
          type: T
          getter: <testLibrary>::@class::B::@getter::x
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        hasEnclosingTypeParameterReference isOriginDeclaration x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F10
          returnType: T
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 isAbstract isOriginDeclaration x (nameOffset:63) (firstTokenOffset:55) (offset:63)
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
            #F12 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:100) (firstTokenOffset:96) (offset:100)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F5 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
            #F6 isAbstract isOriginDeclaration y (nameOffset:42) (firstTokenOffset:34) (offset:42)
              element: <testLibrary>::@class::A::@getter::y
        #F7 isAbstract class B (nameOffset:62) (firstTokenOffset:47) (offset:62)
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
            #F11 isAbstract isOriginDeclaration x (nameOffset:77) (firstTokenOffset:68) (offset:77)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F12 requiredPositional isOriginDeclaration _ (nameOffset:86) (firstTokenOffset:79) (offset:86)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
            #F13 isAbstract isOriginDeclaration y (nameOffset:101) (firstTokenOffset:92) (offset:101)
              element: <testLibrary>::@class::B::@setter::y
              formalParameters
                #F14 requiredPositional isOriginDeclaration _ (nameOffset:110) (firstTokenOffset:103) (offset:110)
                  element: <testLibrary>::@class::B::@setter::y::@formalParameter::_
        #F15 class C (nameOffset:122) (firstTokenOffset:116) (offset:122)
          element: <testLibrary>::@class::C
          fields
            #F16 hasImplicitType isOriginDeclaration x (nameOffset:148) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@class::C::@field::x
              inducedGetter: #F17
              inducedSetter: #F18
            #F19 hasImplicitType isFinal isOriginDeclaration y (nameOffset:159) (firstTokenOffset:159) (offset:159)
              element: <testLibrary>::@class::C::@field::y
              inducedGetter: #F20
          constructors
            #F21 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F17 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F16
            #F20 isComplete isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:159)
              element: <testLibrary>::@class::C::@getter::y
              inducingVariable: #F19
          setters
            #F18 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@class::C::@setter::x
              inducingVariable: #F16
              formalParameters
                #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::y
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F11
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F12
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@setter::y
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F14
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::y
    hasNonFinalField isSimplyBounded class C
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
        hasImplicitType isFinal isOriginDeclaration y
          reference: <testLibrary>::@class::C::@field::y
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@class::C::@getter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F21
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F17
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
          firstFragment: #F18
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isAbstract isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:73) (firstTokenOffset:66) (offset:73)
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
            #F13 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:111) (firstTokenOffset:107) (offset:111)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isAbstract isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:73) (firstTokenOffset:66) (offset:73)
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
            #F13 hasImplicitReturnType isAbstract isOriginDeclaration x (nameOffset:111) (firstTokenOffset:107) (offset:111)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F14 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:113) (firstTokenOffset:113) (offset:113)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        isOriginDeclaration x
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isAbstract isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:70) (firstTokenOffset:66) (offset:70)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
        #F10 class C (nameOffset:82) (firstTokenOffset:76) (offset:82)
          element: <testLibrary>::@class::C
          fields
            #F11 hasImplicitType isOriginDeclaration x (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@class::C::@field::x
              inducedGetter: #F12
              inducedSetter: #F13
          constructors
            #F14 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F12 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F11
          setters
            #F13 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::C::@setter::x
              inducingVariable: #F11
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    hasNonFinalField isSimplyBounded class C
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
          firstFragment: #F14
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F13
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isAbstract isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:70) (firstTokenOffset:66) (offset:70)
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
            #F13 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:108) (firstTokenOffset:104) (offset:108)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
        #F5 isAbstract class B (nameOffset:49) (firstTokenOffset:34) (offset:49)
          element: <testLibrary>::@class::B
          fields
            #F6 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F8 isAbstract isOriginDeclaration x (nameOffset:64) (firstTokenOffset:55) (offset:64)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:70) (firstTokenOffset:66) (offset:70)
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
            #F13 hasImplicitReturnType isAbstract isOriginDeclaration x (nameOffset:108) (firstTokenOffset:104) (offset:108)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F14 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:110) (firstTokenOffset:110) (offset:110)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        isOriginDeclaration x
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F6 isAbstract isOriginDeclaration x (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F7 requiredPositional isOriginDeclaration _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
            #F8 isAbstract isOriginDeclaration y (nameOffset:51) (firstTokenOffset:42) (offset:51)
              element: <testLibrary>::@class::A::@setter::y
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:57) (firstTokenOffset:53) (offset:57)
                  element: <testLibrary>::@class::A::@setter::y::@formalParameter::_
            #F10 isAbstract isOriginDeclaration z (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::A::@setter::z
              formalParameters
                #F11 requiredPositional isOriginDeclaration _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@class::A::@setter::z::@formalParameter::_
        #F12 class B (nameOffset:90) (firstTokenOffset:84) (offset:90)
          element: <testLibrary>::@class::B
          fields
            #F13 hasImplicitType isOriginDeclaration x (nameOffset:113) (firstTokenOffset:113) (offset:113)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F14
              inducedSetter: #F15
            #F16 isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::B::@field::y
            #F17 isOriginGetterSetter z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::B::@field::z
          constructors
            #F18 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F14 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F13
            #F19 hasImplicitReturnType isComplete isOriginDeclaration y (nameOffset:122) (firstTokenOffset:118) (offset:122)
              element: <testLibrary>::@class::B::@getter::y
          setters
            #F15 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F13
              formalParameters
                #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
            #F21 hasImplicitReturnType isComplete isOriginDeclaration z (nameOffset:139) (firstTokenOffset:135) (offset:139)
              element: <testLibrary>::@class::B::@setter::z
              formalParameters
                #F22 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:141) (firstTokenOffset:141) (offset:141)
                  element: <testLibrary>::@class::B::@setter::z::@formalParameter::_
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::A::@setter::y
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::y
        isOriginDeclaration z
          reference: <testLibrary>::@class::A::@setter::z
          firstFragment: #F10
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::z
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F16
          type: int
          getter: <testLibrary>::@class::B::@getter::y
        isOriginGetterSetter z
          reference: <testLibrary>::@class::B::@field::z
          firstFragment: #F17
          type: int
          setter: <testLibrary>::@class::B::@setter::z
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F18
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
        isOriginDeclaration y
          reference: <testLibrary>::@class::B::@getter::y
          firstFragment: #F19
          returnType: int
          variable: <testLibrary>::@class::B::@field::y
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F15
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 isAbstract isOriginDeclaration x (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 requiredPositional isOriginDeclaration _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 isAbstract class B (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::B
          fields
            #F7 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 isAbstract isOriginDeclaration x (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 requiredPositional isOriginDeclaration _ (nameOffset:81) (firstTokenOffset:74) (offset:81)
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
            #F14 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:119) (firstTokenOffset:115) (offset:119)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F10
              type: String
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 isAbstract isOriginDeclaration x (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F5 requiredPositional isOriginDeclaration _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F6 isAbstract class B (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::B
          fields
            #F7 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@field::x
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          setters
            #F9 isAbstract isOriginDeclaration x (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F10 requiredPositional isOriginDeclaration _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
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
            #F14 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:116) (firstTokenOffset:112) (offset:116)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    isAbstract isSimplyBounded class B
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::x
    isSimplyBounded class C
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
            #F6 isComplete isOriginDeclaration x (nameOffset:41) (firstTokenOffset:32) (offset:41)
              element: <testLibrary>::@class::A::@getter::x
            #F7 isComplete isOriginDeclaration y (nameOffset:69) (firstTokenOffset:54) (offset:69)
              element: <testLibrary>::@class::A::@getter::y
        #F8 hasExtendsClause class B (nameOffset:89) (firstTokenOffset:83) (offset:89)
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
            #F12 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:114) (firstTokenOffset:110) (offset:114)
              element: <testLibrary>::@class::B::@getter::x
            #F13 hasImplicitReturnType isComplete isOriginDeclaration y (nameOffset:131) (firstTokenOffset:127) (offset:131)
              element: <testLibrary>::@class::B::@getter::y
      typeAliases
        #F14 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F15 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 T
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginGetterSetter x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F3
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          getter: <testLibrary>::@class::A::@getter::x
        hasEnclosingTypeParameterReference isOriginGetterSetter y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        hasEnclosingTypeParameterReference isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F6
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                T
          variable: <testLibrary>::@class::A::@field::x
        hasEnclosingTypeParameterReference isOriginDeclaration y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F7
          returnType: List<dynamic Function()>
          variable: <testLibrary>::@class::A::@field::y
    isSimplyBounded class B
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
          superConstructor: SubstitutedConstructorElementImpl
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
    isSimplyBounded F
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isAbstract isOriginDeclaration x (nameOffset:43) (firstTokenOffset:34) (offset:43)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional isExplicitlyCovariant isOriginDeclaration _ (nameOffset:59) (firstTokenOffset:45) (offset:59)
                  element: <testLibrary>::@class::A::@setter::x::@formalParameter::_
        #F7 class B (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginDeclaration x (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::B::@field::x
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::B::@getter::x
              inducingVariable: #F8
          setters
            #F10 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::B::@setter::x
              inducingVariable: #F8
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::value
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional isCovariant _
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    hasNonFinalField isSimplyBounded class B
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
          firstFragment: #F11
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@getter::x
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::B::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::B::@setter::x
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional isCovariant value
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isAbstract isOriginDeclaration x (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::x
          setters
            #F5 isAbstract isOriginDeclaration x (nameOffset:43) (firstTokenOffset:34) (offset:43)
              element: <testLibrary>::@class::A::@setter::x
              formalParameters
                #F6 requiredPositional isExplicitlyCovariant isOriginDeclaration _ (nameOffset:59) (firstTokenOffset:45) (offset:59)
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
            #F10 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:94) (firstTokenOffset:90) (offset:94)
              element: <testLibrary>::@class::B::@setter::x
              formalParameters
                #F11 requiredPositional isOriginDeclaration _ (nameOffset:100) (firstTokenOffset:96) (offset:100)
                  element: <testLibrary>::@class::B::@setter::x::@formalParameter::_
  classes
    isAbstract isSimplyBounded class A
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
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::A::@field::x
      setters
        isOriginDeclaration x
          reference: <testLibrary>::@class::A::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional isCovariant _
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::A::@field::x
    isSimplyBounded class B
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
            #E1 requiredPositional isCovariant _
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
            #F2 hasImplicitType hasInitializer isOriginDeclaration t1 (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::t1
              inducedGetter: #F3
              inducedSetter: #F4
            #F5 hasImplicitType hasInitializer isOriginDeclaration t2 (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@class::A::@field::t2
              inducedGetter: #F6
              inducedSetter: #F7
            #F8 hasImplicitType hasInitializer isOriginDeclaration t3 (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@class::A::@field::t3
              inducedGetter: #F9
              inducedSetter: #F10
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::t1
              inducingVariable: #F2
            #F6 isComplete isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@getter::t2
              inducingVariable: #F5
            #F9 isComplete isOriginVariable t3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::A::@getter::t3
              inducingVariable: #F8
          setters
            #F4 isComplete isOriginVariable t1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::t1
              inducingVariable: #F2
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::t1::@formalParameter::value
            #F7 isComplete isOriginVariable t2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@setter::t2
              inducingVariable: #F5
              formalParameters
                #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
                  element: <testLibrary>::@class::A::@setter::t2::@formalParameter::value
            #F10 isComplete isOriginVariable t3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::A::@setter::t3
              inducingVariable: #F8
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
                  element: <testLibrary>::@class::A::@setter::t3::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t1
          reference: <testLibrary>::@class::A::@field::t1
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::t1
          setter: <testLibrary>::@class::A::@setter::t1
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t2
          reference: <testLibrary>::@class::A::@field::t2
          firstFragment: #F5
          type: double
          getter: <testLibrary>::@class::A::@getter::t2
          setter: <testLibrary>::@class::A::@setter::t2
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer t3
          reference: <testLibrary>::@class::A::@field::t3
          firstFragment: #F8
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::t3
          setter: <testLibrary>::@class::A::@setter::t3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F11
      getters
        isOriginVariable t1
          reference: <testLibrary>::@class::A::@getter::t1
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::t1
        isOriginVariable t2
          reference: <testLibrary>::@class::A::@getter::t2
          firstFragment: #F6
          returnType: double
          variable: <testLibrary>::@class::A::@field::t2
        isOriginVariable t3
          reference: <testLibrary>::@class::A::@getter::t3
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::t3
      setters
        isOriginVariable t1
          reference: <testLibrary>::@class::A::@setter::t1
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::t1
        isOriginVariable t2
          reference: <testLibrary>::@class::A::@setter::t2
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: double
          returnType: void
          variable: <testLibrary>::@class::A::@field::t2
        isOriginVariable t3
          reference: <testLibrary>::@class::A::@setter::t3
          firstFragment: #F10
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
            #F3 isComplete isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isComplete isOriginDeclaration m (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:60) (firstTokenOffset:60) (offset:60)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 requiredPositional hasImplicitType isOriginDeclaration b (nameOffset:63) (firstTokenOffset:63) (offset:63)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F3 isComplete isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isComplete isOriginDeclaration m (nameOffset:48) (firstTokenOffset:43) (offset:48)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional isOriginDeclaration a (nameOffset:57) (firstTokenOffset:50) (offset:57)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 hasExtendsClause class C (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:102) (firstTokenOffset:102) (offset:102)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    isSimplyBounded class C
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isAbstract isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:21) (offset:25)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 requiredPositional isOriginDeclaration x (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
        #F5 isAbstract class B (nameOffset:55) (firstTokenOffset:40) (offset:55)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isAbstract isOriginDeclaration foo (nameOffset:68) (firstTokenOffset:61) (offset:68)
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F8 requiredPositional isOriginDeclaration x (nameOffset:76) (firstTokenOffset:72) (offset:76)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::x
        #F9 isAbstract class C (nameOffset:98) (firstTokenOffset:83) (offset:98)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isAbstract isOriginDeclaration foo (nameOffset:126) (firstTokenOffset:120) (offset:126)
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration x (nameOffset:130) (firstTokenOffset:130) (offset:130)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::x
  classes
    isAbstract isSimplyBounded class A
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
            #E0 requiredPositional x
              firstFragment: #F4
              type: int
          returnType: int
    isAbstract isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional x
              firstFragment: #F8
              type: int
          returnType: double
    isAbstract isSimplyBounded class C
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
        isOriginDeclaration foo
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
            #F3 isComplete isOriginDeclaration m (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::m
        #F4 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 isComplete isOriginDeclaration m (nameOffset:44) (firstTokenOffset:37) (offset:44)
              element: <testLibrary>::@class::B::@method::m
        #F7 hasExtendsClause class C (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F9 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:88) (firstTokenOffset:88) (offset:88)
              element: <testLibrary>::@class::C::@method::m
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    isSimplyBounded class C
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
            #F4 isComplete isOriginDeclaration m (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F5 requiredPositional isOriginDeclaration a (nameOffset:24) (firstTokenOffset:22) (offset:24)
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
            #F9 isComplete isOriginDeclaration m (nameOffset:52) (firstTokenOffset:47) (offset:52)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 requiredPositional isOriginDeclaration a (nameOffset:56) (firstTokenOffset:54) (offset:56)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F11 hasExtendsClause class C (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::C
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F13 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:112) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F14 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:114) (firstTokenOffset:114) (offset:114)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F4
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F5
              type: T
          returnType: void
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 E
          firstFragment: #F7
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F9
          formalParameters
            #E3 requiredPositional a
              firstFragment: #F10
              type: E
          returnType: void
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F11
      supertype: A<int>
      interfaces
        B<double>
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
          superConstructor: SubstitutedConstructorElementImpl
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
            #F5 isComplete isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:24) (firstTokenOffset:22) (offset:24)
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
            #F10 isComplete isOriginDeclaration m (nameOffset:49) (firstTokenOffset:47) (offset:49)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 requiredPositional isOriginDeclaration a (nameOffset:55) (firstTokenOffset:51) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F12 hasExtendsClause class C (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::C
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F14 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:119) (firstTokenOffset:119) (offset:119)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F15 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:121) (firstTokenOffset:121) (offset:121)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E3 requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F10
          formalParameters
            #E4 requiredPositional a
              firstFragment: #F11
              type: int
          returnType: T
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F12
      supertype: A<int, String>
      interfaces
        B<double>
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          superConstructor: SubstitutedConstructorElementImpl
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
            #F3 isComplete isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:55) (firstTokenOffset:55) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 optionalNamed hasImplicitType isOriginDeclaration b (nameOffset:59) (firstTokenOffset:59) (offset:59)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F3 isComplete isOriginDeclaration m (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:23) (firstTokenOffset:19) (offset:23)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:55) (firstTokenOffset:55) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F9 optionalPositional hasImplicitType isOriginDeclaration b (nameOffset:59) (firstTokenOffset:59) (offset:59)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F3 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:14) (firstTokenOffset:14) (offset:14)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:46) (firstTokenOffset:46) (offset:46)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F3 isComplete isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:27) (firstTokenOffset:20) (offset:27)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:47) (firstTokenOffset:41) (offset:47)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:65) (firstTokenOffset:65) (offset:65)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::m
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::m
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::m::@formalParameter::value
        #F7 hasExtendsClause class B (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::B
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:48) (firstTokenOffset:48) (offset:48)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:50) (firstTokenOffset:50) (offset:50)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    hasNonFinalField isSimplyBounded class A
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
          firstFragment: #F5
      getters
        isOriginVariable m
          reference: <testLibrary>::@class::A::@getter::m
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::m
      setters
        isOriginVariable m
          reference: <testLibrary>::@class::A::@setter::m
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::m
    hasNonFinalField isSimplyBounded class B
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
            #F5 isComplete isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 hasExtendsClause class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E2 T
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 hasExtendsClause class C (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::C
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F12 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F13 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:96) (firstTokenOffset:96) (offset:96)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E3 requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      supertype: A<int, T>
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: SubstitutedConstructorElementImpl
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: T}
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      supertype: B<String>
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: SubstitutedConstructorElementImpl
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:57) (firstTokenOffset:57) (offset:57)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 hasExtendsClause class C (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:87) (firstTokenOffset:87) (offset:87)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:89) (firstTokenOffset:89) (offset:89)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    isSimplyBounded class C
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:60) (firstTokenOffset:60) (offset:60)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 hasExtendsClause class C (nameOffset:74) (firstTokenOffset:68) (offset:74)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:90) (firstTokenOffset:90) (offset:90)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:92) (firstTokenOffset:92) (offset:92)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    isSimplyBounded class C
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 hasExtendsClause class C (nameOffset:83) (firstTokenOffset:77) (offset:83)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:99) (firstTokenOffset:99) (offset:99)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:101) (firstTokenOffset:101) (offset:101)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    isSimplyBounded class C
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
            #F5 isComplete isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F7 requiredPositional isOriginDeclaration b (nameOffset:34) (firstTokenOffset:27) (offset:34)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F8 hasExtendsClause class B (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::B
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F10 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:79) (firstTokenOffset:79) (offset:79)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F12 requiredPositional hasImplicitType isOriginDeclaration b (nameOffset:82) (firstTokenOffset:82) (offset:82)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F6
              type: K
            #E3 requiredPositional b
              firstFragment: #F7
              type: double
          returnType: V
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F8
      supertype: A<int, String>
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: SubstitutedConstructorElementImpl
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:57) (firstTokenOffset:57) (offset:57)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F5 optionalNamed isOriginDeclaration b (nameOffset:36) (firstTokenOffset:29) (offset:36)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F6 hasExtendsClause class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F9 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F10 optionalNamed hasImplicitType isOriginDeclaration b (nameOffset:73) (firstTokenOffset:73) (offset:73)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
                #F5 optionalPositional isOriginDeclaration b (nameOffset:36) (firstTokenOffset:29) (offset:36)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::b
        #F6 hasExtendsClause class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F9 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
                #F10 optionalPositional hasImplicitType isOriginDeclaration b (nameOffset:73) (firstTokenOffset:73) (offset:73)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::b
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F5 isComplete isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 hasExtendsClause class B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: #E2 T
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 hasExtendsClause class C (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::C
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F12 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F13 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:96) (firstTokenOffset:96) (offset:96)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E3 requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      supertype: A<int, T>
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: SubstitutedConstructorElementImpl
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: int, V: T}
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F10
      supertype: B<String>
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F11
          superConstructor: SubstitutedConstructorElementImpl
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F5 isAbstract isOriginDeclaration m (nameOffset:29) (firstTokenOffset:27) (offset:29)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:33) (firstTokenOffset:31) (offset:33)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 class B (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::B
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F10 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:79) (firstTokenOffset:79) (offset:79)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    isSimplyBounded class B
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isAbstract isOriginDeclaration m (nameOffset:28) (firstTokenOffset:21) (offset:28)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:34) (firstTokenOffset:30) (offset:34)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:46) (firstTokenOffset:40) (offset:46)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:67) (firstTokenOffset:67) (offset:67)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    isAbstract isSimplyBounded class A
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
    isSimplyBounded class B
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
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
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
            #F5 isAbstract isOriginDeclaration m (nameOffset:29) (firstTokenOffset:27) (offset:29)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:33) (firstTokenOffset:31) (offset:33)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F7 hasExtendsClause isAbstract class B (nameOffset:54) (firstTokenOffset:39) (offset:54)
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
            #F13 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:123) (firstTokenOffset:123) (offset:123)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F14 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:125) (firstTokenOffset:125) (offset:125)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E4 requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    isAbstract isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T1
          firstFragment: #F8
        #E3 T2
          firstFragment: #F9
      supertype: A<T2, T1>
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F10
          superConstructor: SubstitutedConstructorElementImpl
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {K: T2, V: T1}
    isSimplyBounded class C
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
            #F3 isComplete isOriginDeclaration _foo (nameOffset:38) (firstTokenOffset:34) (offset:38)
              element: <testLibrary>::@class::A1::@method::_foo
        #F4 hasExtendsClause class A2 (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::A2
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::A2::@constructor::new
              typeName: A2
          methods
            #F6 hasImplicitReturnType isComplete isOriginDeclaration _foo (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::A2::@method::_foo
  classes
    isSimplyBounded class A1
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
    isSimplyBounded class A2
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 hasExtendsClause class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:69) (firstTokenOffset:69) (offset:69)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
            #F5 isComplete isOriginDeclaration m (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F6 requiredPositional isOriginDeclaration a (nameOffset:24) (firstTokenOffset:22) (offset:24)
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
            #F10 isComplete isOriginDeclaration m (nameOffset:49) (firstTokenOffset:47) (offset:49)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F11 requiredPositional isOriginDeclaration a (nameOffset:55) (firstTokenOffset:51) (offset:55)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F12 hasExtendsClause class C (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::C
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F14 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:119) (firstTokenOffset:119) (offset:119)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F15 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:121) (firstTokenOffset:121) (offset:121)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F5
          formalParameters
            #E3 requiredPositional a
              firstFragment: #F6
              type: K
          returnType: V
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F10
          formalParameters
            #E4 requiredPositional a
              firstFragment: #F11
              type: int
          returnType: T
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F12
      supertype: A<int, String>
      interfaces
        B<String>
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          superConstructor: SubstitutedConstructorElementImpl
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
            #F3 isComplete isOriginDeclaration m (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 requiredPositional isOriginDeclaration a (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 isComplete isOriginDeclaration m (nameOffset:52) (firstTokenOffset:45) (offset:52)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 requiredPositional isOriginDeclaration a (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
        #F9 hasExtendsClause class C (nameOffset:72) (firstTokenOffset:66) (offset:72)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F12 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:103) (firstTokenOffset:103) (offset:103)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
  classes
    isSimplyBounded class A
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
    isSimplyBounded class B
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
    isSimplyBounded class C
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
