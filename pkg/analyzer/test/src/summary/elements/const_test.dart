// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstElementTest_keepLinking);
    defineReflectiveTests(ConstElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class ConstElementTest extends ElementsBaseTest {
  test_const_asExpression() async {
    var library = await buildLibrary('''
const num a = 0;
const b = a as int;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration a (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            AsExpression
              expression: SimpleIdentifier
                token: a @27
                element: <testLibrary>::@getter::a
                staticType: num
              asOperator: as @29
              type: NamedType
                name: int @32
                element: dart:core::@class::int
                type: int
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: num
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: num
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_assignmentExpression() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = (a += 1);
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            ParenthesizedExpression
              leftParenthesis: ( @23
              expression: AssignmentExpression
                leftHandSide: SimpleIdentifier
                  token: a @24
                  element: <null>
                  staticType: null
                operator: += @26
                rightHandSide: IntegerLiteral
                  literal: 1 @29
                  staticType: int
                readElement: <testLibrary>::@getter::a
                readType: int
                writeElement: <testLibrary>::@getter::a
                writeType: InvalidType
                element: dart:core::@class::num::@method::+
                staticType: int
              rightParenthesis: ) @30
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_cascadeExpression() async {
    var library = await buildLibrary(r'''
const a = 0..isEven..abs();
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
          initializer: expression_0
            CascadeExpression
              target: IntegerLiteral
                literal: 0 @10
                staticType: int
              cascadeSections
                PropertyAccess
                  operator: .. @11
                  propertyName: SimpleIdentifier
                    token: isEven @13
                    element: dart:core::@class::int::@getter::isEven
                    staticType: bool
                  staticType: bool
                MethodInvocation
                  operator: .. @19
                  methodName: SimpleIdentifier
                    token: abs @21
                    element: dart:core::@class::int::@method::abs
                    staticType: int Function()
                  argumentList: ArgumentList
                    leftParenthesis: ( @24
                    rightParenthesis: ) @25
                  staticInvokeType: int Function()
                  staticType: int
              staticType: int
      getters
        #F2 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_classField() async {
    var library = await buildLibrary(r'''
class C {
  static const int f1 = 1;
  static const int f2 = C.f1, f3 = C.f2;
}
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
            #F2 hasInitializer isOriginDeclaration f1 (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::C::@field::f1
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @34
                  staticType: int
            #F3 hasInitializer isOriginDeclaration f2 (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@class::C::@field::f2
              initializer: expression_1
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C @61
                    element: <testLibrary>::@class::C
                    staticType: null
                  period: . @62
                  identifier: SimpleIdentifier
                    token: f1 @63
                    element: <testLibrary>::@class::C::@getter::f1
                    staticType: int
                  element: <testLibrary>::@class::C::@getter::f1
                  staticType: int
            #F4 hasInitializer isOriginDeclaration f3 (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::C::@field::f3
              initializer: expression_2
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C @72
                    element: <testLibrary>::@class::C
                    staticType: null
                  period: . @73
                  identifier: SimpleIdentifier
                    token: f2 @74
                    element: <testLibrary>::@class::C::@getter::f2
                    staticType: int
                  element: <testLibrary>::@class::C::@getter::f2
                  staticType: int
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F6 isOriginVariable f1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::C::@getter::f1
            #F7 isOriginVariable f2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::C::@getter::f2
            #F8 isOriginVariable f3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@class::C::@getter::f3
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasInitializer isOriginDeclaration f1
          reference: <testLibrary>::@class::C::@field::f1
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::f1
        static const hasInitializer isOriginDeclaration f2
          reference: <testLibrary>::@class::C::@field::f2
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@class::C::@getter::f2
        static const hasInitializer isOriginDeclaration f3
          reference: <testLibrary>::@class::C::@field::f3
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@class::C::@getter::f3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        static isOriginVariable f1
          reference: <testLibrary>::@class::C::@getter::f1
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::C::@field::f1
        static isOriginVariable f2
          reference: <testLibrary>::@class::C::@getter::f2
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::C::@field::f2
        static isOriginVariable f3
          reference: <testLibrary>::@class::C::@getter::f3
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::C::@field::f3
''');
  }

  test_const_constructor_inferred_args() async {
    var library = await buildLibrary('''
class C<T> {
  final T t;
  const C(this.t);
  const C.named(this.t);
}
const Object x = const C(0);
const Object y = const C.named(0);
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 isOriginDeclaration t (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::C::@field::t
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 34
              formalParameters
                #F5 requiredPositional final this.t (nameOffset:41) (firstTokenOffset:36) (offset:41)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::t
            #F6 const isOriginDeclaration named (nameOffset:55) (firstTokenOffset:47) (offset:55)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 53
              periodOffset: 54
              formalParameters
                #F7 requiredPositional final this.t (nameOffset:66) (firstTokenOffset:61) (offset:66)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::t
          getters
            #F8 isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@getter::t
      topLevelVariables
        #F9 hasInitializer isOriginDeclaration x (nameOffset:85) (firstTokenOffset:85) (offset:85)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @89
              constructorName: ConstructorName
                type: NamedType
                  name: C @95
                  element: <testLibrary>::@class::C
                  type: C<int>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {T: int}
              argumentList: ArgumentList
                leftParenthesis: ( @96
                arguments
                  IntegerLiteral
                    literal: 0 @97
                    staticType: int
                rightParenthesis: ) @98
              staticType: C<int>
        #F10 hasInitializer isOriginDeclaration y (nameOffset:114) (firstTokenOffset:114) (offset:114)
          element: <testLibrary>::@topLevelVariable::y
          initializer: expression_1
            InstanceCreationExpression
              keyword: const @118
              constructorName: ConstructorName
                type: NamedType
                  name: C @124
                  element: <testLibrary>::@class::C
                  type: C<int>
                period: . @125
                name: SimpleIdentifier
                  token: named @126
                  element: ConstructorMember
                    baseElement: <testLibrary>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                  staticType: null
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::named
                  substitution: {T: int}
              argumentList: ArgumentList
                leftParenthesis: ( @131
                arguments
                  IntegerLiteral
                    literal: 0 @132
                    staticType: int
                rightParenthesis: ) @133
              staticType: C<int>
      getters
        #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
          element: <testLibrary>::@getter::x
        #F12 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:114)
          element: <testLibrary>::@getter::y
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        final isOriginDeclaration t
          reference: <testLibrary>::@class::C::@field::t
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::C::@getter::t
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional final hasImplicitType this.t
              firstFragment: #F5
              type: T
              field: <testLibrary>::@class::C::@field::t
        const isOriginDeclaration named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional final hasImplicitType this.t
              firstFragment: #F7
              type: T
              field: <testLibrary>::@class::C::@field::t
      getters
        isOriginVariable t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::C::@field::t
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F9
      type: Object
      constantInitializer
        fragment: #F9
        expression: expression_0
      getter: <testLibrary>::@getter::x
    const hasInitializer isOriginDeclaration y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F10
      type: Object
      constantInitializer
        fragment: #F10
        expression: expression_1
      getter: <testLibrary>::@getter::y
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F11
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
    static isOriginVariable y
      reference: <testLibrary>::@getter::y
      firstFragment: #F12
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::y
''');
    var x = library.firstFragment.topLevelVariables[0];
    var xExpr = x.constantInitializer as InstanceCreationExpression;
    var xType = xExpr.constructorName.element!.returnType;
    _assertTypeStr(xType, 'C<int>');
    var y = library.firstFragment.topLevelVariables[0];
    var yExpr = y.constantInitializer as InstanceCreationExpression;
    var yType = yExpr.constructorName.element!.returnType;
    _assertTypeStr(yType, 'C<int>');
  }

  test_const_constructorReference() async {
    var library = await buildLibrary(r'''
class A {
  A.named();
}
const v = A.named;
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
            #F2 isOriginDeclaration named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration v (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ConstructorReference
              constructorName: ConstructorName
                type: NamedType
                  name: A @35
                  element: <testLibrary>::@class::A
                  type: null
                period: . @36
                name: SimpleIdentifier
                  token: named @37
                  element: <testLibrary>::@class::A::@constructor::named
                  staticType: null
                element: <testLibrary>::@class::A::@constructor::named
              staticType: A Function()
      getters
        #F4 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::v
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F3
      type: A Function()
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F4
      returnType: A Function()
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_dotShorthand_constructor_explicit() async {
    var library = await buildLibrary(r'''
class A {
  const A();
}

const A a = const .new();
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
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration a (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            DotShorthandConstructorInvocation
              constKeyword: const @38
              period: . @44
              constructorName: SimpleIdentifier
                token: new @45
                element: <testLibrary>::@class::A::@constructor::new
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              isDotShorthand: true
              staticType: A
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: A
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_dotShorthand_constructor_implicit() async {
    var library = await buildLibrary(r'''
class A {
  const A();
}

const A a = .new();
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
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration a (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            DotShorthandConstructorInvocation
              period: . @38
              constructorName: SimpleIdentifier
                token: new @39
                element: <testLibrary>::@class::A::@constructor::new
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @42
                rightParenthesis: ) @43
              isDotShorthand: true
              staticType: A
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: A
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_dotShorthand_invalid_methodInvocation() async {
    var library = await buildLibrary(r'''
class A {
  static A method() => A();
}

const A a = .method();
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
            #F3 isOriginDeclaration method (nameOffset:21) (firstTokenOffset:12) (offset:21)
              element: <testLibrary>::@class::A::@method::method
      topLevelVariables
        #F4 hasInitializer isOriginDeclaration a (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            DotShorthandInvocation
              period: . @53
              memberName: SimpleIdentifier
                token: method @54
                element: <testLibrary>::@class::A::@method::method
                staticType: A Function()
              argumentList: ArgumentList
                leftParenthesis: ( @60
                rightParenthesis: ) @61
              isDotShorthand: true
              staticInvokeType: A Function()
              staticType: A
      getters
        #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        static isOriginDeclaration method
          reference: <testLibrary>::@class::A::@method::method
          firstFragment: #F3
          returnType: A
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: A
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_dotShorthand_property() async {
    var library = await buildLibrary(r'''
class A {
  static const A a = A();
  const A();
}

const A a = .a;
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
            #F2 hasInitializer isOriginDeclaration a (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::A::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @31
                      element: <testLibrary>::@class::A
                      type: A
                    element: <testLibrary>::@class::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @32
                    rightParenthesis: ) @33
                  staticType: A
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:38) (offset:44)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 44
          getters
            #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::A::@getter::a
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration a (nameOffset:60) (firstTokenOffset:60) (offset:60)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_1
            DotShorthandPropertyAccess
              period: . @64
              propertyName: SimpleIdentifier
                token: a @65
                element: <testLibrary>::@class::A::@getter::a
                staticType: A
              isDotShorthand: true
              staticType: A
      getters
        #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static const hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::a
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@class::A::@field::a
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F5
      type: A
      constantInitializer
        fragment: #F5
        expression: expression_1
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_finalField_hasConstConstructor() async {
    var library = await buildLibrary(r'''
class C {
  final int f = 42;
  const C();
}
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
            #F2 hasInitializer isOriginDeclaration f (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::C::@field::f
              initializer: expression_0
                IntegerLiteral
                  literal: 42 @26
                  staticType: int
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 38
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_const_functionExpression_typeArgumentTypes() async {
    var library = await buildLibrary('''
void f<T>(T a) {}

const void Function(int) v = f;
''');
    checkElementText(library, '''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:44) (firstTokenOffset:44) (offset:44)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            FunctionReference
              function: SimpleIdentifier
                token: f @48
                element: <testLibrary>::@function::f
                staticType: void Function<T>(T)
              staticType: void Function(int)
              typeArgumentTypes
                int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@getter::v
      functions
        #F3 isOriginDeclaration f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F4 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          formalParameters
            #F5 requiredPositional a (nameOffset:12) (firstTokenOffset:10) (offset:12)
              element: <testLibrary>::@function::f::@formalParameter::a
  topLevelVariables
    const hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: void Function(int)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: void Function(int)
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F5
          type: T
      returnType: void
''');
  }

  test_const_functionReference() async {
    var library = await buildLibrary(r'''
void f<T>(T a) {}
const v = f<int>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            FunctionReference
              function: SimpleIdentifier
                token: f @28
                element: <testLibrary>::@function::f
                staticType: void Function<T>(T)
              typeArguments: TypeArgumentList
                leftBracket: < @29
                arguments
                  NamedType
                    name: int @30
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @33
              staticType: void Function(int)
              typeArgumentTypes
                int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::v
      functions
        #F3 isOriginDeclaration f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F4 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          formalParameters
            #F5 requiredPositional a (nameOffset:12) (firstTokenOffset:10) (offset:12)
              element: <testLibrary>::@function::f::@formalParameter::a
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: void Function(int)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: void Function(int)
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F5
          type: T
      returnType: void
''');
  }

  test_const_indexExpression() async {
    var library = await buildLibrary(r'''
const a = [0];
const b = 0;
const c = a[b];
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
          initializer: expression_0
            ListLiteral
              leftBracket: [ @10
              elements
                IntegerLiteral
                  literal: 0 @11
                  staticType: int
              rightBracket: ] @12
              staticType: List<int>
        #F2 hasInitializer isOriginDeclaration b (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            IntegerLiteral
              literal: 0 @25
              staticType: int
        #F3 hasInitializer isOriginDeclaration c (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::c
          initializer: expression_2
            IndexExpression
              target: SimpleIdentifier
                token: a @38
                element: <testLibrary>::@getter::a
                staticType: List<int>
              leftBracket: [ @39
              index: SimpleIdentifier
                token: b @40
                element: <testLibrary>::@getter::b
                staticType: int
              rightBracket: ] @41
              element: MethodMember
                baseElement: dart:core::@class::List::@method::[]
                substitution: {E: int}
              staticType: int
      getters
        #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F5 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::b
        #F6 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::c
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: List<int>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
    const hasImplicitType hasInitializer isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::c
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_const_inference_downward_list() async {
    var library = await buildLibrary('''
class P<T> {
  const P();
}

class P1<T> extends P<T> {
  const P1();
}

class P2<T> extends P<T> {
  const P2();
}

const List<P> values = [
  P1(),
  P2<int>(),
];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class P (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::P
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::P::@constructor::new
              typeName: P
              typeNameOffset: 21
        #F4 class P1 (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::P1
          typeParameters
            #F5 T (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: #E1 T
          constructors
            #F6 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:58) (offset:64)
              element: <testLibrary>::@class::P1::@constructor::new
              typeName: P1
              typeNameOffset: 64
        #F7 class P2 (nameOffset:79) (firstTokenOffset:73) (offset:79)
          element: <testLibrary>::@class::P2
          typeParameters
            #F8 T (nameOffset:82) (firstTokenOffset:82) (offset:82)
              element: #E2 T
          constructors
            #F9 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:102) (offset:108)
              element: <testLibrary>::@class::P2::@constructor::new
              typeName: P2
              typeNameOffset: 108
      topLevelVariables
        #F10 hasInitializer isOriginDeclaration values (nameOffset:131) (firstTokenOffset:131) (offset:131)
          element: <testLibrary>::@topLevelVariable::values
          initializer: expression_0
            ListLiteral
              leftBracket: [ @140
              elements
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: P1 @144
                      element: <testLibrary>::@class::P1
                      type: P1<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@class::P1::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @146
                    rightParenthesis: ) @147
                  staticType: P1<dynamic>
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: P2 @152
                      typeArguments: TypeArgumentList
                        leftBracket: < @154
                        arguments
                          NamedType
                            name: int @155
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @158
                      element: <testLibrary>::@class::P2
                      type: P2<int>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@class::P2::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @159
                    rightParenthesis: ) @160
                  staticType: P2<int>
              rightBracket: ] @163
              staticType: List<P<dynamic>>
      getters
        #F11 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:131)
          element: <testLibrary>::@getter::values
  classes
    class P
      reference: <testLibrary>::@class::P
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::P::@constructor::new
          firstFragment: #F3
    class P1
      reference: <testLibrary>::@class::P1
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      supertype: P<T>
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::P1::@constructor::new
          firstFragment: #F6
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::P::@constructor::new
            substitution: {T: T}
    class P2
      reference: <testLibrary>::@class::P2
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      supertype: P<T>
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::P2::@constructor::new
          firstFragment: #F9
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::P::@constructor::new
            substitution: {T: T}
  topLevelVariables
    const hasInitializer isOriginDeclaration values
      reference: <testLibrary>::@topLevelVariable::values
      firstFragment: #F10
      type: List<P<dynamic>>
      constantInitializer
        fragment: #F10
        expression: expression_0
      getter: <testLibrary>::@getter::values
  getters
    static isOriginVariable values
      reference: <testLibrary>::@getter::values
      firstFragment: #F11
      returnType: List<P<dynamic>>
      variable: <testLibrary>::@topLevelVariable::values
''');
  }

  test_const_invalid_field_const() async {
    var library = await buildLibrary(r'''
class C {
  static const f = 1 + foo();
}
int foo() => 42;
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
            #F2 hasInitializer isOriginDeclaration f (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::f
              initializer: expression_0
                BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @29
                    staticType: int
                  operator: + @31
                  rightOperand: MethodInvocation
                    methodName: SimpleIdentifier
                      token: foo @33
                      element: <testLibrary>::@function::foo
                      staticType: int Function()
                    argumentList: ArgumentList
                      leftParenthesis: ( @36
                      rightParenthesis: ) @37
                    staticInvokeType: int Function()
                    staticType: int
                  element: dart:core::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::f
      functions
        #F5 isOriginDeclaration foo (nameOffset:46) (firstTokenOffset:42) (offset:46)
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasImplicitType hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      returnType: int
''');
  }

  test_const_invalid_field_final() async {
    var library = await buildLibrary(r'''
class C {
  final f = 1 + foo();
}
int foo() => 42;
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
            #F2 hasInitializer isOriginDeclaration f (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::f
      functions
        #F5 isOriginDeclaration foo (nameOffset:39) (firstTokenOffset:35) (offset:39)
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasImplicitType hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
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
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      returnType: int
''');
  }

  test_const_invalid_functionExpression() async {
    var library = await buildLibrary('''
const v = () { return 0; };
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int Function()
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_invalid_functionExpression_assertInitializer() async {
    var library = await buildLibrary('''
class A  {
  const A() : assert((() => true)());
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
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:13) (offset:19)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 19
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          constantInitializers
            AssertInitializer
              assertKeyword: assert @25
              leftParenthesis: ( @31
              condition: SimpleIdentifier
                token: _notSerializableExpression @-1
                element: <null>
                staticType: null
              rightParenthesis: ) @46
''');
  }

  test_const_invalid_functionExpression_assertInitializer_message() async {
    var library = await buildLibrary('''
class A  {
  const A() : assert(b, () => 0);
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
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:13) (offset:19)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 19
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          constantInitializers
            AssertInitializer
              assertKeyword: assert @25
              leftParenthesis: ( @31
              condition: SimpleIdentifier
                token: b @32
                element: <null>
                staticType: InvalidType
              comma: , @33
              message: SimpleIdentifier
                token: _notSerializableExpression @-1
                element: <null>
                staticType: null
              rightParenthesis: ) @42
''');
  }

  test_const_invalid_functionExpression_constructorFieldInitializer() async {
    var library = await buildLibrary('''
class A {
  final Object? foo;
  const A() : foo = (() => 0);
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
            #F2 isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:33) (offset:39)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 39
          getters
            #F4 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: foo @45
                element: <testLibrary>::@class::A::@field::foo
                staticType: null
              equals: = @49
              expression: SimpleIdentifier
                token: _notSerializableExpression @-1
                element: <null>
                staticType: null
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: Object?
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_const_invalid_functionExpression_nested() async {
    var library = await buildLibrary('''
const v = () { return 0; } + 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_invalid_functionExpression_redirectingConstructorInvocation() async {
    var library = await buildLibrary('''
class A {
  const A(Object a, Object b);
  const A.named() : this(0, () => 0);
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
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                #F3 requiredPositional a (nameOffset:27) (firstTokenOffset:20) (offset:27)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 requiredPositional b (nameOffset:37) (firstTokenOffset:30) (offset:37)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
            #F5 const isOriginDeclaration named (nameOffset:51) (firstTokenOffset:43) (offset:51)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 49
              periodOffset: 50
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: Object
            #E1 requiredPositional b
              firstFragment: #F4
              type: Object
        const isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F5
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @61
              argumentList: ArgumentList
                leftParenthesis: ( @65
                arguments
                  IntegerLiteral
                    literal: 0 @66
                    staticType: int
                  SimpleIdentifier
                    token: _notSerializableExpression @-1
                    element: <null>
                    staticType: null
                rightParenthesis: ) @76
              element: <testLibrary>::@class::A::@constructor::new
          redirectedConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_const_invalid_functionExpression_superConstructorInvocation() async {
    var library = await buildLibrary('''
class A {
  const A(Object a, Object b);
}
class B extends A {
  const B() : super(0, () => 0);
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
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                #F3 requiredPositional a (nameOffset:27) (firstTokenOffset:20) (offset:27)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 requiredPositional b (nameOffset:37) (firstTokenOffset:30) (offset:37)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
        #F5 class B (nameOffset:49) (firstTokenOffset:43) (offset:49)
          element: <testLibrary>::@class::B
          constructors
            #F6 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:65) (offset:71)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 71
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: Object
            #E1 requiredPositional b
              firstFragment: #F4
              type: Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @77
              argumentList: ArgumentList
                leftParenthesis: ( @82
                arguments
                  IntegerLiteral
                    literal: 0 @83
                    staticType: int
                  SimpleIdentifier
                    token: _notSerializableExpression @-1
                    element: <null>
                    staticType: null
                rightParenthesis: ) @93
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  @SkippedTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_const_invalid_intLiteral() async {
    var library = await buildLibrary(r'''
const int x = 0x;
''');
    checkElementText(library, r'''
const int x = 0;
''');
  }

  test_const_invalid_methodInvocation() async {
    var library = await buildLibrary(r'''
const a = 'abc'.codeUnitAt(0);
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
          initializer: expression_0
            MethodInvocation
              target: SimpleStringLiteral
                literal: 'abc' @10
              operator: . @15
              methodName: SimpleIdentifier
                token: codeUnitAt @16
                element: dart:core::@class::String::@method::codeUnitAt
                staticType: int Function(int)
              argumentList: ArgumentList
                leftParenthesis: ( @26
                arguments
                  IntegerLiteral
                    literal: 0 @27
                    staticType: int
                rightParenthesis: ) @28
              staticInvokeType: int Function(int)
              staticType: int
      getters
        #F2 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_invalid_patternAssignment() async {
    var library = await buildLibrary('''
const v = (a,) = (0,);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: (int,)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: (int,)
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_invalid_topLevel() async {
    var library = await buildLibrary(r'''
const v = 1 + foo();
int foo() => 42;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @10
                staticType: int
              operator: + @12
              rightOperand: MethodInvocation
                methodName: SimpleIdentifier
                  token: foo @14
                  element: <testLibrary>::@function::foo
                  staticType: int Function()
                argumentList: ArgumentList
                  leftParenthesis: ( @17
                  rightParenthesis: ) @18
                staticInvokeType: int Function()
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
      functions
        #F3 isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:21) (offset:25)
          element: <testLibrary>::@function::foo
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: int
''');
  }

  test_const_invalid_topLevel_switchExpression() async {
    var library = await buildLibrary(r'''
const a = 0 + switch (true) {_ => 1};
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
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
      getters
        #F2 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_invalid_typeMismatch() async {
    var library = await buildLibrary(r'''
const int a = 0;
const bool b = a + 5;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration a (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: a @32
                element: <testLibrary>::@getter::a
                staticType: int
              operator: + @34
              rightOperand: IntegerLiteral
                literal: 5 @36
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: bool
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_invokeConstructor_generic_named() async {
    var library = await buildLibrary(r'''
class C<K, V> {
  const C.named(K k, V v);
}
const V = const C<int, String>.named(1, '222');
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
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 const isOriginDeclaration named (nameOffset:26) (firstTokenOffset:18) (offset:26)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 24
              periodOffset: 25
              formalParameters
                #F5 requiredPositional k (nameOffset:34) (firstTokenOffset:32) (offset:34)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::k
                #F6 requiredPositional v (nameOffset:39) (firstTokenOffset:37) (offset:39)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::v
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration V (nameOffset:51) (firstTokenOffset:51) (offset:51)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @55
              constructorName: ConstructorName
                type: NamedType
                  name: C @61
                  typeArguments: TypeArgumentList
                    leftBracket: < @62
                    arguments
                      NamedType
                        name: int @63
                        element: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @68
                        element: dart:core::@class::String
                        type: String
                    rightBracket: > @74
                  element: <testLibrary>::@class::C
                  type: C<int, String>
                period: . @75
                name: SimpleIdentifier
                  token: named @76
                  element: ConstructorMember
                    baseElement: <testLibrary>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  staticType: null
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::named
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @81
                arguments
                  IntegerLiteral
                    literal: 1 @82
                    staticType: int
                  SimpleStringLiteral
                    literal: '222' @85
                rightParenthesis: ) @90
              staticType: C<int, String>
      getters
        #F8 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F4
          formalParameters
            #E2 requiredPositional k
              firstFragment: #F5
              type: K
            #E3 requiredPositional v
              firstFragment: #F6
              type: V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F7
      type: C<int, String>
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F8
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_generic_named_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = const C<int, String>.named(1, '222');
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  typeArguments: TypeArgumentList
                    leftBracket: < @34
                    arguments
                      NamedType
                        name: int @35
                        element: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @40
                        element: dart:core::@class::String
                        type: String
                    rightBracket: > @46
                  element: package:test/a.dart::@class::C
                  type: C<int, String>
                period: . @47
                name: SimpleIdentifier
                  token: named @48
                  element: ConstructorMember
                    baseElement: package:test/a.dart::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  staticType: null
                element: ConstructorMember
                  baseElement: package:test/a.dart::@class::C::@constructor::named
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @53
                arguments
                  IntegerLiteral
                    literal: 1 @54
                    staticType: int
                  SimpleStringLiteral
                    literal: '222' @57
                rightParenthesis: ) @62
              staticType: C<int, String>
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C<int, String>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_generic_named_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @47
                        element: dart:core::@class::String
                        type: String
                    rightBracket: > @53
                  element: package:test/a.dart::@class::C
                  type: C<int, String>
                period: . @54
                name: SimpleIdentifier
                  token: named @55
                  element: ConstructorMember
                    baseElement: package:test/a.dart::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  staticType: null
                element: ConstructorMember
                  baseElement: package:test/a.dart::@class::C::@constructor::named
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @60
                arguments
                  IntegerLiteral
                    literal: 1 @61
                    staticType: int
                  SimpleStringLiteral
                    literal: '222' @64
                rightParenthesis: ) @69
              staticType: C<int, String>
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C<int, String>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_generic_noTypeArguments() async {
    var library = await buildLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C();
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
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:18) (offset:24)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 24
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration V (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @41
              constructorName: ConstructorName
                type: NamedType
                  name: C @47
                  element: <testLibrary>::@class::C
                  type: C<dynamic, dynamic>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {K: dynamic, V: dynamic}
              argumentList: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              staticType: C<dynamic, dynamic>
      getters
        #F6 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F5
      type: C<dynamic, dynamic>
      constantInitializer
        fragment: #F5
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F6
      returnType: C<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_generic_noTypeArguments_inferred() async {
    var library = await buildLibrary(r'''
class A<T> {
  final T t;
  const A(this.t);
}
const Object a = const A(0);
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
          fields
            #F3 isOriginDeclaration t (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::A::@field::t
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:34)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 34
              formalParameters
                #F5 requiredPositional final this.t (nameOffset:41) (firstTokenOffset:36) (offset:41)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          getters
            #F6 isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@getter::t
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration a (nameOffset:60) (firstTokenOffset:60) (offset:60)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @64
              constructorName: ConstructorName
                type: NamedType
                  name: A @70
                  element: <testLibrary>::@class::A
                  type: A<int>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: int}
              argumentList: ArgumentList
                leftParenthesis: ( @71
                arguments
                  IntegerLiteral
                    literal: 0 @72
                    staticType: int
                rightParenthesis: ) @73
              staticType: A<int>
      getters
        #F8 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        final isOriginDeclaration t
          reference: <testLibrary>::@class::A::@field::t
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::t
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional final hasImplicitType this.t
              firstFragment: #F5
              type: T
              field: <testLibrary>::@class::A::@field::t
      getters
        isOriginVariable t
          reference: <testLibrary>::@class::A::@getter::t
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::t
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: Object
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_const_invokeConstructor_generic_unnamed() async {
    var library = await buildLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C<int, String>();
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
          typeParameters
            #F2 K (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 K
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:18) (offset:24)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 24
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration V (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @41
              constructorName: ConstructorName
                type: NamedType
                  name: C @47
                  typeArguments: TypeArgumentList
                    leftBracket: < @48
                    arguments
                      NamedType
                        name: int @49
                        element: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @54
                        element: dart:core::@class::String
                        type: String
                    rightBracket: > @60
                  element: <testLibrary>::@class::C
                  type: C<int, String>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @61
                rightParenthesis: ) @62
              staticType: C<int, String>
      getters
        #F6 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 K
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F5
      type: C<int, String>
      constantInitializer
        fragment: #F5
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F6
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = const C<int, String>();
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  typeArguments: TypeArgumentList
                    leftBracket: < @34
                    arguments
                      NamedType
                        name: int @35
                        element: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @40
                        element: dart:core::@class::String
                        type: String
                    rightBracket: > @46
                  element: package:test/a.dart::@class::C
                  type: C<int, String>
                element: ConstructorMember
                  baseElement: package:test/a.dart::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C<int, String>
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C<int, String>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @47
                        element: dart:core::@class::String
                        type: String
                    rightBracket: > @53
                  element: package:test/a.dart::@class::C
                  type: C<int, String>
                element: ConstructorMember
                  baseElement: package:test/a.dart::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @54
                rightParenthesis: ) @55
              staticType: C<int, String>
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C<int, String>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named() async {
    var library = await buildLibrary(r'''
class C {
  const C.named(bool a, int b, int c, {String d, double e});
}
const V = const C.named(true, 1, 2, d: 'ccc', e: 3.4);
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
          constructors
            #F2 const isOriginDeclaration named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                #F3 requiredPositional a (nameOffset:31) (firstTokenOffset:26) (offset:31)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::a
                #F4 requiredPositional b (nameOffset:38) (firstTokenOffset:34) (offset:38)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::b
                #F5 requiredPositional c (nameOffset:45) (firstTokenOffset:41) (offset:45)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::c
                #F6 optionalNamed d (nameOffset:56) (firstTokenOffset:49) (offset:56)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::d
                #F7 optionalNamed e (nameOffset:66) (firstTokenOffset:59) (offset:66)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::e
      topLevelVariables
        #F8 hasInitializer isOriginDeclaration V (nameOffset:79) (firstTokenOffset:79) (offset:79)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @83
              constructorName: ConstructorName
                type: NamedType
                  name: C @89
                  element: <testLibrary>::@class::C
                  type: C
                period: . @90
                name: SimpleIdentifier
                  token: named @91
                  element: <testLibrary>::@class::C::@constructor::named
                  staticType: null
                element: <testLibrary>::@class::C::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @96
                arguments
                  BooleanLiteral
                    literal: true @97
                    staticType: bool
                  IntegerLiteral
                    literal: 1 @103
                    staticType: int
                  IntegerLiteral
                    literal: 2 @106
                    staticType: int
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: d @109
                        element: <testLibrary>::@class::C::@constructor::named::@formalParameter::d
                        staticType: null
                      colon: : @110
                    expression: SimpleStringLiteral
                      literal: 'ccc' @112
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: e @119
                        element: <testLibrary>::@class::C::@constructor::named::@formalParameter::e
                        staticType: null
                      colon: : @120
                    expression: DoubleLiteral
                      literal: 3.4 @122
                      staticType: double
                rightParenthesis: ) @125
              staticType: C
      getters
        #F9 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: bool
            #E1 requiredPositional b
              firstFragment: #F4
              type: int
            #E2 requiredPositional c
              firstFragment: #F5
              type: int
            #E3 optionalNamed d
              firstFragment: #F6
              type: String
            #E4 optionalNamed e
              firstFragment: #F7
              type: double
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F8
      type: C
      constantInitializer
        fragment: #F8
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F9
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = const C.named();
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element: package:test/a.dart::@class::C
                  type: C
                period: . @34
                name: SimpleIdentifier
                  token: named @35
                  element: package:test/a.dart::@class::C::@constructor::named
                  staticType: null
                element: package:test/a.dart::@class::C::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @40
                rightParenthesis: ) @41
              staticType: C
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: package:test/a.dart::@class::C
                  type: C
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  element: package:test/a.dart::@class::C::@constructor::named
                  staticType: null
                element: package:test/a.dart::@class::C::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_unresolved() async {
    var library = await buildLibrary(r'''
class C {}
const V = const C.named();
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration V (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @21
              constructorName: ConstructorName
                type: NamedType
                  name: C @27
                  element: <testLibrary>::@class::C
                  type: C
                period: . @28
                name: SimpleIdentifier
                  token: named @29
                  element: <null>
                  staticType: null
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
      getters
        #F4 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F3
      type: C
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_unresolved2() async {
    var library = await buildLibrary(r'''
const V = const C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: C @16
                    period: . @17
                    element: <null>
                  name: named @18
                  element: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @23
                rightParenthesis: ) @24
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_unresolved3() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: package:test/a.dart::@class::C
                  type: C
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  element: <null>
                  staticType: null
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_unresolved4() async {
    newFile('$testPackageLibPath/a.dart', '');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: <null>
                  type: InvalidType
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  element: <null>
                  staticType: null
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_unresolved5() async {
    var library = await buildLibrary(r'''
const V = const p.C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @16
                    period: . @17
                    element: <null>
                  name: C @18
                  element: <null>
                  type: InvalidType
                period: . @19
                name: SimpleIdentifier
                  token: named @20
                  element: <null>
                  staticType: null
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @25
                rightParenthesis: ) @26
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_named_unresolved6() async {
    var library = await buildLibrary(r'''
class C<T> {}
const V = const C.named();
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F4 hasInitializer isOriginDeclaration V (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @24
              constructorName: ConstructorName
                type: NamedType
                  name: C @30
                  element: <testLibrary>::@class::C
                  type: C<dynamic>
                period: . @31
                name: SimpleIdentifier
                  token: named @32
                  element: <null>
                  staticType: null
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              staticType: C<dynamic>
      getters
        #F5 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F4
      type: C<dynamic>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F5
      returnType: C<dynamic>
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_unnamed() async {
    var library = await buildLibrary(r'''
class C {
  const C();
}
const V = const C();
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
          constructors
            #F2 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration V (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @35
              constructorName: ConstructorName
                type: NamedType
                  name: C @41
                  element: <testLibrary>::@class::C
                  type: C
                element: <testLibrary>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @42
                rightParenthesis: ) @43
              staticType: C
      getters
        #F4 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F3
      type: C
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_unnamed_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  const C();
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = const C();
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element: package:test/a.dart::@class::C
                  type: C
                element: package:test/a.dart::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_unnamed_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  const C();
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: package:test/a.dart::@class::C
                  type: C
                element: package:test/a.dart::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: C
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: C
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_unnamed_unresolved() async {
    var library = await buildLibrary(r'''
const V = const C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  name: C @16
                  element: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @17
                rightParenthesis: ) @18
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_unnamed_unresolved2() async {
    newFile('$testPackageLibPath/a.dart', '');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_invokeConstructor_unnamed_unresolved3() async {
    var library = await buildLibrary(r'''
const V = const p.C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @16
                    period: . @17
                    element: <null>
                  name: C @18
                  element: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @19
                rightParenthesis: ) @20
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_isExpression() async {
    var library = await buildLibrary('''
const a = 0;
const b = a is int;
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            IsExpression
              expression: SimpleIdentifier
                token: a @23
                element: <testLibrary>::@getter::a
                staticType: int
              isOperator: is @25
              type: NamedType
                name: int @28
                element: dart:core::@class::int
                type: int
              staticType: bool
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: bool
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_length_ofClassConstField() async {
    var library = await buildLibrary(r'''
class C {
  static const String F = '';
}
const int v = C.F.length;
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
            #F2 hasInitializer isOriginDeclaration F (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: <testLibrary>::@class::C::@field::F
              initializer: expression_0
                SimpleStringLiteral
                  literal: '' @36
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable F (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@getter::F
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration v (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_1
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @56
                  element: <testLibrary>::@class::C
                  staticType: null
                period: . @57
                identifier: SimpleIdentifier
                  token: F @58
                  element: <testLibrary>::@class::C::@getter::F
                  staticType: String
                element: <testLibrary>::@class::C::@getter::F
                staticType: String
              operator: . @59
              propertyName: SimpleIdentifier
                token: length @60
                element: dart:core::@class::String::@getter::length
                staticType: int
              staticType: int
      getters
        #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::v
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasInitializer isOriginDeclaration F
          reference: <testLibrary>::@class::C::@field::F
          firstFragment: #F2
          type: String
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::F
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable F
          reference: <testLibrary>::@class::C::@getter::F
          firstFragment: #F4
          returnType: String
          variable: <testLibrary>::@class::C::@field::F
  topLevelVariables
    const hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F5
      type: int
      constantInitializer
        fragment: #F5
        expression: expression_1
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_ofClassConstField_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const int v = C.F.length;
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @31
                  element: package:test/a.dart::@class::C
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: F @33
                  element: package:test/a.dart::@class::C::@getter::F
                  staticType: String
                element: package:test/a.dart::@class::C::@getter::F
                staticType: String
              operator: . @34
              propertyName: SimpleIdentifier
                token: length @35
                element: dart:core::@class::String::@getter::length
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_ofClassConstField_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const int v = p.C.F.length;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PropertyAccess
              target: PropertyAccess
                target: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: p @36
                    element: <testLibraryFragment>::@prefix2::p
                    staticType: null
                  period: . @37
                  identifier: SimpleIdentifier
                    token: C @38
                    element: package:test/a.dart::@class::C
                    staticType: null
                  element: package:test/a.dart::@class::C
                  staticType: null
                operator: . @39
                propertyName: SimpleIdentifier
                  token: F @40
                  element: package:test/a.dart::@class::C::@getter::F
                  staticType: String
                staticType: String
              operator: . @41
              propertyName: SimpleIdentifier
                token: length @42
                element: dart:core::@class::String::@getter::length
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_ofStringLiteral() async {
    var library = await buildLibrary(r'''
const v = 'abc'.length;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PropertyAccess
              target: SimpleStringLiteral
                literal: 'abc' @10
              operator: . @15
              propertyName: SimpleIdentifier
                token: length @16
                element: dart:core::@class::String::@getter::length
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_ofTopLevelVariable() async {
    var library = await buildLibrary(r'''
const String S = 'abc';
const v = S.length;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration S (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::S
          initializer: expression_0
            SimpleStringLiteral
              literal: 'abc' @17
        #F2 hasInitializer isOriginDeclaration v (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_1
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @34
                element: <testLibrary>::@getter::S
                staticType: String
              period: . @35
              identifier: SimpleIdentifier
                token: length @36
                element: dart:core::@class::String::@getter::length
                staticType: int
              element: dart:core::@class::String::@getter::length
              staticType: int
      getters
        #F3 isOriginVariable S (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::S
        #F4 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasInitializer isOriginDeclaration S
      reference: <testLibrary>::@topLevelVariable::S
      firstFragment: #F1
      type: String
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::S
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable S
      reference: <testLibrary>::@getter::S
      firstFragment: #F3
      returnType: String
      variable: <testLibrary>::@topLevelVariable::S
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_ofTopLevelVariable_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const String S = 'abc';
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const v = S.length;
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @27
                element: package:test/a.dart::@getter::S
                staticType: String
              period: . @28
              identifier: SimpleIdentifier
                token: length @29
                element: dart:core::@class::String::@getter::length
                staticType: int
              element: dart:core::@class::String::@getter::length
              staticType: int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_ofTopLevelVariable_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
const String S = 'abc';
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const v = p.S.length;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: S @34
                  element: package:test/a.dart::@getter::S
                  staticType: String
                element: package:test/a.dart::@getter::S
                staticType: String
              operator: . @35
              propertyName: SimpleIdentifier
                token: length @36
                element: dart:core::@class::String::@getter::length
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_length_staticMethod() async {
    var library = await buildLibrary(r'''
class C {
  static int length() => 42;
}
const v = C.length;
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 isOriginDeclaration length (nameOffset:23) (firstTokenOffset:12) (offset:23)
              element: <testLibrary>::@class::C::@method::length
      topLevelVariables
        #F4 hasInitializer isOriginDeclaration v (nameOffset:47) (firstTokenOffset:47) (offset:47)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @51
                element: <testLibrary>::@class::C
                staticType: null
              period: . @52
              identifier: SimpleIdentifier
                token: length @53
                element: <testLibrary>::@class::C::@method::length
                staticType: int Function()
              element: <testLibrary>::@class::C::@method::length
              staticType: int Function()
      getters
        #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@getter::v
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        static isOriginDeclaration length
          reference: <testLibrary>::@class::C::@method::length
          firstFragment: #F3
          returnType: int
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      type: int Function()
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_list_if() async {
    var library = await buildLibrary('''
const Object x = const <int>[if (true) 1];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: [ @28
              elements
                IfElement
                  ifKeyword: if @29
                  leftParenthesis: ( @32
                  expression: BooleanLiteral
                    literal: true @33
                    staticType: bool
                  rightParenthesis: ) @37
                  thenElement: IntegerLiteral
                    literal: 1 @39
                    staticType: int
              rightBracket: ] @40
              staticType: List<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_list_if_else() async {
    var library = await buildLibrary('''
const Object x = const <int>[if (true) 1 else 2];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: [ @28
              elements
                IfElement
                  ifKeyword: if @29
                  leftParenthesis: ( @32
                  expression: BooleanLiteral
                    literal: true @33
                    staticType: bool
                  rightParenthesis: ) @37
                  thenElement: IntegerLiteral
                    literal: 1 @39
                    staticType: int
                  elseKeyword: else @41
                  elseElement: IntegerLiteral
                    literal: 2 @46
                    staticType: int
              rightBracket: ] @47
              staticType: List<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_list_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await buildLibrary('''
const Object x = const [1];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              leftBracket: [ @23
              elements
                IntegerLiteral
                  literal: 1 @24
                  staticType: int
              rightBracket: ] @25
              staticType: List<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_list_spread() async {
    var library = await buildLibrary('''
const Object x = const <int>[...<int>[1]];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: [ @28
              elements
                SpreadElement
                  spreadOperator: ... @29
                  expression: ListLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: < @32
                      arguments
                        NamedType
                          name: int @33
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @36
                    leftBracket: [ @37
                    elements
                      IntegerLiteral
                        literal: 1 @38
                        staticType: int
                    rightBracket: ] @39
                    staticType: List<int>
              rightBracket: ] @40
              staticType: List<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_list_spread_null_aware() async {
    var library = await buildLibrary('''
const Object x = const <int>[...?<int>[1]];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: [ @28
              elements
                SpreadElement
                  spreadOperator: ...? @29
                  expression: ListLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: < @33
                      arguments
                        NamedType
                          name: int @34
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @37
                    leftBracket: [ @38
                    elements
                      IntegerLiteral
                        literal: 1 @39
                        staticType: int
                    rightBracket: ] @40
                    staticType: List<int>
              rightBracket: ] @41
              staticType: List<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_map_if() async {
    var library = await buildLibrary('''
const Object x = const <int, int>{if (true) 1: 2};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @32
              leftBracket: { @33
              elements
                IfElement
                  ifKeyword: if @34
                  leftParenthesis: ( @37
                  expression: BooleanLiteral
                    literal: true @38
                    staticType: bool
                  rightParenthesis: ) @42
                  thenElement: MapLiteralEntry
                    key: IntegerLiteral
                      literal: 1 @44
                      staticType: int
                    separator: : @45
                    value: IntegerLiteral
                      literal: 2 @47
                      staticType: int
              rightBracket: } @48
              isMap: true
              staticType: Map<int, int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_map_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await buildLibrary('''
const Object x = const {1: 1.0};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              leftBracket: { @23
              elements
                MapLiteralEntry
                  key: IntegerLiteral
                    literal: 1 @24
                    staticType: int
                  separator: : @25
                  value: DoubleLiteral
                    literal: 1.0 @27
                    staticType: double
              rightBracket: } @30
              isMap: true
              staticType: Map<int, double>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_map_spread() async {
    var library = await buildLibrary('''
const Object x = const <int, int>{...<int, int>{1: 2}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @32
              leftBracket: { @33
              elements
                SpreadElement
                  spreadOperator: ... @34
                  expression: SetOrMapLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: < @37
                      arguments
                        NamedType
                          name: int @38
                          element: dart:core::@class::int
                          type: int
                        NamedType
                          name: int @43
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @46
                    leftBracket: { @47
                    elements
                      MapLiteralEntry
                        key: IntegerLiteral
                          literal: 1 @48
                          staticType: int
                        separator: : @49
                        value: IntegerLiteral
                          literal: 2 @51
                          staticType: int
                    rightBracket: } @52
                    isMap: true
                    staticType: Map<int, int>
              rightBracket: } @53
              isMap: true
              staticType: Map<int, int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_map_spread_null_aware() async {
    var library = await buildLibrary('''
const Object x = const <int, int>{...?<int, int>{1: 2}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @32
              leftBracket: { @33
              elements
                SpreadElement
                  spreadOperator: ...? @34
                  expression: SetOrMapLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: < @38
                      arguments
                        NamedType
                          name: int @39
                          element: dart:core::@class::int
                          type: int
                        NamedType
                          name: int @44
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @47
                    leftBracket: { @48
                    elements
                      MapLiteralEntry
                        key: IntegerLiteral
                          literal: 1 @49
                          staticType: int
                        separator: : @50
                        value: IntegerLiteral
                          literal: 2 @52
                          staticType: int
                    rightBracket: } @53
                    isMap: true
                    staticType: Map<int, int>
              rightBracket: } @54
              isMap: true
              staticType: Map<int, int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_methodInvocation() async {
    var library = await buildLibrary(r'''
T f<T>(T a) => a;
const b = f<int>(0);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration b (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_0
            MethodInvocation
              methodName: SimpleIdentifier
                token: f @28
                element: <testLibrary>::@function::f
                staticType: T Function<T>(T)
              typeArguments: TypeArgumentList
                leftBracket: < @29
                arguments
                  NamedType
                    name: int @30
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @33
              argumentList: ArgumentList
                leftParenthesis: ( @34
                arguments
                  IntegerLiteral
                    literal: 0 @35
                    staticType: int
                rightParenthesis: ) @36
              staticInvokeType: int Function(int)
              staticType: int
              typeArgumentTypes
                int
      getters
        #F2 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::b
      functions
        #F3 isOriginDeclaration f (nameOffset:2) (firstTokenOffset:0) (offset:2)
          element: <testLibrary>::@function::f
          typeParameters
            #F4 T (nameOffset:4) (firstTokenOffset:4) (offset:4)
              element: #E0 T
          formalParameters
            #F5 requiredPositional a (nameOffset:9) (firstTokenOffset:7) (offset:9)
              element: <testLibrary>::@function::f::@formalParameter::a
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
  functions
    isOriginDeclaration f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F5
          type: T
      returnType: T
''');
  }

  test_const_parameterDefaultValue_initializingFormal_functionTyped() async {
    var library = await buildLibrary(r'''
class C {
  final x;
  const C({this.x: foo});
}
int foo() => 42;
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
            #F2 isOriginDeclaration x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                #F4 optionalNamed final this.x (nameOffset:37) (firstTokenOffset:32) (offset:37)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  initializer: expression_0
                    SimpleIdentifier
                      token: foo @40
                      element: <testLibrary>::@function::foo
                      staticType: int Function()
          getters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
      functions
        #F6 isOriginDeclaration foo (nameOffset:53) (firstTokenOffset:49) (offset:53)
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasDefaultValue hasImplicitType this.x
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@class::C::@field::x
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F6
      returnType: int
''');
  }

  test_const_parameterDefaultValue_initializingFormal_named() async {
    var library = await buildLibrary(r'''
class C {
  final x;
  const C({this.x: 1 + 2});
}
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
            #F2 isOriginDeclaration x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                #F4 optionalNamed final this.x (nameOffset:37) (firstTokenOffset:32) (offset:37)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  initializer: expression_0
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @40
                        staticType: int
                      operator: + @42
                      rightOperand: IntegerLiteral
                        literal: 2 @44
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
          getters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasDefaultValue hasImplicitType this.x
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@class::C::@field::x
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_const_parameterDefaultValue_initializingFormal_positional() async {
    var library = await buildLibrary(r'''
class C {
  final x;
  const C([this.x = 1 + 2]);
}
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
            #F2 isOriginDeclaration x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                #F4 optionalPositional final this.x (nameOffset:37) (firstTokenOffset:32) (offset:37)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  initializer: expression_0
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @41
                        staticType: int
                      operator: + @43
                      rightOperand: IntegerLiteral
                        literal: 2 @45
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
          getters
            #F5 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasDefaultValue hasImplicitType this.x
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@class::C::@field::x
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_const_parameterDefaultValue_normal() async {
    var library = await buildLibrary(r'''
class C {
  const C.positional([p = 1 + 2]);
  const C.named({p: 1 + 2});
  void methodPositional([p = 1 + 2]) {}
  void methodPositionalWithoutDefault([p]) {}
  void methodNamed({p: 1 + 2}) {}
  void methodNamedWithoutDefault({p}) {}
}
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
          constructors
            #F2 const isOriginDeclaration positional (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::positional
              typeName: C
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                #F3 optionalPositional p (nameOffset:32) (firstTokenOffset:32) (offset:32)
                  element: <testLibrary>::@class::C::@constructor::positional::@formalParameter::p
                  initializer: expression_0
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @36
                        staticType: int
                      operator: + @38
                      rightOperand: IntegerLiteral
                        literal: 2 @40
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
            #F4 const isOriginDeclaration named (nameOffset:55) (firstTokenOffset:47) (offset:55)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 53
              periodOffset: 54
              formalParameters
                #F5 optionalNamed p (nameOffset:62) (firstTokenOffset:62) (offset:62)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::p
                  initializer: expression_1
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @65
                        staticType: int
                      operator: + @67
                      rightOperand: IntegerLiteral
                        literal: 2 @69
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
          methods
            #F6 isOriginDeclaration methodPositional (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@class::C::@method::methodPositional
              formalParameters
                #F7 optionalPositional p (nameOffset:99) (firstTokenOffset:99) (offset:99)
                  element: <testLibrary>::@class::C::@method::methodPositional::@formalParameter::p
                  initializer: expression_2
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @103
                        staticType: int
                      operator: + @105
                      rightOperand: IntegerLiteral
                        literal: 2 @107
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
            #F8 isOriginDeclaration methodPositionalWithoutDefault (nameOffset:121) (firstTokenOffset:116) (offset:121)
              element: <testLibrary>::@class::C::@method::methodPositionalWithoutDefault
              formalParameters
                #F9 optionalPositional p (nameOffset:153) (firstTokenOffset:153) (offset:153)
                  element: <testLibrary>::@class::C::@method::methodPositionalWithoutDefault::@formalParameter::p
            #F10 isOriginDeclaration methodNamed (nameOffset:167) (firstTokenOffset:162) (offset:167)
              element: <testLibrary>::@class::C::@method::methodNamed
              formalParameters
                #F11 optionalNamed p (nameOffset:180) (firstTokenOffset:180) (offset:180)
                  element: <testLibrary>::@class::C::@method::methodNamed::@formalParameter::p
                  initializer: expression_3
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @183
                        staticType: int
                      operator: + @185
                      rightOperand: IntegerLiteral
                        literal: 2 @187
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
            #F12 isOriginDeclaration methodNamedWithoutDefault (nameOffset:201) (firstTokenOffset:196) (offset:201)
              element: <testLibrary>::@class::C::@method::methodNamedWithoutDefault
              formalParameters
                #F13 optionalNamed p (nameOffset:228) (firstTokenOffset:228) (offset:228)
                  element: <testLibrary>::@class::C::@method::methodNamedWithoutDefault::@formalParameter::p
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const isOriginDeclaration positional
          reference: <testLibrary>::@class::C::@constructor::positional
          firstFragment: #F2
          formalParameters
            #E0 optionalPositional hasDefaultValue hasImplicitType p
              firstFragment: #F3
              type: dynamic
              constantInitializer
                fragment: #F3
                expression: expression_0
        const isOriginDeclaration named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F4
          formalParameters
            #E1 optionalNamed hasDefaultValue hasImplicitType p
              firstFragment: #F5
              type: dynamic
              constantInitializer
                fragment: #F5
                expression: expression_1
      methods
        isOriginDeclaration methodPositional
          reference: <testLibrary>::@class::C::@method::methodPositional
          firstFragment: #F6
          formalParameters
            #E2 optionalPositional hasDefaultValue hasImplicitType p
              firstFragment: #F7
              type: dynamic
              constantInitializer
                fragment: #F7
                expression: expression_2
          returnType: void
        isOriginDeclaration methodPositionalWithoutDefault
          reference: <testLibrary>::@class::C::@method::methodPositionalWithoutDefault
          firstFragment: #F8
          formalParameters
            #E3 optionalPositional hasImplicitType p
              firstFragment: #F9
              type: dynamic
          returnType: void
        isOriginDeclaration methodNamed
          reference: <testLibrary>::@class::C::@method::methodNamed
          firstFragment: #F10
          formalParameters
            #E4 optionalNamed hasDefaultValue hasImplicitType p
              firstFragment: #F11
              type: dynamic
              constantInitializer
                fragment: #F11
                expression: expression_3
          returnType: void
        isOriginDeclaration methodNamedWithoutDefault
          reference: <testLibrary>::@class::C::@method::methodNamedWithoutDefault
          firstFragment: #F12
          formalParameters
            #E5 optionalNamed hasImplicitType p
              firstFragment: #F13
              type: dynamic
          returnType: void
''');
  }

  test_const_postfixExpression_increment() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = a++;
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PostfixExpression
              operand: SimpleIdentifier
                token: a @23
                element: <null>
                staticType: null
              operator: ++ @24
              readElement: <testLibrary>::@getter::a
              readType: int
              writeElement: <testLibrary>::@getter::a
              writeType: InvalidType
              element: dart:core::@class::num::@method::+
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_postfixExpression_nullCheck() async {
    var library = await buildLibrary(r'''
const int? a = 0;
const b = a!;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration a (nameOffset:11) (firstTokenOffset:11) (offset:11)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @15
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PostfixExpression
              operand: SimpleIdentifier
                token: a @28
                element: <testLibrary>::@getter::a
                staticType: int?
              operator: ! @29
              element: <null>
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int?
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int?
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_prefixExpression_class_unaryMinus() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = -a;
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PrefixExpression
              operator: - @23
              operand: SimpleIdentifier
                token: a @24
                element: <testLibrary>::@getter::a
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_prefixExpression_extension_unaryMinus() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on Object {
  int operator -() => 0;
}
const a = const Object();
''');
    var library = await buildLibrary('''
import 'a.dart';
const b = -a;
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
        #F1 hasInitializer isOriginDeclaration b (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_0
            PrefixExpression
              operator: - @27
              operand: SimpleIdentifier
                token: a @28
                element: package:test/a.dart::@getter::a
                staticType: Object
              element: package:test/a.dart::@extension::E::@method::unary-
              staticType: int
      getters
        #F2 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_prefixExpression_increment() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = ++a;
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PrefixExpression
              operator: ++ @23
              operand: SimpleIdentifier
                token: a @25
                element: <null>
                staticType: null
              readElement: <testLibrary>::@getter::a
              readType: int
              writeElement: <testLibrary>::@getter::a
              writeType: InvalidType
              element: dart:core::@class::num::@method::+
              staticType: int
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  void test_const_recordLiteral() async {
    var library = await buildLibrary('''
const a = 0;
const b = (a, a: a);
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            RecordLiteral
              leftParenthesis: ( @23
              fields
                SimpleIdentifier
                  token: a @24
                  element: <testLibrary>::@getter::a
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      token: a @27
                      element: <null>
                      staticType: null
                    colon: : @28
                  expression: SimpleIdentifier
                    token: a @30
                    element: <testLibrary>::@getter::a
                    staticType: int
              rightParenthesis: ) @31
              staticType: (int, {int a})
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: (int, {int a})
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: (int, {int a})
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  void test_const_recordLiteral_explicitConst() async {
    var library = await buildLibrary('''
const a = 0;
const b = const (a, a: a);
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
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            RecordLiteral
              constKeyword: const @23
              leftParenthesis: ( @29
              fields
                SimpleIdentifier
                  token: a @30
                  element: <testLibrary>::@getter::a
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      token: a @33
                      element: <null>
                      staticType: null
                    colon: : @34
                  expression: SimpleIdentifier
                    token: a @36
                    element: <testLibrary>::@getter::a
                    staticType: int
              rightParenthesis: ) @37
              staticType: (int, {int a})
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: (int, {int a})
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: (int, {int a})
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_reference_staticField() async {
    var library = await buildLibrary(r'''
class C {
  static const int F = 42;
}
const V = C.F;
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
            #F2 hasInitializer isOriginDeclaration F (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::C::@field::F
              initializer: expression_0
                IntegerLiteral
                  literal: 42 @33
                  staticType: int
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable F (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::C::@getter::F
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration V (nameOffset:45) (firstTokenOffset:45) (offset:45)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_1
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @49
                element: <testLibrary>::@class::C
                staticType: null
              period: . @50
              identifier: SimpleIdentifier
                token: F @51
                element: <testLibrary>::@class::C::@getter::F
                staticType: int
              element: <testLibrary>::@class::C::@getter::F
              staticType: int
      getters
        #F6 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasInitializer isOriginDeclaration F
          reference: <testLibrary>::@class::C::@field::F
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::F
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable F
          reference: <testLibrary>::@class::C::@getter::F
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::F
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F5
      type: int
      constantInitializer
        fragment: #F5
        expression: expression_1
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_staticField_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = C.F;
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @27
                element: package:test/a.dart::@class::C
                staticType: null
              period: . @28
              identifier: SimpleIdentifier
                token: F @29
                element: package:test/a.dart::@class::C::@getter::F
                staticType: int
              element: package:test/a.dart::@class::C::@getter::F
              staticType: int
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_staticField_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = p.C.F;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: C @34
                  element: package:test/a.dart::@class::C
                  staticType: null
                element: package:test/a.dart::@class::C
                staticType: null
              operator: . @35
              propertyName: SimpleIdentifier
                token: F @36
                element: package:test/a.dart::@class::C::@getter::F
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_staticMethod() async {
    var library = await buildLibrary(r'''
class C {
  static int m(int a, String b) => 42;
}
const V = C.m;
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 isOriginDeclaration m (nameOffset:23) (firstTokenOffset:12) (offset:23)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F4 requiredPositional a (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::a
                #F5 requiredPositional b (nameOffset:39) (firstTokenOffset:32) (offset:39)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::b
      topLevelVariables
        #F6 hasInitializer isOriginDeclaration V (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @61
                element: <testLibrary>::@class::C
                staticType: null
              period: . @62
              identifier: SimpleIdentifier
                token: m @63
                element: <testLibrary>::@class::C::@method::m
                staticType: int Function(int, String)
              element: <testLibrary>::@class::C::@method::m
              staticType: int Function(int, String)
      getters
        #F7 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        static isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: int
            #E1 requiredPositional b
              firstFragment: #F5
              type: String
          returnType: int
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F6
      type: int Function(int, String)
      constantInitializer
        fragment: #F6
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F7
      returnType: int Function(int, String)
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_staticMethod_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = C.m;
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @27
                element: package:test/a.dart::@class::C
                staticType: null
              period: . @28
              identifier: SimpleIdentifier
                token: m @29
                element: package:test/a.dart::@class::C::@method::m
                staticType: int Function(int, String)
              element: package:test/a.dart::@class::C::@method::m
              staticType: int Function(int, String)
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int Function(int, String)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int Function(int, String)
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_staticMethod_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = p.C.m;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: C @34
                  element: package:test/a.dart::@class::C
                  staticType: null
                element: package:test/a.dart::@class::C
                staticType: null
              operator: . @35
              propertyName: SimpleIdentifier
                token: m @36
                element: package:test/a.dart::@class::C::@method::m
                staticType: int Function(int, String)
              staticType: int Function(int, String)
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: int Function(int, String)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: int Function(int, String)
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_staticMethod_ofExtension() async {
    var library = await buildLibrary('''
class A {}
extension E on A {
  static void f() {}
}
const x = E.f;
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
      extensions
        #F3 extension E (nameOffset:21) (firstTokenOffset:11) (offset:21)
          element: <testLibrary>::@extension::E
          methods
            #F4 isOriginDeclaration f (nameOffset:44) (firstTokenOffset:32) (offset:44)
              element: <testLibrary>::@extension::E::@method::f
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration x (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: E @63
                element: <testLibrary>::@extension::E
                staticType: null
              period: . @64
              identifier: SimpleIdentifier
                token: f @65
                element: <testLibrary>::@extension::E::@method::f
                staticType: void Function()
              element: <testLibrary>::@extension::E::@method::f
              staticType: void Function()
      getters
        #F6 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::x
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      onDeclaration: <testLibrary>::@class::A
      methods
        static isOriginDeclaration f
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: #F4
          returnType: void
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F5
      type: void Function()
      constantInitializer
        fragment: #F5
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F6
      returnType: void Function()
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_reference_topLevelFunction() async {
    var library = await buildLibrary(r'''
foo() {}
const V = foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @19
              element: <testLibrary>::@function::foo
              staticType: dynamic Function()
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::V
      functions
        #F3 isOriginDeclaration foo (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::foo
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic Function()
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: dynamic Function()
      variable: <testLibrary>::@topLevelVariable::V
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: dynamic
''');
  }

  test_const_reference_topLevelFunction_generic() async {
    var library = await buildLibrary(r'''
R foo<P, R>(P p) {}
const V = foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @30
              element: <testLibrary>::@function::foo
              staticType: R Function<P, R>(P)
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::V
      functions
        #F3 isOriginDeclaration foo (nameOffset:2) (firstTokenOffset:0) (offset:2)
          element: <testLibrary>::@function::foo
          typeParameters
            #F4 P (nameOffset:6) (firstTokenOffset:6) (offset:6)
              element: #E0 P
            #F5 R (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E1 R
          formalParameters
            #F6 requiredPositional p (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@function::foo::@formalParameter::p
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: R Function<P, R>(P)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: R Function<P, R>(P)
      variable: <testLibrary>::@topLevelVariable::V
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      typeParameters
        #E0 P
          firstFragment: #F4
        #E1 R
          firstFragment: #F5
      formalParameters
        #E2 requiredPositional p
          firstFragment: #F6
          type: P
      returnType: R
''');
  }

  test_const_reference_topLevelFunction_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
foo() {}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const V = foo;
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
        #F1 hasInitializer isOriginDeclaration V (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @27
              element: package:test/a.dart::@function::foo
              staticType: dynamic Function()
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic Function()
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: dynamic Function()
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_topLevelFunction_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
foo() {}
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const V = p.foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @32
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @33
              identifier: SimpleIdentifier
                token: foo @34
                element: package:test/a.dart::@function::foo
                staticType: dynamic Function()
              element: package:test/a.dart::@function::foo
              staticType: dynamic Function()
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic Function()
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: dynamic Function()
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_topLevelVariable() async {
    var library = await buildLibrary(r'''
const A = 1;
const B = A + 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration A (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::A
          initializer: expression_0
            IntegerLiteral
              literal: 1 @10
              staticType: int
        #F2 hasInitializer isOriginDeclaration B (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::B
          initializer: expression_1
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @23
                element: <testLibrary>::@getter::A
                staticType: int
              operator: + @25
              rightOperand: IntegerLiteral
                literal: 2 @27
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      getters
        #F3 isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::A
        #F4 isOriginVariable B (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::B
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::A
    const hasImplicitType hasInitializer isOriginDeclaration B
      reference: <testLibrary>::@topLevelVariable::B
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::B
  getters
    static isOriginVariable A
      reference: <testLibrary>::@getter::A
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::A
    static isOriginVariable B
      reference: <testLibrary>::@getter::B
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::B
''');
  }

  test_const_reference_topLevelVariable_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const A = 1;
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const B = A + 2;
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
        #F1 hasInitializer isOriginDeclaration B (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::B
          initializer: expression_0
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @27
                element: package:test/a.dart::@getter::A
                staticType: int
              operator: + @29
              rightOperand: IntegerLiteral
                literal: 2 @31
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      getters
        #F2 isOriginVariable B (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::B
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration B
      reference: <testLibrary>::@topLevelVariable::B
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::B
  getters
    static isOriginVariable B
      reference: <testLibrary>::@getter::B
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::B
''');
  }

  test_const_reference_topLevelVariable_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
const A = 1;
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const B = p.A + 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration B (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::B
          initializer: expression_0
            BinaryExpression
              leftOperand: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: A @34
                  element: package:test/a.dart::@getter::A
                  staticType: int
                element: package:test/a.dart::@getter::A
                staticType: int
              operator: + @36
              rightOperand: IntegerLiteral
                literal: 2 @38
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      getters
        #F2 isOriginVariable B (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::B
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration B
      reference: <testLibrary>::@topLevelVariable::B
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::B
  getters
    static isOriginVariable B
      reference: <testLibrary>::@getter::B
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::B
''');
  }

  test_const_reference_type() async {
    var library = await buildLibrary(r'''
class C {}
class D<T> {}
enum E {a, b, c}
typedef F(int a, String b);
const vDynamic = dynamic;
const vNull = Null;
const vObject = Object;
const vClass = C;
const vGenericClass = D;
const vEnum = E;
const vFunctionTypeAlias = F;
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::D
          typeParameters
            #F4 T (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: #E0 T
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      enums
        #F6 enum E (nameOffset:30) (firstTokenOffset:25) (offset:30)
          element: <testLibrary>::@enum::E
          fields
            #F7 hasInitializer isOriginDeclaration a (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F8 hasInitializer isOriginDeclaration b (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F9 hasInitializer isOriginDeclaration c (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F10 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibrary>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F11 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F12 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@enum::E::@getter::a
            #F13 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::E::@getter::b
            #F14 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@enum::E::@getter::c
            #F15 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@enum::E::@getter::values
      typeAliases
        #F16 F (nameOffset:50) (firstTokenOffset:42) (offset:50)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F17 hasInitializer isOriginDeclaration vDynamic (nameOffset:76) (firstTokenOffset:76) (offset:76)
          element: <testLibrary>::@topLevelVariable::vDynamic
          initializer: expression_4
            TypeLiteral
              type: NamedType
                name: dynamic @87
                element: dynamic
                type: dynamic
              staticType: Type
        #F18 hasInitializer isOriginDeclaration vNull (nameOffset:102) (firstTokenOffset:102) (offset:102)
          element: <testLibrary>::@topLevelVariable::vNull
          initializer: expression_5
            TypeLiteral
              type: NamedType
                name: Null @110
                element: dart:core::@class::Null
                type: Null
              staticType: Type
        #F19 hasInitializer isOriginDeclaration vObject (nameOffset:122) (firstTokenOffset:122) (offset:122)
          element: <testLibrary>::@topLevelVariable::vObject
          initializer: expression_6
            TypeLiteral
              type: NamedType
                name: Object @132
                element: dart:core::@class::Object
                type: Object
              staticType: Type
        #F20 hasInitializer isOriginDeclaration vClass (nameOffset:146) (firstTokenOffset:146) (offset:146)
          element: <testLibrary>::@topLevelVariable::vClass
          initializer: expression_7
            TypeLiteral
              type: NamedType
                name: C @155
                element: <testLibrary>::@class::C
                type: C
              staticType: Type
        #F21 hasInitializer isOriginDeclaration vGenericClass (nameOffset:164) (firstTokenOffset:164) (offset:164)
          element: <testLibrary>::@topLevelVariable::vGenericClass
          initializer: expression_8
            TypeLiteral
              type: NamedType
                name: D @180
                element: <testLibrary>::@class::D
                type: D<dynamic>
              staticType: Type
        #F22 hasInitializer isOriginDeclaration vEnum (nameOffset:189) (firstTokenOffset:189) (offset:189)
          element: <testLibrary>::@topLevelVariable::vEnum
          initializer: expression_9
            TypeLiteral
              type: NamedType
                name: E @197
                element: <testLibrary>::@enum::E
                type: E
              staticType: Type
        #F23 hasInitializer isOriginDeclaration vFunctionTypeAlias (nameOffset:206) (firstTokenOffset:206) (offset:206)
          element: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
          initializer: expression_10
            TypeLiteral
              type: NamedType
                name: F @227
                element: <testLibrary>::@typeAlias::F
                type: dynamic Function(int, String)
                  alias: <testLibrary>::@typeAlias::F
              staticType: Type
      getters
        #F24 isOriginVariable vDynamic (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@getter::vDynamic
        #F25 isOriginVariable vNull (nameOffset:<null>) (firstTokenOffset:<null>) (offset:102)
          element: <testLibrary>::@getter::vNull
        #F26 isOriginVariable vObject (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
          element: <testLibrary>::@getter::vObject
        #F27 isOriginVariable vClass (nameOffset:<null>) (firstTokenOffset:<null>) (offset:146)
          element: <testLibrary>::@getter::vClass
        #F28 isOriginVariable vGenericClass (nameOffset:<null>) (firstTokenOffset:<null>) (offset:164)
          element: <testLibrary>::@getter::vGenericClass
        #F29 isOriginVariable vEnum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:189)
          element: <testLibrary>::@getter::vEnum
        #F30 isOriginVariable vFunctionTypeAlias (nameOffset:<null>) (firstTokenOffset:<null>) (offset:206)
          element: <testLibrary>::@getter::vFunctionTypeAlias
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F6
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F7
          type: E
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F8
          type: E
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F9
          type: E
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F10
          type: List<E>
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F11
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F12
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F13
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        static isOriginVariable c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F14
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F15
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F16
      aliasedType: dynamic Function(int, String)
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vDynamic
      reference: <testLibrary>::@topLevelVariable::vDynamic
      firstFragment: #F17
      type: Type
      constantInitializer
        fragment: #F17
        expression: expression_4
      getter: <testLibrary>::@getter::vDynamic
    const hasImplicitType hasInitializer isOriginDeclaration vNull
      reference: <testLibrary>::@topLevelVariable::vNull
      firstFragment: #F18
      type: Type
      constantInitializer
        fragment: #F18
        expression: expression_5
      getter: <testLibrary>::@getter::vNull
    const hasImplicitType hasInitializer isOriginDeclaration vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: #F19
      type: Type
      constantInitializer
        fragment: #F19
        expression: expression_6
      getter: <testLibrary>::@getter::vObject
    const hasImplicitType hasInitializer isOriginDeclaration vClass
      reference: <testLibrary>::@topLevelVariable::vClass
      firstFragment: #F20
      type: Type
      constantInitializer
        fragment: #F20
        expression: expression_7
      getter: <testLibrary>::@getter::vClass
    const hasImplicitType hasInitializer isOriginDeclaration vGenericClass
      reference: <testLibrary>::@topLevelVariable::vGenericClass
      firstFragment: #F21
      type: Type
      constantInitializer
        fragment: #F21
        expression: expression_8
      getter: <testLibrary>::@getter::vGenericClass
    const hasImplicitType hasInitializer isOriginDeclaration vEnum
      reference: <testLibrary>::@topLevelVariable::vEnum
      firstFragment: #F22
      type: Type
      constantInitializer
        fragment: #F22
        expression: expression_9
      getter: <testLibrary>::@getter::vEnum
    const hasImplicitType hasInitializer isOriginDeclaration vFunctionTypeAlias
      reference: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
      firstFragment: #F23
      type: Type
      constantInitializer
        fragment: #F23
        expression: expression_10
      getter: <testLibrary>::@getter::vFunctionTypeAlias
  getters
    static isOriginVariable vDynamic
      reference: <testLibrary>::@getter::vDynamic
      firstFragment: #F24
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vDynamic
    static isOriginVariable vNull
      reference: <testLibrary>::@getter::vNull
      firstFragment: #F25
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vNull
    static isOriginVariable vObject
      reference: <testLibrary>::@getter::vObject
      firstFragment: #F26
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vObject
    static isOriginVariable vClass
      reference: <testLibrary>::@getter::vClass
      firstFragment: #F27
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vClass
    static isOriginVariable vGenericClass
      reference: <testLibrary>::@getter::vGenericClass
      firstFragment: #F28
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vGenericClass
    static isOriginVariable vEnum
      reference: <testLibrary>::@getter::vEnum
      firstFragment: #F29
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vEnum
    static isOriginVariable vFunctionTypeAlias
      reference: <testLibrary>::@getter::vFunctionTypeAlias
      firstFragment: #F30
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
''');
  }

  test_const_reference_type_functionType() async {
    var library = await buildLibrary(r'''
typedef F();
class C {
  final f = <F>[];
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:19) (firstTokenOffset:13) (offset:19)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer isOriginDeclaration f (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::C::@getter::f
      typeAliases
        #F5 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasImplicitType hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: List<dynamic Function()>
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: List<dynamic Function()>
          variable: <testLibrary>::@class::C::@field::f
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F5
      aliasedType: dynamic Function()
''');
  }

  test_const_reference_type_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await buildLibrary(r'''
import 'a.dart';
const vClass = C;
const vEnum = E;
const vFunctionTypeAlias = F;
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
        #F1 hasInitializer isOriginDeclaration vClass (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::vClass
          initializer: expression_0
            TypeLiteral
              type: NamedType
                name: C @32
                element: package:test/a.dart::@class::C
                type: C
              staticType: Type
        #F2 hasInitializer isOriginDeclaration vEnum (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::vEnum
          initializer: expression_1
            TypeLiteral
              type: NamedType
                name: E @49
                element: package:test/a.dart::@enum::E
                type: E
              staticType: Type
        #F3 hasInitializer isOriginDeclaration vFunctionTypeAlias (nameOffset:58) (firstTokenOffset:58) (offset:58)
          element: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
          initializer: expression_2
            TypeLiteral
              type: NamedType
                name: F @79
                element: package:test/a.dart::@typeAlias::F
                type: dynamic Function(int, String)
                  alias: package:test/a.dart::@typeAlias::F
              staticType: Type
      getters
        #F4 isOriginVariable vClass (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::vClass
        #F5 isOriginVariable vEnum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::vEnum
        #F6 isOriginVariable vFunctionTypeAlias (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
          element: <testLibrary>::@getter::vFunctionTypeAlias
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vClass
      reference: <testLibrary>::@topLevelVariable::vClass
      firstFragment: #F1
      type: Type
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vClass
    const hasImplicitType hasInitializer isOriginDeclaration vEnum
      reference: <testLibrary>::@topLevelVariable::vEnum
      firstFragment: #F2
      type: Type
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vEnum
    const hasImplicitType hasInitializer isOriginDeclaration vFunctionTypeAlias
      reference: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
      firstFragment: #F3
      type: Type
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vFunctionTypeAlias
  getters
    static isOriginVariable vClass
      reference: <testLibrary>::@getter::vClass
      firstFragment: #F4
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vClass
    static isOriginVariable vEnum
      reference: <testLibrary>::@getter::vEnum
      firstFragment: #F5
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vEnum
    static isOriginVariable vFunctionTypeAlias
      reference: <testLibrary>::@getter::vFunctionTypeAlias
      firstFragment: #F6
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
''');
  }

  test_const_reference_type_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const vClass = p.C;
const vEnum = p.E;
const vFunctionTypeAlias = p.F;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vClass (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::vClass
          initializer: expression_0
            TypeLiteral
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: p @37
                  period: . @38
                  element: <testLibraryFragment>::@prefix2::p
                name: C @39
                element: package:test/a.dart::@class::C
                type: C
              staticType: Type
        #F2 hasInitializer isOriginDeclaration vEnum (nameOffset:48) (firstTokenOffset:48) (offset:48)
          element: <testLibrary>::@topLevelVariable::vEnum
          initializer: expression_1
            TypeLiteral
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: p @56
                  period: . @57
                  element: <testLibraryFragment>::@prefix2::p
                name: E @58
                element: package:test/a.dart::@enum::E
                type: E
              staticType: Type
        #F3 hasInitializer isOriginDeclaration vFunctionTypeAlias (nameOffset:67) (firstTokenOffset:67) (offset:67)
          element: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
          initializer: expression_2
            TypeLiteral
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: p @88
                  period: . @89
                  element: <testLibraryFragment>::@prefix2::p
                name: F @90
                element: package:test/a.dart::@typeAlias::F
                type: dynamic Function(int, String)
                  alias: package:test/a.dart::@typeAlias::F
              staticType: Type
      getters
        #F4 isOriginVariable vClass (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::vClass
        #F5 isOriginVariable vEnum (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@getter::vEnum
        #F6 isOriginVariable vFunctionTypeAlias (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
          element: <testLibrary>::@getter::vFunctionTypeAlias
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vClass
      reference: <testLibrary>::@topLevelVariable::vClass
      firstFragment: #F1
      type: Type
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vClass
    const hasImplicitType hasInitializer isOriginDeclaration vEnum
      reference: <testLibrary>::@topLevelVariable::vEnum
      firstFragment: #F2
      type: Type
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vEnum
    const hasImplicitType hasInitializer isOriginDeclaration vFunctionTypeAlias
      reference: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
      firstFragment: #F3
      type: Type
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vFunctionTypeAlias
  getters
    static isOriginVariable vClass
      reference: <testLibrary>::@getter::vClass
      firstFragment: #F4
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vClass
    static isOriginVariable vEnum
      reference: <testLibrary>::@getter::vEnum
      firstFragment: #F5
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vEnum
    static isOriginVariable vFunctionTypeAlias
      reference: <testLibrary>::@getter::vFunctionTypeAlias
      firstFragment: #F6
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
''');
  }

  test_const_reference_type_typeParameter() async {
    var library = await buildLibrary(r'''
class C<T> {
  final f = <T>[];
}
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 hasInitializer isOriginDeclaration f (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        final hasImplicitType hasInitializer isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: List<T>
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: List<T>
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_const_reference_unresolved_prefix0() async {
    var library = await buildLibrary(r'''
const V = foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @10
              element: <null>
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_unresolved_prefix1() async {
    var library = await buildLibrary(r'''
class C {}
const V = C.foo;
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 hasInitializer isOriginDeclaration V (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @21
                element: <testLibrary>::@class::C
                staticType: null
              period: . @22
              identifier: SimpleIdentifier
                token: foo @23
                element: <null>
                staticType: InvalidType
              element: <null>
              staticType: InvalidType
      getters
        #F4 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F3
      type: InvalidType
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F4
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_reference_unresolved_prefix2() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    var library = await buildLibrary(r'''
import 'foo.dart' as p;
const V = p.C.foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as p (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @21
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration V (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @34
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @35
                identifier: SimpleIdentifier
                  token: C @36
                  element: package:test/foo.dart::@class::C
                  staticType: null
                element: package:test/foo.dart::@class::C
                staticType: null
              operator: . @37
              propertyName: SimpleIdentifier
                token: foo @38
                element: <null>
                staticType: InvalidType
              staticType: InvalidType
      getters
        #F2 isOriginVariable V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::V
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::V
  getters
    static isOriginVariable V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V
''');
  }

  test_const_set_if() async {
    var library = await buildLibrary('''
const Object x = const <int>{if (true) 1};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: { @28
              elements
                IfElement
                  ifKeyword: if @29
                  leftParenthesis: ( @32
                  expression: BooleanLiteral
                    literal: true @33
                    staticType: bool
                  rightParenthesis: ) @37
                  thenElement: IntegerLiteral
                    literal: 1 @39
                    staticType: int
              rightBracket: } @40
              isMap: false
              staticType: Set<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_set_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await buildLibrary('''
const Object x = const {1};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              leftBracket: { @23
              elements
                IntegerLiteral
                  literal: 1 @24
                  staticType: int
              rightBracket: } @25
              isMap: false
              staticType: Set<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_set_spread() async {
    var library = await buildLibrary('''
const Object x = const <int>{...<int>{1}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: { @28
              elements
                SpreadElement
                  spreadOperator: ... @29
                  expression: SetOrMapLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: < @32
                      arguments
                        NamedType
                          name: int @33
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @36
                    leftBracket: { @37
                    elements
                      IntegerLiteral
                        literal: 1 @38
                        staticType: int
                    rightBracket: } @39
                    isMap: false
                    staticType: Set<int>
              rightBracket: } @40
              isMap: false
              staticType: Set<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_set_spread_null_aware() async {
    var library = await buildLibrary('''
const Object x = const <int>{...?<int>{1}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration x (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @27
              leftBracket: { @28
              elements
                SpreadElement
                  spreadOperator: ...? @29
                  expression: SetOrMapLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: < @33
                      arguments
                        NamedType
                          name: int @34
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @37
                    leftBracket: { @38
                    elements
                      IntegerLiteral
                        literal: 1 @39
                        staticType: int
                    rightBracket: } @40
                    isMap: false
                    staticType: Set<int>
              rightBracket: } @41
              isMap: false
              staticType: Set<int>
      getters
        #F2 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Object
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Object
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_const_topLevel_binary() async {
    var library = await buildLibrary(r'''
const vEqual = 1 == 2;
const vAnd = true && false;
const vOr = false || true;
const vBitXor = 1 ^ 2;
const vBitAnd = 1 & 2;
const vBitOr = 1 | 2;
const vBitShiftLeft = 1 << 2;
const vBitShiftRight = 1 >> 2;
const vAdd = 1 + 2;
const vSubtract = 1 - 2;
const vMiltiply = 1 * 2;
const vDivide = 1 / 2;
const vFloorDivide = 1 ~/ 2;
const vModulo = 1 % 2;
const vGreater = 1 > 2;
const vGreaterEqual = 1 >= 2;
const vLess = 1 < 2;
const vLessEqual = 1 <= 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vEqual (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vEqual
          initializer: expression_0
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @15
                staticType: int
              operator: == @17
              rightOperand: IntegerLiteral
                literal: 2 @20
                staticType: int
              element: dart:core::@class::num::@method::==
              staticInvokeType: bool Function(Object)
              staticType: bool
        #F2 hasInitializer isOriginDeclaration vAnd (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::vAnd
          initializer: expression_1
            BinaryExpression
              leftOperand: BooleanLiteral
                literal: true @36
                staticType: bool
              operator: && @41
              rightOperand: BooleanLiteral
                literal: false @44
                staticType: bool
              element: <null>
              staticInvokeType: null
              staticType: bool
        #F3 hasInitializer isOriginDeclaration vOr (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::vOr
          initializer: expression_2
            BinaryExpression
              leftOperand: BooleanLiteral
                literal: false @63
                staticType: bool
              operator: || @69
              rightOperand: BooleanLiteral
                literal: true @72
                staticType: bool
              element: <null>
              staticInvokeType: null
              staticType: bool
        #F4 hasInitializer isOriginDeclaration vBitXor (nameOffset:84) (firstTokenOffset:84) (offset:84)
          element: <testLibrary>::@topLevelVariable::vBitXor
          initializer: expression_3
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @94
                staticType: int
              operator: ^ @96
              rightOperand: IntegerLiteral
                literal: 2 @98
                staticType: int
              element: dart:core::@class::int::@method::^
              staticInvokeType: int Function(int)
              staticType: int
        #F5 hasInitializer isOriginDeclaration vBitAnd (nameOffset:107) (firstTokenOffset:107) (offset:107)
          element: <testLibrary>::@topLevelVariable::vBitAnd
          initializer: expression_4
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @117
                staticType: int
              operator: & @119
              rightOperand: IntegerLiteral
                literal: 2 @121
                staticType: int
              element: dart:core::@class::int::@method::&
              staticInvokeType: int Function(int)
              staticType: int
        #F6 hasInitializer isOriginDeclaration vBitOr (nameOffset:130) (firstTokenOffset:130) (offset:130)
          element: <testLibrary>::@topLevelVariable::vBitOr
          initializer: expression_5
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @139
                staticType: int
              operator: | @141
              rightOperand: IntegerLiteral
                literal: 2 @143
                staticType: int
              element: dart:core::@class::int::@method::|
              staticInvokeType: int Function(int)
              staticType: int
        #F7 hasInitializer isOriginDeclaration vBitShiftLeft (nameOffset:152) (firstTokenOffset:152) (offset:152)
          element: <testLibrary>::@topLevelVariable::vBitShiftLeft
          initializer: expression_6
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @168
                staticType: int
              operator: << @170
              rightOperand: IntegerLiteral
                literal: 2 @173
                staticType: int
              element: dart:core::@class::int::@method::<<
              staticInvokeType: int Function(int)
              staticType: int
        #F8 hasInitializer isOriginDeclaration vBitShiftRight (nameOffset:182) (firstTokenOffset:182) (offset:182)
          element: <testLibrary>::@topLevelVariable::vBitShiftRight
          initializer: expression_7
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @199
                staticType: int
              operator: >> @201
              rightOperand: IntegerLiteral
                literal: 2 @204
                staticType: int
              element: dart:core::@class::int::@method::>>
              staticInvokeType: int Function(int)
              staticType: int
        #F9 hasInitializer isOriginDeclaration vAdd (nameOffset:213) (firstTokenOffset:213) (offset:213)
          element: <testLibrary>::@topLevelVariable::vAdd
          initializer: expression_8
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @220
                staticType: int
              operator: + @222
              rightOperand: IntegerLiteral
                literal: 2 @224
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
        #F10 hasInitializer isOriginDeclaration vSubtract (nameOffset:233) (firstTokenOffset:233) (offset:233)
          element: <testLibrary>::@topLevelVariable::vSubtract
          initializer: expression_9
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @245
                staticType: int
              operator: - @247
              rightOperand: IntegerLiteral
                literal: 2 @249
                staticType: int
              element: dart:core::@class::num::@method::-
              staticInvokeType: num Function(num)
              staticType: int
        #F11 hasInitializer isOriginDeclaration vMiltiply (nameOffset:258) (firstTokenOffset:258) (offset:258)
          element: <testLibrary>::@topLevelVariable::vMiltiply
          initializer: expression_10
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @270
                staticType: int
              operator: * @272
              rightOperand: IntegerLiteral
                literal: 2 @274
                staticType: int
              element: dart:core::@class::num::@method::*
              staticInvokeType: num Function(num)
              staticType: int
        #F12 hasInitializer isOriginDeclaration vDivide (nameOffset:283) (firstTokenOffset:283) (offset:283)
          element: <testLibrary>::@topLevelVariable::vDivide
          initializer: expression_11
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @293
                staticType: int
              operator: / @295
              rightOperand: IntegerLiteral
                literal: 2 @297
                staticType: int
              element: dart:core::@class::num::@method::/
              staticInvokeType: double Function(num)
              staticType: double
        #F13 hasInitializer isOriginDeclaration vFloorDivide (nameOffset:306) (firstTokenOffset:306) (offset:306)
          element: <testLibrary>::@topLevelVariable::vFloorDivide
          initializer: expression_12
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @321
                staticType: int
              operator: ~/ @323
              rightOperand: IntegerLiteral
                literal: 2 @326
                staticType: int
              element: dart:core::@class::num::@method::~/
              staticInvokeType: int Function(num)
              staticType: int
        #F14 hasInitializer isOriginDeclaration vModulo (nameOffset:335) (firstTokenOffset:335) (offset:335)
          element: <testLibrary>::@topLevelVariable::vModulo
          initializer: expression_13
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @345
                staticType: int
              operator: % @347
              rightOperand: IntegerLiteral
                literal: 2 @349
                staticType: int
              element: dart:core::@class::num::@method::%
              staticInvokeType: num Function(num)
              staticType: int
        #F15 hasInitializer isOriginDeclaration vGreater (nameOffset:358) (firstTokenOffset:358) (offset:358)
          element: <testLibrary>::@topLevelVariable::vGreater
          initializer: expression_14
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @369
                staticType: int
              operator: > @371
              rightOperand: IntegerLiteral
                literal: 2 @373
                staticType: int
              element: dart:core::@class::num::@method::>
              staticInvokeType: bool Function(num)
              staticType: bool
        #F16 hasInitializer isOriginDeclaration vGreaterEqual (nameOffset:382) (firstTokenOffset:382) (offset:382)
          element: <testLibrary>::@topLevelVariable::vGreaterEqual
          initializer: expression_15
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @398
                staticType: int
              operator: >= @400
              rightOperand: IntegerLiteral
                literal: 2 @403
                staticType: int
              element: dart:core::@class::num::@method::>=
              staticInvokeType: bool Function(num)
              staticType: bool
        #F17 hasInitializer isOriginDeclaration vLess (nameOffset:412) (firstTokenOffset:412) (offset:412)
          element: <testLibrary>::@topLevelVariable::vLess
          initializer: expression_16
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @420
                staticType: int
              operator: < @422
              rightOperand: IntegerLiteral
                literal: 2 @424
                staticType: int
              element: dart:core::@class::num::@method::<
              staticInvokeType: bool Function(num)
              staticType: bool
        #F18 hasInitializer isOriginDeclaration vLessEqual (nameOffset:433) (firstTokenOffset:433) (offset:433)
          element: <testLibrary>::@topLevelVariable::vLessEqual
          initializer: expression_17
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @446
                staticType: int
              operator: <= @448
              rightOperand: IntegerLiteral
                literal: 2 @451
                staticType: int
              element: dart:core::@class::num::@method::<=
              staticInvokeType: bool Function(num)
              staticType: bool
      getters
        #F19 isOriginVariable vEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vEqual
        #F20 isOriginVariable vAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::vAnd
        #F21 isOriginVariable vOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::vOr
        #F22 isOriginVariable vBitXor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:84)
          element: <testLibrary>::@getter::vBitXor
        #F23 isOriginVariable vBitAnd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:107)
          element: <testLibrary>::@getter::vBitAnd
        #F24 isOriginVariable vBitOr (nameOffset:<null>) (firstTokenOffset:<null>) (offset:130)
          element: <testLibrary>::@getter::vBitOr
        #F25 isOriginVariable vBitShiftLeft (nameOffset:<null>) (firstTokenOffset:<null>) (offset:152)
          element: <testLibrary>::@getter::vBitShiftLeft
        #F26 isOriginVariable vBitShiftRight (nameOffset:<null>) (firstTokenOffset:<null>) (offset:182)
          element: <testLibrary>::@getter::vBitShiftRight
        #F27 isOriginVariable vAdd (nameOffset:<null>) (firstTokenOffset:<null>) (offset:213)
          element: <testLibrary>::@getter::vAdd
        #F28 isOriginVariable vSubtract (nameOffset:<null>) (firstTokenOffset:<null>) (offset:233)
          element: <testLibrary>::@getter::vSubtract
        #F29 isOriginVariable vMiltiply (nameOffset:<null>) (firstTokenOffset:<null>) (offset:258)
          element: <testLibrary>::@getter::vMiltiply
        #F30 isOriginVariable vDivide (nameOffset:<null>) (firstTokenOffset:<null>) (offset:283)
          element: <testLibrary>::@getter::vDivide
        #F31 isOriginVariable vFloorDivide (nameOffset:<null>) (firstTokenOffset:<null>) (offset:306)
          element: <testLibrary>::@getter::vFloorDivide
        #F32 isOriginVariable vModulo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:335)
          element: <testLibrary>::@getter::vModulo
        #F33 isOriginVariable vGreater (nameOffset:<null>) (firstTokenOffset:<null>) (offset:358)
          element: <testLibrary>::@getter::vGreater
        #F34 isOriginVariable vGreaterEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:382)
          element: <testLibrary>::@getter::vGreaterEqual
        #F35 isOriginVariable vLess (nameOffset:<null>) (firstTokenOffset:<null>) (offset:412)
          element: <testLibrary>::@getter::vLess
        #F36 isOriginVariable vLessEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:433)
          element: <testLibrary>::@getter::vLessEqual
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vEqual
      reference: <testLibrary>::@topLevelVariable::vEqual
      firstFragment: #F1
      type: bool
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vEqual
    const hasImplicitType hasInitializer isOriginDeclaration vAnd
      reference: <testLibrary>::@topLevelVariable::vAnd
      firstFragment: #F2
      type: bool
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vAnd
    const hasImplicitType hasInitializer isOriginDeclaration vOr
      reference: <testLibrary>::@topLevelVariable::vOr
      firstFragment: #F3
      type: bool
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vOr
    const hasImplicitType hasInitializer isOriginDeclaration vBitXor
      reference: <testLibrary>::@topLevelVariable::vBitXor
      firstFragment: #F4
      type: int
      constantInitializer
        fragment: #F4
        expression: expression_3
      getter: <testLibrary>::@getter::vBitXor
    const hasImplicitType hasInitializer isOriginDeclaration vBitAnd
      reference: <testLibrary>::@topLevelVariable::vBitAnd
      firstFragment: #F5
      type: int
      constantInitializer
        fragment: #F5
        expression: expression_4
      getter: <testLibrary>::@getter::vBitAnd
    const hasImplicitType hasInitializer isOriginDeclaration vBitOr
      reference: <testLibrary>::@topLevelVariable::vBitOr
      firstFragment: #F6
      type: int
      constantInitializer
        fragment: #F6
        expression: expression_5
      getter: <testLibrary>::@getter::vBitOr
    const hasImplicitType hasInitializer isOriginDeclaration vBitShiftLeft
      reference: <testLibrary>::@topLevelVariable::vBitShiftLeft
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_6
      getter: <testLibrary>::@getter::vBitShiftLeft
    const hasImplicitType hasInitializer isOriginDeclaration vBitShiftRight
      reference: <testLibrary>::@topLevelVariable::vBitShiftRight
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_7
      getter: <testLibrary>::@getter::vBitShiftRight
    const hasImplicitType hasInitializer isOriginDeclaration vAdd
      reference: <testLibrary>::@topLevelVariable::vAdd
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_8
      getter: <testLibrary>::@getter::vAdd
    const hasImplicitType hasInitializer isOriginDeclaration vSubtract
      reference: <testLibrary>::@topLevelVariable::vSubtract
      firstFragment: #F10
      type: int
      constantInitializer
        fragment: #F10
        expression: expression_9
      getter: <testLibrary>::@getter::vSubtract
    const hasImplicitType hasInitializer isOriginDeclaration vMiltiply
      reference: <testLibrary>::@topLevelVariable::vMiltiply
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_10
      getter: <testLibrary>::@getter::vMiltiply
    const hasImplicitType hasInitializer isOriginDeclaration vDivide
      reference: <testLibrary>::@topLevelVariable::vDivide
      firstFragment: #F12
      type: double
      constantInitializer
        fragment: #F12
        expression: expression_11
      getter: <testLibrary>::@getter::vDivide
    const hasImplicitType hasInitializer isOriginDeclaration vFloorDivide
      reference: <testLibrary>::@topLevelVariable::vFloorDivide
      firstFragment: #F13
      type: int
      constantInitializer
        fragment: #F13
        expression: expression_12
      getter: <testLibrary>::@getter::vFloorDivide
    const hasImplicitType hasInitializer isOriginDeclaration vModulo
      reference: <testLibrary>::@topLevelVariable::vModulo
      firstFragment: #F14
      type: int
      constantInitializer
        fragment: #F14
        expression: expression_13
      getter: <testLibrary>::@getter::vModulo
    const hasImplicitType hasInitializer isOriginDeclaration vGreater
      reference: <testLibrary>::@topLevelVariable::vGreater
      firstFragment: #F15
      type: bool
      constantInitializer
        fragment: #F15
        expression: expression_14
      getter: <testLibrary>::@getter::vGreater
    const hasImplicitType hasInitializer isOriginDeclaration vGreaterEqual
      reference: <testLibrary>::@topLevelVariable::vGreaterEqual
      firstFragment: #F16
      type: bool
      constantInitializer
        fragment: #F16
        expression: expression_15
      getter: <testLibrary>::@getter::vGreaterEqual
    const hasImplicitType hasInitializer isOriginDeclaration vLess
      reference: <testLibrary>::@topLevelVariable::vLess
      firstFragment: #F17
      type: bool
      constantInitializer
        fragment: #F17
        expression: expression_16
      getter: <testLibrary>::@getter::vLess
    const hasImplicitType hasInitializer isOriginDeclaration vLessEqual
      reference: <testLibrary>::@topLevelVariable::vLessEqual
      firstFragment: #F18
      type: bool
      constantInitializer
        fragment: #F18
        expression: expression_17
      getter: <testLibrary>::@getter::vLessEqual
  getters
    static isOriginVariable vEqual
      reference: <testLibrary>::@getter::vEqual
      firstFragment: #F19
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vEqual
    static isOriginVariable vAnd
      reference: <testLibrary>::@getter::vAnd
      firstFragment: #F20
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vAnd
    static isOriginVariable vOr
      reference: <testLibrary>::@getter::vOr
      firstFragment: #F21
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vOr
    static isOriginVariable vBitXor
      reference: <testLibrary>::@getter::vBitXor
      firstFragment: #F22
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitXor
    static isOriginVariable vBitAnd
      reference: <testLibrary>::@getter::vBitAnd
      firstFragment: #F23
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitAnd
    static isOriginVariable vBitOr
      reference: <testLibrary>::@getter::vBitOr
      firstFragment: #F24
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitOr
    static isOriginVariable vBitShiftLeft
      reference: <testLibrary>::@getter::vBitShiftLeft
      firstFragment: #F25
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftLeft
    static isOriginVariable vBitShiftRight
      reference: <testLibrary>::@getter::vBitShiftRight
      firstFragment: #F26
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vBitShiftRight
    static isOriginVariable vAdd
      reference: <testLibrary>::@getter::vAdd
      firstFragment: #F27
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vAdd
    static isOriginVariable vSubtract
      reference: <testLibrary>::@getter::vSubtract
      firstFragment: #F28
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vSubtract
    static isOriginVariable vMiltiply
      reference: <testLibrary>::@getter::vMiltiply
      firstFragment: #F29
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vMiltiply
    static isOriginVariable vDivide
      reference: <testLibrary>::@getter::vDivide
      firstFragment: #F30
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDivide
    static isOriginVariable vFloorDivide
      reference: <testLibrary>::@getter::vFloorDivide
      firstFragment: #F31
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vFloorDivide
    static isOriginVariable vModulo
      reference: <testLibrary>::@getter::vModulo
      firstFragment: #F32
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vModulo
    static isOriginVariable vGreater
      reference: <testLibrary>::@getter::vGreater
      firstFragment: #F33
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreater
    static isOriginVariable vGreaterEqual
      reference: <testLibrary>::@getter::vGreaterEqual
      firstFragment: #F34
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vGreaterEqual
    static isOriginVariable vLess
      reference: <testLibrary>::@getter::vLess
      firstFragment: #F35
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLess
    static isOriginVariable vLessEqual
      reference: <testLibrary>::@getter::vLessEqual
      firstFragment: #F36
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vLessEqual
''');
  }

  test_const_topLevel_conditional() async {
    var library = await buildLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vConditional (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vConditional
          initializer: expression_0
            ConditionalExpression
              condition: ParenthesizedExpression
                leftParenthesis: ( @21
                expression: BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @22
                    staticType: int
                  operator: == @24
                  rightOperand: IntegerLiteral
                    literal: 2 @27
                    staticType: int
                  element: dart:core::@class::num::@method::==
                  staticInvokeType: bool Function(Object)
                  staticType: bool
                rightParenthesis: ) @28
                staticType: bool
              question: ? @30
              thenExpression: IntegerLiteral
                literal: 11 @32
                staticType: int
              colon: : @35
              elseExpression: IntegerLiteral
                literal: 22 @37
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable vConditional (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vConditional
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vConditional
      reference: <testLibrary>::@topLevelVariable::vConditional
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vConditional
  getters
    static isOriginVariable vConditional
      reference: <testLibrary>::@getter::vConditional
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vConditional
''');
  }

  test_const_topLevel_identical() async {
    var library = await buildLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vIdentical (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vIdentical
          initializer: expression_0
            ConditionalExpression
              condition: ParenthesizedExpression
                leftParenthesis: ( @19
                expression: BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @20
                    staticType: int
                  operator: == @22
                  rightOperand: IntegerLiteral
                    literal: 2 @25
                    staticType: int
                  element: dart:core::@class::num::@method::==
                  staticInvokeType: bool Function(Object)
                  staticType: bool
                rightParenthesis: ) @26
                staticType: bool
              question: ? @28
              thenExpression: IntegerLiteral
                literal: 11 @30
                staticType: int
              colon: : @33
              elseExpression: IntegerLiteral
                literal: 22 @35
                staticType: int
              staticType: int
      getters
        #F2 isOriginVariable vIdentical (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vIdentical
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vIdentical
      reference: <testLibrary>::@topLevelVariable::vIdentical
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vIdentical
  getters
    static isOriginVariable vIdentical
      reference: <testLibrary>::@getter::vIdentical
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIdentical
''');
  }

  test_const_topLevel_ifNull() async {
    var library = await buildLibrary(r'''
const vIfNull = 1 ?? 2.0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vIfNull (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vIfNull
          initializer: expression_0
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @16
                staticType: int
              operator: ?? @18
              rightOperand: DoubleLiteral
                literal: 2.0 @21
                staticType: double
              element: <null>
              staticInvokeType: null
              staticType: num
      getters
        #F2 isOriginVariable vIfNull (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vIfNull
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vIfNull
      reference: <testLibrary>::@topLevelVariable::vIfNull
      firstFragment: #F1
      type: num
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vIfNull
  getters
    static isOriginVariable vIfNull
      reference: <testLibrary>::@getter::vIfNull
      firstFragment: #F2
      returnType: num
      variable: <testLibrary>::@topLevelVariable::vIfNull
''');
  }

  test_const_topLevel_literal() async {
    var library = await buildLibrary(r'''
const vNull = null;
const vBoolFalse = false;
const vBoolTrue = true;
const vIntPositive = 1;
const vIntNegative = -2;
const vIntLong1 = 0x7FFFFFFFFFFFFFFF;
const vIntLong2 = 0xFFFFFFFFFFFFFFFF;
const vIntLong3 = 0x8000000000000000;
const vDouble = 2.3;
const vString = 'abc';
const vStringConcat = 'aaa' 'bbb';
const vStringInterpolation = 'aaa ${true} ${42} bbb';
const vSymbol = #aaa.bbb.ccc;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vNull (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vNull
          initializer: expression_0
            NullLiteral
              literal: null @14
              staticType: Null
        #F2 hasInitializer isOriginDeclaration vBoolFalse (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::vBoolFalse
          initializer: expression_1
            BooleanLiteral
              literal: false @39
              staticType: bool
        #F3 hasInitializer isOriginDeclaration vBoolTrue (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::vBoolTrue
          initializer: expression_2
            BooleanLiteral
              literal: true @64
              staticType: bool
        #F4 hasInitializer isOriginDeclaration vIntPositive (nameOffset:76) (firstTokenOffset:76) (offset:76)
          element: <testLibrary>::@topLevelVariable::vIntPositive
          initializer: expression_3
            IntegerLiteral
              literal: 1 @91
              staticType: int
        #F5 hasInitializer isOriginDeclaration vIntNegative (nameOffset:100) (firstTokenOffset:100) (offset:100)
          element: <testLibrary>::@topLevelVariable::vIntNegative
          initializer: expression_4
            PrefixExpression
              operator: - @115
              operand: IntegerLiteral
                literal: 2 @116
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
        #F6 hasInitializer isOriginDeclaration vIntLong1 (nameOffset:125) (firstTokenOffset:125) (offset:125)
          element: <testLibrary>::@topLevelVariable::vIntLong1
          initializer: expression_5
            IntegerLiteral
              literal: 0x7FFFFFFFFFFFFFFF @137
              staticType: int
        #F7 hasInitializer isOriginDeclaration vIntLong2 (nameOffset:163) (firstTokenOffset:163) (offset:163)
          element: <testLibrary>::@topLevelVariable::vIntLong2
          initializer: expression_6
            IntegerLiteral
              literal: 0xFFFFFFFFFFFFFFFF @175
              staticType: int
        #F8 hasInitializer isOriginDeclaration vIntLong3 (nameOffset:201) (firstTokenOffset:201) (offset:201)
          element: <testLibrary>::@topLevelVariable::vIntLong3
          initializer: expression_7
            IntegerLiteral
              literal: 0x8000000000000000 @213
              staticType: int
        #F9 hasInitializer isOriginDeclaration vDouble (nameOffset:239) (firstTokenOffset:239) (offset:239)
          element: <testLibrary>::@topLevelVariable::vDouble
          initializer: expression_8
            DoubleLiteral
              literal: 2.3 @249
              staticType: double
        #F10 hasInitializer isOriginDeclaration vString (nameOffset:260) (firstTokenOffset:260) (offset:260)
          element: <testLibrary>::@topLevelVariable::vString
          initializer: expression_9
            SimpleStringLiteral
              literal: 'abc' @270
        #F11 hasInitializer isOriginDeclaration vStringConcat (nameOffset:283) (firstTokenOffset:283) (offset:283)
          element: <testLibrary>::@topLevelVariable::vStringConcat
          initializer: expression_10
            AdjacentStrings
              strings
                SimpleStringLiteral
                  literal: 'aaa' @299
                SimpleStringLiteral
                  literal: 'bbb' @305
              staticType: String
              stringValue: aaabbb
        #F12 hasInitializer isOriginDeclaration vStringInterpolation (nameOffset:318) (firstTokenOffset:318) (offset:318)
          element: <testLibrary>::@topLevelVariable::vStringInterpolation
          initializer: expression_11
            StringInterpolation
              elements
                InterpolationString
                  contents: 'aaa  @341
                InterpolationExpression
                  leftBracket: ${ @346
                  expression: BooleanLiteral
                    literal: true @348
                    staticType: bool
                  rightBracket: } @352
                InterpolationString
                  contents:   @353
                InterpolationExpression
                  leftBracket: ${ @354
                  expression: IntegerLiteral
                    literal: 42 @356
                    staticType: int
                  rightBracket: } @358
                InterpolationString
                  contents:  bbb' @359
              staticType: String
              stringValue: null
        #F13 hasInitializer isOriginDeclaration vSymbol (nameOffset:372) (firstTokenOffset:372) (offset:372)
          element: <testLibrary>::@topLevelVariable::vSymbol
          initializer: expression_12
            SymbolLiteral
              poundSign: # @382
              components
                aaa
                  offset: 383
                bbb
                  offset: 387
                ccc
                  offset: 391
      getters
        #F14 isOriginVariable vNull (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vNull
        #F15 isOriginVariable vBoolFalse (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::vBoolFalse
        #F16 isOriginVariable vBoolTrue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::vBoolTrue
        #F17 isOriginVariable vIntPositive (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
          element: <testLibrary>::@getter::vIntPositive
        #F18 isOriginVariable vIntNegative (nameOffset:<null>) (firstTokenOffset:<null>) (offset:100)
          element: <testLibrary>::@getter::vIntNegative
        #F19 isOriginVariable vIntLong1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:125)
          element: <testLibrary>::@getter::vIntLong1
        #F20 isOriginVariable vIntLong2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:163)
          element: <testLibrary>::@getter::vIntLong2
        #F21 isOriginVariable vIntLong3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:201)
          element: <testLibrary>::@getter::vIntLong3
        #F22 isOriginVariable vDouble (nameOffset:<null>) (firstTokenOffset:<null>) (offset:239)
          element: <testLibrary>::@getter::vDouble
        #F23 isOriginVariable vString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:260)
          element: <testLibrary>::@getter::vString
        #F24 isOriginVariable vStringConcat (nameOffset:<null>) (firstTokenOffset:<null>) (offset:283)
          element: <testLibrary>::@getter::vStringConcat
        #F25 isOriginVariable vStringInterpolation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:318)
          element: <testLibrary>::@getter::vStringInterpolation
        #F26 isOriginVariable vSymbol (nameOffset:<null>) (firstTokenOffset:<null>) (offset:372)
          element: <testLibrary>::@getter::vSymbol
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vNull
      reference: <testLibrary>::@topLevelVariable::vNull
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vNull
    const hasImplicitType hasInitializer isOriginDeclaration vBoolFalse
      reference: <testLibrary>::@topLevelVariable::vBoolFalse
      firstFragment: #F2
      type: bool
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vBoolFalse
    const hasImplicitType hasInitializer isOriginDeclaration vBoolTrue
      reference: <testLibrary>::@topLevelVariable::vBoolTrue
      firstFragment: #F3
      type: bool
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vBoolTrue
    const hasImplicitType hasInitializer isOriginDeclaration vIntPositive
      reference: <testLibrary>::@topLevelVariable::vIntPositive
      firstFragment: #F4
      type: int
      constantInitializer
        fragment: #F4
        expression: expression_3
      getter: <testLibrary>::@getter::vIntPositive
    const hasImplicitType hasInitializer isOriginDeclaration vIntNegative
      reference: <testLibrary>::@topLevelVariable::vIntNegative
      firstFragment: #F5
      type: int
      constantInitializer
        fragment: #F5
        expression: expression_4
      getter: <testLibrary>::@getter::vIntNegative
    const hasImplicitType hasInitializer isOriginDeclaration vIntLong1
      reference: <testLibrary>::@topLevelVariable::vIntLong1
      firstFragment: #F6
      type: int
      constantInitializer
        fragment: #F6
        expression: expression_5
      getter: <testLibrary>::@getter::vIntLong1
    const hasImplicitType hasInitializer isOriginDeclaration vIntLong2
      reference: <testLibrary>::@topLevelVariable::vIntLong2
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_6
      getter: <testLibrary>::@getter::vIntLong2
    const hasImplicitType hasInitializer isOriginDeclaration vIntLong3
      reference: <testLibrary>::@topLevelVariable::vIntLong3
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_7
      getter: <testLibrary>::@getter::vIntLong3
    const hasImplicitType hasInitializer isOriginDeclaration vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: #F9
      type: double
      constantInitializer
        fragment: #F9
        expression: expression_8
      getter: <testLibrary>::@getter::vDouble
    const hasImplicitType hasInitializer isOriginDeclaration vString
      reference: <testLibrary>::@topLevelVariable::vString
      firstFragment: #F10
      type: String
      constantInitializer
        fragment: #F10
        expression: expression_9
      getter: <testLibrary>::@getter::vString
    const hasImplicitType hasInitializer isOriginDeclaration vStringConcat
      reference: <testLibrary>::@topLevelVariable::vStringConcat
      firstFragment: #F11
      type: String
      constantInitializer
        fragment: #F11
        expression: expression_10
      getter: <testLibrary>::@getter::vStringConcat
    const hasImplicitType hasInitializer isOriginDeclaration vStringInterpolation
      reference: <testLibrary>::@topLevelVariable::vStringInterpolation
      firstFragment: #F12
      type: String
      constantInitializer
        fragment: #F12
        expression: expression_11
      getter: <testLibrary>::@getter::vStringInterpolation
    const hasImplicitType hasInitializer isOriginDeclaration vSymbol
      reference: <testLibrary>::@topLevelVariable::vSymbol
      firstFragment: #F13
      type: Symbol
      constantInitializer
        fragment: #F13
        expression: expression_12
      getter: <testLibrary>::@getter::vSymbol
  getters
    static isOriginVariable vNull
      reference: <testLibrary>::@getter::vNull
      firstFragment: #F14
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::vNull
    static isOriginVariable vBoolFalse
      reference: <testLibrary>::@getter::vBoolFalse
      firstFragment: #F15
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vBoolFalse
    static isOriginVariable vBoolTrue
      reference: <testLibrary>::@getter::vBoolTrue
      firstFragment: #F16
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vBoolTrue
    static isOriginVariable vIntPositive
      reference: <testLibrary>::@getter::vIntPositive
      firstFragment: #F17
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIntPositive
    static isOriginVariable vIntNegative
      reference: <testLibrary>::@getter::vIntNegative
      firstFragment: #F18
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIntNegative
    static isOriginVariable vIntLong1
      reference: <testLibrary>::@getter::vIntLong1
      firstFragment: #F19
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIntLong1
    static isOriginVariable vIntLong2
      reference: <testLibrary>::@getter::vIntLong2
      firstFragment: #F20
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIntLong2
    static isOriginVariable vIntLong3
      reference: <testLibrary>::@getter::vIntLong3
      firstFragment: #F21
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIntLong3
    static isOriginVariable vDouble
      reference: <testLibrary>::@getter::vDouble
      firstFragment: #F22
      returnType: double
      variable: <testLibrary>::@topLevelVariable::vDouble
    static isOriginVariable vString
      reference: <testLibrary>::@getter::vString
      firstFragment: #F23
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vString
    static isOriginVariable vStringConcat
      reference: <testLibrary>::@getter::vStringConcat
      firstFragment: #F24
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vStringConcat
    static isOriginVariable vStringInterpolation
      reference: <testLibrary>::@getter::vStringInterpolation
      firstFragment: #F25
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vStringInterpolation
    static isOriginVariable vSymbol
      reference: <testLibrary>::@getter::vSymbol
      firstFragment: #F26
      returnType: Symbol
      variable: <testLibrary>::@topLevelVariable::vSymbol
''');
  }

  test_const_topLevel_methodInvocation_questionPeriod() async {
    var library = await buildLibrary(r'''
const int? a = 0;
const b = a?.toString();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration a (nameOffset:11) (firstTokenOffset:11) (offset:11)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @15
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            MethodInvocation
              target: SimpleIdentifier
                token: a @28
                element: <testLibrary>::@getter::a
                staticType: int?
              operator: ?. @29
              methodName: SimpleIdentifier
                token: toString @31
                element: dart:core::@class::int::@method::toString
                staticType: String Function()
              argumentList: ArgumentList
                leftParenthesis: ( @39
                rightParenthesis: ) @40
              staticInvokeType: String Function()
              staticType: String?
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int?
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: String?
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int?
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: String?
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_topLevel_methodInvocation_questionPeriodPeriod() async {
    var library = await buildLibrary(r'''
const int? a = 0;
const b = a?..toString();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration a (nameOffset:11) (firstTokenOffset:11) (offset:11)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @15
              staticType: int
        #F2 hasInitializer isOriginDeclaration b (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            CascadeExpression
              target: SimpleIdentifier
                token: a @28
                element: <testLibrary>::@getter::a
                staticType: int?
              cascadeSections
                MethodInvocation
                  operator: ?.. @29
                  methodName: SimpleIdentifier
                    token: toString @32
                    element: dart:core::@class::int::@method::toString
                    staticType: String Function()
                  argumentList: ArgumentList
                    leftParenthesis: ( @40
                    rightParenthesis: ) @41
                  staticInvokeType: String Function()
                  staticType: String
              staticType: int?
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int?
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int?
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int?
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int?
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_topLevel_nullAware_propertyAccess() async {
    var library = await buildLibrary(r'''
const String? a = '';

const List<int?> b = [
  a?.length,
];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration a (nameOffset:14) (firstTokenOffset:14) (offset:14)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            SimpleStringLiteral
              literal: '' @18
        #F2 hasInitializer isOriginDeclaration b (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            ListLiteral
              leftBracket: [ @44
              elements
                PropertyAccess
                  target: SimpleIdentifier
                    token: a @48
                    element: <testLibrary>::@getter::a
                    staticType: String?
                  operator: ?. @49
                  propertyName: SimpleIdentifier
                    token: length @51
                    element: dart:core::@class::String::@getter::length
                    staticType: int
                  staticType: int?
              rightBracket: ] @59
              staticType: List<int?>
      getters
        #F3 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
          element: <testLibrary>::@getter::a
        #F4 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::b
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: String?
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: List<int?>
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: String?
      variable: <testLibrary>::@topLevelVariable::a
    static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: List<int?>
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_const_topLevel_parenthesis() async {
    var library = await buildLibrary(r'''
const int v1 = (1 + 2) * 3;
const int v2 = -(1 + 2);
const int v3 = ('aaa' + 'bbb').length;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v1 (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::v1
          initializer: expression_0
            BinaryExpression
              leftOperand: ParenthesizedExpression
                leftParenthesis: ( @15
                expression: BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @16
                    staticType: int
                  operator: + @18
                  rightOperand: IntegerLiteral
                    literal: 2 @20
                    staticType: int
                  element: dart:core::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
                rightParenthesis: ) @21
                staticType: int
              operator: * @23
              rightOperand: IntegerLiteral
                literal: 3 @25
                staticType: int
              element: dart:core::@class::num::@method::*
              staticInvokeType: num Function(num)
              staticType: int
        #F2 hasInitializer isOriginDeclaration v2 (nameOffset:38) (firstTokenOffset:38) (offset:38)
          element: <testLibrary>::@topLevelVariable::v2
          initializer: expression_1
            PrefixExpression
              operator: - @43
              operand: ParenthesizedExpression
                leftParenthesis: ( @44
                expression: BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @45
                    staticType: int
                  operator: + @47
                  rightOperand: IntegerLiteral
                    literal: 2 @49
                    staticType: int
                  element: dart:core::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
                rightParenthesis: ) @50
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
        #F3 hasInitializer isOriginDeclaration v3 (nameOffset:63) (firstTokenOffset:63) (offset:63)
          element: <testLibrary>::@topLevelVariable::v3
          initializer: expression_2
            PropertyAccess
              target: ParenthesizedExpression
                leftParenthesis: ( @68
                expression: BinaryExpression
                  leftOperand: SimpleStringLiteral
                    literal: 'aaa' @69
                  operator: + @75
                  rightOperand: SimpleStringLiteral
                    literal: 'bbb' @77
                  element: dart:core::@class::String::@method::+
                  staticInvokeType: String Function(String)
                  staticType: String
                rightParenthesis: ) @82
                staticType: String
              operator: . @83
              propertyName: SimpleIdentifier
                token: length @84
                element: dart:core::@class::String::@getter::length
                staticType: int
              staticType: int
      getters
        #F4 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::v1
        #F5 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@getter::v2
        #F6 isOriginVariable v3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
          element: <testLibrary>::@getter::v3
  topLevelVariables
    const hasInitializer isOriginDeclaration v1
      reference: <testLibrary>::@topLevelVariable::v1
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v1
    const hasInitializer isOriginDeclaration v2
      reference: <testLibrary>::@topLevelVariable::v2
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::v2
    const hasInitializer isOriginDeclaration v3
      reference: <testLibrary>::@topLevelVariable::v3
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::v3
  getters
    static isOriginVariable v1
      reference: <testLibrary>::@getter::v1
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v1
    static isOriginVariable v2
      reference: <testLibrary>::@getter::v2
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v2
    static isOriginVariable v3
      reference: <testLibrary>::@getter::v3
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v3
''');
  }

  test_const_topLevel_prefix() async {
    var library = await buildLibrary(r'''
const vNotEqual = 1 != 2;
const vNot = !true;
const vNegate = -1;
const vComplement = ~1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vNotEqual (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vNotEqual
          initializer: expression_0
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @18
                staticType: int
              operator: != @20
              rightOperand: IntegerLiteral
                literal: 2 @23
                staticType: int
              element: dart:core::@class::num::@method::==
              staticInvokeType: bool Function(Object)
              staticType: bool
        #F2 hasInitializer isOriginDeclaration vNot (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::vNot
          initializer: expression_1
            PrefixExpression
              operator: ! @39
              operand: BooleanLiteral
                literal: true @40
                staticType: bool
              element: <null>
              staticType: bool
        #F3 hasInitializer isOriginDeclaration vNegate (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::vNegate
          initializer: expression_2
            PrefixExpression
              operator: - @62
              operand: IntegerLiteral
                literal: 1 @63
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
        #F4 hasInitializer isOriginDeclaration vComplement (nameOffset:72) (firstTokenOffset:72) (offset:72)
          element: <testLibrary>::@topLevelVariable::vComplement
          initializer: expression_3
            PrefixExpression
              operator: ~ @86
              operand: IntegerLiteral
                literal: 1 @87
                staticType: int
              element: dart:core::@class::int::@method::~
              staticType: int
      getters
        #F5 isOriginVariable vNotEqual (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vNotEqual
        #F6 isOriginVariable vNot (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::vNot
        #F7 isOriginVariable vNegate (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::vNegate
        #F8 isOriginVariable vComplement (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@getter::vComplement
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vNotEqual
      reference: <testLibrary>::@topLevelVariable::vNotEqual
      firstFragment: #F1
      type: bool
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vNotEqual
    const hasImplicitType hasInitializer isOriginDeclaration vNot
      reference: <testLibrary>::@topLevelVariable::vNot
      firstFragment: #F2
      type: bool
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vNot
    const hasImplicitType hasInitializer isOriginDeclaration vNegate
      reference: <testLibrary>::@topLevelVariable::vNegate
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vNegate
    const hasImplicitType hasInitializer isOriginDeclaration vComplement
      reference: <testLibrary>::@topLevelVariable::vComplement
      firstFragment: #F4
      type: int
      constantInitializer
        fragment: #F4
        expression: expression_3
      getter: <testLibrary>::@getter::vComplement
  getters
    static isOriginVariable vNotEqual
      reference: <testLibrary>::@getter::vNotEqual
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNotEqual
    static isOriginVariable vNot
      reference: <testLibrary>::@getter::vNot
      firstFragment: #F6
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::vNot
    static isOriginVariable vNegate
      reference: <testLibrary>::@getter::vNegate
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vNegate
    static isOriginVariable vComplement
      reference: <testLibrary>::@getter::vComplement
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vComplement
''');
  }

  test_const_topLevel_super() async {
    var library = await buildLibrary(r'''
const vSuper = super;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vSuper (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vSuper
          initializer: expression_0
            SuperExpression
              superKeyword: super @15
              staticType: InvalidType
      getters
        #F2 isOriginVariable vSuper (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vSuper
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vSuper
      reference: <testLibrary>::@topLevelVariable::vSuper
      firstFragment: #F1
      type: InvalidType
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vSuper
  getters
    static isOriginVariable vSuper
      reference: <testLibrary>::@getter::vSuper
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::vSuper
''');
  }

  test_const_topLevel_this() async {
    var library = await buildLibrary(r'''
const vThis = this;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vThis (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vThis
          initializer: expression_0
            ThisExpression
              thisKeyword: this @14
              staticType: dynamic
      getters
        #F2 isOriginVariable vThis (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vThis
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vThis
      reference: <testLibrary>::@topLevelVariable::vThis
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vThis
  getters
    static isOriginVariable vThis
      reference: <testLibrary>::@getter::vThis
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::vThis
''');
  }

  test_const_topLevel_throw() async {
    var library = await buildLibrary(r'''
const c = throw 42;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration c (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::c
          initializer: expression_0
            ThrowExpression
              throwKeyword: throw @10
              expression: IntegerLiteral
                literal: 42 @16
                staticType: int
              staticType: Never
      getters
        #F2 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::c
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: Never
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::c
  getters
    static isOriginVariable c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: Never
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_const_topLevel_typedList() async {
    var library = await buildLibrary(r'''
const vNull = const <Null>[];
const vDynamic = const <dynamic>[1, 2, 3];
const vInterfaceNoTypeParameters = const <int>[1, 2, 3];
const vInterfaceNoTypeArguments = const <List>[];
const vInterfaceWithTypeArguments = const <List<String>>[];
const vInterfaceWithTypeArguments2 = const <Map<int, List<String>>>[];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vNull (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vNull
          initializer: expression_0
            ListLiteral
              constKeyword: const @14
              typeArguments: TypeArgumentList
                leftBracket: < @20
                arguments
                  NamedType
                    name: Null @21
                    element: dart:core::@class::Null
                    type: Null
                rightBracket: > @25
              leftBracket: [ @26
              rightBracket: ] @27
              staticType: List<Null>
        #F2 hasInitializer isOriginDeclaration vDynamic (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::vDynamic
          initializer: expression_1
            ListLiteral
              constKeyword: const @47
              typeArguments: TypeArgumentList
                leftBracket: < @53
                arguments
                  NamedType
                    name: dynamic @54
                    element: dynamic
                    type: dynamic
                rightBracket: > @61
              leftBracket: [ @62
              elements
                IntegerLiteral
                  literal: 1 @63
                  staticType: int
                IntegerLiteral
                  literal: 2 @66
                  staticType: int
                IntegerLiteral
                  literal: 3 @69
                  staticType: int
              rightBracket: ] @70
              staticType: List<dynamic>
        #F3 hasInitializer isOriginDeclaration vInterfaceNoTypeParameters (nameOffset:79) (firstTokenOffset:79) (offset:79)
          element: <testLibrary>::@topLevelVariable::vInterfaceNoTypeParameters
          initializer: expression_2
            ListLiteral
              constKeyword: const @108
              typeArguments: TypeArgumentList
                leftBracket: < @114
                arguments
                  NamedType
                    name: int @115
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @118
              leftBracket: [ @119
              elements
                IntegerLiteral
                  literal: 1 @120
                  staticType: int
                IntegerLiteral
                  literal: 2 @123
                  staticType: int
                IntegerLiteral
                  literal: 3 @126
                  staticType: int
              rightBracket: ] @127
              staticType: List<int>
        #F4 hasInitializer isOriginDeclaration vInterfaceNoTypeArguments (nameOffset:136) (firstTokenOffset:136) (offset:136)
          element: <testLibrary>::@topLevelVariable::vInterfaceNoTypeArguments
          initializer: expression_3
            ListLiteral
              constKeyword: const @164
              typeArguments: TypeArgumentList
                leftBracket: < @170
                arguments
                  NamedType
                    name: List @171
                    element: dart:core::@class::List
                    type: List<dynamic>
                rightBracket: > @175
              leftBracket: [ @176
              rightBracket: ] @177
              staticType: List<List<dynamic>>
        #F5 hasInitializer isOriginDeclaration vInterfaceWithTypeArguments (nameOffset:186) (firstTokenOffset:186) (offset:186)
          element: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
          initializer: expression_4
            ListLiteral
              constKeyword: const @216
              typeArguments: TypeArgumentList
                leftBracket: < @222
                arguments
                  NamedType
                    name: List @223
                    typeArguments: TypeArgumentList
                      leftBracket: < @227
                      arguments
                        NamedType
                          name: String @228
                          element: dart:core::@class::String
                          type: String
                      rightBracket: > @234
                    element: dart:core::@class::List
                    type: List<String>
                rightBracket: > @235
              leftBracket: [ @236
              rightBracket: ] @237
              staticType: List<List<String>>
        #F6 hasInitializer isOriginDeclaration vInterfaceWithTypeArguments2 (nameOffset:246) (firstTokenOffset:246) (offset:246)
          element: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments2
          initializer: expression_5
            ListLiteral
              constKeyword: const @277
              typeArguments: TypeArgumentList
                leftBracket: < @283
                arguments
                  NamedType
                    name: Map @284
                    typeArguments: TypeArgumentList
                      leftBracket: < @287
                      arguments
                        NamedType
                          name: int @288
                          element: dart:core::@class::int
                          type: int
                        NamedType
                          name: List @293
                          typeArguments: TypeArgumentList
                            leftBracket: < @297
                            arguments
                              NamedType
                                name: String @298
                                element: dart:core::@class::String
                                type: String
                            rightBracket: > @304
                          element: dart:core::@class::List
                          type: List<String>
                      rightBracket: > @305
                    element: dart:core::@class::Map
                    type: Map<int, List<String>>
                rightBracket: > @306
              leftBracket: [ @307
              rightBracket: ] @308
              staticType: List<Map<int, List<String>>>
      getters
        #F7 isOriginVariable vNull (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vNull
        #F8 isOriginVariable vDynamic (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::vDynamic
        #F9 isOriginVariable vInterfaceNoTypeParameters (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
          element: <testLibrary>::@getter::vInterfaceNoTypeParameters
        #F10 isOriginVariable vInterfaceNoTypeArguments (nameOffset:<null>) (firstTokenOffset:<null>) (offset:136)
          element: <testLibrary>::@getter::vInterfaceNoTypeArguments
        #F11 isOriginVariable vInterfaceWithTypeArguments (nameOffset:<null>) (firstTokenOffset:<null>) (offset:186)
          element: <testLibrary>::@getter::vInterfaceWithTypeArguments
        #F12 isOriginVariable vInterfaceWithTypeArguments2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:246)
          element: <testLibrary>::@getter::vInterfaceWithTypeArguments2
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vNull
      reference: <testLibrary>::@topLevelVariable::vNull
      firstFragment: #F1
      type: List<Null>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vNull
    const hasImplicitType hasInitializer isOriginDeclaration vDynamic
      reference: <testLibrary>::@topLevelVariable::vDynamic
      firstFragment: #F2
      type: List<dynamic>
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vDynamic
    const hasImplicitType hasInitializer isOriginDeclaration vInterfaceNoTypeParameters
      reference: <testLibrary>::@topLevelVariable::vInterfaceNoTypeParameters
      firstFragment: #F3
      type: List<int>
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vInterfaceNoTypeParameters
    const hasImplicitType hasInitializer isOriginDeclaration vInterfaceNoTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceNoTypeArguments
      firstFragment: #F4
      type: List<List<dynamic>>
      constantInitializer
        fragment: #F4
        expression: expression_3
      getter: <testLibrary>::@getter::vInterfaceNoTypeArguments
    const hasImplicitType hasInitializer isOriginDeclaration vInterfaceWithTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
      firstFragment: #F5
      type: List<List<String>>
      constantInitializer
        fragment: #F5
        expression: expression_4
      getter: <testLibrary>::@getter::vInterfaceWithTypeArguments
    const hasImplicitType hasInitializer isOriginDeclaration vInterfaceWithTypeArguments2
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments2
      firstFragment: #F6
      type: List<Map<int, List<String>>>
      constantInitializer
        fragment: #F6
        expression: expression_5
      getter: <testLibrary>::@getter::vInterfaceWithTypeArguments2
  getters
    static isOriginVariable vNull
      reference: <testLibrary>::@getter::vNull
      firstFragment: #F7
      returnType: List<Null>
      variable: <testLibrary>::@topLevelVariable::vNull
    static isOriginVariable vDynamic
      reference: <testLibrary>::@getter::vDynamic
      firstFragment: #F8
      returnType: List<dynamic>
      variable: <testLibrary>::@topLevelVariable::vDynamic
    static isOriginVariable vInterfaceNoTypeParameters
      reference: <testLibrary>::@getter::vInterfaceNoTypeParameters
      firstFragment: #F9
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::vInterfaceNoTypeParameters
    static isOriginVariable vInterfaceNoTypeArguments
      reference: <testLibrary>::@getter::vInterfaceNoTypeArguments
      firstFragment: #F10
      returnType: List<List<dynamic>>
      variable: <testLibrary>::@topLevelVariable::vInterfaceNoTypeArguments
    static isOriginVariable vInterfaceWithTypeArguments
      reference: <testLibrary>::@getter::vInterfaceWithTypeArguments
      firstFragment: #F11
      returnType: List<List<String>>
      variable: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
    static isOriginVariable vInterfaceWithTypeArguments2
      reference: <testLibrary>::@getter::vInterfaceWithTypeArguments2
      firstFragment: #F12
      returnType: List<Map<int, List<String>>>
      variable: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments2
''');
  }

  test_const_topLevel_typedList_imported() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    var library = await buildLibrary(r'''
import 'a.dart';
const v = const <C>[];
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ListLiteral
              constKeyword: const @27
              typeArguments: TypeArgumentList
                leftBracket: < @33
                arguments
                  NamedType
                    name: C @34
                    element: package:test/a.dart::@class::C
                    type: C
                rightBracket: > @35
              leftBracket: [ @36
              rightBracket: ] @37
              staticType: List<C>
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: List<C>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: List<C>
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_topLevel_typedList_importedWithPrefix() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    var library = await buildLibrary(r'''
import 'a.dart' as p;
const v = const <p.C>[];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ListLiteral
              constKeyword: const @32
              typeArguments: TypeArgumentList
                leftBracket: < @38
                arguments
                  NamedType
                    importPrefix: ImportPrefixReference
                      name: p @39
                      period: . @40
                      element: <testLibraryFragment>::@prefix2::p
                    name: C @41
                    element: package:test/a.dart::@class::C
                    type: C
                rightBracket: > @42
              leftBracket: [ @43
              rightBracket: ] @44
              staticType: List<C>
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: List<C>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: List<C>
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_topLevel_typedList_typedefArgument() async {
    var library = await buildLibrary(r'''
typedef int F(String id);
const v = const <F>[];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasInitializer isOriginDeclaration v (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ListLiteral
              constKeyword: const @36
              typeArguments: TypeArgumentList
                leftBracket: < @42
                arguments
                  NamedType
                    name: F @43
                    element: <testLibrary>::@typeAlias::F
                    type: int Function(String)
                      alias: <testLibrary>::@typeAlias::F
                rightBracket: > @44
              leftBracket: [ @45
              rightBracket: ] @46
              staticType: List<int Function(String)>
      getters
        #F3 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::v
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: int Function(String)
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F2
      type: List<int Function(String)>
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F3
      returnType: List<int Function(String)>
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_topLevel_typedMap() async {
    var library = await buildLibrary(r'''
const vDynamic1 = const <dynamic, int>{};
const vDynamic2 = const <int, dynamic>{};
const vInterface = const <int, String>{};
const vInterfaceWithTypeArguments = const <int, List<String>>{};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vDynamic1 (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vDynamic1
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @18
              typeArguments: TypeArgumentList
                leftBracket: < @24
                arguments
                  NamedType
                    name: dynamic @25
                    element: dynamic
                    type: dynamic
                  NamedType
                    name: int @34
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @37
              leftBracket: { @38
              rightBracket: } @39
              isMap: true
              staticType: Map<dynamic, int>
        #F2 hasInitializer isOriginDeclaration vDynamic2 (nameOffset:48) (firstTokenOffset:48) (offset:48)
          element: <testLibrary>::@topLevelVariable::vDynamic2
          initializer: expression_1
            SetOrMapLiteral
              constKeyword: const @60
              typeArguments: TypeArgumentList
                leftBracket: < @66
                arguments
                  NamedType
                    name: int @67
                    element: dart:core::@class::int
                    type: int
                  NamedType
                    name: dynamic @72
                    element: dynamic
                    type: dynamic
                rightBracket: > @79
              leftBracket: { @80
              rightBracket: } @81
              isMap: true
              staticType: Map<int, dynamic>
        #F3 hasInitializer isOriginDeclaration vInterface (nameOffset:90) (firstTokenOffset:90) (offset:90)
          element: <testLibrary>::@topLevelVariable::vInterface
          initializer: expression_2
            SetOrMapLiteral
              constKeyword: const @103
              typeArguments: TypeArgumentList
                leftBracket: < @109
                arguments
                  NamedType
                    name: int @110
                    element: dart:core::@class::int
                    type: int
                  NamedType
                    name: String @115
                    element: dart:core::@class::String
                    type: String
                rightBracket: > @121
              leftBracket: { @122
              rightBracket: } @123
              isMap: true
              staticType: Map<int, String>
        #F4 hasInitializer isOriginDeclaration vInterfaceWithTypeArguments (nameOffset:132) (firstTokenOffset:132) (offset:132)
          element: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
          initializer: expression_3
            SetOrMapLiteral
              constKeyword: const @162
              typeArguments: TypeArgumentList
                leftBracket: < @168
                arguments
                  NamedType
                    name: int @169
                    element: dart:core::@class::int
                    type: int
                  NamedType
                    name: List @174
                    typeArguments: TypeArgumentList
                      leftBracket: < @178
                      arguments
                        NamedType
                          name: String @179
                          element: dart:core::@class::String
                          type: String
                      rightBracket: > @185
                    element: dart:core::@class::List
                    type: List<String>
                rightBracket: > @186
              leftBracket: { @187
              rightBracket: } @188
              isMap: true
              staticType: Map<int, List<String>>
      getters
        #F5 isOriginVariable vDynamic1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vDynamic1
        #F6 isOriginVariable vDynamic2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@getter::vDynamic2
        #F7 isOriginVariable vInterface (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
          element: <testLibrary>::@getter::vInterface
        #F8 isOriginVariable vInterfaceWithTypeArguments (nameOffset:<null>) (firstTokenOffset:<null>) (offset:132)
          element: <testLibrary>::@getter::vInterfaceWithTypeArguments
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vDynamic1
      reference: <testLibrary>::@topLevelVariable::vDynamic1
      firstFragment: #F1
      type: Map<dynamic, int>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vDynamic1
    const hasImplicitType hasInitializer isOriginDeclaration vDynamic2
      reference: <testLibrary>::@topLevelVariable::vDynamic2
      firstFragment: #F2
      type: Map<int, dynamic>
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vDynamic2
    const hasImplicitType hasInitializer isOriginDeclaration vInterface
      reference: <testLibrary>::@topLevelVariable::vInterface
      firstFragment: #F3
      type: Map<int, String>
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vInterface
    const hasImplicitType hasInitializer isOriginDeclaration vInterfaceWithTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
      firstFragment: #F4
      type: Map<int, List<String>>
      constantInitializer
        fragment: #F4
        expression: expression_3
      getter: <testLibrary>::@getter::vInterfaceWithTypeArguments
  getters
    static isOriginVariable vDynamic1
      reference: <testLibrary>::@getter::vDynamic1
      firstFragment: #F5
      returnType: Map<dynamic, int>
      variable: <testLibrary>::@topLevelVariable::vDynamic1
    static isOriginVariable vDynamic2
      reference: <testLibrary>::@getter::vDynamic2
      firstFragment: #F6
      returnType: Map<int, dynamic>
      variable: <testLibrary>::@topLevelVariable::vDynamic2
    static isOriginVariable vInterface
      reference: <testLibrary>::@getter::vInterface
      firstFragment: #F7
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::vInterface
    static isOriginVariable vInterfaceWithTypeArguments
      reference: <testLibrary>::@getter::vInterfaceWithTypeArguments
      firstFragment: #F8
      returnType: Map<int, List<String>>
      variable: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
''');
  }

  test_const_topLevel_typedSet() async {
    var library = await buildLibrary(r'''
const vDynamic1 = const <dynamic>{};
const vInterface = const <int>{};
const vInterfaceWithTypeArguments = const <List<String>>{};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration vDynamic1 (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::vDynamic1
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @18
              typeArguments: TypeArgumentList
                leftBracket: < @24
                arguments
                  NamedType
                    name: dynamic @25
                    element: dynamic
                    type: dynamic
                rightBracket: > @32
              leftBracket: { @33
              rightBracket: } @34
              isMap: false
              staticType: Set<dynamic>
        #F2 hasInitializer isOriginDeclaration vInterface (nameOffset:43) (firstTokenOffset:43) (offset:43)
          element: <testLibrary>::@topLevelVariable::vInterface
          initializer: expression_1
            SetOrMapLiteral
              constKeyword: const @56
              typeArguments: TypeArgumentList
                leftBracket: < @62
                arguments
                  NamedType
                    name: int @63
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @66
              leftBracket: { @67
              rightBracket: } @68
              isMap: false
              staticType: Set<int>
        #F3 hasInitializer isOriginDeclaration vInterfaceWithTypeArguments (nameOffset:77) (firstTokenOffset:77) (offset:77)
          element: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
          initializer: expression_2
            SetOrMapLiteral
              constKeyword: const @107
              typeArguments: TypeArgumentList
                leftBracket: < @113
                arguments
                  NamedType
                    name: List @114
                    typeArguments: TypeArgumentList
                      leftBracket: < @118
                      arguments
                        NamedType
                          name: String @119
                          element: dart:core::@class::String
                          type: String
                      rightBracket: > @125
                    element: dart:core::@class::List
                    type: List<String>
                rightBracket: > @126
              leftBracket: { @127
              rightBracket: } @128
              isMap: false
              staticType: Set<List<String>>
      getters
        #F4 isOriginVariable vDynamic1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::vDynamic1
        #F5 isOriginVariable vInterface (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@getter::vInterface
        #F6 isOriginVariable vInterfaceWithTypeArguments (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
          element: <testLibrary>::@getter::vInterfaceWithTypeArguments
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration vDynamic1
      reference: <testLibrary>::@topLevelVariable::vDynamic1
      firstFragment: #F1
      type: Set<dynamic>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::vDynamic1
    const hasImplicitType hasInitializer isOriginDeclaration vInterface
      reference: <testLibrary>::@topLevelVariable::vInterface
      firstFragment: #F2
      type: Set<int>
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::vInterface
    const hasImplicitType hasInitializer isOriginDeclaration vInterfaceWithTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
      firstFragment: #F3
      type: Set<List<String>>
      constantInitializer
        fragment: #F3
        expression: expression_2
      getter: <testLibrary>::@getter::vInterfaceWithTypeArguments
  getters
    static isOriginVariable vDynamic1
      reference: <testLibrary>::@getter::vDynamic1
      firstFragment: #F4
      returnType: Set<dynamic>
      variable: <testLibrary>::@topLevelVariable::vDynamic1
    static isOriginVariable vInterface
      reference: <testLibrary>::@getter::vInterface
      firstFragment: #F5
      returnType: Set<int>
      variable: <testLibrary>::@topLevelVariable::vInterface
    static isOriginVariable vInterfaceWithTypeArguments
      reference: <testLibrary>::@getter::vInterfaceWithTypeArguments
      firstFragment: #F6
      returnType: Set<List<String>>
      variable: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
''');
  }

  test_const_topLevel_untypedList() async {
    var library = await buildLibrary(r'''
const v = const [1, 2, 3];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ListLiteral
              constKeyword: const @10
              leftBracket: [ @16
              elements
                IntegerLiteral
                  literal: 1 @17
                  staticType: int
                IntegerLiteral
                  literal: 2 @20
                  staticType: int
                IntegerLiteral
                  literal: 3 @23
                  staticType: int
              rightBracket: ] @24
              staticType: List<int>
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: List<int>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_topLevel_untypedMap() async {
    var library = await buildLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @10
              leftBracket: { @16
              elements
                MapLiteralEntry
                  key: IntegerLiteral
                    literal: 0 @17
                    staticType: int
                  separator: : @18
                  value: SimpleStringLiteral
                    literal: 'aaa' @20
                MapLiteralEntry
                  key: IntegerLiteral
                    literal: 1 @27
                    staticType: int
                  separator: : @28
                  value: SimpleStringLiteral
                    literal: 'bbb' @30
                MapLiteralEntry
                  key: IntegerLiteral
                    literal: 2 @37
                    staticType: int
                  separator: : @38
                  value: SimpleStringLiteral
                    literal: 'ccc' @40
              rightBracket: } @45
              isMap: true
              staticType: Map<int, String>
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Map<int, String>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Map<int, String>
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_topLevel_untypedSet() async {
    var library = await buildLibrary(r'''
const v = const {0, 1, 2};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @10
              leftBracket: { @16
              elements
                IntegerLiteral
                  literal: 0 @17
                  staticType: int
                IntegerLiteral
                  literal: 1 @20
                  staticType: int
                IntegerLiteral
                  literal: 2 @23
                  staticType: int
              rightBracket: } @24
              isMap: false
              staticType: Set<int>
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Set<int>
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Set<int>
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_const_typeLiteral() async {
    var library = await buildLibrary(r'''
const v = List<int>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            TypeLiteral
              type: NamedType
                name: List @10
                typeArguments: TypeArgumentList
                  leftBracket: < @14
                  arguments
                    NamedType
                      name: int @15
                      element: dart:core::@class::int
                      type: int
                  rightBracket: > @18
                element: dart:core::@class::List
                type: List<int>
              staticType: Type
      getters
        #F2 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Type
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_constExpr_pushReference_enum_field() async {
    var library = await buildLibrary('''
enum E {a, b, c}
final vValue = E.a;
final vValues = E.values;
final vIndex = E.a.index;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration a (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer isOriginDeclaration b (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 hasInitializer isOriginDeclaration c (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibrary>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::E::@getter::a
            #F8 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::b
            #F9 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::c
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F11 hasInitializer isOriginDeclaration vValue (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::vValue
        #F12 hasInitializer isOriginDeclaration vValues (nameOffset:43) (firstTokenOffset:43) (offset:43)
          element: <testLibrary>::@topLevelVariable::vValues
        #F13 hasInitializer isOriginDeclaration vIndex (nameOffset:69) (firstTokenOffset:69) (offset:69)
          element: <testLibrary>::@topLevelVariable::vIndex
      getters
        #F14 isOriginVariable vValue (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::vValue
        #F15 isOriginVariable vValues (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@getter::vValues
        #F16 isOriginVariable vIndex (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@getter::vIndex
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        static isOriginVariable c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration vValue
      reference: <testLibrary>::@topLevelVariable::vValue
      firstFragment: #F11
      type: E
      getter: <testLibrary>::@getter::vValue
    final hasImplicitType hasInitializer isOriginDeclaration vValues
      reference: <testLibrary>::@topLevelVariable::vValues
      firstFragment: #F12
      type: List<E>
      getter: <testLibrary>::@getter::vValues
    final hasImplicitType hasInitializer isOriginDeclaration vIndex
      reference: <testLibrary>::@topLevelVariable::vIndex
      firstFragment: #F13
      type: int
      getter: <testLibrary>::@getter::vIndex
  getters
    static isOriginVariable vValue
      reference: <testLibrary>::@getter::vValue
      firstFragment: #F14
      returnType: E
      variable: <testLibrary>::@topLevelVariable::vValue
    static isOriginVariable vValues
      reference: <testLibrary>::@getter::vValues
      firstFragment: #F15
      returnType: List<E>
      variable: <testLibrary>::@topLevelVariable::vValues
    static isOriginVariable vIndex
      reference: <testLibrary>::@getter::vIndex
      firstFragment: #F16
      returnType: int
      variable: <testLibrary>::@topLevelVariable::vIndex
''');
  }

  test_constExpr_pushReference_enum_method() async {
    var library = await buildLibrary('''
enum E {a}
final vToString = E.a.toString();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration a (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@getter::a
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::E::@getter::a
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration vToString (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::vToString
      getters
        #F8 isOriginVariable vToString (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::vToString
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration vToString
      reference: <testLibrary>::@topLevelVariable::vToString
      firstFragment: #F7
      type: String
      getter: <testLibrary>::@getter::vToString
  getters
    static isOriginVariable vToString
      reference: <testLibrary>::@getter::vToString
      firstFragment: #F8
      returnType: String
      variable: <testLibrary>::@topLevelVariable::vToString
''');
  }

  test_constExpr_pushReference_field_simpleIdentifier() async {
    var library = await buildLibrary('''
class C {
  static const a = b;
  static const b = null;
}
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
            #F2 hasInitializer isOriginDeclaration a (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::a
              initializer: expression_0
                SimpleIdentifier
                  token: b @29
                  element: <testLibrary>::@class::C::@getter::b
                  staticType: dynamic
            #F3 hasInitializer isOriginDeclaration b (nameOffset:47) (firstTokenOffset:47) (offset:47)
              element: <testLibrary>::@class::C::@field::b
              initializer: expression_1
                NullLiteral
                  literal: null @51
                  staticType: Null
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::a
            #F6 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@class::C::@getter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F2
          type: dynamic
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::a
        static const hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F3
          type: dynamic
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@class::C::@getter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        static isOriginVariable a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::b
''');
  }

  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    var library = await buildLibrary('''
class C {
  static const a = m;
  static m() {}
}
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
            #F2 hasInitializer isOriginDeclaration a (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::a
              initializer: expression_0
                SimpleIdentifier
                  token: m @29
                  element: <testLibrary>::@class::C::@method::m
                  staticType: dynamic Function()
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::a
          methods
            #F5 isOriginDeclaration m (nameOffset:41) (firstTokenOffset:34) (offset:41)
              element: <testLibrary>::@class::C::@method::m
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F2
          type: dynamic Function()
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static isOriginVariable a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F4
          returnType: dynamic Function()
          variable: <testLibrary>::@class::C::@field::a
      methods
        static isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F5
          returnType: dynamic
''');
  }

  // TODO(scheglov): This is duplicate.
  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }
}

@reflectiveTest
class ConstElementTest_fromBytes extends ConstElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ConstElementTest_keepLinking extends ConstElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
