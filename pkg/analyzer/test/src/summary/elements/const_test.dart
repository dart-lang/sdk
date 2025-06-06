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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            AsExpression
              expression: SimpleIdentifier
                token: a @27
                element: <testLibraryFragment>::@getter::a#element
                staticType: num
              asOperator: as @29
              type: NamedType
                name: int @32
                element2: dart:core::@class::int
                type: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: num
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: num
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
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
                readElement2: <testLibraryFragment>::@getter::a#element
                readType: int
                writeElement2: <testLibraryFragment>::@getter::a#element
                writeType: InvalidType
                element: dart:core::@class::num::@method::+
                staticType: int
              rightParenthesis: ) @30
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
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
                    element: dart:core::<fragment>::@class::int::@getter::isEven#element
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
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer f1 @29
              reference: <testLibraryFragment>::@class::C::@field::f1
              element: <testLibrary>::@class::C::@field::f1
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @34
                  staticType: int
              getter2: <testLibraryFragment>::@class::C::@getter::f1
            hasInitializer f2 @56
              reference: <testLibraryFragment>::@class::C::@field::f2
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
                    element: <testLibraryFragment>::@class::C::@getter::f1#element
                    staticType: int
                  element: <testLibraryFragment>::@class::C::@getter::f1#element
                  staticType: int
              getter2: <testLibraryFragment>::@class::C::@getter::f2
            hasInitializer f3 @67
              reference: <testLibraryFragment>::@class::C::@field::f3
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
                    element: <testLibraryFragment>::@class::C::@getter::f2#element
                    staticType: int
                  element: <testLibraryFragment>::@class::C::@getter::f2#element
                  staticType: int
              getter2: <testLibraryFragment>::@class::C::@getter::f3
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get f1
              reference: <testLibraryFragment>::@class::C::@getter::f1
              element: <testLibraryFragment>::@class::C::@getter::f1#element
            synthetic get f2
              reference: <testLibraryFragment>::@class::C::@getter::f2
              element: <testLibraryFragment>::@class::C::@getter::f2#element
            synthetic get f3
              reference: <testLibraryFragment>::@class::C::@getter::f3
              element: <testLibraryFragment>::@class::C::@getter::f3#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const hasInitializer f1
          firstFragment: <testLibraryFragment>::@class::C::@field::f1
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::f1
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::f1#element
        static const hasInitializer f2
          firstFragment: <testLibraryFragment>::@class::C::@field::f2
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::f2
            expression: expression_1
          getter: <testLibraryFragment>::@class::C::@getter::f2#element
        static const hasInitializer f3
          firstFragment: <testLibraryFragment>::@class::C::@field::f3
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::f3
            expression: expression_2
          getter: <testLibraryFragment>::@class::C::@getter::f3#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get f1
          firstFragment: <testLibraryFragment>::@class::C::@getter::f1
          returnType: int
        synthetic static get f2
          firstFragment: <testLibraryFragment>::@class::C::@getter::f2
          returnType: int
        synthetic static get f3
          firstFragment: <testLibraryFragment>::@class::C::@getter::f3
          returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          fields
            t @23
              reference: <testLibraryFragment>::@class::C::@field::t
              element: <testLibrary>::@class::C::@field::t
              getter2: <testLibraryFragment>::@class::C::@getter::t
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 34
              formalParameters
                this.t @41
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::t#element
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 53
              periodOffset: 54
              formalParameters
                this.t @66
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::t#element
          getters
            synthetic get t
              reference: <testLibraryFragment>::@class::C::@getter::t
              element: <testLibraryFragment>::@class::C::@getter::t#element
      topLevelVariables
        hasInitializer x @85
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @89
              constructorName: ConstructorName
                type: NamedType
                  name: C @95
                  element2: <testLibrary>::@class::C
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
          getter2: <testLibraryFragment>::@getter::x
        hasInitializer y @114
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibrary>::@topLevelVariable::y
          initializer: expression_1
            InstanceCreationExpression
              keyword: const @118
              constructorName: ConstructorName
                type: NamedType
                  name: C @124
                  element2: <testLibrary>::@class::C
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
          getter2: <testLibraryFragment>::@getter::y
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
        synthetic get y
          reference: <testLibraryFragment>::@getter::y
          element: <testLibraryFragment>::@getter::y#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        final t
          firstFragment: <testLibraryFragment>::@class::C::@field::t
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibraryFragment>::@class::C::@getter::t#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType t
              type: T
        const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            requiredPositional final hasImplicitType t
              type: T
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
          hasEnclosingTypeParameterReference: true
          returnType: T
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
    const hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::y
        expression: expression_1
      getter: <testLibraryFragment>::@getter::y#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
      returnType: Object
''');
    var x = library.definingCompilationUnit.topLevelVariables[0];
    var xExpr = x.constantInitializer as InstanceCreationExpression;
    var xType = xExpr.constructorName.element!.returnType;
    _assertTypeStr(xType, 'C<int>');
    var y = library.definingCompilationUnit.topLevelVariables[0];
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
      topLevelVariables
        hasInitializer v @31
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ConstructorReference
              constructorName: ConstructorName
                type: NamedType
                  name: A @35
                  element2: <testLibrary>::@class::A
                  type: null
                period: . @36
                name: SimpleIdentifier
                  token: named @37
                  element: <testLibrary>::@class::A::@constructor::named
                  staticType: null
                element: <testLibrary>::@class::A::@constructor::named
              staticType: A Function()
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: A Function()
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
      topLevelVariables
        hasInitializer a @34
          reference: <testLibraryFragment>::@topLevelVariable::a
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
              staticType: A
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: A
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: A
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
      topLevelVariables
        hasInitializer a @34
          reference: <testLibraryFragment>::@topLevelVariable::a
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
              staticType: A
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: A
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: A
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer a @27
              reference: <testLibraryFragment>::@class::A::@field::a
              element: <testLibrary>::@class::A::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @31
                      element2: <testLibrary>::@class::A
                      type: A
                    element: <testLibrary>::@class::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @32
                    rightParenthesis: ) @33
                  staticType: A
              getter2: <testLibraryFragment>::@class::A::@getter::a
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 44
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::A::@getter::a
              element: <testLibraryFragment>::@class::A::@getter::a#element
      topLevelVariables
        hasInitializer a @60
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_1
            DotShorthandPropertyAccess
              period: . @64
              propertyName: SimpleIdentifier
                token: a @65
                element: <testLibraryFragment>::@class::A::@getter::a#element
                staticType: A
              staticType: A
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static const hasInitializer a
          firstFragment: <testLibraryFragment>::@class::A::@field::a
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@class::A::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@class::A::@getter::a#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@class::A::@getter::a
          returnType: A
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: A
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_1
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: A
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer f @22
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibrary>::@class::C::@field::f
              initializer: expression_0
                IntegerLiteral
                  literal: 42 @26
                  staticType: int
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 38
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final hasInitializer f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::f
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @44
          reference: <testLibraryFragment>::@topLevelVariable::v
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
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
          formalParameters
            a @12
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: void Function(int)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: void Function(int)
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
      formalParameters
        requiredPositional a
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @24
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                    element2: dart:core::@class::int
                    type: int
                rightBracket: > @33
              staticType: void Function(int)
              typeArgumentTypes
                int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
          formalParameters
            a @12
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: void Function(int)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: void Function(int)
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
      formalParameters
        requiredPositional a
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
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
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @21
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            IntegerLiteral
              literal: 0 @25
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
        hasInitializer c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          initializer: expression_2
            IndexExpression
              target: SimpleIdentifier
                token: a @38
                element: <testLibraryFragment>::@getter::a#element
                staticType: List<int>
              leftBracket: [ @39
              index: SimpleIdentifier
                token: b @40
                element: <testLibraryFragment>::@getter::b#element
                staticType: int
              rightBracket: ] @41
              element: MethodMember
                baseElement: dart:core::@class::List::@method::[]
                substitution: {E: int}
              staticType: int
          getter2: <testLibraryFragment>::@getter::c
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: List<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
    const hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::c
        expression: expression_2
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: List<int>
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class P @6
          reference: <testLibraryFragment>::@class::P
          element: <testLibrary>::@class::P
          typeParameters
            T @8
              element: T@8
          constructors
            const new
              reference: <testLibraryFragment>::@class::P::@constructor::new
              element: <testLibrary>::@class::P::@constructor::new
              typeName: P
              typeNameOffset: 21
        class P1 @35
          reference: <testLibraryFragment>::@class::P1
          element: <testLibrary>::@class::P1
          typeParameters
            T @38
              element: T@38
          constructors
            const new
              reference: <testLibraryFragment>::@class::P1::@constructor::new
              element: <testLibrary>::@class::P1::@constructor::new
              typeName: P1
              typeNameOffset: 64
        class P2 @79
          reference: <testLibraryFragment>::@class::P2
          element: <testLibrary>::@class::P2
          typeParameters
            T @82
              element: T@82
          constructors
            const new
              reference: <testLibraryFragment>::@class::P2::@constructor::new
              element: <testLibrary>::@class::P2::@constructor::new
              typeName: P2
              typeNameOffset: 108
      topLevelVariables
        hasInitializer values @131
          reference: <testLibraryFragment>::@topLevelVariable::values
          element: <testLibrary>::@topLevelVariable::values
          initializer: expression_0
            ListLiteral
              leftBracket: [ @140
              elements
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: P1 @144
                      element2: <testLibrary>::@class::P1
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
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @158
                      element2: <testLibrary>::@class::P2
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
          getter2: <testLibraryFragment>::@getter::values
      getters
        synthetic get values
          reference: <testLibraryFragment>::@getter::values
          element: <testLibraryFragment>::@getter::values#element
  classes
    class P
      reference: <testLibrary>::@class::P
      firstFragment: <testLibraryFragment>::@class::P
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::P::@constructor::new
    class P1
      reference: <testLibrary>::@class::P1
      firstFragment: <testLibraryFragment>::@class::P1
      typeParameters
        T
      supertype: P<T>
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::P1::@constructor::new
          superConstructor: <testLibrary>::@class::P::@constructor::new
    class P2
      reference: <testLibrary>::@class::P2
      firstFragment: <testLibraryFragment>::@class::P2
      typeParameters
        T
      supertype: P<T>
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::P2::@constructor::new
          superConstructor: <testLibrary>::@class::P::@constructor::new
  topLevelVariables
    const hasInitializer values
      reference: <testLibrary>::@topLevelVariable::values
      firstFragment: <testLibraryFragment>::@topLevelVariable::values
      type: List<P<dynamic>>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::values
        expression: expression_0
      getter: <testLibraryFragment>::@getter::values#element
  getters
    synthetic static get values
      firstFragment: <testLibraryFragment>::@getter::values
      returnType: List<P<dynamic>>
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer f @25
              reference: <testLibraryFragment>::@class::C::@field::f
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
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      functions
        foo @46
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const hasInitializer f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::f
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          returnType: int
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer f @18
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibrary>::@class::C::@field::f
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      functions
        foo @39
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final hasInitializer f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          returnType: int
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int Function()
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 19
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 19
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            foo @26
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibrary>::@class::A::@field::foo
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 39
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: Object?
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
          returnType: Object?
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                a @27
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                b @37
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::b#element
            const named @51
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 49
              periodOffset: 50
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional a
              type: Object
            requiredPositional b
              type: Object
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                a @27
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                b @37
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::b#element
        class B @49
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 71
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional a
              type: Object
            requiredPositional b
              type: Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
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
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: (int,)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: (int,)
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
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
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        foo @25
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @28
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: a @32
                element: <testLibraryFragment>::@getter::a#element
                staticType: int
              operator: + @34
              rightOperand: IntegerLiteral
                literal: 5 @36
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: bool
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            K @8
              element: K@8
            V @11
              element: V@11
          constructors
            const named @26
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 24
              periodOffset: 25
              formalParameters
                k @34
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::k#element
                v @39
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::v#element
      topLevelVariables
        hasInitializer V @51
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                        element2: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @68
                        element2: dart:core::@class::String
                        type: String
                    rightBracket: > @74
                  element2: <testLibrary>::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        K
        V
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            requiredPositional k
              type: K
            requiredPositional v
              type: V
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                        element2: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @40
                        element2: dart:core::@class::String
                        type: String
                    rightBracket: > @46
                  element2: package:test/a.dart::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element2: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @47
                        element2: dart:core::@class::String
                        type: String
                    rightBracket: > @53
                  element2: package:test/a.dart::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            K @8
              element: K@8
            V @11
              element: V@11
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 24
      topLevelVariables
        hasInitializer V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @41
              constructorName: ConstructorName
                type: NamedType
                  name: C @47
                  element2: <testLibrary>::@class::C
                  type: C<dynamic, dynamic>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {K: dynamic, V: dynamic}
              argumentList: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              staticType: C<dynamic, dynamic>
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        K
        V
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<dynamic, dynamic>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<dynamic, dynamic>
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          fields
            t @23
              reference: <testLibraryFragment>::@class::A::@field::t
              element: <testLibrary>::@class::A::@field::t
              getter2: <testLibraryFragment>::@class::A::@getter::t
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 34
              formalParameters
                this.t @41
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::t#element
          getters
            synthetic get t
              reference: <testLibraryFragment>::@class::A::@getter::t
              element: <testLibraryFragment>::@class::A::@getter::t#element
      topLevelVariables
        hasInitializer a @60
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @64
              constructorName: ConstructorName
                type: NamedType
                  name: A @70
                  element2: <testLibrary>::@class::A
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
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      fields
        final t
          firstFragment: <testLibraryFragment>::@class::A::@field::t
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibraryFragment>::@class::A::@getter::t#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType t
              type: T
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::A::@getter::t
          hasEnclosingTypeParameterReference: true
          returnType: T
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            K @8
              element: K@8
            V @11
              element: V@11
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 24
      topLevelVariables
        hasInitializer V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                        element2: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @54
                        element2: dart:core::@class::String
                        type: String
                    rightBracket: > @60
                  element2: <testLibrary>::@class::C
                  type: C<int, String>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @61
                rightParenthesis: ) @62
              staticType: C<int, String>
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        K
        V
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                        element2: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @40
                        element2: dart:core::@class::String
                        type: String
                    rightBracket: > @46
                  element2: package:test/a.dart::@class::C
                  type: C<int, String>
                element: ConstructorMember
                  baseElement: package:test/a.dart::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C<int, String>
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element2: dart:core::@class::int
                        type: int
                      NamedType
                        name: String @47
                        element2: dart:core::@class::String
                        type: String
                    rightBracket: > @53
                  element2: package:test/a.dart::@class::C
                  type: C<int, String>
                element: ConstructorMember
                  baseElement: package:test/a.dart::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @54
                rightParenthesis: ) @55
              staticType: C<int, String>
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                a @31
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::a#element
                b @38
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::b#element
                c @45
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::c#element
                default d @56
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d#element
                default e @66
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e#element
      topLevelVariables
        hasInitializer V @79
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @83
              constructorName: ConstructorName
                type: NamedType
                  name: C @89
                  element2: <testLibrary>::@class::C
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
                        element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d#element
                        staticType: null
                      colon: : @110
                    expression: SimpleStringLiteral
                      literal: 'ccc' @112
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: e @119
                        element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e#element
                        staticType: null
                      colon: : @120
                    expression: DoubleLiteral
                      literal: 3.4 @122
                      staticType: double
                rightParenthesis: ) @125
              staticType: C
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            requiredPositional a
              type: bool
            requiredPositional b
              type: int
            requiredPositional c
              type: int
            optionalNamed d
              firstFragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d
              type: String
            optionalNamed e
              firstFragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e
              type: double
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element2: package:test/a.dart::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element2: package:test/a.dart::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        hasInitializer V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @21
              constructorName: ConstructorName
                type: NamedType
                  name: C @27
                  element2: <testLibrary>::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: C @16
                    period: . @17
                    element2: <null>
                  name: named @18
                  element2: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @23
                rightParenthesis: ) @24
              staticType: InvalidType
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element2: package:test/a.dart::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element2: <null>
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @16
                    period: . @17
                    element2: <null>
                  name: C @18
                  element2: <null>
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        hasInitializer V @20
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @24
              constructorName: ConstructorName
                type: NamedType
                  name: C @30
                  element2: <testLibrary>::@class::C
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<dynamic>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C<dynamic>
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
      topLevelVariables
        hasInitializer V @31
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @35
              constructorName: ConstructorName
                type: NamedType
                  name: C @41
                  element2: <testLibrary>::@class::C
                  type: C
                element: <testLibrary>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @42
                rightParenthesis: ) @43
              staticType: C
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element2: package:test/a.dart::@class::C
                  type: C
                element: package:test/a.dart::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element2: package:test/a.dart::@class::C
                  type: C
                element: package:test/a.dart::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: C
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: C
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  name: C @16
                  element2: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @17
                rightParenthesis: ) @18
              staticType: InvalidType
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element2: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: InvalidType
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @16
                    period: . @17
                    element2: <null>
                  name: C @18
                  element2: <null>
                  type: InvalidType
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @19
                rightParenthesis: ) @20
              staticType: InvalidType
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            IsExpression
              expression: SimpleIdentifier
                token: a @23
                element: <testLibraryFragment>::@getter::a#element
                staticType: int
              isOperator: is @25
              type: NamedType
                name: int @28
                element2: dart:core::@class::int
                type: int
              staticType: bool
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: bool
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer F @32
              reference: <testLibraryFragment>::@class::C::@field::F
              element: <testLibrary>::@class::C::@field::F
              initializer: expression_0
                SimpleStringLiteral
                  literal: '' @36
              getter2: <testLibraryFragment>::@class::C::@getter::F
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get F
              reference: <testLibraryFragment>::@class::C::@getter::F
              element: <testLibraryFragment>::@class::C::@getter::F#element
      topLevelVariables
        hasInitializer v @52
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                  element: <testLibraryFragment>::@class::C::@getter::F#element
                  staticType: String
                element: <testLibraryFragment>::@class::C::@getter::F#element
                staticType: String
              operator: . @59
              propertyName: SimpleIdentifier
                token: length @60
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const hasInitializer F
          firstFragment: <testLibraryFragment>::@class::C::@field::F
          type: String
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::F
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::F#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get F
          firstFragment: <testLibraryFragment>::@class::C::@getter::F
          returnType: String
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_1
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer v @27
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                  element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                  staticType: String
                element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                staticType: String
              operator: . @34
              propertyName: SimpleIdentifier
                token: length @35
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                  element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                  staticType: String
                staticType: String
              operator: . @41
              propertyName: SimpleIdentifier
                token: length @42
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PropertyAccess
              target: SimpleStringLiteral
                literal: 'abc' @10
              operator: . @15
              propertyName: SimpleIdentifier
                token: length @16
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer S @13
          reference: <testLibraryFragment>::@topLevelVariable::S
          element: <testLibrary>::@topLevelVariable::S
          initializer: expression_0
            SimpleStringLiteral
              literal: 'abc' @17
          getter2: <testLibraryFragment>::@getter::S
        hasInitializer v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_1
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @34
                element: <testLibraryFragment>::@getter::S#element
                staticType: String
              period: . @35
              identifier: SimpleIdentifier
                token: length @36
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              element: dart:core::<fragment>::@class::String::@getter::length#element
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get S
          reference: <testLibraryFragment>::@getter::S
          element: <testLibraryFragment>::@getter::S#element
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer S
      reference: <testLibrary>::@topLevelVariable::S
      firstFragment: <testLibraryFragment>::@topLevelVariable::S
      type: String
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::S
        expression: expression_0
      getter: <testLibraryFragment>::@getter::S#element
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_1
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get S
      firstFragment: <testLibraryFragment>::@getter::S
      returnType: String
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @27
                element: package:test/a.dart::<fragment>::@getter::S#element
                staticType: String
              period: . @28
              identifier: SimpleIdentifier
                token: length @29
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              element: dart:core::<fragment>::@class::String::@getter::length#element
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                  element: package:test/a.dart::<fragment>::@getter::S#element
                  staticType: String
                element: package:test/a.dart::<fragment>::@getter::S#element
                staticType: String
              operator: . @35
              propertyName: SimpleIdentifier
                token: length @36
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            length @23
              reference: <testLibraryFragment>::@class::C::@method::length
              element: <testLibrary>::@class::C::@method::length
      topLevelVariables
        hasInitializer v @47
          reference: <testLibraryFragment>::@topLevelVariable::v
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
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static length
          reference: <testLibrary>::@class::C::@method::length
          firstFragment: <testLibraryFragment>::@class::C::@method::length
          returnType: int
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int Function()
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
                          element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
                          element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
                    type: int
                  NamedType
                    name: int @29
                    element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
                    type: int
                  NamedType
                    name: int @29
                    element2: dart:core::@class::int
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
                          element2: dart:core::@class::int
                          type: int
                        NamedType
                          name: int @43
                          element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
                    type: int
                  NamedType
                    name: int @29
                    element2: dart:core::@class::int
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
                          element2: dart:core::@class::int
                          type: int
                        NamedType
                          name: int @44
                          element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
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
                    element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @4
              element: T@4
          formalParameters
            a @9
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  topLevelVariables
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_0
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
      formalParameters
        requiredPositional a
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibrary>::@class::C::@field::x
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                default this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
                  initializer: expression_0
                    SimpleIdentifier
                      token: foo @40
                      element: <testLibrary>::@function::foo
                      staticType: int Function()
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
      functions
        foo @53
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalNamed final hasImplicitType x
              firstFragment: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
              type: dynamic
              constantInitializer
                fragment: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                expression: expression_0
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibrary>::@class::C::@field::x
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                default this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
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
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalNamed final hasImplicitType x
              firstFragment: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
              type: dynamic
              constantInitializer
                fragment: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                expression: expression_0
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibrary>::@class::C::@field::x
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                default this.x @37
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
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
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalPositional final hasImplicitType x
              type: dynamic
              constantInitializer
                expression: expression_0
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            const positional @20
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              element: <testLibrary>::@class::C::@constructor::positional
              typeName: C
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                default p @32
                  element: <testLibraryFragment>::@class::C::@constructor::positional::@parameter::p#element
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
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 53
              periodOffset: 54
              formalParameters
                default p @62
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p#element
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
            methodPositional @81
              reference: <testLibraryFragment>::@class::C::@method::methodPositional
              element: <testLibrary>::@class::C::@method::methodPositional
              formalParameters
                default p @99
                  element: <testLibraryFragment>::@class::C::@method::methodPositional::@parameter::p#element
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
            methodPositionalWithoutDefault @121
              reference: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
              element: <testLibrary>::@class::C::@method::methodPositionalWithoutDefault
              formalParameters
                default p @153
                  element: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault::@parameter::p#element
            methodNamed @167
              reference: <testLibraryFragment>::@class::C::@method::methodNamed
              element: <testLibrary>::@class::C::@method::methodNamed
              formalParameters
                default p @180
                  reference: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p
                  element: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p#element
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
            methodNamedWithoutDefault @201
              reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
              element: <testLibrary>::@class::C::@method::methodNamedWithoutDefault
              formalParameters
                default p @228
                  reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p
                  element: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const positional
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
          formalParameters
            optionalPositional hasImplicitType p
              type: dynamic
              constantInitializer
                expression: expression_0
        const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            optionalNamed hasImplicitType p
              firstFragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p
              type: dynamic
              constantInitializer
                fragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p
                expression: expression_1
      methods
        methodPositional
          reference: <testLibrary>::@class::C::@method::methodPositional
          firstFragment: <testLibraryFragment>::@class::C::@method::methodPositional
          formalParameters
            optionalPositional hasImplicitType p
              type: dynamic
              constantInitializer
                expression: expression_2
          returnType: void
        methodPositionalWithoutDefault
          reference: <testLibrary>::@class::C::@method::methodPositionalWithoutDefault
          firstFragment: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
          formalParameters
            optionalPositional hasImplicitType p
              type: dynamic
          returnType: void
        methodNamed
          reference: <testLibrary>::@class::C::@method::methodNamed
          firstFragment: <testLibraryFragment>::@class::C::@method::methodNamed
          formalParameters
            optionalNamed hasImplicitType p
              firstFragment: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p
              type: dynamic
              constantInitializer
                fragment: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p
                expression: expression_3
          returnType: void
        methodNamedWithoutDefault
          reference: <testLibrary>::@class::C::@method::methodNamedWithoutDefault
          firstFragment: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
          formalParameters
            optionalNamed hasImplicitType p
              firstFragment: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PostfixExpression
              operand: SimpleIdentifier
                token: a @23
                element: <null>
                staticType: null
              operator: ++ @24
              readElement2: <testLibraryFragment>::@getter::a#element
              readType: int
              writeElement2: <testLibraryFragment>::@getter::a#element
              writeType: InvalidType
              element: dart:core::@class::num::@method::+
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @15
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PostfixExpression
              operand: SimpleIdentifier
                token: a @28
                element: <testLibraryFragment>::@getter::a#element
                staticType: int?
              operator: ! @29
              element: <null>
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int?
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int?
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PrefixExpression
              operator: - @23
              operand: SimpleIdentifier
                token: a @24
                element: <testLibraryFragment>::@getter::a#element
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_0
            PrefixExpression
              operator: - @27
              operand: SimpleIdentifier
                token: a @28
                element: package:test/a.dart::<fragment>::@getter::a#element
                staticType: Object
              element: package:test/a.dart::@extension::E::@method::unary-
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_0
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            PrefixExpression
              operator: ++ @23
              operand: SimpleIdentifier
                token: a @25
                element: <null>
                staticType: null
              readElement2: <testLibraryFragment>::@getter::a#element
              readType: int
              writeElement2: <testLibraryFragment>::@getter::a#element
              writeType: InvalidType
              element: dart:core::@class::num::@method::+
              staticType: int
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            RecordLiteral
              leftParenthesis: ( @23
              fields
                SimpleIdentifier
                  token: a @24
                  element: <testLibraryFragment>::@getter::a#element
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
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: int
              rightParenthesis: ) @31
              staticType: (int, {int a})
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: (int, {int a})
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: (int, {int a})
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            RecordLiteral
              constKeyword: const @23
              leftParenthesis: ( @29
              fields
                SimpleIdentifier
                  token: a @30
                  element: <testLibraryFragment>::@getter::a#element
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
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: int
              rightParenthesis: ) @37
              staticType: (int, {int a})
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: (int, {int a})
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: (int, {int a})
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer F @29
              reference: <testLibraryFragment>::@class::C::@field::F
              element: <testLibrary>::@class::C::@field::F
              initializer: expression_0
                IntegerLiteral
                  literal: 42 @33
                  staticType: int
              getter2: <testLibraryFragment>::@class::C::@getter::F
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get F
              reference: <testLibraryFragment>::@class::C::@getter::F
              element: <testLibraryFragment>::@class::C::@getter::F#element
      topLevelVariables
        hasInitializer V @45
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                element: <testLibraryFragment>::@class::C::@getter::F#element
                staticType: int
              element: <testLibraryFragment>::@class::C::@getter::F#element
              staticType: int
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const hasInitializer F
          firstFragment: <testLibraryFragment>::@class::C::@field::F
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::F
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::F#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get F
          firstFragment: <testLibraryFragment>::@class::C::@getter::F
          returnType: int
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_1
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                staticType: int
              element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
              staticType: int
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
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
                element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            m @23
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                a @29
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::a#element
                b @39
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::b#element
      topLevelVariables
        hasInitializer V @57
          reference: <testLibraryFragment>::@topLevelVariable::V
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          formalParameters
            requiredPositional a
              type: int
            requiredPositional b
              type: String
          returnType: int
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int Function(int, String)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int Function(int, String)
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int Function(int, String)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int Function(int, String)
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int Function(int, String)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int Function(int, String)
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          element: <testLibrary>::@extension::E
          methods
            f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              element: <testLibrary>::@extension::E::@method::f
      topLevelVariables
        hasInitializer x @59
          reference: <testLibraryFragment>::@topLevelVariable::x
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      methods
        static f
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: <testLibraryFragment>::@extension::E::@method::f
          returnType: void
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: void Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: void Function()
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @15
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @19
              element: <testLibrary>::@function::foo
              staticType: dynamic Function()
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: dynamic Function()
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @26
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @30
              element: <testLibrary>::@function::foo
              staticType: R Function<P, R>(P)
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
      functions
        foo @2
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
          typeParameters
            P @6
              element: P@6
            R @9
              element: R@9
          formalParameters
            p @14
              element: <testLibraryFragment>::@function::foo::@parameter::p#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: R Function<P, R>(P)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: R Function<P, R>(P)
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      typeParameters
        P
        R
      formalParameters
        requiredPositional p
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @27
              element: package:test/a.dart::@function::foo
              staticType: dynamic Function()
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: dynamic Function()
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic Function()
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: dynamic Function()
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer A @6
          reference: <testLibraryFragment>::@topLevelVariable::A
          element: <testLibrary>::@topLevelVariable::A
          initializer: expression_0
            IntegerLiteral
              literal: 1 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::A
        hasInitializer B @19
          reference: <testLibraryFragment>::@topLevelVariable::B
          element: <testLibrary>::@topLevelVariable::B
          initializer: expression_1
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @23
                element: <testLibraryFragment>::@getter::A#element
                staticType: int
              operator: + @25
              rightOperand: IntegerLiteral
                literal: 2 @27
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
          getter2: <testLibraryFragment>::@getter::B
      getters
        synthetic get A
          reference: <testLibraryFragment>::@getter::A
          element: <testLibraryFragment>::@getter::A#element
        synthetic get B
          reference: <testLibraryFragment>::@getter::B
          element: <testLibraryFragment>::@getter::B#element
  topLevelVariables
    const hasInitializer A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: <testLibraryFragment>::@topLevelVariable::A
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::A
        expression: expression_0
      getter: <testLibraryFragment>::@getter::A#element
    const hasInitializer B
      reference: <testLibrary>::@topLevelVariable::B
      firstFragment: <testLibraryFragment>::@topLevelVariable::B
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::B
        expression: expression_1
      getter: <testLibraryFragment>::@getter::B#element
  getters
    synthetic static get A
      firstFragment: <testLibraryFragment>::@getter::A
      returnType: int
    synthetic static get B
      firstFragment: <testLibraryFragment>::@getter::B
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer B @23
          reference: <testLibraryFragment>::@topLevelVariable::B
          element: <testLibrary>::@topLevelVariable::B
          initializer: expression_0
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @27
                element: package:test/a.dart::<fragment>::@getter::A#element
                staticType: int
              operator: + @29
              rightOperand: IntegerLiteral
                literal: 2 @31
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
          getter2: <testLibraryFragment>::@getter::B
      getters
        synthetic get B
          reference: <testLibraryFragment>::@getter::B
          element: <testLibraryFragment>::@getter::B#element
  topLevelVariables
    const hasInitializer B
      reference: <testLibrary>::@topLevelVariable::B
      firstFragment: <testLibraryFragment>::@topLevelVariable::B
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::B
        expression: expression_0
      getter: <testLibraryFragment>::@getter::B#element
  getters
    synthetic static get B
      firstFragment: <testLibraryFragment>::@getter::B
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer B @28
          reference: <testLibraryFragment>::@topLevelVariable::B
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
                  element: package:test/a.dart::<fragment>::@getter::A#element
                  staticType: int
                element: package:test/a.dart::<fragment>::@getter::A#element
                staticType: int
              operator: + @36
              rightOperand: IntegerLiteral
                literal: 2 @38
                staticType: int
              element: dart:core::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
          getter2: <testLibraryFragment>::@getter::B
      getters
        synthetic get B
          reference: <testLibraryFragment>::@getter::B
          element: <testLibraryFragment>::@getter::B#element
  topLevelVariables
    const hasInitializer B
      reference: <testLibrary>::@topLevelVariable::B
      firstFragment: <testLibraryFragment>::@topLevelVariable::B
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::B
        expression: expression_0
      getter: <testLibraryFragment>::@getter::B#element
  getters
    synthetic static get B
      firstFragment: <testLibraryFragment>::@getter::B
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        class D @17
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          typeParameters
            T @19
              element: T@19
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      enums
        enum E @30
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer a @33
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            hasInitializer b @36
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            hasInitializer c @39
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibraryFragment>::@enum::E::@getter::c#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            synthetic get a
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            synthetic get b
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            synthetic get c
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <testLibraryFragment>::@enum::E::@getter::c#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      typeAliases
        F @50
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer vDynamic @76
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          element: <testLibrary>::@topLevelVariable::vDynamic
          initializer: expression_4
            SimpleIdentifier
              token: dynamic @87
              element: dynamic
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vDynamic
        hasInitializer vNull @102
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          element: <testLibrary>::@topLevelVariable::vNull
          initializer: expression_5
            SimpleIdentifier
              token: Null @110
              element: dart:core::@class::Null
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vNull
        hasInitializer vObject @122
          reference: <testLibraryFragment>::@topLevelVariable::vObject
          element: <testLibrary>::@topLevelVariable::vObject
          initializer: expression_6
            SimpleIdentifier
              token: Object @132
              element: dart:core::@class::Object
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vObject
        hasInitializer vClass @146
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          element: <testLibrary>::@topLevelVariable::vClass
          initializer: expression_7
            SimpleIdentifier
              token: C @155
              element: <testLibrary>::@class::C
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vClass
        hasInitializer vGenericClass @164
          reference: <testLibraryFragment>::@topLevelVariable::vGenericClass
          element: <testLibrary>::@topLevelVariable::vGenericClass
          initializer: expression_8
            SimpleIdentifier
              token: D @180
              element: <testLibrary>::@class::D
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vGenericClass
        hasInitializer vEnum @189
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          element: <testLibrary>::@topLevelVariable::vEnum
          initializer: expression_9
            SimpleIdentifier
              token: E @197
              element: <testLibrary>::@enum::E
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vEnum
        hasInitializer vFunctionTypeAlias @206
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          element: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
          initializer: expression_10
            SimpleIdentifier
              token: F @227
              element: <testLibrary>::@typeAlias::F
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vFunctionTypeAlias
      getters
        synthetic get vDynamic
          reference: <testLibraryFragment>::@getter::vDynamic
          element: <testLibraryFragment>::@getter::vDynamic#element
        synthetic get vNull
          reference: <testLibraryFragment>::@getter::vNull
          element: <testLibraryFragment>::@getter::vNull#element
        synthetic get vObject
          reference: <testLibraryFragment>::@getter::vObject
          element: <testLibraryFragment>::@getter::vObject#element
        synthetic get vClass
          reference: <testLibraryFragment>::@getter::vClass
          element: <testLibraryFragment>::@getter::vClass#element
        synthetic get vGenericClass
          reference: <testLibraryFragment>::@getter::vGenericClass
          element: <testLibraryFragment>::@getter::vGenericClass#element
        synthetic get vEnum
          reference: <testLibraryFragment>::@getter::vEnum
          element: <testLibraryFragment>::@getter::vEnum#element
        synthetic get vFunctionTypeAlias
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          element: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const enumConstant hasInitializer b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::b
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        static const enumConstant hasInitializer c
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::c
            expression: expression_2
          getter: <testLibraryFragment>::@enum::E::@getter::c#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_3
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
          returnType: E
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
          returnType: E
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function(int, String)
  topLevelVariables
    const hasInitializer vDynamic
      reference: <testLibrary>::@topLevelVariable::vDynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDynamic
        expression: expression_4
      getter: <testLibraryFragment>::@getter::vDynamic#element
    const hasInitializer vNull
      reference: <testLibrary>::@topLevelVariable::vNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNull
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vNull
        expression: expression_5
      getter: <testLibraryFragment>::@getter::vNull#element
    const hasInitializer vObject
      reference: <testLibrary>::@topLevelVariable::vObject
      firstFragment: <testLibraryFragment>::@topLevelVariable::vObject
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vObject
        expression: expression_6
      getter: <testLibraryFragment>::@getter::vObject#element
    const hasInitializer vClass
      reference: <testLibrary>::@topLevelVariable::vClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vClass
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vClass
        expression: expression_7
      getter: <testLibraryFragment>::@getter::vClass#element
    const hasInitializer vGenericClass
      reference: <testLibrary>::@topLevelVariable::vGenericClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vGenericClass
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vGenericClass
        expression: expression_8
      getter: <testLibraryFragment>::@getter::vGenericClass#element
    const hasInitializer vEnum
      reference: <testLibrary>::@topLevelVariable::vEnum
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEnum
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vEnum
        expression: expression_9
      getter: <testLibraryFragment>::@getter::vEnum#element
    const hasInitializer vFunctionTypeAlias
      reference: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
        expression: expression_10
      getter: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  getters
    synthetic static get vDynamic
      firstFragment: <testLibraryFragment>::@getter::vDynamic
      returnType: Type
    synthetic static get vNull
      firstFragment: <testLibraryFragment>::@getter::vNull
      returnType: Type
    synthetic static get vObject
      firstFragment: <testLibraryFragment>::@getter::vObject
      returnType: Type
    synthetic static get vClass
      firstFragment: <testLibraryFragment>::@getter::vClass
      returnType: Type
    synthetic static get vGenericClass
      firstFragment: <testLibraryFragment>::@getter::vGenericClass
      returnType: Type
    synthetic static get vEnum
      firstFragment: <testLibraryFragment>::@getter::vEnum
      returnType: Type
    synthetic static get vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@getter::vFunctionTypeAlias
      returnType: Type
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer f @31
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibrary>::@class::C::@field::f
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final hasInitializer f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: List<dynamic Function()>
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          returnType: List<dynamic Function()>
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer vClass @23
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          element: <testLibrary>::@topLevelVariable::vClass
          initializer: expression_0
            SimpleIdentifier
              token: C @32
              element: package:test/a.dart::@class::C
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vClass
        hasInitializer vEnum @41
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          element: <testLibrary>::@topLevelVariable::vEnum
          initializer: expression_1
            SimpleIdentifier
              token: E @49
              element: package:test/a.dart::@enum::E
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vEnum
        hasInitializer vFunctionTypeAlias @58
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          element: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
          initializer: expression_2
            SimpleIdentifier
              token: F @79
              element: package:test/a.dart::@typeAlias::F
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vFunctionTypeAlias
      getters
        synthetic get vClass
          reference: <testLibraryFragment>::@getter::vClass
          element: <testLibraryFragment>::@getter::vClass#element
        synthetic get vEnum
          reference: <testLibraryFragment>::@getter::vEnum
          element: <testLibraryFragment>::@getter::vEnum#element
        synthetic get vFunctionTypeAlias
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          element: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  topLevelVariables
    const hasInitializer vClass
      reference: <testLibrary>::@topLevelVariable::vClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vClass
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vClass
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vClass#element
    const hasInitializer vEnum
      reference: <testLibrary>::@topLevelVariable::vEnum
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEnum
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vEnum
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vEnum#element
    const hasInitializer vFunctionTypeAlias
      reference: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  getters
    synthetic static get vClass
      firstFragment: <testLibraryFragment>::@getter::vClass
      returnType: Type
    synthetic static get vEnum
      firstFragment: <testLibraryFragment>::@getter::vEnum
      returnType: Type
    synthetic static get vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@getter::vFunctionTypeAlias
      returnType: Type
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer vClass @28
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          element: <testLibrary>::@topLevelVariable::vClass
          initializer: expression_0
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @37
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @38
              identifier: SimpleIdentifier
                token: C @39
                element: package:test/a.dart::@class::C
                staticType: Type
              element: package:test/a.dart::@class::C
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vClass
        hasInitializer vEnum @48
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          element: <testLibrary>::@topLevelVariable::vEnum
          initializer: expression_1
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @56
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @57
              identifier: SimpleIdentifier
                token: E @58
                element: package:test/a.dart::@enum::E
                staticType: Type
              element: package:test/a.dart::@enum::E
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vEnum
        hasInitializer vFunctionTypeAlias @67
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          element: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
          initializer: expression_2
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @88
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @89
              identifier: SimpleIdentifier
                token: F @90
                element: package:test/a.dart::@typeAlias::F
                staticType: Type
              element: package:test/a.dart::@typeAlias::F
              staticType: Type
          getter2: <testLibraryFragment>::@getter::vFunctionTypeAlias
      getters
        synthetic get vClass
          reference: <testLibraryFragment>::@getter::vClass
          element: <testLibraryFragment>::@getter::vClass#element
        synthetic get vEnum
          reference: <testLibraryFragment>::@getter::vEnum
          element: <testLibraryFragment>::@getter::vEnum#element
        synthetic get vFunctionTypeAlias
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          element: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  topLevelVariables
    const hasInitializer vClass
      reference: <testLibrary>::@topLevelVariable::vClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vClass
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vClass
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vClass#element
    const hasInitializer vEnum
      reference: <testLibrary>::@topLevelVariable::vEnum
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEnum
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vEnum
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vEnum#element
    const hasInitializer vFunctionTypeAlias
      reference: <testLibrary>::@topLevelVariable::vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  getters
    synthetic static get vClass
      firstFragment: <testLibraryFragment>::@getter::vClass
      returnType: Type
    synthetic static get vEnum
      firstFragment: <testLibraryFragment>::@getter::vEnum
      returnType: Type
    synthetic static get vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@getter::vFunctionTypeAlias
      returnType: Type
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          fields
            hasInitializer f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibrary>::@class::C::@field::f
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        final hasInitializer f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          hasEnclosingTypeParameterReference: true
          type: List<T>
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          hasEnclosingTypeParameterReference: true
          returnType: List<T>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          initializer: expression_0
            SimpleIdentifier
              token: foo @10
              element: <null>
              staticType: InvalidType
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        hasInitializer V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as p @21
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @21
      topLevelVariables
        hasInitializer V @30
          reference: <testLibraryFragment>::@topLevelVariable::V
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
          getter2: <testLibraryFragment>::@getter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::V
        expression: expression_0
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
                          element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element2: dart:core::@class::int
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
                          element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Object
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vEqual
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
          getter2: <testLibraryFragment>::@getter::vEqual
        hasInitializer vAnd @29
          reference: <testLibraryFragment>::@topLevelVariable::vAnd
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
          getter2: <testLibraryFragment>::@getter::vAnd
        hasInitializer vOr @57
          reference: <testLibraryFragment>::@topLevelVariable::vOr
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
          getter2: <testLibraryFragment>::@getter::vOr
        hasInitializer vBitXor @84
          reference: <testLibraryFragment>::@topLevelVariable::vBitXor
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
          getter2: <testLibraryFragment>::@getter::vBitXor
        hasInitializer vBitAnd @107
          reference: <testLibraryFragment>::@topLevelVariable::vBitAnd
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
          getter2: <testLibraryFragment>::@getter::vBitAnd
        hasInitializer vBitOr @130
          reference: <testLibraryFragment>::@topLevelVariable::vBitOr
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
          getter2: <testLibraryFragment>::@getter::vBitOr
        hasInitializer vBitShiftLeft @152
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
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
          getter2: <testLibraryFragment>::@getter::vBitShiftLeft
        hasInitializer vBitShiftRight @182
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
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
          getter2: <testLibraryFragment>::@getter::vBitShiftRight
        hasInitializer vAdd @213
          reference: <testLibraryFragment>::@topLevelVariable::vAdd
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
          getter2: <testLibraryFragment>::@getter::vAdd
        hasInitializer vSubtract @233
          reference: <testLibraryFragment>::@topLevelVariable::vSubtract
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
          getter2: <testLibraryFragment>::@getter::vSubtract
        hasInitializer vMiltiply @258
          reference: <testLibraryFragment>::@topLevelVariable::vMiltiply
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
          getter2: <testLibraryFragment>::@getter::vMiltiply
        hasInitializer vDivide @283
          reference: <testLibraryFragment>::@topLevelVariable::vDivide
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
          getter2: <testLibraryFragment>::@getter::vDivide
        hasInitializer vFloorDivide @306
          reference: <testLibraryFragment>::@topLevelVariable::vFloorDivide
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
          getter2: <testLibraryFragment>::@getter::vFloorDivide
        hasInitializer vModulo @335
          reference: <testLibraryFragment>::@topLevelVariable::vModulo
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
          getter2: <testLibraryFragment>::@getter::vModulo
        hasInitializer vGreater @358
          reference: <testLibraryFragment>::@topLevelVariable::vGreater
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
          getter2: <testLibraryFragment>::@getter::vGreater
        hasInitializer vGreaterEqual @382
          reference: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
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
          getter2: <testLibraryFragment>::@getter::vGreaterEqual
        hasInitializer vLess @412
          reference: <testLibraryFragment>::@topLevelVariable::vLess
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
          getter2: <testLibraryFragment>::@getter::vLess
        hasInitializer vLessEqual @433
          reference: <testLibraryFragment>::@topLevelVariable::vLessEqual
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
          getter2: <testLibraryFragment>::@getter::vLessEqual
      getters
        synthetic get vEqual
          reference: <testLibraryFragment>::@getter::vEqual
          element: <testLibraryFragment>::@getter::vEqual#element
        synthetic get vAnd
          reference: <testLibraryFragment>::@getter::vAnd
          element: <testLibraryFragment>::@getter::vAnd#element
        synthetic get vOr
          reference: <testLibraryFragment>::@getter::vOr
          element: <testLibraryFragment>::@getter::vOr#element
        synthetic get vBitXor
          reference: <testLibraryFragment>::@getter::vBitXor
          element: <testLibraryFragment>::@getter::vBitXor#element
        synthetic get vBitAnd
          reference: <testLibraryFragment>::@getter::vBitAnd
          element: <testLibraryFragment>::@getter::vBitAnd#element
        synthetic get vBitOr
          reference: <testLibraryFragment>::@getter::vBitOr
          element: <testLibraryFragment>::@getter::vBitOr#element
        synthetic get vBitShiftLeft
          reference: <testLibraryFragment>::@getter::vBitShiftLeft
          element: <testLibraryFragment>::@getter::vBitShiftLeft#element
        synthetic get vBitShiftRight
          reference: <testLibraryFragment>::@getter::vBitShiftRight
          element: <testLibraryFragment>::@getter::vBitShiftRight#element
        synthetic get vAdd
          reference: <testLibraryFragment>::@getter::vAdd
          element: <testLibraryFragment>::@getter::vAdd#element
        synthetic get vSubtract
          reference: <testLibraryFragment>::@getter::vSubtract
          element: <testLibraryFragment>::@getter::vSubtract#element
        synthetic get vMiltiply
          reference: <testLibraryFragment>::@getter::vMiltiply
          element: <testLibraryFragment>::@getter::vMiltiply#element
        synthetic get vDivide
          reference: <testLibraryFragment>::@getter::vDivide
          element: <testLibraryFragment>::@getter::vDivide#element
        synthetic get vFloorDivide
          reference: <testLibraryFragment>::@getter::vFloorDivide
          element: <testLibraryFragment>::@getter::vFloorDivide#element
        synthetic get vModulo
          reference: <testLibraryFragment>::@getter::vModulo
          element: <testLibraryFragment>::@getter::vModulo#element
        synthetic get vGreater
          reference: <testLibraryFragment>::@getter::vGreater
          element: <testLibraryFragment>::@getter::vGreater#element
        synthetic get vGreaterEqual
          reference: <testLibraryFragment>::@getter::vGreaterEqual
          element: <testLibraryFragment>::@getter::vGreaterEqual#element
        synthetic get vLess
          reference: <testLibraryFragment>::@getter::vLess
          element: <testLibraryFragment>::@getter::vLess#element
        synthetic get vLessEqual
          reference: <testLibraryFragment>::@getter::vLessEqual
          element: <testLibraryFragment>::@getter::vLessEqual#element
  topLevelVariables
    const hasInitializer vEqual
      reference: <testLibrary>::@topLevelVariable::vEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEqual
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vEqual
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vEqual#element
    const hasInitializer vAnd
      reference: <testLibrary>::@topLevelVariable::vAnd
      firstFragment: <testLibraryFragment>::@topLevelVariable::vAnd
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vAnd
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vAnd#element
    const hasInitializer vOr
      reference: <testLibrary>::@topLevelVariable::vOr
      firstFragment: <testLibraryFragment>::@topLevelVariable::vOr
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vOr
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vOr#element
    const hasInitializer vBitXor
      reference: <testLibrary>::@topLevelVariable::vBitXor
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitXor
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBitXor
        expression: expression_3
      getter: <testLibraryFragment>::@getter::vBitXor#element
    const hasInitializer vBitAnd
      reference: <testLibrary>::@topLevelVariable::vBitAnd
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitAnd
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBitAnd
        expression: expression_4
      getter: <testLibraryFragment>::@getter::vBitAnd#element
    const hasInitializer vBitOr
      reference: <testLibrary>::@topLevelVariable::vBitOr
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitOr
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBitOr
        expression: expression_5
      getter: <testLibraryFragment>::@getter::vBitOr#element
    const hasInitializer vBitShiftLeft
      reference: <testLibrary>::@topLevelVariable::vBitShiftLeft
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
        expression: expression_6
      getter: <testLibraryFragment>::@getter::vBitShiftLeft#element
    const hasInitializer vBitShiftRight
      reference: <testLibrary>::@topLevelVariable::vBitShiftRight
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
        expression: expression_7
      getter: <testLibraryFragment>::@getter::vBitShiftRight#element
    const hasInitializer vAdd
      reference: <testLibrary>::@topLevelVariable::vAdd
      firstFragment: <testLibraryFragment>::@topLevelVariable::vAdd
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vAdd
        expression: expression_8
      getter: <testLibraryFragment>::@getter::vAdd#element
    const hasInitializer vSubtract
      reference: <testLibrary>::@topLevelVariable::vSubtract
      firstFragment: <testLibraryFragment>::@topLevelVariable::vSubtract
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vSubtract
        expression: expression_9
      getter: <testLibraryFragment>::@getter::vSubtract#element
    const hasInitializer vMiltiply
      reference: <testLibrary>::@topLevelVariable::vMiltiply
      firstFragment: <testLibraryFragment>::@topLevelVariable::vMiltiply
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vMiltiply
        expression: expression_10
      getter: <testLibraryFragment>::@getter::vMiltiply#element
    const hasInitializer vDivide
      reference: <testLibrary>::@topLevelVariable::vDivide
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDivide
      type: double
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDivide
        expression: expression_11
      getter: <testLibraryFragment>::@getter::vDivide#element
    const hasInitializer vFloorDivide
      reference: <testLibrary>::@topLevelVariable::vFloorDivide
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFloorDivide
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vFloorDivide
        expression: expression_12
      getter: <testLibraryFragment>::@getter::vFloorDivide#element
    const hasInitializer vModulo
      reference: <testLibrary>::@topLevelVariable::vModulo
      firstFragment: <testLibraryFragment>::@topLevelVariable::vModulo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vModulo
        expression: expression_13
      getter: <testLibraryFragment>::@getter::vModulo#element
    const hasInitializer vGreater
      reference: <testLibrary>::@topLevelVariable::vGreater
      firstFragment: <testLibraryFragment>::@topLevelVariable::vGreater
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vGreater
        expression: expression_14
      getter: <testLibraryFragment>::@getter::vGreater#element
    const hasInitializer vGreaterEqual
      reference: <testLibrary>::@topLevelVariable::vGreaterEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
        expression: expression_15
      getter: <testLibraryFragment>::@getter::vGreaterEqual#element
    const hasInitializer vLess
      reference: <testLibrary>::@topLevelVariable::vLess
      firstFragment: <testLibraryFragment>::@topLevelVariable::vLess
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vLess
        expression: expression_16
      getter: <testLibraryFragment>::@getter::vLess#element
    const hasInitializer vLessEqual
      reference: <testLibrary>::@topLevelVariable::vLessEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vLessEqual
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vLessEqual
        expression: expression_17
      getter: <testLibraryFragment>::@getter::vLessEqual#element
  getters
    synthetic static get vEqual
      firstFragment: <testLibraryFragment>::@getter::vEqual
      returnType: bool
    synthetic static get vAnd
      firstFragment: <testLibraryFragment>::@getter::vAnd
      returnType: bool
    synthetic static get vOr
      firstFragment: <testLibraryFragment>::@getter::vOr
      returnType: bool
    synthetic static get vBitXor
      firstFragment: <testLibraryFragment>::@getter::vBitXor
      returnType: int
    synthetic static get vBitAnd
      firstFragment: <testLibraryFragment>::@getter::vBitAnd
      returnType: int
    synthetic static get vBitOr
      firstFragment: <testLibraryFragment>::@getter::vBitOr
      returnType: int
    synthetic static get vBitShiftLeft
      firstFragment: <testLibraryFragment>::@getter::vBitShiftLeft
      returnType: int
    synthetic static get vBitShiftRight
      firstFragment: <testLibraryFragment>::@getter::vBitShiftRight
      returnType: int
    synthetic static get vAdd
      firstFragment: <testLibraryFragment>::@getter::vAdd
      returnType: int
    synthetic static get vSubtract
      firstFragment: <testLibraryFragment>::@getter::vSubtract
      returnType: int
    synthetic static get vMiltiply
      firstFragment: <testLibraryFragment>::@getter::vMiltiply
      returnType: int
    synthetic static get vDivide
      firstFragment: <testLibraryFragment>::@getter::vDivide
      returnType: double
    synthetic static get vFloorDivide
      firstFragment: <testLibraryFragment>::@getter::vFloorDivide
      returnType: int
    synthetic static get vModulo
      firstFragment: <testLibraryFragment>::@getter::vModulo
      returnType: int
    synthetic static get vGreater
      firstFragment: <testLibraryFragment>::@getter::vGreater
      returnType: bool
    synthetic static get vGreaterEqual
      firstFragment: <testLibraryFragment>::@getter::vGreaterEqual
      returnType: bool
    synthetic static get vLess
      firstFragment: <testLibraryFragment>::@getter::vLess
      returnType: bool
    synthetic static get vLessEqual
      firstFragment: <testLibraryFragment>::@getter::vLessEqual
      returnType: bool
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vConditional @6
          reference: <testLibraryFragment>::@topLevelVariable::vConditional
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
          getter2: <testLibraryFragment>::@getter::vConditional
      getters
        synthetic get vConditional
          reference: <testLibraryFragment>::@getter::vConditional
          element: <testLibraryFragment>::@getter::vConditional#element
  topLevelVariables
    const hasInitializer vConditional
      reference: <testLibrary>::@topLevelVariable::vConditional
      firstFragment: <testLibraryFragment>::@topLevelVariable::vConditional
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vConditional
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vConditional#element
  getters
    synthetic static get vConditional
      firstFragment: <testLibraryFragment>::@getter::vConditional
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vIdentical @6
          reference: <testLibraryFragment>::@topLevelVariable::vIdentical
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
          getter2: <testLibraryFragment>::@getter::vIdentical
      getters
        synthetic get vIdentical
          reference: <testLibraryFragment>::@getter::vIdentical
          element: <testLibraryFragment>::@getter::vIdentical#element
  topLevelVariables
    const hasInitializer vIdentical
      reference: <testLibrary>::@topLevelVariable::vIdentical
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIdentical
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIdentical
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vIdentical#element
  getters
    synthetic static get vIdentical
      firstFragment: <testLibraryFragment>::@getter::vIdentical
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vIfNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vIfNull
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
          getter2: <testLibraryFragment>::@getter::vIfNull
      getters
        synthetic get vIfNull
          reference: <testLibraryFragment>::@getter::vIfNull
          element: <testLibraryFragment>::@getter::vIfNull#element
  topLevelVariables
    const hasInitializer vIfNull
      reference: <testLibrary>::@topLevelVariable::vIfNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIfNull
      type: num
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIfNull
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vIfNull#element
  getters
    synthetic static get vIfNull
      firstFragment: <testLibraryFragment>::@getter::vIfNull
      returnType: num
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          element: <testLibrary>::@topLevelVariable::vNull
          initializer: expression_0
            NullLiteral
              literal: null @14
              staticType: Null
          getter2: <testLibraryFragment>::@getter::vNull
        hasInitializer vBoolFalse @26
          reference: <testLibraryFragment>::@topLevelVariable::vBoolFalse
          element: <testLibrary>::@topLevelVariable::vBoolFalse
          initializer: expression_1
            BooleanLiteral
              literal: false @39
              staticType: bool
          getter2: <testLibraryFragment>::@getter::vBoolFalse
        hasInitializer vBoolTrue @52
          reference: <testLibraryFragment>::@topLevelVariable::vBoolTrue
          element: <testLibrary>::@topLevelVariable::vBoolTrue
          initializer: expression_2
            BooleanLiteral
              literal: true @64
              staticType: bool
          getter2: <testLibraryFragment>::@getter::vBoolTrue
        hasInitializer vIntPositive @76
          reference: <testLibraryFragment>::@topLevelVariable::vIntPositive
          element: <testLibrary>::@topLevelVariable::vIntPositive
          initializer: expression_3
            IntegerLiteral
              literal: 1 @91
              staticType: int
          getter2: <testLibraryFragment>::@getter::vIntPositive
        hasInitializer vIntNegative @100
          reference: <testLibraryFragment>::@topLevelVariable::vIntNegative
          element: <testLibrary>::@topLevelVariable::vIntNegative
          initializer: expression_4
            PrefixExpression
              operator: - @115
              operand: IntegerLiteral
                literal: 2 @116
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
          getter2: <testLibraryFragment>::@getter::vIntNegative
        hasInitializer vIntLong1 @125
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong1
          element: <testLibrary>::@topLevelVariable::vIntLong1
          initializer: expression_5
            IntegerLiteral
              literal: 0x7FFFFFFFFFFFFFFF @137
              staticType: int
          getter2: <testLibraryFragment>::@getter::vIntLong1
        hasInitializer vIntLong2 @163
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong2
          element: <testLibrary>::@topLevelVariable::vIntLong2
          initializer: expression_6
            IntegerLiteral
              literal: 0xFFFFFFFFFFFFFFFF @175
              staticType: int
          getter2: <testLibraryFragment>::@getter::vIntLong2
        hasInitializer vIntLong3 @201
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong3
          element: <testLibrary>::@topLevelVariable::vIntLong3
          initializer: expression_7
            IntegerLiteral
              literal: 0x8000000000000000 @213
              staticType: int
          getter2: <testLibraryFragment>::@getter::vIntLong3
        hasInitializer vDouble @239
          reference: <testLibraryFragment>::@topLevelVariable::vDouble
          element: <testLibrary>::@topLevelVariable::vDouble
          initializer: expression_8
            DoubleLiteral
              literal: 2.3 @249
              staticType: double
          getter2: <testLibraryFragment>::@getter::vDouble
        hasInitializer vString @260
          reference: <testLibraryFragment>::@topLevelVariable::vString
          element: <testLibrary>::@topLevelVariable::vString
          initializer: expression_9
            SimpleStringLiteral
              literal: 'abc' @270
          getter2: <testLibraryFragment>::@getter::vString
        hasInitializer vStringConcat @283
          reference: <testLibraryFragment>::@topLevelVariable::vStringConcat
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
          getter2: <testLibraryFragment>::@getter::vStringConcat
        hasInitializer vStringInterpolation @318
          reference: <testLibraryFragment>::@topLevelVariable::vStringInterpolation
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
          getter2: <testLibraryFragment>::@getter::vStringInterpolation
        hasInitializer vSymbol @372
          reference: <testLibraryFragment>::@topLevelVariable::vSymbol
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
          getter2: <testLibraryFragment>::@getter::vSymbol
      getters
        synthetic get vNull
          reference: <testLibraryFragment>::@getter::vNull
          element: <testLibraryFragment>::@getter::vNull#element
        synthetic get vBoolFalse
          reference: <testLibraryFragment>::@getter::vBoolFalse
          element: <testLibraryFragment>::@getter::vBoolFalse#element
        synthetic get vBoolTrue
          reference: <testLibraryFragment>::@getter::vBoolTrue
          element: <testLibraryFragment>::@getter::vBoolTrue#element
        synthetic get vIntPositive
          reference: <testLibraryFragment>::@getter::vIntPositive
          element: <testLibraryFragment>::@getter::vIntPositive#element
        synthetic get vIntNegative
          reference: <testLibraryFragment>::@getter::vIntNegative
          element: <testLibraryFragment>::@getter::vIntNegative#element
        synthetic get vIntLong1
          reference: <testLibraryFragment>::@getter::vIntLong1
          element: <testLibraryFragment>::@getter::vIntLong1#element
        synthetic get vIntLong2
          reference: <testLibraryFragment>::@getter::vIntLong2
          element: <testLibraryFragment>::@getter::vIntLong2#element
        synthetic get vIntLong3
          reference: <testLibraryFragment>::@getter::vIntLong3
          element: <testLibraryFragment>::@getter::vIntLong3#element
        synthetic get vDouble
          reference: <testLibraryFragment>::@getter::vDouble
          element: <testLibraryFragment>::@getter::vDouble#element
        synthetic get vString
          reference: <testLibraryFragment>::@getter::vString
          element: <testLibraryFragment>::@getter::vString#element
        synthetic get vStringConcat
          reference: <testLibraryFragment>::@getter::vStringConcat
          element: <testLibraryFragment>::@getter::vStringConcat#element
        synthetic get vStringInterpolation
          reference: <testLibraryFragment>::@getter::vStringInterpolation
          element: <testLibraryFragment>::@getter::vStringInterpolation#element
        synthetic get vSymbol
          reference: <testLibraryFragment>::@getter::vSymbol
          element: <testLibraryFragment>::@getter::vSymbol#element
  topLevelVariables
    const hasInitializer vNull
      reference: <testLibrary>::@topLevelVariable::vNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNull
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vNull
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vNull#element
    const hasInitializer vBoolFalse
      reference: <testLibrary>::@topLevelVariable::vBoolFalse
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBoolFalse
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBoolFalse
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vBoolFalse#element
    const hasInitializer vBoolTrue
      reference: <testLibrary>::@topLevelVariable::vBoolTrue
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBoolTrue
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vBoolTrue
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vBoolTrue#element
    const hasInitializer vIntPositive
      reference: <testLibrary>::@topLevelVariable::vIntPositive
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntPositive
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIntPositive
        expression: expression_3
      getter: <testLibraryFragment>::@getter::vIntPositive#element
    const hasInitializer vIntNegative
      reference: <testLibrary>::@topLevelVariable::vIntNegative
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntNegative
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIntNegative
        expression: expression_4
      getter: <testLibraryFragment>::@getter::vIntNegative#element
    const hasInitializer vIntLong1
      reference: <testLibrary>::@topLevelVariable::vIntLong1
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntLong1
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIntLong1
        expression: expression_5
      getter: <testLibraryFragment>::@getter::vIntLong1#element
    const hasInitializer vIntLong2
      reference: <testLibrary>::@topLevelVariable::vIntLong2
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntLong2
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIntLong2
        expression: expression_6
      getter: <testLibraryFragment>::@getter::vIntLong2#element
    const hasInitializer vIntLong3
      reference: <testLibrary>::@topLevelVariable::vIntLong3
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntLong3
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vIntLong3
        expression: expression_7
      getter: <testLibraryFragment>::@getter::vIntLong3#element
    const hasInitializer vDouble
      reference: <testLibrary>::@topLevelVariable::vDouble
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDouble
      type: double
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDouble
        expression: expression_8
      getter: <testLibraryFragment>::@getter::vDouble#element
    const hasInitializer vString
      reference: <testLibrary>::@topLevelVariable::vString
      firstFragment: <testLibraryFragment>::@topLevelVariable::vString
      type: String
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vString
        expression: expression_9
      getter: <testLibraryFragment>::@getter::vString#element
    const hasInitializer vStringConcat
      reference: <testLibrary>::@topLevelVariable::vStringConcat
      firstFragment: <testLibraryFragment>::@topLevelVariable::vStringConcat
      type: String
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vStringConcat
        expression: expression_10
      getter: <testLibraryFragment>::@getter::vStringConcat#element
    const hasInitializer vStringInterpolation
      reference: <testLibrary>::@topLevelVariable::vStringInterpolation
      firstFragment: <testLibraryFragment>::@topLevelVariable::vStringInterpolation
      type: String
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vStringInterpolation
        expression: expression_11
      getter: <testLibraryFragment>::@getter::vStringInterpolation#element
    const hasInitializer vSymbol
      reference: <testLibrary>::@topLevelVariable::vSymbol
      firstFragment: <testLibraryFragment>::@topLevelVariable::vSymbol
      type: Symbol
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vSymbol
        expression: expression_12
      getter: <testLibraryFragment>::@getter::vSymbol#element
  getters
    synthetic static get vNull
      firstFragment: <testLibraryFragment>::@getter::vNull
      returnType: dynamic
    synthetic static get vBoolFalse
      firstFragment: <testLibraryFragment>::@getter::vBoolFalse
      returnType: bool
    synthetic static get vBoolTrue
      firstFragment: <testLibraryFragment>::@getter::vBoolTrue
      returnType: bool
    synthetic static get vIntPositive
      firstFragment: <testLibraryFragment>::@getter::vIntPositive
      returnType: int
    synthetic static get vIntNegative
      firstFragment: <testLibraryFragment>::@getter::vIntNegative
      returnType: int
    synthetic static get vIntLong1
      firstFragment: <testLibraryFragment>::@getter::vIntLong1
      returnType: int
    synthetic static get vIntLong2
      firstFragment: <testLibraryFragment>::@getter::vIntLong2
      returnType: int
    synthetic static get vIntLong3
      firstFragment: <testLibraryFragment>::@getter::vIntLong3
      returnType: int
    synthetic static get vDouble
      firstFragment: <testLibraryFragment>::@getter::vDouble
      returnType: double
    synthetic static get vString
      firstFragment: <testLibraryFragment>::@getter::vString
      returnType: String
    synthetic static get vStringConcat
      firstFragment: <testLibraryFragment>::@getter::vStringConcat
      returnType: String
    synthetic static get vStringInterpolation
      firstFragment: <testLibraryFragment>::@getter::vStringInterpolation
      returnType: String
    synthetic static get vSymbol
      firstFragment: <testLibraryFragment>::@getter::vSymbol
      returnType: Symbol
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @15
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            MethodInvocation
              target: SimpleIdentifier
                token: a @28
                element: <testLibraryFragment>::@getter::a#element
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
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int?
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: String?
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int?
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: String?
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @15
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            CascadeExpression
              target: SimpleIdentifier
                token: a @28
                element: <testLibraryFragment>::@getter::a#element
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
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int?
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int?
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int?
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int?
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @14
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            SimpleStringLiteral
              literal: '' @18
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @40
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            ListLiteral
              leftBracket: [ @44
              elements
                PropertyAccess
                  target: SimpleIdentifier
                    token: a @48
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: String?
                  operator: ?. @49
                  propertyName: SimpleIdentifier
                    token: length @51
                    element: dart:core::<fragment>::@class::String::@getter::length#element
                    staticType: int
                  staticType: int?
              rightBracket: ] @59
              staticType: List<int?>
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: String?
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: List<int?>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: String?
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: List<int?>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v1 @10
          reference: <testLibraryFragment>::@topLevelVariable::v1
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
          getter2: <testLibraryFragment>::@getter::v1
        hasInitializer v2 @38
          reference: <testLibraryFragment>::@topLevelVariable::v2
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
          getter2: <testLibraryFragment>::@getter::v2
        hasInitializer v3 @63
          reference: <testLibraryFragment>::@topLevelVariable::v3
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
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
          getter2: <testLibraryFragment>::@getter::v3
      getters
        synthetic get v1
          reference: <testLibraryFragment>::@getter::v1
          element: <testLibraryFragment>::@getter::v1#element
        synthetic get v2
          reference: <testLibraryFragment>::@getter::v2
          element: <testLibraryFragment>::@getter::v2#element
        synthetic get v3
          reference: <testLibraryFragment>::@getter::v3
          element: <testLibraryFragment>::@getter::v3#element
  topLevelVariables
    const hasInitializer v1
      reference: <testLibrary>::@topLevelVariable::v1
      firstFragment: <testLibraryFragment>::@topLevelVariable::v1
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v1
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v1#element
    const hasInitializer v2
      reference: <testLibrary>::@topLevelVariable::v2
      firstFragment: <testLibraryFragment>::@topLevelVariable::v2
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v2
        expression: expression_1
      getter: <testLibraryFragment>::@getter::v2#element
    const hasInitializer v3
      reference: <testLibrary>::@topLevelVariable::v3
      firstFragment: <testLibraryFragment>::@topLevelVariable::v3
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v3
        expression: expression_2
      getter: <testLibraryFragment>::@getter::v3#element
  getters
    synthetic static get v1
      firstFragment: <testLibraryFragment>::@getter::v1
      returnType: int
    synthetic static get v2
      firstFragment: <testLibraryFragment>::@getter::v2
      returnType: int
    synthetic static get v3
      firstFragment: <testLibraryFragment>::@getter::v3
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vNotEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vNotEqual
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
          getter2: <testLibraryFragment>::@getter::vNotEqual
        hasInitializer vNot @32
          reference: <testLibraryFragment>::@topLevelVariable::vNot
          element: <testLibrary>::@topLevelVariable::vNot
          initializer: expression_1
            PrefixExpression
              operator: ! @39
              operand: BooleanLiteral
                literal: true @40
                staticType: bool
              element: <null>
              staticType: bool
          getter2: <testLibraryFragment>::@getter::vNot
        hasInitializer vNegate @52
          reference: <testLibraryFragment>::@topLevelVariable::vNegate
          element: <testLibrary>::@topLevelVariable::vNegate
          initializer: expression_2
            PrefixExpression
              operator: - @62
              operand: IntegerLiteral
                literal: 1 @63
                staticType: int
              element: dart:core::@class::int::@method::unary-
              staticType: int
          getter2: <testLibraryFragment>::@getter::vNegate
        hasInitializer vComplement @72
          reference: <testLibraryFragment>::@topLevelVariable::vComplement
          element: <testLibrary>::@topLevelVariable::vComplement
          initializer: expression_3
            PrefixExpression
              operator: ~ @86
              operand: IntegerLiteral
                literal: 1 @87
                staticType: int
              element: dart:core::@class::int::@method::~
              staticType: int
          getter2: <testLibraryFragment>::@getter::vComplement
      getters
        synthetic get vNotEqual
          reference: <testLibraryFragment>::@getter::vNotEqual
          element: <testLibraryFragment>::@getter::vNotEqual#element
        synthetic get vNot
          reference: <testLibraryFragment>::@getter::vNot
          element: <testLibraryFragment>::@getter::vNot#element
        synthetic get vNegate
          reference: <testLibraryFragment>::@getter::vNegate
          element: <testLibraryFragment>::@getter::vNegate#element
        synthetic get vComplement
          reference: <testLibraryFragment>::@getter::vComplement
          element: <testLibraryFragment>::@getter::vComplement#element
  topLevelVariables
    const hasInitializer vNotEqual
      reference: <testLibrary>::@topLevelVariable::vNotEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNotEqual
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vNotEqual
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vNotEqual#element
    const hasInitializer vNot
      reference: <testLibrary>::@topLevelVariable::vNot
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNot
      type: bool
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vNot
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vNot#element
    const hasInitializer vNegate
      reference: <testLibrary>::@topLevelVariable::vNegate
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNegate
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vNegate
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vNegate#element
    const hasInitializer vComplement
      reference: <testLibrary>::@topLevelVariable::vComplement
      firstFragment: <testLibraryFragment>::@topLevelVariable::vComplement
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vComplement
        expression: expression_3
      getter: <testLibraryFragment>::@getter::vComplement#element
  getters
    synthetic static get vNotEqual
      firstFragment: <testLibraryFragment>::@getter::vNotEqual
      returnType: bool
    synthetic static get vNot
      firstFragment: <testLibraryFragment>::@getter::vNot
      returnType: bool
    synthetic static get vNegate
      firstFragment: <testLibraryFragment>::@getter::vNegate
      returnType: int
    synthetic static get vComplement
      firstFragment: <testLibraryFragment>::@getter::vComplement
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vSuper @6
          reference: <testLibraryFragment>::@topLevelVariable::vSuper
          element: <testLibrary>::@topLevelVariable::vSuper
          initializer: expression_0
            SuperExpression
              superKeyword: super @15
              staticType: InvalidType
          getter2: <testLibraryFragment>::@getter::vSuper
      getters
        synthetic get vSuper
          reference: <testLibraryFragment>::@getter::vSuper
          element: <testLibraryFragment>::@getter::vSuper#element
  topLevelVariables
    const hasInitializer vSuper
      reference: <testLibrary>::@topLevelVariable::vSuper
      firstFragment: <testLibraryFragment>::@topLevelVariable::vSuper
      type: InvalidType
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vSuper
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vSuper#element
  getters
    synthetic static get vSuper
      firstFragment: <testLibraryFragment>::@getter::vSuper
      returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vThis @6
          reference: <testLibraryFragment>::@topLevelVariable::vThis
          element: <testLibrary>::@topLevelVariable::vThis
          initializer: expression_0
            ThisExpression
              thisKeyword: this @14
              staticType: dynamic
          getter2: <testLibraryFragment>::@getter::vThis
      getters
        synthetic get vThis
          reference: <testLibraryFragment>::@getter::vThis
          element: <testLibraryFragment>::@getter::vThis#element
  topLevelVariables
    const hasInitializer vThis
      reference: <testLibrary>::@topLevelVariable::vThis
      firstFragment: <testLibraryFragment>::@topLevelVariable::vThis
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vThis
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vThis#element
  getters
    synthetic static get vThis
      firstFragment: <testLibraryFragment>::@getter::vThis
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer c @6
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          initializer: expression_0
            ThrowExpression
              throwKeyword: throw @10
              expression: IntegerLiteral
                literal: 42 @16
                staticType: int
              staticType: Never
          getter2: <testLibraryFragment>::@getter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    const hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: Never
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::c
        expression: expression_0
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: Never
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          element: <testLibrary>::@topLevelVariable::vNull
          initializer: expression_0
            ListLiteral
              constKeyword: const @14
              typeArguments: TypeArgumentList
                leftBracket: < @20
                arguments
                  NamedType
                    name: Null @21
                    element2: dart:core::@class::Null
                    type: Null
                rightBracket: > @25
              leftBracket: [ @26
              rightBracket: ] @27
              staticType: List<Null>
          getter2: <testLibraryFragment>::@getter::vNull
        hasInitializer vDynamic @36
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          element: <testLibrary>::@topLevelVariable::vDynamic
          initializer: expression_1
            ListLiteral
              constKeyword: const @47
              typeArguments: TypeArgumentList
                leftBracket: < @53
                arguments
                  NamedType
                    name: dynamic @54
                    element2: dynamic
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
          getter2: <testLibraryFragment>::@getter::vDynamic
        hasInitializer vInterfaceNoTypeParameters @79
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters
          element: <testLibrary>::@topLevelVariable::vInterfaceNoTypeParameters
          initializer: expression_2
            ListLiteral
              constKeyword: const @108
              typeArguments: TypeArgumentList
                leftBracket: < @114
                arguments
                  NamedType
                    name: int @115
                    element2: dart:core::@class::int
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
          getter2: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
        hasInitializer vInterfaceNoTypeArguments @136
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments
          element: <testLibrary>::@topLevelVariable::vInterfaceNoTypeArguments
          initializer: expression_3
            ListLiteral
              constKeyword: const @164
              typeArguments: TypeArgumentList
                leftBracket: < @170
                arguments
                  NamedType
                    name: List @171
                    element2: dart:core::@class::List
                    type: List<dynamic>
                rightBracket: > @175
              leftBracket: [ @176
              rightBracket: ] @177
              staticType: List<List<dynamic>>
          getter2: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
        hasInitializer vInterfaceWithTypeArguments @186
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
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
                          element2: dart:core::@class::String
                          type: String
                      rightBracket: > @234
                    element2: dart:core::@class::List
                    type: List<String>
                rightBracket: > @235
              leftBracket: [ @236
              rightBracket: ] @237
              staticType: List<List<String>>
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
        hasInitializer vInterfaceWithTypeArguments2 @246
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
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
                          element2: dart:core::@class::int
                          type: int
                        NamedType
                          name: List @293
                          typeArguments: TypeArgumentList
                            leftBracket: < @297
                            arguments
                              NamedType
                                name: String @298
                                element2: dart:core::@class::String
                                type: String
                            rightBracket: > @304
                          element2: dart:core::@class::List
                          type: List<String>
                      rightBracket: > @305
                    element2: dart:core::@class::Map
                    type: Map<int, List<String>>
                rightBracket: > @306
              leftBracket: [ @307
              rightBracket: ] @308
              staticType: List<Map<int, List<String>>>
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
      getters
        synthetic get vNull
          reference: <testLibraryFragment>::@getter::vNull
          element: <testLibraryFragment>::@getter::vNull#element
        synthetic get vDynamic
          reference: <testLibraryFragment>::@getter::vDynamic
          element: <testLibraryFragment>::@getter::vDynamic#element
        synthetic get vInterfaceNoTypeParameters
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
          element: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters#element
        synthetic get vInterfaceNoTypeArguments
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments#element
        synthetic get vInterfaceWithTypeArguments
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
        synthetic get vInterfaceWithTypeArguments2
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2#element
  topLevelVariables
    const hasInitializer vNull
      reference: <testLibrary>::@topLevelVariable::vNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNull
      type: List<Null>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vNull
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vNull#element
    const hasInitializer vDynamic
      reference: <testLibrary>::@topLevelVariable::vDynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic
      type: List<dynamic>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDynamic
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vDynamic#element
    const hasInitializer vInterfaceNoTypeParameters
      reference: <testLibrary>::@topLevelVariable::vInterfaceNoTypeParameters
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters
      type: List<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters#element
    const hasInitializer vInterfaceNoTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceNoTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments
      type: List<List<dynamic>>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments
        expression: expression_3
      getter: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments#element
    const hasInitializer vInterfaceWithTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
      type: List<List<String>>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
        expression: expression_4
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
    const hasInitializer vInterfaceWithTypeArguments2
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments2
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
      type: List<Map<int, List<String>>>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
        expression: expression_5
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2#element
  getters
    synthetic static get vNull
      firstFragment: <testLibraryFragment>::@getter::vNull
      returnType: List<Null>
    synthetic static get vDynamic
      firstFragment: <testLibraryFragment>::@getter::vDynamic
      returnType: List<dynamic>
    synthetic static get vInterfaceNoTypeParameters
      firstFragment: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
      returnType: List<int>
    synthetic static get vInterfaceNoTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
      returnType: List<List<dynamic>>
    synthetic static get vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      returnType: List<List<String>>
    synthetic static get vInterfaceWithTypeArguments2
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
      returnType: List<Map<int, List<String>>>
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ListLiteral
              constKeyword: const @27
              typeArguments: TypeArgumentList
                leftBracket: < @33
                arguments
                  NamedType
                    name: C @34
                    element2: package:test/a.dart::@class::C
                    type: C
                rightBracket: > @35
              leftBracket: [ @36
              rightBracket: ] @37
              staticType: List<C>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<C>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: List<C>
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @19
      topLevelVariables
        hasInitializer v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                      element2: <testLibraryFragment>::@prefix2::p
                    name: C @41
                    element2: package:test/a.dart::@class::C
                    type: C
                rightBracket: > @42
              leftBracket: [ @43
              rightBracket: ] @44
              staticType: List<C>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<C>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: List<C>
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @12
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            ListLiteral
              constKeyword: const @36
              typeArguments: TypeArgumentList
                leftBracket: < @42
                arguments
                  NamedType
                    name: F @43
                    element2: <testLibrary>::@typeAlias::F
                    type: int Function(String)
                      alias: <testLibrary>::@typeAlias::F
                rightBracket: > @44
              leftBracket: [ @45
              rightBracket: ] @46
              staticType: List<int Function(String)>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: int Function(String)
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<int Function(String)>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: List<int Function(String)>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          element: <testLibrary>::@topLevelVariable::vDynamic1
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @18
              typeArguments: TypeArgumentList
                leftBracket: < @24
                arguments
                  NamedType
                    name: dynamic @25
                    element2: dynamic
                    type: dynamic
                  NamedType
                    name: int @34
                    element2: dart:core::@class::int
                    type: int
                rightBracket: > @37
              leftBracket: { @38
              rightBracket: } @39
              isMap: true
              staticType: Map<dynamic, int>
          getter2: <testLibraryFragment>::@getter::vDynamic1
        hasInitializer vDynamic2 @48
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic2
          element: <testLibrary>::@topLevelVariable::vDynamic2
          initializer: expression_1
            SetOrMapLiteral
              constKeyword: const @60
              typeArguments: TypeArgumentList
                leftBracket: < @66
                arguments
                  NamedType
                    name: int @67
                    element2: dart:core::@class::int
                    type: int
                  NamedType
                    name: dynamic @72
                    element2: dynamic
                    type: dynamic
                rightBracket: > @79
              leftBracket: { @80
              rightBracket: } @81
              isMap: true
              staticType: Map<int, dynamic>
          getter2: <testLibraryFragment>::@getter::vDynamic2
        hasInitializer vInterface @90
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          element: <testLibrary>::@topLevelVariable::vInterface
          initializer: expression_2
            SetOrMapLiteral
              constKeyword: const @103
              typeArguments: TypeArgumentList
                leftBracket: < @109
                arguments
                  NamedType
                    name: int @110
                    element2: dart:core::@class::int
                    type: int
                  NamedType
                    name: String @115
                    element2: dart:core::@class::String
                    type: String
                rightBracket: > @121
              leftBracket: { @122
              rightBracket: } @123
              isMap: true
              staticType: Map<int, String>
          getter2: <testLibraryFragment>::@getter::vInterface
        hasInitializer vInterfaceWithTypeArguments @132
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          element: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
          initializer: expression_3
            SetOrMapLiteral
              constKeyword: const @162
              typeArguments: TypeArgumentList
                leftBracket: < @168
                arguments
                  NamedType
                    name: int @169
                    element2: dart:core::@class::int
                    type: int
                  NamedType
                    name: List @174
                    typeArguments: TypeArgumentList
                      leftBracket: < @178
                      arguments
                        NamedType
                          name: String @179
                          element2: dart:core::@class::String
                          type: String
                      rightBracket: > @185
                    element2: dart:core::@class::List
                    type: List<String>
                rightBracket: > @186
              leftBracket: { @187
              rightBracket: } @188
              isMap: true
              staticType: Map<int, List<String>>
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      getters
        synthetic get vDynamic1
          reference: <testLibraryFragment>::@getter::vDynamic1
          element: <testLibraryFragment>::@getter::vDynamic1#element
        synthetic get vDynamic2
          reference: <testLibraryFragment>::@getter::vDynamic2
          element: <testLibraryFragment>::@getter::vDynamic2#element
        synthetic get vInterface
          reference: <testLibraryFragment>::@getter::vInterface
          element: <testLibraryFragment>::@getter::vInterface#element
        synthetic get vInterfaceWithTypeArguments
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  topLevelVariables
    const hasInitializer vDynamic1
      reference: <testLibrary>::@topLevelVariable::vDynamic1
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic1
      type: Map<dynamic, int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDynamic1
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vDynamic1#element
    const hasInitializer vDynamic2
      reference: <testLibrary>::@topLevelVariable::vDynamic2
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic2
      type: Map<int, dynamic>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDynamic2
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vDynamic2#element
    const hasInitializer vInterface
      reference: <testLibrary>::@topLevelVariable::vInterface
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterface
      type: Map<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterface
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vInterface#element
    const hasInitializer vInterfaceWithTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
      type: Map<int, List<String>>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
        expression: expression_3
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  getters
    synthetic static get vDynamic1
      firstFragment: <testLibraryFragment>::@getter::vDynamic1
      returnType: Map<dynamic, int>
    synthetic static get vDynamic2
      firstFragment: <testLibraryFragment>::@getter::vDynamic2
      returnType: Map<int, dynamic>
    synthetic static get vInterface
      firstFragment: <testLibraryFragment>::@getter::vInterface
      returnType: Map<int, String>
    synthetic static get vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      returnType: Map<int, List<String>>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          element: <testLibrary>::@topLevelVariable::vDynamic1
          initializer: expression_0
            SetOrMapLiteral
              constKeyword: const @18
              typeArguments: TypeArgumentList
                leftBracket: < @24
                arguments
                  NamedType
                    name: dynamic @25
                    element2: dynamic
                    type: dynamic
                rightBracket: > @32
              leftBracket: { @33
              rightBracket: } @34
              isMap: false
              staticType: Set<dynamic>
          getter2: <testLibraryFragment>::@getter::vDynamic1
        hasInitializer vInterface @43
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          element: <testLibrary>::@topLevelVariable::vInterface
          initializer: expression_1
            SetOrMapLiteral
              constKeyword: const @56
              typeArguments: TypeArgumentList
                leftBracket: < @62
                arguments
                  NamedType
                    name: int @63
                    element2: dart:core::@class::int
                    type: int
                rightBracket: > @66
              leftBracket: { @67
              rightBracket: } @68
              isMap: false
              staticType: Set<int>
          getter2: <testLibraryFragment>::@getter::vInterface
        hasInitializer vInterfaceWithTypeArguments @77
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
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
                          element2: dart:core::@class::String
                          type: String
                      rightBracket: > @125
                    element2: dart:core::@class::List
                    type: List<String>
                rightBracket: > @126
              leftBracket: { @127
              rightBracket: } @128
              isMap: false
              staticType: Set<List<String>>
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      getters
        synthetic get vDynamic1
          reference: <testLibraryFragment>::@getter::vDynamic1
          element: <testLibraryFragment>::@getter::vDynamic1#element
        synthetic get vInterface
          reference: <testLibraryFragment>::@getter::vInterface
          element: <testLibraryFragment>::@getter::vInterface#element
        synthetic get vInterfaceWithTypeArguments
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  topLevelVariables
    const hasInitializer vDynamic1
      reference: <testLibrary>::@topLevelVariable::vDynamic1
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic1
      type: Set<dynamic>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vDynamic1
        expression: expression_0
      getter: <testLibraryFragment>::@getter::vDynamic1#element
    const hasInitializer vInterface
      reference: <testLibrary>::@topLevelVariable::vInterface
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterface
      type: Set<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterface
        expression: expression_1
      getter: <testLibraryFragment>::@getter::vInterface#element
    const hasInitializer vInterfaceWithTypeArguments
      reference: <testLibrary>::@topLevelVariable::vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
      type: Set<List<String>>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
        expression: expression_2
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  getters
    synthetic static get vDynamic1
      firstFragment: <testLibraryFragment>::@getter::vDynamic1
      returnType: Set<dynamic>
    synthetic static get vInterface
      firstFragment: <testLibraryFragment>::@getter::vInterface
      returnType: Set<int>
    synthetic static get vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      returnType: Set<List<String>>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
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
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: List<int>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
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
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Map<int, String>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Map<int, String>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
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
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Set<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Set<int>
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
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
                      element2: dart:core::@class::int
                      type: int
                  rightBracket: > @18
                element2: dart:core::@class::List
                type: List<int>
              staticType: Type
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Type
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
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            hasInitializer b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            hasInitializer c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibraryFragment>::@enum::E::@getter::c#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            synthetic get a
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            synthetic get b
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            synthetic get c
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <testLibraryFragment>::@enum::E::@getter::c#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        hasInitializer vValue @23
          reference: <testLibraryFragment>::@topLevelVariable::vValue
          element: <testLibrary>::@topLevelVariable::vValue
          getter2: <testLibraryFragment>::@getter::vValue
        hasInitializer vValues @43
          reference: <testLibraryFragment>::@topLevelVariable::vValues
          element: <testLibrary>::@topLevelVariable::vValues
          getter2: <testLibraryFragment>::@getter::vValues
        hasInitializer vIndex @69
          reference: <testLibraryFragment>::@topLevelVariable::vIndex
          element: <testLibrary>::@topLevelVariable::vIndex
          getter2: <testLibraryFragment>::@getter::vIndex
      getters
        synthetic get vValue
          reference: <testLibraryFragment>::@getter::vValue
          element: <testLibraryFragment>::@getter::vValue#element
        synthetic get vValues
          reference: <testLibraryFragment>::@getter::vValues
          element: <testLibraryFragment>::@getter::vValues#element
        synthetic get vIndex
          reference: <testLibraryFragment>::@getter::vIndex
          element: <testLibraryFragment>::@getter::vIndex#element
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const enumConstant hasInitializer b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::b
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        static const enumConstant hasInitializer c
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::c
            expression: expression_2
          getter: <testLibraryFragment>::@enum::E::@getter::c#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_3
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
          returnType: E
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
          returnType: E
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  topLevelVariables
    final hasInitializer vValue
      reference: <testLibrary>::@topLevelVariable::vValue
      firstFragment: <testLibraryFragment>::@topLevelVariable::vValue
      type: E
      getter: <testLibraryFragment>::@getter::vValue#element
    final hasInitializer vValues
      reference: <testLibrary>::@topLevelVariable::vValues
      firstFragment: <testLibraryFragment>::@topLevelVariable::vValues
      type: List<E>
      getter: <testLibraryFragment>::@getter::vValues#element
    final hasInitializer vIndex
      reference: <testLibrary>::@topLevelVariable::vIndex
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIndex
      type: int
      getter: <testLibraryFragment>::@getter::vIndex#element
  getters
    synthetic static get vValue
      firstFragment: <testLibraryFragment>::@getter::vValue
      returnType: E
    synthetic static get vValues
      firstFragment: <testLibraryFragment>::@getter::vValues
      returnType: List<E>
    synthetic static get vIndex
      firstFragment: <testLibraryFragment>::@getter::vIndex
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            synthetic get a
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        hasInitializer vToString @17
          reference: <testLibraryFragment>::@topLevelVariable::vToString
          element: <testLibrary>::@topLevelVariable::vToString
          getter2: <testLibraryFragment>::@getter::vToString
      getters
        synthetic get vToString
          reference: <testLibraryFragment>::@getter::vToString
          element: <testLibraryFragment>::@getter::vToString#element
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  topLevelVariables
    final hasInitializer vToString
      reference: <testLibrary>::@topLevelVariable::vToString
      firstFragment: <testLibraryFragment>::@topLevelVariable::vToString
      type: String
      getter: <testLibraryFragment>::@getter::vToString#element
  getters
    synthetic static get vToString
      firstFragment: <testLibraryFragment>::@getter::vToString
      returnType: String
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              element: <testLibrary>::@class::C::@field::a
              initializer: expression_0
                SimpleIdentifier
                  token: b @29
                  element: <testLibraryFragment>::@class::C::@getter::b#element
                  staticType: dynamic
              getter2: <testLibraryFragment>::@class::C::@getter::a
            hasInitializer b @47
              reference: <testLibraryFragment>::@class::C::@field::b
              element: <testLibrary>::@class::C::@field::b
              initializer: expression_1
                NullLiteral
                  literal: null @51
                  staticType: Null
              getter2: <testLibraryFragment>::@class::C::@getter::b
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::C::@getter::a
              element: <testLibraryFragment>::@class::C::@getter::a#element
            synthetic get b
              reference: <testLibraryFragment>::@class::C::@getter::b
              element: <testLibraryFragment>::@class::C::@getter::b#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const hasInitializer a
          firstFragment: <testLibraryFragment>::@class::C::@field::a
          type: dynamic
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::a#element
        static const hasInitializer b
          firstFragment: <testLibraryFragment>::@class::C::@field::b
          type: dynamic
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::b
            expression: expression_1
          getter: <testLibraryFragment>::@class::C::@getter::b#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
          returnType: dynamic
        synthetic static get b
          firstFragment: <testLibraryFragment>::@class::C::@getter::b
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              element: <testLibrary>::@class::C::@field::a
              initializer: expression_0
                SimpleIdentifier
                  token: m @29
                  element: <testLibrary>::@class::C::@method::m
                  staticType: dynamic Function()
              getter2: <testLibraryFragment>::@class::C::@getter::a
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::C::@getter::a
              element: <testLibraryFragment>::@class::C::@getter::a#element
          methods
            m @41
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibrary>::@class::C::@method::m
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const hasInitializer a
          firstFragment: <testLibraryFragment>::@class::C::@field::a
          type: dynamic Function()
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
          returnType: dynamic Function()
      methods
        static m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
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
