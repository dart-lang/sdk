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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: num
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @14
              staticType: int
        static const b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            AsExpression
              expression: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: num
              asOperator: as @29
              type: NamedType
                name: int @32
                element: dart:core::<fragment>::@class::int
                element2: dart:core::<fragment>::@class::int#element
                type: int
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: num
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: num
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ParenthesizedExpression
              leftParenthesis: ( @23
              expression: AssignmentExpression
                leftHandSide: SimpleIdentifier
                  token: a @24
                  staticElement: <null>
                  element: <null>
                  staticType: null
                operator: += @26
                rightHandSide: IntegerLiteral
                  literal: 1 @29
                  staticType: int
                readElement: <testLibraryFragment>::@getter::a
                readElement2: <testLibraryFragment>::@getter::a#element
                readType: int
                writeElement: <testLibraryFragment>::@getter::a
                writeElement2: <testLibraryFragment>::@getter::a#element
                writeType: InvalidType
                staticElement: dart:core::<fragment>::@class::num::@method::+
                element: dart:core::<fragment>::@class::num::@method::+#element
                staticType: int
              rightParenthesis: ) @30
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
''');
  }

  test_const_cascadeExpression() async {
    var library = await buildLibrary(r'''
const a = 0..isEven..abs();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            CascadeExpression
              target: IntegerLiteral
                literal: 0 @10
                staticType: int
              cascadeSections
                PropertyAccess
                  operator: .. @11
                  propertyName: SimpleIdentifier
                    token: isEven @13
                    staticElement: dart:core::<fragment>::@class::int::@getter::isEven
                    element: dart:core::<fragment>::@class::int::@getter::isEven#element
                    staticType: bool
                  staticType: bool
                MethodInvocation
                  operator: .. @19
                  methodName: SimpleIdentifier
                    token: abs @21
                    staticElement: dart:core::<fragment>::@class::int::@method::abs
                    element: dart:core::<fragment>::@class::int::@method::abs#element
                    staticType: int Function()
                  argumentList: ArgumentList
                    leftParenthesis: ( @24
                    rightParenthesis: ) @25
                  staticInvokeType: int Function()
                  staticType: int
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            static const f1 @29
              reference: <testLibraryFragment>::@class::C::@field::f1
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 1 @34
                  staticType: int
            static const f2 @56
              reference: <testLibraryFragment>::@class::C::@field::f2
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C @61
                    staticElement: <testLibraryFragment>::@class::C
                    element: <testLibraryFragment>::@class::C#element
                    staticType: null
                  period: . @62
                  identifier: SimpleIdentifier
                    token: f1 @63
                    staticElement: <testLibraryFragment>::@class::C::@getter::f1
                    element: <testLibraryFragment>::@class::C::@getter::f1#element
                    staticType: int
                  staticElement: <testLibraryFragment>::@class::C::@getter::f1
                  element: <testLibraryFragment>::@class::C::@getter::f1#element
                  staticType: int
            static const f3 @67
              reference: <testLibraryFragment>::@class::C::@field::f3
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C @72
                    staticElement: <testLibraryFragment>::@class::C
                    element: <testLibraryFragment>::@class::C#element
                    staticType: null
                  period: . @73
                  identifier: SimpleIdentifier
                    token: f2 @74
                    staticElement: <testLibraryFragment>::@class::C::@getter::f2
                    element: <testLibraryFragment>::@class::C::@getter::f2#element
                    staticType: int
                  staticElement: <testLibraryFragment>::@class::C::@getter::f2
                  element: <testLibraryFragment>::@class::C::@getter::f2#element
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get f1 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f1
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic static get f2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic static get f3 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f3
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            f1 @29
              reference: <testLibraryFragment>::@class::C::@field::f1
              element: <testLibraryFragment>::@class::C::@field::f1#element
              getter2: <testLibraryFragment>::@class::C::@getter::f1
            f2 @56
              reference: <testLibraryFragment>::@class::C::@field::f2
              element: <testLibraryFragment>::@class::C::@field::f2#element
              getter2: <testLibraryFragment>::@class::C::@getter::f2
            f3 @67
              reference: <testLibraryFragment>::@class::C::@field::f3
              element: <testLibraryFragment>::@class::C::@field::f3#element
              getter2: <testLibraryFragment>::@class::C::@getter::f3
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get f1 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f1
              element: <testLibraryFragment>::@class::C::@getter::f1#element
            get f2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f2
              element: <testLibraryFragment>::@class::C::@getter::f2#element
            get f3 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f3
              element: <testLibraryFragment>::@class::C::@getter::f3#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const f1
          firstFragment: <testLibraryFragment>::@class::C::@field::f1
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f1#element
        static const f2
          firstFragment: <testLibraryFragment>::@class::C::@field::f2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f2#element
        static const f3
          firstFragment: <testLibraryFragment>::@class::C::@field::f3
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f3#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get f1
          firstFragment: <testLibraryFragment>::@class::C::@getter::f1
        synthetic static get f2
          firstFragment: <testLibraryFragment>::@class::C::@getter::f2
        synthetic static get f3
          firstFragment: <testLibraryFragment>::@class::C::@getter::f3
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final t @23
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingElement3: <testLibraryFragment>::@class::C
              type: T
          constructors
            const @34
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional final this.t @41
                  type: T
                  field: <testLibraryFragment>::@class::C::@field::t
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 54
              nameEnd: 60
              parameters
                requiredPositional final this.t @66
                  type: T
                  field: <testLibraryFragment>::@class::C::@field::t
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: T
      topLevelVariables
        static const x @85
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              keyword: const @89
              constructorName: ConstructorName
                type: NamedType
                  name: C @95
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @96
                arguments
                  IntegerLiteral
                    literal: 0 @97
                    staticType: int
                rightParenthesis: ) @98
              staticType: C<int>
        static const y @114
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              keyword: const @118
              constructorName: ConstructorName
                type: NamedType
                  name: C @124
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C<int>
                period: . @125
                name: SimpleIdentifier
                  token: named @126
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                  element: <testLibraryFragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::named
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::C::@constructor::named#element
              argumentList: ArgumentList
                leftParenthesis: ( @131
                arguments
                  IntegerLiteral
                    literal: 0 @132
                    staticType: int
                rightParenthesis: ) @133
              staticType: C<int>
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @8
              element: <not-implemented>
          fields
            t @23
              reference: <testLibraryFragment>::@class::C::@field::t
              element: <testLibraryFragment>::@class::C::@field::t#element
              getter2: <testLibraryFragment>::@class::C::@getter::t
          constructors
            const new @34
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                this.t @41
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::t#element
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              periodOffset: 54
              nameEnd: 60
              formalParameters
                this.t @66
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::t#element
          getters
            get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              element: <testLibraryFragment>::@class::C::@getter::t#element
      topLevelVariables
        const x @85
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
        const y @114
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibraryFragment>::@topLevelVariable::y#element
          getter2: <testLibraryFragment>::@getter::y
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
        get y @-1
          reference: <testLibraryFragment>::@getter::y
          element: <testLibraryFragment>::@getter::y#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        final t
          firstFragment: <testLibraryFragment>::@class::C::@field::t
          type: T
          getter: <testLibraryFragment>::@class::C::@getter::t#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional final t
              type: T
        const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            requiredPositional final t
              type: T
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
    const y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: Object
      getter: <testLibraryFragment>::@getter::y#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
''');
    var x = library.definingCompilationUnit.topLevelVariables[0];
    var xExpr = x.constantInitializer as InstanceCreationExpression;
    var xType = xExpr.constructorName.staticElement!.returnType;
    _assertTypeStr(
      xType,
      'C<int>',
    );
    var y = library.definingCompilationUnit.topLevelVariables[0];
    var yExpr = y.constantInitializer as InstanceCreationExpression;
    var yType = yExpr.constructorName.staticElement!.returnType;
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 13
              nameEnd: 19
      topLevelVariables
        static const v @31
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: A Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ConstructorReference
              constructorName: ConstructorName
                type: NamedType
                  name: A @35
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibraryFragment>::@class::A#element
                  type: null
                period: . @36
                name: SimpleIdentifier
                  token: named @37
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
                  element: <testLibraryFragment>::@class::A::@constructor::named#element
                  staticType: null
                staticElement: <testLibraryFragment>::@class::A::@constructor::named
                element: <testLibraryFragment>::@class::A::@constructor::named#element
              staticType: A Function()
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: A Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 13
              nameEnd: 19
      topLevelVariables
        const v @31
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A Function()
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            final f @22
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 42 @26
                  staticType: int
          constructors
            const @38
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            f @22
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            const new @38
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @44
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: void Function(int)
          shouldUseTypeForInitializerInference: true
          constantInitializer
            FunctionReference
              function: SimpleIdentifier
                token: f @48
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: void Function<T>(T)
              staticType: void Function(int)
              typeArgumentTypes
                int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: void Function(int)
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          parameters
            requiredPositional a @12
              type: T
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @44
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          typeParameters
            T @7
              element: <not-implemented>
          formalParameters
            a @12
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: void Function(int)
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @24
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: void Function(int)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            FunctionReference
              function: SimpleIdentifier
                token: f @28
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: void Function<T>(T)
              typeArguments: TypeArgumentList
                leftBracket: < @29
                arguments
                  NamedType
                    name: int @30
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @33
              staticType: void Function(int)
              typeArgumentTypes
                int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: void Function(int)
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          parameters
            requiredPositional a @12
              type: T
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @24
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          typeParameters
            T @7
              element: <not-implemented>
          formalParameters
            a @12
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: void Function(int)
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: List<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              leftBracket: [ @10
              elements
                IntegerLiteral
                  literal: 0 @11
                  staticType: int
              rightBracket: ] @12
              staticType: List<int>
        static const b @21
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @25
              staticType: int
        static const c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IndexExpression
              target: SimpleIdentifier
                token: a @38
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: List<int>
              leftBracket: [ @39
              index: SimpleIdentifier
                token: b @40
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: int
              rightBracket: ] @41
              staticElement: MethodMember
                base: dart:core::<fragment>::@class::List::@method::[]
                substitution: {E: int}
              element: dart:core::<fragment>::@class::List::@method::[]#element
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: List<int>
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @21
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
        const c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibraryFragment>::@topLevelVariable::c#element
          getter2: <testLibraryFragment>::@getter::c
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: List<int>
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
    const c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: int
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class P @6
          reference: <testLibraryFragment>::@class::P
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::P::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::P
        class P1 @35
          reference: <testLibraryFragment>::@class::P1
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @38
              defaultType: dynamic
          supertype: P<T>
          constructors
            const @64
              reference: <testLibraryFragment>::@class::P1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::P1
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
        class P2 @79
          reference: <testLibraryFragment>::@class::P2
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @82
              defaultType: dynamic
          supertype: P<T>
          constructors
            const @108
              reference: <testLibraryFragment>::@class::P2::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::P2
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
      topLevelVariables
        static const values @131
          reference: <testLibraryFragment>::@topLevelVariable::values
          enclosingElement3: <testLibraryFragment>
          type: List<P<dynamic>>
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              leftBracket: [ @140
              elements
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: P1 @144
                      element: <testLibraryFragment>::@class::P1
                      element2: <testLibraryFragment>::@class::P1#element
                      type: P1<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@class::P1::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@class::P1::@constructor::new#element
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
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::<fragment>::@class::int#element
                            type: int
                        rightBracket: > @158
                      element: <testLibraryFragment>::@class::P2
                      element2: <testLibraryFragment>::@class::P2#element
                      type: P2<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@class::P2::@constructor::new
                      substitution: {T: int}
                    element: <testLibraryFragment>::@class::P2::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @159
                    rightParenthesis: ) @160
                  staticType: P2<int>
              rightBracket: ] @163
              staticType: List<P<dynamic>>
      accessors
        synthetic static get values @-1
          reference: <testLibraryFragment>::@getter::values
          enclosingElement3: <testLibraryFragment>
          returnType: List<P<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class P @6
          reference: <testLibraryFragment>::@class::P
          element: <testLibraryFragment>::@class::P#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::P::@constructor::new
              element: <testLibraryFragment>::@class::P::@constructor::new#element
        class P1 @35
          reference: <testLibraryFragment>::@class::P1
          element: <testLibraryFragment>::@class::P1#element
          typeParameters
            T @38
              element: <not-implemented>
          constructors
            const new @64
              reference: <testLibraryFragment>::@class::P1::@constructor::new
              element: <testLibraryFragment>::@class::P1::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
        class P2 @79
          reference: <testLibraryFragment>::@class::P2
          element: <testLibraryFragment>::@class::P2#element
          typeParameters
            T @82
              element: <not-implemented>
          constructors
            const new @108
              reference: <testLibraryFragment>::@class::P2::@constructor::new
              element: <testLibraryFragment>::@class::P2::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
      topLevelVariables
        const values @131
          reference: <testLibraryFragment>::@topLevelVariable::values
          element: <testLibraryFragment>::@topLevelVariable::values#element
          getter2: <testLibraryFragment>::@getter::values
      getters
        get values @-1
          reference: <testLibraryFragment>::@getter::values
          element: <testLibraryFragment>::@getter::values#element
  classes
    class P
      firstFragment: <testLibraryFragment>::@class::P
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::P::@constructor::new
    class P1
      firstFragment: <testLibraryFragment>::@class::P1
      typeParameters
        T
      supertype: P<T>
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::P1::@constructor::new
          superConstructor: <testLibraryFragment>::@class::P::@constructor::new#element
    class P2
      firstFragment: <testLibraryFragment>::@class::P2
      typeParameters
        T
      supertype: P<T>
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::P2::@constructor::new
          superConstructor: <testLibraryFragment>::@class::P::@constructor::new#element
  topLevelVariables
    const values
      firstFragment: <testLibraryFragment>::@topLevelVariable::values
      type: List<P<dynamic>>
      getter: <testLibraryFragment>::@getter::values#element
  getters
    synthetic static get values
      firstFragment: <testLibraryFragment>::@getter::values
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            static const f @25
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @29
                    staticType: int
                  operator: + @31
                  rightOperand: MethodInvocation
                    methodName: SimpleIdentifier
                      token: foo @33
                      staticElement: <testLibraryFragment>::@function::foo
                      element: <testLibraryFragment>::@function::foo#element
                      staticType: int Function()
                    argumentList: ArgumentList
                      leftParenthesis: ( @36
                      rightParenthesis: ) @37
                    staticInvokeType: int Function()
                    staticType: int
                  staticElement: dart:core::<fragment>::@class::num::@method::+
                  element: dart:core::<fragment>::@class::num::@method::+#element
                  staticInvokeType: num Function(num)
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
      functions
        foo @46
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            f @25
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      functions
        foo @46
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
  functions
    foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            final f @18
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
      functions
        foo @39
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            f @18
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      functions
        foo @39
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
  functions
    foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              element: <null>
              staticType: null
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    element: <null>
                    staticType: null
                  rightParenthesis: ) @46
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    element: <null>
                    staticType: null
                  rightParenthesis: ) @46
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: b @32
                    staticElement: <null>
                    element: <null>
                    staticType: InvalidType
                  comma: , @33
                  message: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    element: <null>
                    staticType: null
                  rightParenthesis: ) @42
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: b @32
                    staticElement: <null>
                    element: <null>
                    staticType: InvalidType
                  comma: , @33
                  message: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    element: <null>
                    staticType: null
                  rightParenthesis: ) @42
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final foo @26
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: Object?
          constructors
            const @39
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @45
                    staticElement: <testLibraryFragment>::@class::A::@field::foo
                    element: <testLibraryFragment>::@class::A::@field::foo#element
                    staticType: null
                  equals: = @49
                  expression: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    element: <null>
                    staticType: null
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: Object?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @26
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          constructors
            const new @39
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @45
                    staticElement: <testLibraryFragment>::@class::A::@field::foo
                    element: <testLibraryFragment>::@class::A::@field::foo#element
                    staticType: null
                  equals: = @49
                  expression: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    element: <null>
                    staticType: null
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: Object?
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_const_invalid_functionExpression_nested() async {
    var library = await buildLibrary('''
const v = () { return 0; } + 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              element: <null>
              staticType: null
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: InvalidType
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @27
                  type: Object
                requiredPositional b @37
                  type: Object
            const named @51
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 50
              nameEnd: 56
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
                        staticElement: <null>
                        element: <null>
                        staticType: null
                    rightParenthesis: ) @76
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              redirectedConstructor: <testLibraryFragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                a @27
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                b @37
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::b#element
            const named @51
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 50
              nameEnd: 56
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
                        staticElement: <null>
                        element: <null>
                        staticType: null
                    rightParenthesis: ) @76
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              redirectedConstructor: <testLibraryFragment>::@class::A::@constructor::new
  classes
    class A
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
          redirectedConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @27
                  type: Object
                requiredPositional b @37
                  type: Object
        class B @49
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A
          constructors
            const @71
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
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
                        staticElement: <null>
                        element: <null>
                        staticType: null
                    rightParenthesis: ) @93
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                a @27
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                b @37
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::b#element
        class B @49
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            const new @71
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
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
                        staticElement: <null>
                        element: <null>
                        staticType: null
                    rightParenthesis: ) @93
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
  classes
    class A
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
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            MethodInvocation
              target: SimpleStringLiteral
                literal: 'abc' @10
              operator: . @15
              methodName: SimpleIdentifier
                token: codeUnitAt @16
                staticElement: dart:core::<fragment>::@class::String::@method::codeUnitAt
                element: dart:core::<fragment>::@class::String::@method::codeUnitAt#element
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
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_const_invalid_patternAssignment() async {
    var library = await buildLibrary('''
const v = (a,) = (0,);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: (int,)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              element: <null>
              staticType: null
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: (int,)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: (int,)
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @10
                staticType: int
              operator: + @12
              rightOperand: MethodInvocation
                methodName: SimpleIdentifier
                  token: foo @14
                  staticElement: <testLibraryFragment>::@function::foo
                  element: <testLibraryFragment>::@function::foo#element
                  staticType: int Function()
                argumentList: ArgumentList
                  leftParenthesis: ( @17
                  rightParenthesis: ) @18
                staticInvokeType: int Function()
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
      functions
        foo @25
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        foo @25
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  functions
    foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              element: <null>
              staticType: null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @14
              staticType: int
        static const b @28
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: true
          constantInitializer
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: a @32
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: int
              operator: + @34
              rightOperand: IntegerLiteral
                literal: 5 @36
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @28
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: bool
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant K @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          constructors
            const named @26
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 25
              nameEnd: 31
              parameters
                requiredPositional k @34
                  type: K
                requiredPositional v @39
                  type: V
      topLevelVariables
        static const V @51
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                        element: dart:core::<fragment>::@class::int
                        element2: dart:core::<fragment>::@class::int#element
                        type: int
                      NamedType
                        name: String @68
                        element: dart:core::<fragment>::@class::String
                        element2: dart:core::<fragment>::@class::String#element
                        type: String
                    rightBracket: > @74
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C<int, String>
                period: . @75
                name: SimpleIdentifier
                  token: named @76
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  element: <testLibraryFragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::named
                  substitution: {K: int, V: String}
                element: <testLibraryFragment>::@class::C::@constructor::named#element
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
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            K @8
              element: <not-implemented>
            V @11
              element: <not-implemented>
          constructors
            const named @26
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              periodOffset: 25
              nameEnd: 31
              formalParameters
                k @34
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::k#element
                v @39
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::v#element
      topLevelVariables
        const V @51
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
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
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                        element: dart:core::<fragment>::@class::int
                        element2: dart:core::<fragment>::@class::int#element
                        type: int
                      NamedType
                        name: String @40
                        element: dart:core::<fragment>::@class::String
                        element2: dart:core::<fragment>::@class::String#element
                        type: String
                    rightBracket: > @46
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C<int, String>
                period: . @47
                name: SimpleIdentifier
                  token: named @48
                  staticElement: ConstructorMember
                    base: package:test/a.dart::<fragment>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::named
                  substitution: {K: int, V: String}
                element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
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
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element: dart:core::<fragment>::@class::int
                        element2: dart:core::<fragment>::@class::int#element
                        type: int
                      NamedType
                        name: String @47
                        element: dart:core::<fragment>::@class::String
                        element2: dart:core::<fragment>::@class::String#element
                        type: String
                    rightBracket: > @53
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C<int, String>
                period: . @54
                name: SimpleIdentifier
                  token: named @55
                  staticElement: ConstructorMember
                    base: package:test/a.dart::<fragment>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::named
                  substitution: {K: int, V: String}
                element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
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
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant K @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          constructors
            const @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<dynamic, dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @41
              constructorName: ConstructorName
                type: NamedType
                  name: C @47
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C<dynamic, dynamic>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {K: dynamic, V: dynamic}
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              staticType: C<dynamic, dynamic>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<dynamic, dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            K @8
              element: <not-implemented>
            V @11
              element: <not-implemented>
          constructors
            const new @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        K
        V
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<dynamic, dynamic>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final t @23
              reference: <testLibraryFragment>::@class::A::@field::t
              enclosingElement3: <testLibraryFragment>::@class::A
              type: T
          constructors
            const @34
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.t @41
                  type: T
                  field: <testLibraryFragment>::@class::A::@field::t
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::A::@getter::t
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: T
      topLevelVariables
        static const a @60
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              keyword: const @64
              constructorName: ConstructorName
                type: NamedType
                  name: A @70
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibraryFragment>::@class::A#element
                  type: A<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @71
                arguments
                  IntegerLiteral
                    literal: 0 @72
                    staticType: int
                rightParenthesis: ) @73
              staticType: A<int>
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          fields
            t @23
              reference: <testLibraryFragment>::@class::A::@field::t
              element: <testLibraryFragment>::@class::A::@field::t#element
              getter2: <testLibraryFragment>::@class::A::@getter::t
          constructors
            const new @34
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                this.t @41
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::t#element
          getters
            get t @-1
              reference: <testLibraryFragment>::@class::A::@getter::t
              element: <testLibraryFragment>::@class::A::@getter::t#element
      topLevelVariables
        const a @60
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      fields
        final t
          firstFragment: <testLibraryFragment>::@class::A::@field::t
          type: T
          getter: <testLibraryFragment>::@class::A::@getter::t#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional final t
              type: T
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::A::@getter::t
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: Object
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant K @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          constructors
            const @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                        element: dart:core::<fragment>::@class::int
                        element2: dart:core::<fragment>::@class::int#element
                        type: int
                      NamedType
                        name: String @54
                        element: dart:core::<fragment>::@class::String
                        element2: dart:core::<fragment>::@class::String#element
                        type: String
                    rightBracket: > @60
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C<int, String>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @61
                rightParenthesis: ) @62
              staticType: C<int, String>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            K @8
              element: <not-implemented>
            V @11
              element: <not-implemented>
          constructors
            const new @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        K
        V
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                        element: dart:core::<fragment>::@class::int
                        element2: dart:core::<fragment>::@class::int#element
                        type: int
                      NamedType
                        name: String @40
                        element: dart:core::<fragment>::@class::String
                        element2: dart:core::<fragment>::@class::String#element
                        type: String
                    rightBracket: > @46
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C<int, String>
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
                element: package:test/a.dart::<fragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C<int, String>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element: dart:core::<fragment>::@class::int
                        element2: dart:core::<fragment>::@class::int#element
                        type: int
                      NamedType
                        name: String @47
                        element: dart:core::<fragment>::@class::String
                        element2: dart:core::<fragment>::@class::String#element
                        type: String
                    rightBracket: > @53
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C<int, String>
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
                element: package:test/a.dart::<fragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @54
                rightParenthesis: ) @55
              staticType: C<int, String>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 19
              nameEnd: 25
              parameters
                requiredPositional a @31
                  type: bool
                requiredPositional b @38
                  type: int
                requiredPositional c @45
                  type: int
                optionalNamed default d @56
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d
                  type: String
                optionalNamed default e @66
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e
                  type: double
      topLevelVariables
        static const V @79
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @83
              constructorName: ConstructorName
                type: NamedType
                  name: C @89
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C
                period: . @90
                name: SimpleIdentifier
                  token: named @91
                  staticElement: <testLibraryFragment>::@class::C::@constructor::named
                  element: <testLibraryFragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: <testLibraryFragment>::@class::C::@constructor::named
                element: <testLibraryFragment>::@class::C::@constructor::named#element
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
                        staticElement: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d
                        element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::d#element
                        staticType: null
                      colon: : @110
                    expression: SimpleStringLiteral
                      literal: 'ccc' @112
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: e @119
                        staticElement: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e
                        element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e#element
                        staticType: null
                      colon: : @120
                    expression: DoubleLiteral
                      literal: 3.4 @122
                      staticType: double
                rightParenthesis: ) @125
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              periodOffset: 19
              nameEnd: 25
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
        const V @79
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
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
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C
                period: . @34
                name: SimpleIdentifier
                  token: named @35
                  staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
                  element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
                element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
              argumentList: ArgumentList
                leftParenthesis: ( @40
                rightParenthesis: ) @41
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
                  element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
                element: package:test/a.dart::<fragment>::@class::C::@constructor::named#element
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @21
              constructorName: ConstructorName
                type: NamedType
                  name: C @27
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C
                period: . @28
                name: SimpleIdentifier
                  token: named @29
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
''');
  }

  test_const_invokeConstructor_named_unresolved2() async {
    var library = await buildLibrary(r'''
const V = const C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: C @16
                    period: . @17
                    element: <null>
                    element2: <null>
                  name: named @18
                  element: <null>
                  element2: <null>
                  type: InvalidType
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @23
                rightParenthesis: ) @24
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: <null>
                  element2: <null>
                  type: InvalidType
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
''');
  }

  test_const_invokeConstructor_named_unresolved5() async {
    var library = await buildLibrary(r'''
const V = const p.C.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @16
                    period: . @17
                    element: <null>
                    element2: <null>
                  name: C @18
                  element: <null>
                  element2: <null>
                  type: InvalidType
                period: . @19
                name: SimpleIdentifier
                  token: named @20
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @25
                rightParenthesis: ) @26
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @20
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C<dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @24
              constructorName: ConstructorName
                type: NamedType
                  name: C @30
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C<dynamic>
                period: . @31
                name: SimpleIdentifier
                  token: named @32
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              staticType: C<dynamic>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C<dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const V @20
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C<dynamic>
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            const @18
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @31
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @35
              constructorName: ConstructorName
                type: NamedType
                  name: C @41
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibraryFragment>::@class::C#element
                  type: C
                staticElement: <testLibraryFragment>::@class::C::@constructor::new
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @42
                rightParenthesis: ) @43
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const V @31
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::new
                element: package:test/a.dart::<fragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: package:test/a.dart::<fragment>::@class::C
                  element2: package:test/a.dart::<fragment>::@class::C#element
                  type: C
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::new
                element: package:test/a.dart::<fragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: C
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
''');
  }

  test_const_invokeConstructor_unnamed_unresolved() async {
    var library = await buildLibrary(r'''
const V = const C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  name: C @16
                  element: <null>
                  element2: <null>
                  type: InvalidType
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @17
                rightParenthesis: ) @18
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @32
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @38
                    period: . @39
                    element: <testLibraryFragment>::@prefix::p
                    element2: <testLibraryFragment>::@prefix2::p
                  name: C @40
                  element: <null>
                  element2: <null>
                  type: InvalidType
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
''');
  }

  test_const_invokeConstructor_unnamed_unresolved3() async {
    var library = await buildLibrary(r'''
const V = const p.C();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  importPrefix: ImportPrefixReference
                    name: p @16
                    period: . @17
                    element: <null>
                    element2: <null>
                  name: C @18
                  element: <null>
                  element2: <null>
                  type: InvalidType
                staticElement: <null>
                element: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @19
                rightParenthesis: ) @20
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IsExpression
              expression: SimpleIdentifier
                token: a @23
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: int
              isOperator: is @25
              type: NamedType
                name: int @28
                element: dart:core::<fragment>::@class::int
                element2: dart:core::<fragment>::@class::int#element
                type: int
              staticType: bool
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: bool
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            static const F @32
              reference: <testLibraryFragment>::@class::C::@field::F
              enclosingElement3: <testLibraryFragment>::@class::C
              type: String
              shouldUseTypeForInitializerInference: true
              constantInitializer
                SimpleStringLiteral
                  literal: '' @36
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: String
      topLevelVariables
        static const v @52
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @56
                  staticElement: <testLibraryFragment>::@class::C
                  element: <testLibraryFragment>::@class::C#element
                  staticType: null
                period: . @57
                identifier: SimpleIdentifier
                  token: F @58
                  staticElement: <testLibraryFragment>::@class::C::@getter::F
                  element: <testLibraryFragment>::@class::C::@getter::F#element
                  staticType: String
                staticElement: <testLibraryFragment>::@class::C::@getter::F
                element: <testLibraryFragment>::@class::C::@getter::F#element
                staticType: String
              operator: . @59
              propertyName: SimpleIdentifier
                token: length @60
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            F @32
              reference: <testLibraryFragment>::@class::C::@field::F
              element: <testLibraryFragment>::@class::C::@field::F#element
              getter2: <testLibraryFragment>::@class::C::@getter::F
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              element: <testLibraryFragment>::@class::C::@getter::F#element
      topLevelVariables
        const v @52
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const F
          firstFragment: <testLibraryFragment>::@class::C::@field::F
          type: String
          getter: <testLibraryFragment>::@class::C::@getter::F#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get F
          firstFragment: <testLibraryFragment>::@class::C::@getter::F
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @27
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @31
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  element: package:test/a.dart::<fragment>::@class::C#element
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: F @33
                  staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                  element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                  staticType: String
                staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                staticType: String
              operator: . @34
              propertyName: SimpleIdentifier
                token: length @35
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const v @27
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: PropertyAccess
                target: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: p @36
                    staticElement: <testLibraryFragment>::@prefix::p
                    element: <testLibraryFragment>::@prefix2::p
                    staticType: null
                  period: . @37
                  identifier: SimpleIdentifier
                    token: C @38
                    staticElement: package:test/a.dart::<fragment>::@class::C
                    element: package:test/a.dart::<fragment>::@class::C#element
                    staticType: null
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  element: package:test/a.dart::<fragment>::@class::C#element
                  staticType: null
                operator: . @39
                propertyName: SimpleIdentifier
                  token: F @40
                  staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                  element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                  staticType: String
                staticType: String
              operator: . @41
              propertyName: SimpleIdentifier
                token: length @42
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
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
        const v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_const_length_ofStringLiteral() async {
    var library = await buildLibrary(r'''
const v = 'abc'.length;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: SimpleStringLiteral
                literal: 'abc' @10
              operator: . @15
              propertyName: SimpleIdentifier
                token: length @16
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const S @13
          reference: <testLibraryFragment>::@topLevelVariable::S
          enclosingElement3: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SimpleStringLiteral
              literal: 'abc' @17
        static const v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @34
                staticElement: <testLibraryFragment>::@getter::S
                element: <testLibraryFragment>::@getter::S#element
                staticType: String
              period: . @35
              identifier: SimpleIdentifier
                token: length @36
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticElement: dart:core::<fragment>::@class::String::@getter::length
              element: dart:core::<fragment>::@class::String::@getter::length#element
              staticType: int
      accessors
        synthetic static get S @-1
          reference: <testLibraryFragment>::@getter::S
          enclosingElement3: <testLibraryFragment>
          returnType: String
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const S @13
          reference: <testLibraryFragment>::@topLevelVariable::S
          element: <testLibraryFragment>::@topLevelVariable::S#element
          getter2: <testLibraryFragment>::@getter::S
        const v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get S @-1
          reference: <testLibraryFragment>::@getter::S
          element: <testLibraryFragment>::@getter::S#element
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const S
      firstFragment: <testLibraryFragment>::@topLevelVariable::S
      type: String
      getter: <testLibraryFragment>::@getter::S#element
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get S
      firstFragment: <testLibraryFragment>::@getter::S
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @27
                staticElement: package:test/a.dart::<fragment>::@getter::S
                element: package:test/a.dart::<fragment>::@getter::S#element
                staticType: String
              period: . @28
              identifier: SimpleIdentifier
                token: length @29
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticElement: dart:core::<fragment>::@class::String::@getter::length
              element: dart:core::<fragment>::@class::String::@getter::length#element
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: S @34
                  staticElement: package:test/a.dart::<fragment>::@getter::S
                  element: package:test/a.dart::<fragment>::@getter::S#element
                  staticType: String
                staticElement: package:test/a.dart::<fragment>::@getter::S
                element: package:test/a.dart::<fragment>::@getter::S#element
                staticType: String
              operator: . @35
              propertyName: SimpleIdentifier
                token: length @36
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
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
        const v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            static length @23
              reference: <testLibraryFragment>::@class::C::@method::length
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
      topLevelVariables
        static const v @47
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @51
                staticElement: <testLibraryFragment>::@class::C
                element: <testLibraryFragment>::@class::C#element
                staticType: null
              period: . @52
              identifier: SimpleIdentifier
                token: length @53
                staticElement: <testLibraryFragment>::@class::C::@method::length
                element: <testLibraryFragment>::@class::C::@method::length#element
                staticType: int Function()
              staticElement: <testLibraryFragment>::@class::C::@method::length
              element: <testLibraryFragment>::@class::C::@method::length#element
              staticType: int Function()
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            length @23
              reference: <testLibraryFragment>::@class::C::@method::length
              element: <testLibraryFragment>::@class::C::@method::length#element
      topLevelVariables
        const v @47
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static length
          firstFragment: <testLibraryFragment>::@class::C::@method::length
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_const_list_if() async {
    var library = await buildLibrary('''
const Object x = const <int>[if (true) 1];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_list_if_else() async {
    var library = await buildLibrary('''
const Object x = const <int>[if (true) 1 else 2];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              constKeyword: const @17
              leftBracket: [ @23
              elements
                IntegerLiteral
                  literal: 1 @24
                  staticType: int
              rightBracket: ] @25
              staticType: List<int>
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_list_spread() async {
    var library = await buildLibrary('''
const Object x = const <int>[...<int>[1]];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_list_spread_null_aware() async {
    var library = await buildLibrary('''
const Object x = const <int>[...?<int>[1]];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_map_if() async {
    var library = await buildLibrary('''
const Object x = const <int, int>{if (true) 1: 2};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_map_spread() async {
    var library = await buildLibrary('''
const Object x = const <int, int>{...<int, int>{1: 2}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
                          type: int
                        NamedType
                          name: int @43
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_map_spread_null_aware() async {
    var library = await buildLibrary('''
const Object x = const <int, int>{...?<int, int>{1: 2}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
                          type: int
                        NamedType
                          name: int @44
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            MethodInvocation
              methodName: SimpleIdentifier
                token: f @28
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>(T)
              typeArguments: TypeArgumentList
                leftBracket: < @29
                arguments
                  NamedType
                    name: int @30
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @4
              defaultType: dynamic
          parameters
            requiredPositional a @9
              type: T
          returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          typeParameters
            T @4
              element: <not-implemented>
          formalParameters
            a @9
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  topLevelVariables
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            const @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalNamed default final this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  type: dynamic
                  constantInitializer
                    SimpleIdentifier
                      token: foo @40
                      staticElement: <testLibraryFragment>::@function::foo
                      element: <testLibraryFragment>::@function::foo#element
                      staticType: int Function()
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
      functions
        foo @53
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            const new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                default this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
      functions
        foo @53
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  classes
    class C
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
            optionalNamed final x
              firstFragment: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
              type: dynamic
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
  functions
    foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            const @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalNamed default final this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  type: dynamic
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @40
                        staticType: int
                      operator: + @42
                      rightOperand: IntegerLiteral
                        literal: 2 @44
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            const new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                default this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
  classes
    class C
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
            optionalNamed final x
              firstFragment: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
              type: dynamic
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            const @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default final this.x @37
                  type: dynamic
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @41
                        staticType: int
                      operator: + @43
                      rightOperand: IntegerLiteral
                        literal: 2 @45
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            const new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                default this.x @37
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
  classes
    class C
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
            optionalPositional final x
              type: dynamic
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            const positional @20
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 19
              nameEnd: 30
              parameters
                optionalPositional default p @32
                  type: dynamic
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @36
                        staticType: int
                      operator: + @38
                      rightOperand: IntegerLiteral
                        literal: 2 @40
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 54
              nameEnd: 60
              parameters
                optionalNamed default p @62
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p
                  type: dynamic
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @65
                        staticType: int
                      operator: + @67
                      rightOperand: IntegerLiteral
                        literal: 2 @69
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
          methods
            methodPositional @81
              reference: <testLibraryFragment>::@class::C::@method::methodPositional
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default p @99
                  type: dynamic
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @103
                        staticType: int
                      operator: + @105
                      rightOperand: IntegerLiteral
                        literal: 2 @107
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
              returnType: void
            methodPositionalWithoutDefault @121
              reference: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default p @153
                  type: dynamic
              returnType: void
            methodNamed @167
              reference: <testLibraryFragment>::@class::C::@method::methodNamed
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalNamed default p @180
                  reference: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p
                  type: dynamic
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @183
                        staticType: int
                      operator: + @185
                      rightOperand: IntegerLiteral
                        literal: 2 @187
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
              returnType: void
            methodNamedWithoutDefault @201
              reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalNamed default p @228
                  reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p
                  type: dynamic
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            const positional @20
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              element: <testLibraryFragment>::@class::C::@constructor::positional#element
              periodOffset: 19
              nameEnd: 30
              formalParameters
                default p @32
                  element: <testLibraryFragment>::@class::C::@constructor::positional::@parameter::p#element
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              periodOffset: 54
              nameEnd: 60
              formalParameters
                default p @62
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p#element
          methods
            methodPositional @81
              reference: <testLibraryFragment>::@class::C::@method::methodPositional
              element: <testLibraryFragment>::@class::C::@method::methodPositional#element
              formalParameters
                default p @99
                  element: <testLibraryFragment>::@class::C::@method::methodPositional::@parameter::p#element
            methodPositionalWithoutDefault @121
              reference: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
              element: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault#element
              formalParameters
                default p @153
                  element: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault::@parameter::p#element
            methodNamed @167
              reference: <testLibraryFragment>::@class::C::@method::methodNamed
              element: <testLibraryFragment>::@class::C::@method::methodNamed#element
              formalParameters
                default p @180
                  reference: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p
                  element: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p#element
            methodNamedWithoutDefault @201
              reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
              element: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault#element
              formalParameters
                default p @228
                  reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p
                  element: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const positional
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
          formalParameters
            optionalPositional p
              type: dynamic
        const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            optionalNamed p
              firstFragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::p
              type: dynamic
      methods
        methodPositional
          firstFragment: <testLibraryFragment>::@class::C::@method::methodPositional
          formalParameters
            optionalPositional p
              type: dynamic
        methodPositionalWithoutDefault
          firstFragment: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
          formalParameters
            optionalPositional p
              type: dynamic
        methodNamed
          firstFragment: <testLibraryFragment>::@class::C::@method::methodNamed
          formalParameters
            optionalNamed p
              firstFragment: <testLibraryFragment>::@class::C::@method::methodNamed::@parameter::p
              type: dynamic
        methodNamedWithoutDefault
          firstFragment: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
          formalParameters
            optionalNamed p
              firstFragment: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault::@parameter::p
              type: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PostfixExpression
              operand: SimpleIdentifier
                token: a @23
                staticElement: <null>
                element: <null>
                staticType: null
              operator: ++ @24
              readElement: <testLibraryFragment>::@getter::a
              readElement2: <testLibraryFragment>::@getter::a#element
              readType: int
              writeElement: <testLibraryFragment>::@getter::a
              writeElement2: <testLibraryFragment>::@getter::a#element
              writeType: InvalidType
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @15
              staticType: int
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PostfixExpression
              operand: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: int?
              operator: ! @29
              staticElement: <null>
              element: <null>
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int?
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @23
              operand: SimpleIdentifier
                token: a @24
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              element: dart:core::<fragment>::@class::int::@method::unary-#element
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @27
              operand: SimpleIdentifier
                token: a @28
                staticElement: package:test/a.dart::<fragment>::@getter::a
                element: package:test/a.dart::<fragment>::@getter::a#element
                staticType: Object
              staticElement: package:test/a.dart::<fragment>::@extension::E::@method::unary-
              element: package:test/a.dart::<fragment>::@extension::E::@method::unary-#element
              staticType: int
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: ++ @23
              operand: SimpleIdentifier
                token: a @25
                staticElement: <null>
                element: <null>
                staticType: null
              readElement: <testLibraryFragment>::@getter::a
              readElement2: <testLibraryFragment>::@getter::a#element
              readType: int
              writeElement: <testLibraryFragment>::@getter::a
              writeElement2: <testLibraryFragment>::@getter::a#element
              writeType: InvalidType
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: (int, {int a})
          shouldUseTypeForInitializerInference: false
          constantInitializer
            RecordLiteral
              leftParenthesis: ( @23
              fields
                SimpleIdentifier
                  token: a @24
                  staticElement: <testLibraryFragment>::@getter::a
                  element: <testLibraryFragment>::@getter::a#element
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      token: a @27
                      staticElement: <null>
                      element: <null>
                      staticType: null
                    colon: : @28
                  expression: SimpleIdentifier
                    token: a @30
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: int
              rightParenthesis: ) @31
              staticType: (int, {int a})
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: (int, {int a})
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: (int, {int a})
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: (int, {int a})
          shouldUseTypeForInitializerInference: false
          constantInitializer
            RecordLiteral
              constKeyword: const @23
              leftParenthesis: ( @29
              fields
                SimpleIdentifier
                  token: a @30
                  staticElement: <testLibraryFragment>::@getter::a
                  element: <testLibraryFragment>::@getter::a#element
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      token: a @33
                      staticElement: <null>
                      element: <null>
                      staticType: null
                    colon: : @34
                  expression: SimpleIdentifier
                    token: a @36
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: int
              rightParenthesis: ) @37
              staticType: (int, {int a})
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: (int, {int a})
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: (int, {int a})
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            static const F @29
              reference: <testLibraryFragment>::@class::C::@field::F
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 42 @33
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
      topLevelVariables
        static const V @45
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @49
                staticElement: <testLibraryFragment>::@class::C
                element: <testLibraryFragment>::@class::C#element
                staticType: null
              period: . @50
              identifier: SimpleIdentifier
                token: F @51
                staticElement: <testLibraryFragment>::@class::C::@getter::F
                element: <testLibraryFragment>::@class::C::@getter::F#element
                staticType: int
              staticElement: <testLibraryFragment>::@class::C::@getter::F
              element: <testLibraryFragment>::@class::C::@getter::F#element
              staticType: int
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            F @29
              reference: <testLibraryFragment>::@class::C::@field::F
              element: <testLibraryFragment>::@class::C::@field::F#element
              getter2: <testLibraryFragment>::@class::C::@getter::F
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              element: <testLibraryFragment>::@class::C::@getter::F#element
      topLevelVariables
        const V @45
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const F
          firstFragment: <testLibraryFragment>::@class::C::@field::F
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::F#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get F
          firstFragment: <testLibraryFragment>::@class::C::@getter::F
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @27
                staticElement: package:test/a.dart::<fragment>::@class::C
                element: package:test/a.dart::<fragment>::@class::C#element
                staticType: null
              period: . @28
              identifier: SimpleIdentifier
                token: F @29
                staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                staticType: int
              staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
              element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
              staticType: int
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: C @34
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  element: package:test/a.dart::<fragment>::@class::C#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C
                element: package:test/a.dart::<fragment>::@class::C#element
                staticType: null
              operator: . @35
              propertyName: SimpleIdentifier
                token: F @36
                staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                element: package:test/a.dart::<fragment>::@class::C::@getter::F#element
                staticType: int
              staticType: int
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            static m @23
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional a @29
                  type: int
                requiredPositional b @39
                  type: String
              returnType: int
      topLevelVariables
        static const V @57
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @61
                staticElement: <testLibraryFragment>::@class::C
                element: <testLibraryFragment>::@class::C#element
                staticType: null
              period: . @62
              identifier: SimpleIdentifier
                token: m @63
                staticElement: <testLibraryFragment>::@class::C::@method::m
                element: <testLibraryFragment>::@class::C::@method::m#element
                staticType: int Function(int, String)
              staticElement: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              staticType: int Function(int, String)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            m @23
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              formalParameters
                a @29
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::a#element
                b @39
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::b#element
      topLevelVariables
        const V @57
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          formalParameters
            requiredPositional a
              type: int
            requiredPositional b
              type: String
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int Function(int, String)
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @27
                staticElement: package:test/a.dart::<fragment>::@class::C
                element: package:test/a.dart::<fragment>::@class::C#element
                staticType: null
              period: . @28
              identifier: SimpleIdentifier
                token: m @29
                staticElement: package:test/a.dart::<fragment>::@class::C::@method::m
                element: package:test/a.dart::<fragment>::@class::C::@method::m#element
                staticType: int Function(int, String)
              staticElement: package:test/a.dart::<fragment>::@class::C::@method::m
              element: package:test/a.dart::<fragment>::@class::C::@method::m#element
              staticType: int Function(int, String)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int Function(int, String)
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: C @34
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  element: package:test/a.dart::<fragment>::@class::C#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C
                element: package:test/a.dart::<fragment>::@class::C#element
                staticType: null
              operator: . @35
              propertyName: SimpleIdentifier
                token: m @36
                staticElement: package:test/a.dart::<fragment>::@class::C::@method::m
                element: package:test/a.dart::<fragment>::@class::C::@method::m#element
                staticType: int Function(int, String)
              staticType: int Function(int, String)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int Function(int, String)
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      extensions
        E @21
          reference: <testLibraryFragment>::@extension::E
          enclosingElement3: <testLibraryFragment>
          extendedType: A
          methods
            static f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              enclosingElement3: <testLibraryFragment>::@extension::E
              returnType: void
      topLevelVariables
        static const x @59
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: void Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: E @63
                staticElement: <testLibraryFragment>::@extension::E
                element: <testLibraryFragment>::@extension::E#element
                staticType: null
              period: . @64
              identifier: SimpleIdentifier
                token: f @65
                staticElement: <testLibraryFragment>::@extension::E::@method::f
                element: <testLibraryFragment>::@extension::E::@method::f#element
                staticType: void Function()
              staticElement: <testLibraryFragment>::@extension::E::@method::f
              element: <testLibraryFragment>::@extension::E::@method::f#element
              staticType: void Function()
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: void Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          element: <testLibraryFragment>::@extension::E#element
          methods
            f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              element: <testLibraryFragment>::@extension::E::@method::f#element
      topLevelVariables
        const x @59
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension E
      firstFragment: <testLibraryFragment>::@extension::E
      methods
        static f
          firstFragment: <testLibraryFragment>::@extension::E::@method::f
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: void Function()
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @15
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @19
              staticElement: <testLibraryFragment>::@function::foo
              element: <testLibraryFragment>::@function::foo#element
              staticType: dynamic Function()
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @15
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic Function()
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
  functions
    foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @26
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: R Function<P, R>(P)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @30
              staticElement: <testLibraryFragment>::@function::foo
              element: <testLibraryFragment>::@function::foo#element
              staticType: R Function<P, R>(P)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: R Function<P, R>(P)
      functions
        foo @2
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant P @6
              defaultType: dynamic
            covariant R @9
              defaultType: dynamic
          parameters
            requiredPositional p @14
              type: P
          returnType: R
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @26
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
      functions
        foo @2
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          typeParameters
            P @6
              element: <not-implemented>
            R @9
              element: <not-implemented>
          formalParameters
            p @14
              element: <testLibraryFragment>::@function::foo::@parameter::p#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: R Function<P, R>(P)
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
  functions
    foo
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @27
              staticElement: package:test/a.dart::<fragment>::@function::foo
              element: package:test/a.dart::<fragment>::@function::foo#element
              staticType: dynamic Function()
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic Function()
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @32
                staticElement: <testLibraryFragment>::@prefix::p
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @33
              identifier: SimpleIdentifier
                token: foo @34
                staticElement: package:test/a.dart::<fragment>::@function::foo
                element: package:test/a.dart::<fragment>::@function::foo#element
                staticType: dynamic Function()
              staticElement: package:test/a.dart::<fragment>::@function::foo
              element: package:test/a.dart::<fragment>::@function::foo#element
              staticType: dynamic Function()
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
----------------------------------------
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
        const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic Function()
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const A @6
          reference: <testLibraryFragment>::@topLevelVariable::A
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 1 @10
              staticType: int
        static const B @19
          reference: <testLibraryFragment>::@topLevelVariable::B
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @23
                staticElement: <testLibraryFragment>::@getter::A
                element: <testLibraryFragment>::@getter::A#element
                staticType: int
              operator: + @25
              rightOperand: IntegerLiteral
                literal: 2 @27
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get A @-1
          reference: <testLibraryFragment>::@getter::A
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get B @-1
          reference: <testLibraryFragment>::@getter::B
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const A @6
          reference: <testLibraryFragment>::@topLevelVariable::A
          element: <testLibraryFragment>::@topLevelVariable::A#element
          getter2: <testLibraryFragment>::@getter::A
        const B @19
          reference: <testLibraryFragment>::@topLevelVariable::B
          element: <testLibraryFragment>::@topLevelVariable::B#element
          getter2: <testLibraryFragment>::@getter::B
      getters
        get A @-1
          reference: <testLibraryFragment>::@getter::A
          element: <testLibraryFragment>::@getter::A#element
        get B @-1
          reference: <testLibraryFragment>::@getter::B
          element: <testLibraryFragment>::@getter::B#element
  topLevelVariables
    const A
      firstFragment: <testLibraryFragment>::@topLevelVariable::A
      type: int
      getter: <testLibraryFragment>::@getter::A#element
    const B
      firstFragment: <testLibraryFragment>::@topLevelVariable::B
      type: int
      getter: <testLibraryFragment>::@getter::B#element
  getters
    synthetic static get A
      firstFragment: <testLibraryFragment>::@getter::A
    synthetic static get B
      firstFragment: <testLibraryFragment>::@getter::B
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const B @23
          reference: <testLibraryFragment>::@topLevelVariable::B
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @27
                staticElement: package:test/a.dart::<fragment>::@getter::A
                element: package:test/a.dart::<fragment>::@getter::A#element
                staticType: int
              operator: + @29
              rightOperand: IntegerLiteral
                literal: 2 @31
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get B @-1
          reference: <testLibraryFragment>::@getter::B
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const B @23
          reference: <testLibraryFragment>::@topLevelVariable::B
          element: <testLibraryFragment>::@topLevelVariable::B#element
          getter2: <testLibraryFragment>::@getter::B
      getters
        get B @-1
          reference: <testLibraryFragment>::@getter::B
          element: <testLibraryFragment>::@getter::B#element
  topLevelVariables
    const B
      firstFragment: <testLibraryFragment>::@topLevelVariable::B
      type: int
      getter: <testLibraryFragment>::@getter::B#element
  getters
    synthetic static get B
      firstFragment: <testLibraryFragment>::@getter::B
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const B @28
          reference: <testLibraryFragment>::@topLevelVariable::B
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: A @34
                  staticElement: package:test/a.dart::<fragment>::@getter::A
                  element: package:test/a.dart::<fragment>::@getter::A#element
                  staticType: int
                staticElement: package:test/a.dart::<fragment>::@getter::A
                element: package:test/a.dart::<fragment>::@getter::A#element
                staticType: int
              operator: + @36
              rightOperand: IntegerLiteral
                literal: 2 @38
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get B @-1
          reference: <testLibraryFragment>::@getter::B
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
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
        const B @28
          reference: <testLibraryFragment>::@topLevelVariable::B
          element: <testLibraryFragment>::@topLevelVariable::B#element
          getter2: <testLibraryFragment>::@getter::B
      getters
        get B @-1
          reference: <testLibraryFragment>::@getter::B
          element: <testLibraryFragment>::@getter::B#element
  topLevelVariables
    const B
      firstFragment: <testLibraryFragment>::@topLevelVariable::B
      type: int
      getter: <testLibraryFragment>::@getter::B#element
  getters
    synthetic static get B
      firstFragment: <testLibraryFragment>::@getter::B
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        class D @17
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @19
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
      enums
        enum E @30
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @33
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @36
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @39
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      element: <testLibraryFragment>::@enum::E::@getter::c#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @50
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(int, String)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @56
                type: int
              requiredPositional b @66
                type: String
            returnType: dynamic
      topLevelVariables
        static const vDynamic @76
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: dynamic @87
              staticElement: dynamic@-1
              element: dynamic@-1
              staticType: Type
        static const vNull @102
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: Null @110
              staticElement: dart:core::<fragment>::@class::Null
              element: dart:core::<fragment>::@class::Null#element
              staticType: Type
        static const vObject @122
          reference: <testLibraryFragment>::@topLevelVariable::vObject
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: Object @132
              staticElement: dart:core::<fragment>::@class::Object
              element: dart:core::<fragment>::@class::Object#element
              staticType: Type
        static const vClass @146
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: C @155
              staticElement: <testLibraryFragment>::@class::C
              element: <testLibraryFragment>::@class::C#element
              staticType: Type
        static const vGenericClass @164
          reference: <testLibraryFragment>::@topLevelVariable::vGenericClass
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: D @180
              staticElement: <testLibraryFragment>::@class::D
              element: <testLibraryFragment>::@class::D#element
              staticType: Type
        static const vEnum @189
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: E @197
              staticElement: <testLibraryFragment>::@enum::E
              element: <testLibraryFragment>::@enum::E#element
              staticType: Type
        static const vFunctionTypeAlias @206
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: F @227
              staticElement: <testLibraryFragment>::@typeAlias::F
              element: <testLibraryFragment>::@typeAlias::F#element
              staticType: Type
      accessors
        synthetic static get vDynamic @-1
          reference: <testLibraryFragment>::@getter::vDynamic
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vObject @-1
          reference: <testLibraryFragment>::@getter::vObject
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vGenericClass @-1
          reference: <testLibraryFragment>::@getter::vGenericClass
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          enclosingElement3: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
        class D @17
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          typeParameters
            T @19
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
      enums
        enum E @30
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @33
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @36
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @39
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibraryFragment>::@enum::E::@field::c#element
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <testLibraryFragment>::@enum::E::@getter::c#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      typeAliases
        F @50
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
      topLevelVariables
        const vDynamic @76
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          element: <testLibraryFragment>::@topLevelVariable::vDynamic#element
          getter2: <testLibraryFragment>::@getter::vDynamic
        const vNull @102
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          element: <testLibraryFragment>::@topLevelVariable::vNull#element
          getter2: <testLibraryFragment>::@getter::vNull
        const vObject @122
          reference: <testLibraryFragment>::@topLevelVariable::vObject
          element: <testLibraryFragment>::@topLevelVariable::vObject#element
          getter2: <testLibraryFragment>::@getter::vObject
        const vClass @146
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          element: <testLibraryFragment>::@topLevelVariable::vClass#element
          getter2: <testLibraryFragment>::@getter::vClass
        const vGenericClass @164
          reference: <testLibraryFragment>::@topLevelVariable::vGenericClass
          element: <testLibraryFragment>::@topLevelVariable::vGenericClass#element
          getter2: <testLibraryFragment>::@getter::vGenericClass
        const vEnum @189
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          element: <testLibraryFragment>::@topLevelVariable::vEnum#element
          getter2: <testLibraryFragment>::@getter::vEnum
        const vFunctionTypeAlias @206
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          element: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias#element
          getter2: <testLibraryFragment>::@getter::vFunctionTypeAlias
      getters
        get vDynamic @-1
          reference: <testLibraryFragment>::@getter::vDynamic
          element: <testLibraryFragment>::@getter::vDynamic#element
        get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          element: <testLibraryFragment>::@getter::vNull#element
        get vObject @-1
          reference: <testLibraryFragment>::@getter::vObject
          element: <testLibraryFragment>::@getter::vObject#element
        get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          element: <testLibraryFragment>::@getter::vClass#element
        get vGenericClass @-1
          reference: <testLibraryFragment>::@getter::vGenericClass
          element: <testLibraryFragment>::@getter::vGenericClass#element
        get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          element: <testLibraryFragment>::@getter::vEnum#element
        get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          element: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        static const c
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::c#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function(int, String)
  topLevelVariables
    const vDynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic
      type: Type
      getter: <testLibraryFragment>::@getter::vDynamic#element
    const vNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNull
      type: Type
      getter: <testLibraryFragment>::@getter::vNull#element
    const vObject
      firstFragment: <testLibraryFragment>::@topLevelVariable::vObject
      type: Type
      getter: <testLibraryFragment>::@getter::vObject#element
    const vClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vClass
      type: Type
      getter: <testLibraryFragment>::@getter::vClass#element
    const vGenericClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vGenericClass
      type: Type
      getter: <testLibraryFragment>::@getter::vGenericClass#element
    const vEnum
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEnum
      type: Type
      getter: <testLibraryFragment>::@getter::vEnum#element
    const vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
      type: Type
      getter: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  getters
    synthetic static get vDynamic
      firstFragment: <testLibraryFragment>::@getter::vDynamic
    synthetic static get vNull
      firstFragment: <testLibraryFragment>::@getter::vNull
    synthetic static get vObject
      firstFragment: <testLibraryFragment>::@getter::vObject
    synthetic static get vClass
      firstFragment: <testLibraryFragment>::@getter::vClass
    synthetic static get vGenericClass
      firstFragment: <testLibraryFragment>::@getter::vGenericClass
    synthetic static get vEnum
      firstFragment: <testLibraryFragment>::@getter::vEnum
    synthetic static get vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@getter::vFunctionTypeAlias
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            final f @31
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: List<dynamic Function()>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: List<dynamic Function()>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            f @31
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: List<dynamic Function()>
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const vClass @23
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: C @32
              staticElement: package:test/a.dart::<fragment>::@class::C
              element: package:test/a.dart::<fragment>::@class::C#element
              staticType: Type
        static const vEnum @41
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: E @49
              staticElement: package:test/a.dart::<fragment>::@enum::E
              element: package:test/a.dart::<fragment>::@enum::E#element
              staticType: Type
        static const vFunctionTypeAlias @58
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: F @79
              staticElement: package:test/a.dart::<fragment>::@typeAlias::F
              element: package:test/a.dart::<fragment>::@typeAlias::F#element
              staticType: Type
      accessors
        synthetic static get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          enclosingElement3: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const vClass @23
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          element: <testLibraryFragment>::@topLevelVariable::vClass#element
          getter2: <testLibraryFragment>::@getter::vClass
        const vEnum @41
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          element: <testLibraryFragment>::@topLevelVariable::vEnum#element
          getter2: <testLibraryFragment>::@getter::vEnum
        const vFunctionTypeAlias @58
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          element: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias#element
          getter2: <testLibraryFragment>::@getter::vFunctionTypeAlias
      getters
        get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          element: <testLibraryFragment>::@getter::vClass#element
        get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          element: <testLibraryFragment>::@getter::vEnum#element
        get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          element: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  topLevelVariables
    const vClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vClass
      type: Type
      getter: <testLibraryFragment>::@getter::vClass#element
    const vEnum
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEnum
      type: Type
      getter: <testLibraryFragment>::@getter::vEnum#element
    const vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
      type: Type
      getter: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  getters
    synthetic static get vClass
      firstFragment: <testLibraryFragment>::@getter::vClass
    synthetic static get vEnum
      firstFragment: <testLibraryFragment>::@getter::vEnum
    synthetic static get vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@getter::vFunctionTypeAlias
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const vClass @28
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @37
                staticElement: <testLibraryFragment>::@prefix::p
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @38
              identifier: SimpleIdentifier
                token: C @39
                staticElement: package:test/a.dart::<fragment>::@class::C
                element: package:test/a.dart::<fragment>::@class::C#element
                staticType: Type
              staticElement: package:test/a.dart::<fragment>::@class::C
              element: package:test/a.dart::<fragment>::@class::C#element
              staticType: Type
        static const vEnum @48
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @56
                staticElement: <testLibraryFragment>::@prefix::p
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @57
              identifier: SimpleIdentifier
                token: E @58
                staticElement: package:test/a.dart::<fragment>::@enum::E
                element: package:test/a.dart::<fragment>::@enum::E#element
                staticType: Type
              staticElement: package:test/a.dart::<fragment>::@enum::E
              element: package:test/a.dart::<fragment>::@enum::E#element
              staticType: Type
        static const vFunctionTypeAlias @67
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @88
                staticElement: <testLibraryFragment>::@prefix::p
                element: <testLibraryFragment>::@prefix2::p
                staticType: null
              period: . @89
              identifier: SimpleIdentifier
                token: F @90
                staticElement: package:test/a.dart::<fragment>::@typeAlias::F
                element: package:test/a.dart::<fragment>::@typeAlias::F#element
                staticType: Type
              staticElement: package:test/a.dart::<fragment>::@typeAlias::F
              element: package:test/a.dart::<fragment>::@typeAlias::F#element
              staticType: Type
      accessors
        synthetic static get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          enclosingElement3: <testLibraryFragment>
          returnType: Type
        synthetic static get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          enclosingElement3: <testLibraryFragment>
          returnType: Type
----------------------------------------
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
        const vClass @28
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          element: <testLibraryFragment>::@topLevelVariable::vClass#element
          getter2: <testLibraryFragment>::@getter::vClass
        const vEnum @48
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          element: <testLibraryFragment>::@topLevelVariable::vEnum#element
          getter2: <testLibraryFragment>::@getter::vEnum
        const vFunctionTypeAlias @67
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          element: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias#element
          getter2: <testLibraryFragment>::@getter::vFunctionTypeAlias
      getters
        get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          element: <testLibraryFragment>::@getter::vClass#element
        get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          element: <testLibraryFragment>::@getter::vEnum#element
        get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          element: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  topLevelVariables
    const vClass
      firstFragment: <testLibraryFragment>::@topLevelVariable::vClass
      type: Type
      getter: <testLibraryFragment>::@getter::vClass#element
    const vEnum
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEnum
      type: Type
      getter: <testLibraryFragment>::@getter::vEnum#element
    const vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
      type: Type
      getter: <testLibraryFragment>::@getter::vFunctionTypeAlias#element
  getters
    synthetic static get vClass
      firstFragment: <testLibraryFragment>::@getter::vClass
    synthetic static get vEnum
      firstFragment: <testLibraryFragment>::@getter::vEnum
    synthetic static get vFunctionTypeAlias
      firstFragment: <testLibraryFragment>::@getter::vFunctionTypeAlias
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: List<T>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: List<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @8
              element: <not-implemented>
          fields
            f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: List<T>
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
''');
  }

  test_const_reference_unresolved_prefix0() async {
    var library = await buildLibrary(r'''
const V = foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @10
              staticElement: <null>
              element: <null>
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @21
                staticElement: <testLibraryFragment>::@class::C
                element: <testLibraryFragment>::@class::C#element
                staticType: null
              period: . @22
              identifier: SimpleIdentifier
                token: foo @23
                staticElement: <null>
                element: <null>
                staticType: InvalidType
              staticElement: <null>
              element: <null>
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
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
  libraryImports
    package:test/foo.dart as p @21
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @21
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as p @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @21
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @30
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @34
                  staticElement: <testLibraryFragment>::@prefix::p
                  element: <testLibraryFragment>::@prefix2::p
                  staticType: null
                period: . @35
                identifier: SimpleIdentifier
                  token: C @36
                  staticElement: package:test/foo.dart::<fragment>::@class::C
                  element: package:test/foo.dart::<fragment>::@class::C#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::C
                element: package:test/foo.dart::<fragment>::@class::C#element
                staticType: null
              operator: . @37
              propertyName: SimpleIdentifier
                token: foo @38
                staticElement: <null>
                element: <null>
                staticType: InvalidType
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
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
        const V @30
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibraryFragment>::@topLevelVariable::V#element
          getter2: <testLibraryFragment>::@getter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
  topLevelVariables
    const V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: InvalidType
      getter: <testLibraryFragment>::@getter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
''');
  }

  test_const_set_if() async {
    var library = await buildLibrary('''
const Object x = const <int>{if (true) 1};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_set_spread() async {
    var library = await buildLibrary('''
const Object x = const <int>{...<int>{1}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_const_set_spread_null_aware() async {
    var library = await buildLibrary('''
const Object x = const <int>{...?<int>{1}};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @17
              typeArguments: TypeArgumentList
                leftBracket: < @23
                arguments
                  NamedType
                    name: int @24
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Object
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vEqual
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @15
                staticType: int
              operator: == @17
              rightOperand: IntegerLiteral
                literal: 2 @20
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::==
              element: dart:core::<fragment>::@class::num::@method::==#element
              staticInvokeType: bool Function(Object)
              staticType: bool
        static const vAnd @29
          reference: <testLibraryFragment>::@topLevelVariable::vAnd
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: BooleanLiteral
                literal: true @36
                staticType: bool
              operator: && @41
              rightOperand: BooleanLiteral
                literal: false @44
                staticType: bool
              staticElement: <null>
              element: <null>
              staticInvokeType: null
              staticType: bool
        static const vOr @57
          reference: <testLibraryFragment>::@topLevelVariable::vOr
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: BooleanLiteral
                literal: false @63
                staticType: bool
              operator: || @69
              rightOperand: BooleanLiteral
                literal: true @72
                staticType: bool
              staticElement: <null>
              element: <null>
              staticInvokeType: null
              staticType: bool
        static const vBitXor @84
          reference: <testLibraryFragment>::@topLevelVariable::vBitXor
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @94
                staticType: int
              operator: ^ @96
              rightOperand: IntegerLiteral
                literal: 2 @98
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::^
              element: dart:core::<fragment>::@class::int::@method::^#element
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitAnd @107
          reference: <testLibraryFragment>::@topLevelVariable::vBitAnd
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @117
                staticType: int
              operator: & @119
              rightOperand: IntegerLiteral
                literal: 2 @121
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::&
              element: dart:core::<fragment>::@class::int::@method::&#element
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitOr @130
          reference: <testLibraryFragment>::@topLevelVariable::vBitOr
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @139
                staticType: int
              operator: | @141
              rightOperand: IntegerLiteral
                literal: 2 @143
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::|
              element: dart:core::<fragment>::@class::int::@method::|#element
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitShiftLeft @152
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @168
                staticType: int
              operator: << @170
              rightOperand: IntegerLiteral
                literal: 2 @173
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::<<
              element: dart:core::<fragment>::@class::int::@method::<<#element
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitShiftRight @182
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @199
                staticType: int
              operator: >> @201
              rightOperand: IntegerLiteral
                literal: 2 @204
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::>>
              element: dart:core::<fragment>::@class::int::@method::>>#element
              staticInvokeType: int Function(int)
              staticType: int
        static const vAdd @213
          reference: <testLibraryFragment>::@topLevelVariable::vAdd
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @220
                staticType: int
              operator: + @222
              rightOperand: IntegerLiteral
                literal: 2 @224
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
        static const vSubtract @233
          reference: <testLibraryFragment>::@topLevelVariable::vSubtract
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @245
                staticType: int
              operator: - @247
              rightOperand: IntegerLiteral
                literal: 2 @249
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::-
              element: dart:core::<fragment>::@class::num::@method::-#element
              staticInvokeType: num Function(num)
              staticType: int
        static const vMiltiply @258
          reference: <testLibraryFragment>::@topLevelVariable::vMiltiply
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @270
                staticType: int
              operator: * @272
              rightOperand: IntegerLiteral
                literal: 2 @274
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::*
              element: dart:core::<fragment>::@class::num::@method::*#element
              staticInvokeType: num Function(num)
              staticType: int
        static const vDivide @283
          reference: <testLibraryFragment>::@topLevelVariable::vDivide
          enclosingElement3: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @293
                staticType: int
              operator: / @295
              rightOperand: IntegerLiteral
                literal: 2 @297
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::/
              element: dart:core::<fragment>::@class::num::@method::/#element
              staticInvokeType: double Function(num)
              staticType: double
        static const vFloorDivide @306
          reference: <testLibraryFragment>::@topLevelVariable::vFloorDivide
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @321
                staticType: int
              operator: ~/ @323
              rightOperand: IntegerLiteral
                literal: 2 @326
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::~/
              element: dart:core::<fragment>::@class::num::@method::~/#element
              staticInvokeType: int Function(num)
              staticType: int
        static const vModulo @335
          reference: <testLibraryFragment>::@topLevelVariable::vModulo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @345
                staticType: int
              operator: % @347
              rightOperand: IntegerLiteral
                literal: 2 @349
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::%
              element: dart:core::<fragment>::@class::num::@method::%#element
              staticInvokeType: num Function(num)
              staticType: int
        static const vGreater @358
          reference: <testLibraryFragment>::@topLevelVariable::vGreater
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @369
                staticType: int
              operator: > @371
              rightOperand: IntegerLiteral
                literal: 2 @373
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::>
              element: dart:core::<fragment>::@class::num::@method::>#element
              staticInvokeType: bool Function(num)
              staticType: bool
        static const vGreaterEqual @382
          reference: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @398
                staticType: int
              operator: >= @400
              rightOperand: IntegerLiteral
                literal: 2 @403
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::>=
              element: dart:core::<fragment>::@class::num::@method::>=#element
              staticInvokeType: bool Function(num)
              staticType: bool
        static const vLess @412
          reference: <testLibraryFragment>::@topLevelVariable::vLess
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @420
                staticType: int
              operator: < @422
              rightOperand: IntegerLiteral
                literal: 2 @424
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::<
              element: dart:core::<fragment>::@class::num::@method::<#element
              staticInvokeType: bool Function(num)
              staticType: bool
        static const vLessEqual @433
          reference: <testLibraryFragment>::@topLevelVariable::vLessEqual
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @446
                staticType: int
              operator: <= @448
              rightOperand: IntegerLiteral
                literal: 2 @451
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::<=
              element: dart:core::<fragment>::@class::num::@method::<=#element
              staticInvokeType: bool Function(num)
              staticType: bool
      accessors
        synthetic static get vEqual @-1
          reference: <testLibraryFragment>::@getter::vEqual
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vAnd @-1
          reference: <testLibraryFragment>::@getter::vAnd
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vOr @-1
          reference: <testLibraryFragment>::@getter::vOr
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vBitXor @-1
          reference: <testLibraryFragment>::@getter::vBitXor
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vBitAnd @-1
          reference: <testLibraryFragment>::@getter::vBitAnd
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vBitOr @-1
          reference: <testLibraryFragment>::@getter::vBitOr
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vBitShiftLeft @-1
          reference: <testLibraryFragment>::@getter::vBitShiftLeft
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vBitShiftRight @-1
          reference: <testLibraryFragment>::@getter::vBitShiftRight
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vAdd @-1
          reference: <testLibraryFragment>::@getter::vAdd
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vSubtract @-1
          reference: <testLibraryFragment>::@getter::vSubtract
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vMiltiply @-1
          reference: <testLibraryFragment>::@getter::vMiltiply
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vDivide @-1
          reference: <testLibraryFragment>::@getter::vDivide
          enclosingElement3: <testLibraryFragment>
          returnType: double
        synthetic static get vFloorDivide @-1
          reference: <testLibraryFragment>::@getter::vFloorDivide
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vModulo @-1
          reference: <testLibraryFragment>::@getter::vModulo
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vGreater @-1
          reference: <testLibraryFragment>::@getter::vGreater
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vGreaterEqual @-1
          reference: <testLibraryFragment>::@getter::vGreaterEqual
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vLess @-1
          reference: <testLibraryFragment>::@getter::vLess
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vLessEqual @-1
          reference: <testLibraryFragment>::@getter::vLessEqual
          enclosingElement3: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vEqual
          element: <testLibraryFragment>::@topLevelVariable::vEqual#element
          getter2: <testLibraryFragment>::@getter::vEqual
        const vAnd @29
          reference: <testLibraryFragment>::@topLevelVariable::vAnd
          element: <testLibraryFragment>::@topLevelVariable::vAnd#element
          getter2: <testLibraryFragment>::@getter::vAnd
        const vOr @57
          reference: <testLibraryFragment>::@topLevelVariable::vOr
          element: <testLibraryFragment>::@topLevelVariable::vOr#element
          getter2: <testLibraryFragment>::@getter::vOr
        const vBitXor @84
          reference: <testLibraryFragment>::@topLevelVariable::vBitXor
          element: <testLibraryFragment>::@topLevelVariable::vBitXor#element
          getter2: <testLibraryFragment>::@getter::vBitXor
        const vBitAnd @107
          reference: <testLibraryFragment>::@topLevelVariable::vBitAnd
          element: <testLibraryFragment>::@topLevelVariable::vBitAnd#element
          getter2: <testLibraryFragment>::@getter::vBitAnd
        const vBitOr @130
          reference: <testLibraryFragment>::@topLevelVariable::vBitOr
          element: <testLibraryFragment>::@topLevelVariable::vBitOr#element
          getter2: <testLibraryFragment>::@getter::vBitOr
        const vBitShiftLeft @152
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
          element: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft#element
          getter2: <testLibraryFragment>::@getter::vBitShiftLeft
        const vBitShiftRight @182
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
          element: <testLibraryFragment>::@topLevelVariable::vBitShiftRight#element
          getter2: <testLibraryFragment>::@getter::vBitShiftRight
        const vAdd @213
          reference: <testLibraryFragment>::@topLevelVariable::vAdd
          element: <testLibraryFragment>::@topLevelVariable::vAdd#element
          getter2: <testLibraryFragment>::@getter::vAdd
        const vSubtract @233
          reference: <testLibraryFragment>::@topLevelVariable::vSubtract
          element: <testLibraryFragment>::@topLevelVariable::vSubtract#element
          getter2: <testLibraryFragment>::@getter::vSubtract
        const vMiltiply @258
          reference: <testLibraryFragment>::@topLevelVariable::vMiltiply
          element: <testLibraryFragment>::@topLevelVariable::vMiltiply#element
          getter2: <testLibraryFragment>::@getter::vMiltiply
        const vDivide @283
          reference: <testLibraryFragment>::@topLevelVariable::vDivide
          element: <testLibraryFragment>::@topLevelVariable::vDivide#element
          getter2: <testLibraryFragment>::@getter::vDivide
        const vFloorDivide @306
          reference: <testLibraryFragment>::@topLevelVariable::vFloorDivide
          element: <testLibraryFragment>::@topLevelVariable::vFloorDivide#element
          getter2: <testLibraryFragment>::@getter::vFloorDivide
        const vModulo @335
          reference: <testLibraryFragment>::@topLevelVariable::vModulo
          element: <testLibraryFragment>::@topLevelVariable::vModulo#element
          getter2: <testLibraryFragment>::@getter::vModulo
        const vGreater @358
          reference: <testLibraryFragment>::@topLevelVariable::vGreater
          element: <testLibraryFragment>::@topLevelVariable::vGreater#element
          getter2: <testLibraryFragment>::@getter::vGreater
        const vGreaterEqual @382
          reference: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
          element: <testLibraryFragment>::@topLevelVariable::vGreaterEqual#element
          getter2: <testLibraryFragment>::@getter::vGreaterEqual
        const vLess @412
          reference: <testLibraryFragment>::@topLevelVariable::vLess
          element: <testLibraryFragment>::@topLevelVariable::vLess#element
          getter2: <testLibraryFragment>::@getter::vLess
        const vLessEqual @433
          reference: <testLibraryFragment>::@topLevelVariable::vLessEqual
          element: <testLibraryFragment>::@topLevelVariable::vLessEqual#element
          getter2: <testLibraryFragment>::@getter::vLessEqual
      getters
        get vEqual @-1
          reference: <testLibraryFragment>::@getter::vEqual
          element: <testLibraryFragment>::@getter::vEqual#element
        get vAnd @-1
          reference: <testLibraryFragment>::@getter::vAnd
          element: <testLibraryFragment>::@getter::vAnd#element
        get vOr @-1
          reference: <testLibraryFragment>::@getter::vOr
          element: <testLibraryFragment>::@getter::vOr#element
        get vBitXor @-1
          reference: <testLibraryFragment>::@getter::vBitXor
          element: <testLibraryFragment>::@getter::vBitXor#element
        get vBitAnd @-1
          reference: <testLibraryFragment>::@getter::vBitAnd
          element: <testLibraryFragment>::@getter::vBitAnd#element
        get vBitOr @-1
          reference: <testLibraryFragment>::@getter::vBitOr
          element: <testLibraryFragment>::@getter::vBitOr#element
        get vBitShiftLeft @-1
          reference: <testLibraryFragment>::@getter::vBitShiftLeft
          element: <testLibraryFragment>::@getter::vBitShiftLeft#element
        get vBitShiftRight @-1
          reference: <testLibraryFragment>::@getter::vBitShiftRight
          element: <testLibraryFragment>::@getter::vBitShiftRight#element
        get vAdd @-1
          reference: <testLibraryFragment>::@getter::vAdd
          element: <testLibraryFragment>::@getter::vAdd#element
        get vSubtract @-1
          reference: <testLibraryFragment>::@getter::vSubtract
          element: <testLibraryFragment>::@getter::vSubtract#element
        get vMiltiply @-1
          reference: <testLibraryFragment>::@getter::vMiltiply
          element: <testLibraryFragment>::@getter::vMiltiply#element
        get vDivide @-1
          reference: <testLibraryFragment>::@getter::vDivide
          element: <testLibraryFragment>::@getter::vDivide#element
        get vFloorDivide @-1
          reference: <testLibraryFragment>::@getter::vFloorDivide
          element: <testLibraryFragment>::@getter::vFloorDivide#element
        get vModulo @-1
          reference: <testLibraryFragment>::@getter::vModulo
          element: <testLibraryFragment>::@getter::vModulo#element
        get vGreater @-1
          reference: <testLibraryFragment>::@getter::vGreater
          element: <testLibraryFragment>::@getter::vGreater#element
        get vGreaterEqual @-1
          reference: <testLibraryFragment>::@getter::vGreaterEqual
          element: <testLibraryFragment>::@getter::vGreaterEqual#element
        get vLess @-1
          reference: <testLibraryFragment>::@getter::vLess
          element: <testLibraryFragment>::@getter::vLess#element
        get vLessEqual @-1
          reference: <testLibraryFragment>::@getter::vLessEqual
          element: <testLibraryFragment>::@getter::vLessEqual#element
  topLevelVariables
    const vEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vEqual
      type: bool
      getter: <testLibraryFragment>::@getter::vEqual#element
    const vAnd
      firstFragment: <testLibraryFragment>::@topLevelVariable::vAnd
      type: bool
      getter: <testLibraryFragment>::@getter::vAnd#element
    const vOr
      firstFragment: <testLibraryFragment>::@topLevelVariable::vOr
      type: bool
      getter: <testLibraryFragment>::@getter::vOr#element
    const vBitXor
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitXor
      type: int
      getter: <testLibraryFragment>::@getter::vBitXor#element
    const vBitAnd
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitAnd
      type: int
      getter: <testLibraryFragment>::@getter::vBitAnd#element
    const vBitOr
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitOr
      type: int
      getter: <testLibraryFragment>::@getter::vBitOr#element
    const vBitShiftLeft
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
      type: int
      getter: <testLibraryFragment>::@getter::vBitShiftLeft#element
    const vBitShiftRight
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
      type: int
      getter: <testLibraryFragment>::@getter::vBitShiftRight#element
    const vAdd
      firstFragment: <testLibraryFragment>::@topLevelVariable::vAdd
      type: int
      getter: <testLibraryFragment>::@getter::vAdd#element
    const vSubtract
      firstFragment: <testLibraryFragment>::@topLevelVariable::vSubtract
      type: int
      getter: <testLibraryFragment>::@getter::vSubtract#element
    const vMiltiply
      firstFragment: <testLibraryFragment>::@topLevelVariable::vMiltiply
      type: int
      getter: <testLibraryFragment>::@getter::vMiltiply#element
    const vDivide
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDivide
      type: double
      getter: <testLibraryFragment>::@getter::vDivide#element
    const vFloorDivide
      firstFragment: <testLibraryFragment>::@topLevelVariable::vFloorDivide
      type: int
      getter: <testLibraryFragment>::@getter::vFloorDivide#element
    const vModulo
      firstFragment: <testLibraryFragment>::@topLevelVariable::vModulo
      type: int
      getter: <testLibraryFragment>::@getter::vModulo#element
    const vGreater
      firstFragment: <testLibraryFragment>::@topLevelVariable::vGreater
      type: bool
      getter: <testLibraryFragment>::@getter::vGreater#element
    const vGreaterEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
      type: bool
      getter: <testLibraryFragment>::@getter::vGreaterEqual#element
    const vLess
      firstFragment: <testLibraryFragment>::@topLevelVariable::vLess
      type: bool
      getter: <testLibraryFragment>::@getter::vLess#element
    const vLessEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vLessEqual
      type: bool
      getter: <testLibraryFragment>::@getter::vLessEqual#element
  getters
    synthetic static get vEqual
      firstFragment: <testLibraryFragment>::@getter::vEqual
    synthetic static get vAnd
      firstFragment: <testLibraryFragment>::@getter::vAnd
    synthetic static get vOr
      firstFragment: <testLibraryFragment>::@getter::vOr
    synthetic static get vBitXor
      firstFragment: <testLibraryFragment>::@getter::vBitXor
    synthetic static get vBitAnd
      firstFragment: <testLibraryFragment>::@getter::vBitAnd
    synthetic static get vBitOr
      firstFragment: <testLibraryFragment>::@getter::vBitOr
    synthetic static get vBitShiftLeft
      firstFragment: <testLibraryFragment>::@getter::vBitShiftLeft
    synthetic static get vBitShiftRight
      firstFragment: <testLibraryFragment>::@getter::vBitShiftRight
    synthetic static get vAdd
      firstFragment: <testLibraryFragment>::@getter::vAdd
    synthetic static get vSubtract
      firstFragment: <testLibraryFragment>::@getter::vSubtract
    synthetic static get vMiltiply
      firstFragment: <testLibraryFragment>::@getter::vMiltiply
    synthetic static get vDivide
      firstFragment: <testLibraryFragment>::@getter::vDivide
    synthetic static get vFloorDivide
      firstFragment: <testLibraryFragment>::@getter::vFloorDivide
    synthetic static get vModulo
      firstFragment: <testLibraryFragment>::@getter::vModulo
    synthetic static get vGreater
      firstFragment: <testLibraryFragment>::@getter::vGreater
    synthetic static get vGreaterEqual
      firstFragment: <testLibraryFragment>::@getter::vGreaterEqual
    synthetic static get vLess
      firstFragment: <testLibraryFragment>::@getter::vLess
    synthetic static get vLessEqual
      firstFragment: <testLibraryFragment>::@getter::vLessEqual
''');
  }

  test_const_topLevel_conditional() async {
    var library = await buildLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vConditional @6
          reference: <testLibraryFragment>::@topLevelVariable::vConditional
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                  staticElement: dart:core::<fragment>::@class::num::@method::==
                  element: dart:core::<fragment>::@class::num::@method::==#element
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
      accessors
        synthetic static get vConditional @-1
          reference: <testLibraryFragment>::@getter::vConditional
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vConditional @6
          reference: <testLibraryFragment>::@topLevelVariable::vConditional
          element: <testLibraryFragment>::@topLevelVariable::vConditional#element
          getter2: <testLibraryFragment>::@getter::vConditional
      getters
        get vConditional @-1
          reference: <testLibraryFragment>::@getter::vConditional
          element: <testLibraryFragment>::@getter::vConditional#element
  topLevelVariables
    const vConditional
      firstFragment: <testLibraryFragment>::@topLevelVariable::vConditional
      type: int
      getter: <testLibraryFragment>::@getter::vConditional#element
  getters
    synthetic static get vConditional
      firstFragment: <testLibraryFragment>::@getter::vConditional
''');
  }

  test_const_topLevel_identical() async {
    var library = await buildLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vIdentical @6
          reference: <testLibraryFragment>::@topLevelVariable::vIdentical
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                  staticElement: dart:core::<fragment>::@class::num::@method::==
                  element: dart:core::<fragment>::@class::num::@method::==#element
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
      accessors
        synthetic static get vIdentical @-1
          reference: <testLibraryFragment>::@getter::vIdentical
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vIdentical @6
          reference: <testLibraryFragment>::@topLevelVariable::vIdentical
          element: <testLibraryFragment>::@topLevelVariable::vIdentical#element
          getter2: <testLibraryFragment>::@getter::vIdentical
      getters
        get vIdentical @-1
          reference: <testLibraryFragment>::@getter::vIdentical
          element: <testLibraryFragment>::@getter::vIdentical#element
  topLevelVariables
    const vIdentical
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIdentical
      type: int
      getter: <testLibraryFragment>::@getter::vIdentical#element
  getters
    synthetic static get vIdentical
      firstFragment: <testLibraryFragment>::@getter::vIdentical
''');
  }

  test_const_topLevel_ifNull() async {
    var library = await buildLibrary(r'''
const vIfNull = 1 ?? 2.0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vIfNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vIfNull
          enclosingElement3: <testLibraryFragment>
          type: num
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @16
                staticType: int
              operator: ?? @18
              rightOperand: DoubleLiteral
                literal: 2.0 @21
                staticType: double
              staticElement: <null>
              element: <null>
              staticInvokeType: null
              staticType: num
      accessors
        synthetic static get vIfNull @-1
          reference: <testLibraryFragment>::@getter::vIfNull
          enclosingElement3: <testLibraryFragment>
          returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vIfNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vIfNull
          element: <testLibraryFragment>::@topLevelVariable::vIfNull#element
          getter2: <testLibraryFragment>::@getter::vIfNull
      getters
        get vIfNull @-1
          reference: <testLibraryFragment>::@getter::vIfNull
          element: <testLibraryFragment>::@getter::vIfNull#element
  topLevelVariables
    const vIfNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIfNull
      type: num
      getter: <testLibraryFragment>::@getter::vIfNull#element
  getters
    synthetic static get vIfNull
      firstFragment: <testLibraryFragment>::@getter::vIfNull
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @14
              staticType: Null
        static const vBoolFalse @26
          reference: <testLibraryFragment>::@topLevelVariable::vBoolFalse
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BooleanLiteral
              literal: false @39
              staticType: bool
        static const vBoolTrue @52
          reference: <testLibraryFragment>::@topLevelVariable::vBoolTrue
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BooleanLiteral
              literal: true @64
              staticType: bool
        static const vIntPositive @76
          reference: <testLibraryFragment>::@topLevelVariable::vIntPositive
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 1 @91
              staticType: int
        static const vIntNegative @100
          reference: <testLibraryFragment>::@topLevelVariable::vIntNegative
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @115
              operand: IntegerLiteral
                literal: 2 @116
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              element: dart:core::<fragment>::@class::int::@method::unary-#element
              staticType: int
        static const vIntLong1 @125
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong1
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0x7FFFFFFFFFFFFFFF @137
              staticType: int
        static const vIntLong2 @163
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong2
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0xFFFFFFFFFFFFFFFF @175
              staticType: int
        static const vIntLong3 @201
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong3
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0x8000000000000000 @213
              staticType: int
        static const vDouble @239
          reference: <testLibraryFragment>::@topLevelVariable::vDouble
          enclosingElement3: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
          constantInitializer
            DoubleLiteral
              literal: 2.3 @249
              staticType: double
        static const vString @260
          reference: <testLibraryFragment>::@topLevelVariable::vString
          enclosingElement3: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleStringLiteral
              literal: 'abc' @270
        static const vStringConcat @283
          reference: <testLibraryFragment>::@topLevelVariable::vStringConcat
          enclosingElement3: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: false
          constantInitializer
            AdjacentStrings
              strings
                SimpleStringLiteral
                  literal: 'aaa' @299
                SimpleStringLiteral
                  literal: 'bbb' @305
              staticType: String
              stringValue: aaabbb
        static const vStringInterpolation @318
          reference: <testLibraryFragment>::@topLevelVariable::vStringInterpolation
          enclosingElement3: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
        static const vSymbol @372
          reference: <testLibraryFragment>::@topLevelVariable::vSymbol
          enclosingElement3: <testLibraryFragment>
          type: Symbol
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SymbolLiteral
              poundSign: # @382
              components
                aaa
                  offset: 383
                bbb
                  offset: 387
                ccc
                  offset: 391
      accessors
        synthetic static get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get vBoolFalse @-1
          reference: <testLibraryFragment>::@getter::vBoolFalse
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vBoolTrue @-1
          reference: <testLibraryFragment>::@getter::vBoolTrue
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vIntPositive @-1
          reference: <testLibraryFragment>::@getter::vIntPositive
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vIntNegative @-1
          reference: <testLibraryFragment>::@getter::vIntNegative
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vIntLong1 @-1
          reference: <testLibraryFragment>::@getter::vIntLong1
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vIntLong2 @-1
          reference: <testLibraryFragment>::@getter::vIntLong2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vIntLong3 @-1
          reference: <testLibraryFragment>::@getter::vIntLong3
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vDouble @-1
          reference: <testLibraryFragment>::@getter::vDouble
          enclosingElement3: <testLibraryFragment>
          returnType: double
        synthetic static get vString @-1
          reference: <testLibraryFragment>::@getter::vString
          enclosingElement3: <testLibraryFragment>
          returnType: String
        synthetic static get vStringConcat @-1
          reference: <testLibraryFragment>::@getter::vStringConcat
          enclosingElement3: <testLibraryFragment>
          returnType: String
        synthetic static get vStringInterpolation @-1
          reference: <testLibraryFragment>::@getter::vStringInterpolation
          enclosingElement3: <testLibraryFragment>
          returnType: String
        synthetic static get vSymbol @-1
          reference: <testLibraryFragment>::@getter::vSymbol
          enclosingElement3: <testLibraryFragment>
          returnType: Symbol
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          element: <testLibraryFragment>::@topLevelVariable::vNull#element
          getter2: <testLibraryFragment>::@getter::vNull
        const vBoolFalse @26
          reference: <testLibraryFragment>::@topLevelVariable::vBoolFalse
          element: <testLibraryFragment>::@topLevelVariable::vBoolFalse#element
          getter2: <testLibraryFragment>::@getter::vBoolFalse
        const vBoolTrue @52
          reference: <testLibraryFragment>::@topLevelVariable::vBoolTrue
          element: <testLibraryFragment>::@topLevelVariable::vBoolTrue#element
          getter2: <testLibraryFragment>::@getter::vBoolTrue
        const vIntPositive @76
          reference: <testLibraryFragment>::@topLevelVariable::vIntPositive
          element: <testLibraryFragment>::@topLevelVariable::vIntPositive#element
          getter2: <testLibraryFragment>::@getter::vIntPositive
        const vIntNegative @100
          reference: <testLibraryFragment>::@topLevelVariable::vIntNegative
          element: <testLibraryFragment>::@topLevelVariable::vIntNegative#element
          getter2: <testLibraryFragment>::@getter::vIntNegative
        const vIntLong1 @125
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong1
          element: <testLibraryFragment>::@topLevelVariable::vIntLong1#element
          getter2: <testLibraryFragment>::@getter::vIntLong1
        const vIntLong2 @163
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong2
          element: <testLibraryFragment>::@topLevelVariable::vIntLong2#element
          getter2: <testLibraryFragment>::@getter::vIntLong2
        const vIntLong3 @201
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong3
          element: <testLibraryFragment>::@topLevelVariable::vIntLong3#element
          getter2: <testLibraryFragment>::@getter::vIntLong3
        const vDouble @239
          reference: <testLibraryFragment>::@topLevelVariable::vDouble
          element: <testLibraryFragment>::@topLevelVariable::vDouble#element
          getter2: <testLibraryFragment>::@getter::vDouble
        const vString @260
          reference: <testLibraryFragment>::@topLevelVariable::vString
          element: <testLibraryFragment>::@topLevelVariable::vString#element
          getter2: <testLibraryFragment>::@getter::vString
        const vStringConcat @283
          reference: <testLibraryFragment>::@topLevelVariable::vStringConcat
          element: <testLibraryFragment>::@topLevelVariable::vStringConcat#element
          getter2: <testLibraryFragment>::@getter::vStringConcat
        const vStringInterpolation @318
          reference: <testLibraryFragment>::@topLevelVariable::vStringInterpolation
          element: <testLibraryFragment>::@topLevelVariable::vStringInterpolation#element
          getter2: <testLibraryFragment>::@getter::vStringInterpolation
        const vSymbol @372
          reference: <testLibraryFragment>::@topLevelVariable::vSymbol
          element: <testLibraryFragment>::@topLevelVariable::vSymbol#element
          getter2: <testLibraryFragment>::@getter::vSymbol
      getters
        get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          element: <testLibraryFragment>::@getter::vNull#element
        get vBoolFalse @-1
          reference: <testLibraryFragment>::@getter::vBoolFalse
          element: <testLibraryFragment>::@getter::vBoolFalse#element
        get vBoolTrue @-1
          reference: <testLibraryFragment>::@getter::vBoolTrue
          element: <testLibraryFragment>::@getter::vBoolTrue#element
        get vIntPositive @-1
          reference: <testLibraryFragment>::@getter::vIntPositive
          element: <testLibraryFragment>::@getter::vIntPositive#element
        get vIntNegative @-1
          reference: <testLibraryFragment>::@getter::vIntNegative
          element: <testLibraryFragment>::@getter::vIntNegative#element
        get vIntLong1 @-1
          reference: <testLibraryFragment>::@getter::vIntLong1
          element: <testLibraryFragment>::@getter::vIntLong1#element
        get vIntLong2 @-1
          reference: <testLibraryFragment>::@getter::vIntLong2
          element: <testLibraryFragment>::@getter::vIntLong2#element
        get vIntLong3 @-1
          reference: <testLibraryFragment>::@getter::vIntLong3
          element: <testLibraryFragment>::@getter::vIntLong3#element
        get vDouble @-1
          reference: <testLibraryFragment>::@getter::vDouble
          element: <testLibraryFragment>::@getter::vDouble#element
        get vString @-1
          reference: <testLibraryFragment>::@getter::vString
          element: <testLibraryFragment>::@getter::vString#element
        get vStringConcat @-1
          reference: <testLibraryFragment>::@getter::vStringConcat
          element: <testLibraryFragment>::@getter::vStringConcat#element
        get vStringInterpolation @-1
          reference: <testLibraryFragment>::@getter::vStringInterpolation
          element: <testLibraryFragment>::@getter::vStringInterpolation#element
        get vSymbol @-1
          reference: <testLibraryFragment>::@getter::vSymbol
          element: <testLibraryFragment>::@getter::vSymbol#element
  topLevelVariables
    const vNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNull
      type: dynamic
      getter: <testLibraryFragment>::@getter::vNull#element
    const vBoolFalse
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBoolFalse
      type: bool
      getter: <testLibraryFragment>::@getter::vBoolFalse#element
    const vBoolTrue
      firstFragment: <testLibraryFragment>::@topLevelVariable::vBoolTrue
      type: bool
      getter: <testLibraryFragment>::@getter::vBoolTrue#element
    const vIntPositive
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntPositive
      type: int
      getter: <testLibraryFragment>::@getter::vIntPositive#element
    const vIntNegative
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntNegative
      type: int
      getter: <testLibraryFragment>::@getter::vIntNegative#element
    const vIntLong1
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntLong1
      type: int
      getter: <testLibraryFragment>::@getter::vIntLong1#element
    const vIntLong2
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntLong2
      type: int
      getter: <testLibraryFragment>::@getter::vIntLong2#element
    const vIntLong3
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIntLong3
      type: int
      getter: <testLibraryFragment>::@getter::vIntLong3#element
    const vDouble
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDouble
      type: double
      getter: <testLibraryFragment>::@getter::vDouble#element
    const vString
      firstFragment: <testLibraryFragment>::@topLevelVariable::vString
      type: String
      getter: <testLibraryFragment>::@getter::vString#element
    const vStringConcat
      firstFragment: <testLibraryFragment>::@topLevelVariable::vStringConcat
      type: String
      getter: <testLibraryFragment>::@getter::vStringConcat#element
    const vStringInterpolation
      firstFragment: <testLibraryFragment>::@topLevelVariable::vStringInterpolation
      type: String
      getter: <testLibraryFragment>::@getter::vStringInterpolation#element
    const vSymbol
      firstFragment: <testLibraryFragment>::@topLevelVariable::vSymbol
      type: Symbol
      getter: <testLibraryFragment>::@getter::vSymbol#element
  getters
    synthetic static get vNull
      firstFragment: <testLibraryFragment>::@getter::vNull
    synthetic static get vBoolFalse
      firstFragment: <testLibraryFragment>::@getter::vBoolFalse
    synthetic static get vBoolTrue
      firstFragment: <testLibraryFragment>::@getter::vBoolTrue
    synthetic static get vIntPositive
      firstFragment: <testLibraryFragment>::@getter::vIntPositive
    synthetic static get vIntNegative
      firstFragment: <testLibraryFragment>::@getter::vIntNegative
    synthetic static get vIntLong1
      firstFragment: <testLibraryFragment>::@getter::vIntLong1
    synthetic static get vIntLong2
      firstFragment: <testLibraryFragment>::@getter::vIntLong2
    synthetic static get vIntLong3
      firstFragment: <testLibraryFragment>::@getter::vIntLong3
    synthetic static get vDouble
      firstFragment: <testLibraryFragment>::@getter::vDouble
    synthetic static get vString
      firstFragment: <testLibraryFragment>::@getter::vString
    synthetic static get vStringConcat
      firstFragment: <testLibraryFragment>::@getter::vStringConcat
    synthetic static get vStringInterpolation
      firstFragment: <testLibraryFragment>::@getter::vStringInterpolation
    synthetic static get vSymbol
      firstFragment: <testLibraryFragment>::@getter::vSymbol
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @15
              staticType: int
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: String?
          shouldUseTypeForInitializerInference: false
          constantInitializer
            MethodInvocation
              target: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: int?
              operator: ?. @29
              methodName: SimpleIdentifier
                token: toString @31
                staticElement: dart:core::<fragment>::@class::int::@method::toString
                element: dart:core::<fragment>::@class::int::@method::toString#element
                staticType: String Function()
              argumentList: ArgumentList
                leftParenthesis: ( @39
                rightParenthesis: ) @40
              staticInvokeType: String Function()
              staticType: String?
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: String?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int?
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: String?
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @15
              staticType: int
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: false
          constantInitializer
            CascadeExpression
              target: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: int?
              cascadeSections
                MethodInvocation
                  operator: ?.. @29
                  methodName: SimpleIdentifier
                    token: toString @32
                    staticElement: dart:core::<fragment>::@class::int::@method::toString
                    element: dart:core::<fragment>::@class::int::@method::toString#element
                    staticType: String Function()
                  argumentList: ArgumentList
                    leftParenthesis: ( @40
                    rightParenthesis: ) @41
                  staticInvokeType: String Function()
                  staticType: String
              staticType: int?
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int?
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int?
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @14
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: String?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SimpleStringLiteral
              literal: '' @18
        static const b @40
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: List<int?>
          shouldUseTypeForInitializerInference: true
          constantInitializer
            ListLiteral
              leftBracket: [ @44
              elements
                PropertyAccess
                  target: SimpleIdentifier
                    token: a @48
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: String?
                  operator: ?. @49
                  propertyName: SimpleIdentifier
                    token: length @51
                    staticElement: dart:core::<fragment>::@class::String::@getter::length
                    element: dart:core::<fragment>::@class::String::@getter::length#element
                    staticType: int
                  staticType: int?
              rightBracket: ] @59
              staticType: List<int?>
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: String?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: List<int?>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @14
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @40
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: String?
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: List<int?>
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v1 @10
          reference: <testLibraryFragment>::@topLevelVariable::v1
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
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
                  staticElement: dart:core::<fragment>::@class::num::@method::+
                  element: dart:core::<fragment>::@class::num::@method::+#element
                  staticInvokeType: num Function(num)
                  staticType: int
                rightParenthesis: ) @21
                staticType: int
              operator: * @23
              rightOperand: IntegerLiteral
                literal: 3 @25
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::*
              element: dart:core::<fragment>::@class::num::@method::*#element
              staticInvokeType: num Function(num)
              staticType: int
        static const v2 @38
          reference: <testLibraryFragment>::@topLevelVariable::v2
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
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
                  staticElement: dart:core::<fragment>::@class::num::@method::+
                  element: dart:core::<fragment>::@class::num::@method::+#element
                  staticInvokeType: num Function(num)
                  staticType: int
                rightParenthesis: ) @50
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              element: dart:core::<fragment>::@class::int::@method::unary-#element
              staticType: int
        static const v3 @63
          reference: <testLibraryFragment>::@topLevelVariable::v3
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: ParenthesizedExpression
                leftParenthesis: ( @68
                expression: BinaryExpression
                  leftOperand: SimpleStringLiteral
                    literal: 'aaa' @69
                  operator: + @75
                  rightOperand: SimpleStringLiteral
                    literal: 'bbb' @77
                  staticElement: dart:core::<fragment>::@class::String::@method::+
                  element: dart:core::<fragment>::@class::String::@method::+#element
                  staticInvokeType: String Function(String)
                  staticType: String
                rightParenthesis: ) @82
                staticType: String
              operator: . @83
              propertyName: SimpleIdentifier
                token: length @84
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticType: int
      accessors
        synthetic static get v1 @-1
          reference: <testLibraryFragment>::@getter::v1
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get v2 @-1
          reference: <testLibraryFragment>::@getter::v2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get v3 @-1
          reference: <testLibraryFragment>::@getter::v3
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v1 @10
          reference: <testLibraryFragment>::@topLevelVariable::v1
          element: <testLibraryFragment>::@topLevelVariable::v1#element
          getter2: <testLibraryFragment>::@getter::v1
        const v2 @38
          reference: <testLibraryFragment>::@topLevelVariable::v2
          element: <testLibraryFragment>::@topLevelVariable::v2#element
          getter2: <testLibraryFragment>::@getter::v2
        const v3 @63
          reference: <testLibraryFragment>::@topLevelVariable::v3
          element: <testLibraryFragment>::@topLevelVariable::v3#element
          getter2: <testLibraryFragment>::@getter::v3
      getters
        get v1 @-1
          reference: <testLibraryFragment>::@getter::v1
          element: <testLibraryFragment>::@getter::v1#element
        get v2 @-1
          reference: <testLibraryFragment>::@getter::v2
          element: <testLibraryFragment>::@getter::v2#element
        get v3 @-1
          reference: <testLibraryFragment>::@getter::v3
          element: <testLibraryFragment>::@getter::v3#element
  topLevelVariables
    const v1
      firstFragment: <testLibraryFragment>::@topLevelVariable::v1
      type: int
      getter: <testLibraryFragment>::@getter::v1#element
    const v2
      firstFragment: <testLibraryFragment>::@topLevelVariable::v2
      type: int
      getter: <testLibraryFragment>::@getter::v2#element
    const v3
      firstFragment: <testLibraryFragment>::@topLevelVariable::v3
      type: int
      getter: <testLibraryFragment>::@getter::v3#element
  getters
    synthetic static get v1
      firstFragment: <testLibraryFragment>::@getter::v1
    synthetic static get v2
      firstFragment: <testLibraryFragment>::@getter::v2
    synthetic static get v3
      firstFragment: <testLibraryFragment>::@getter::v3
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vNotEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vNotEqual
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: IntegerLiteral
                literal: 1 @18
                staticType: int
              operator: != @20
              rightOperand: IntegerLiteral
                literal: 2 @23
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::==
              element: dart:core::<fragment>::@class::num::@method::==#element
              staticInvokeType: bool Function(Object)
              staticType: bool
        static const vNot @32
          reference: <testLibraryFragment>::@topLevelVariable::vNot
          enclosingElement3: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: ! @39
              operand: BooleanLiteral
                literal: true @40
                staticType: bool
              staticElement: <null>
              element: <null>
              staticType: bool
        static const vNegate @52
          reference: <testLibraryFragment>::@topLevelVariable::vNegate
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @62
              operand: IntegerLiteral
                literal: 1 @63
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              element: dart:core::<fragment>::@class::int::@method::unary-#element
              staticType: int
        static const vComplement @72
          reference: <testLibraryFragment>::@topLevelVariable::vComplement
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: ~ @86
              operand: IntegerLiteral
                literal: 1 @87
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::~
              element: dart:core::<fragment>::@class::int::@method::~#element
              staticType: int
      accessors
        synthetic static get vNotEqual @-1
          reference: <testLibraryFragment>::@getter::vNotEqual
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vNot @-1
          reference: <testLibraryFragment>::@getter::vNot
          enclosingElement3: <testLibraryFragment>
          returnType: bool
        synthetic static get vNegate @-1
          reference: <testLibraryFragment>::@getter::vNegate
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get vComplement @-1
          reference: <testLibraryFragment>::@getter::vComplement
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vNotEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vNotEqual
          element: <testLibraryFragment>::@topLevelVariable::vNotEqual#element
          getter2: <testLibraryFragment>::@getter::vNotEqual
        const vNot @32
          reference: <testLibraryFragment>::@topLevelVariable::vNot
          element: <testLibraryFragment>::@topLevelVariable::vNot#element
          getter2: <testLibraryFragment>::@getter::vNot
        const vNegate @52
          reference: <testLibraryFragment>::@topLevelVariable::vNegate
          element: <testLibraryFragment>::@topLevelVariable::vNegate#element
          getter2: <testLibraryFragment>::@getter::vNegate
        const vComplement @72
          reference: <testLibraryFragment>::@topLevelVariable::vComplement
          element: <testLibraryFragment>::@topLevelVariable::vComplement#element
          getter2: <testLibraryFragment>::@getter::vComplement
      getters
        get vNotEqual @-1
          reference: <testLibraryFragment>::@getter::vNotEqual
          element: <testLibraryFragment>::@getter::vNotEqual#element
        get vNot @-1
          reference: <testLibraryFragment>::@getter::vNot
          element: <testLibraryFragment>::@getter::vNot#element
        get vNegate @-1
          reference: <testLibraryFragment>::@getter::vNegate
          element: <testLibraryFragment>::@getter::vNegate#element
        get vComplement @-1
          reference: <testLibraryFragment>::@getter::vComplement
          element: <testLibraryFragment>::@getter::vComplement#element
  topLevelVariables
    const vNotEqual
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNotEqual
      type: bool
      getter: <testLibraryFragment>::@getter::vNotEqual#element
    const vNot
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNot
      type: bool
      getter: <testLibraryFragment>::@getter::vNot#element
    const vNegate
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNegate
      type: int
      getter: <testLibraryFragment>::@getter::vNegate#element
    const vComplement
      firstFragment: <testLibraryFragment>::@topLevelVariable::vComplement
      type: int
      getter: <testLibraryFragment>::@getter::vComplement#element
  getters
    synthetic static get vNotEqual
      firstFragment: <testLibraryFragment>::@getter::vNotEqual
    synthetic static get vNot
      firstFragment: <testLibraryFragment>::@getter::vNot
    synthetic static get vNegate
      firstFragment: <testLibraryFragment>::@getter::vNegate
    synthetic static get vComplement
      firstFragment: <testLibraryFragment>::@getter::vComplement
''');
  }

  test_const_topLevel_super() async {
    var library = await buildLibrary(r'''
const vSuper = super;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vSuper @6
          reference: <testLibraryFragment>::@topLevelVariable::vSuper
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SuperExpression
              superKeyword: super @15
              staticType: InvalidType
      accessors
        synthetic static get vSuper @-1
          reference: <testLibraryFragment>::@getter::vSuper
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vSuper @6
          reference: <testLibraryFragment>::@topLevelVariable::vSuper
          element: <testLibraryFragment>::@topLevelVariable::vSuper#element
          getter2: <testLibraryFragment>::@getter::vSuper
      getters
        get vSuper @-1
          reference: <testLibraryFragment>::@getter::vSuper
          element: <testLibraryFragment>::@getter::vSuper#element
  topLevelVariables
    const vSuper
      firstFragment: <testLibraryFragment>::@topLevelVariable::vSuper
      type: InvalidType
      getter: <testLibraryFragment>::@getter::vSuper#element
  getters
    synthetic static get vSuper
      firstFragment: <testLibraryFragment>::@getter::vSuper
''');
  }

  test_const_topLevel_this() async {
    var library = await buildLibrary(r'''
const vThis = this;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vThis @6
          reference: <testLibraryFragment>::@topLevelVariable::vThis
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ThisExpression
              thisKeyword: this @14
              staticType: dynamic
      accessors
        synthetic static get vThis @-1
          reference: <testLibraryFragment>::@getter::vThis
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vThis @6
          reference: <testLibraryFragment>::@topLevelVariable::vThis
          element: <testLibraryFragment>::@topLevelVariable::vThis#element
          getter2: <testLibraryFragment>::@getter::vThis
      getters
        get vThis @-1
          reference: <testLibraryFragment>::@getter::vThis
          element: <testLibraryFragment>::@getter::vThis#element
  topLevelVariables
    const vThis
      firstFragment: <testLibraryFragment>::@topLevelVariable::vThis
      type: dynamic
      getter: <testLibraryFragment>::@getter::vThis#element
  getters
    synthetic static get vThis
      firstFragment: <testLibraryFragment>::@getter::vThis
''');
  }

  test_const_topLevel_throw() async {
    var library = await buildLibrary(r'''
const c = throw 42;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const c @6
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: Never
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ThrowExpression
              throwKeyword: throw @10
              expression: IntegerLiteral
                literal: 42 @16
                staticType: int
              staticType: Never
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: Never
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const c @6
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibraryFragment>::@topLevelVariable::c#element
          getter2: <testLibraryFragment>::@getter::c
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    const c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: Never
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          enclosingElement3: <testLibraryFragment>
          type: List<Null>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @14
              typeArguments: TypeArgumentList
                leftBracket: < @20
                arguments
                  NamedType
                    name: Null @21
                    element: dart:core::<fragment>::@class::Null
                    element2: dart:core::<fragment>::@class::Null#element
                    type: Null
                rightBracket: > @25
              leftBracket: [ @26
              rightBracket: ] @27
              staticType: List<Null>
        static const vDynamic @36
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          enclosingElement3: <testLibraryFragment>
          type: List<dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @47
              typeArguments: TypeArgumentList
                leftBracket: < @53
                arguments
                  NamedType
                    name: dynamic @54
                    element: dynamic@-1
                    element2: dynamic@-1
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
        static const vInterfaceNoTypeParameters @79
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters
          enclosingElement3: <testLibraryFragment>
          type: List<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @108
              typeArguments: TypeArgumentList
                leftBracket: < @114
                arguments
                  NamedType
                    name: int @115
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
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
        static const vInterfaceNoTypeArguments @136
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments
          enclosingElement3: <testLibraryFragment>
          type: List<List<dynamic>>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @164
              typeArguments: TypeArgumentList
                leftBracket: < @170
                arguments
                  NamedType
                    name: List @171
                    element: dart:core::<fragment>::@class::List
                    element2: dart:core::<fragment>::@class::List#element
                    type: List<dynamic>
                rightBracket: > @175
              leftBracket: [ @176
              rightBracket: ] @177
              staticType: List<List<dynamic>>
        static const vInterfaceWithTypeArguments @186
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          enclosingElement3: <testLibraryFragment>
          type: List<List<String>>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::<fragment>::@class::String#element
                          type: String
                      rightBracket: > @234
                    element: dart:core::<fragment>::@class::List
                    element2: dart:core::<fragment>::@class::List#element
                    type: List<String>
                rightBracket: > @235
              leftBracket: [ @236
              rightBracket: ] @237
              staticType: List<List<String>>
        static const vInterfaceWithTypeArguments2 @246
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
          enclosingElement3: <testLibraryFragment>
          type: List<Map<int, List<String>>>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                          element: dart:core::<fragment>::@class::int
                          element2: dart:core::<fragment>::@class::int#element
                          type: int
                        NamedType
                          name: List @293
                          typeArguments: TypeArgumentList
                            leftBracket: < @297
                            arguments
                              NamedType
                                name: String @298
                                element: dart:core::<fragment>::@class::String
                                element2: dart:core::<fragment>::@class::String#element
                                type: String
                            rightBracket: > @304
                          element: dart:core::<fragment>::@class::List
                          element2: dart:core::<fragment>::@class::List#element
                          type: List<String>
                      rightBracket: > @305
                    element: dart:core::<fragment>::@class::Map
                    element2: dart:core::<fragment>::@class::Map#element
                    type: Map<int, List<String>>
                rightBracket: > @306
              leftBracket: [ @307
              rightBracket: ] @308
              staticType: List<Map<int, List<String>>>
      accessors
        synthetic static get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          enclosingElement3: <testLibraryFragment>
          returnType: List<Null>
        synthetic static get vDynamic @-1
          reference: <testLibraryFragment>::@getter::vDynamic
          enclosingElement3: <testLibraryFragment>
          returnType: List<dynamic>
        synthetic static get vInterfaceNoTypeParameters @-1
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
          enclosingElement3: <testLibraryFragment>
          returnType: List<int>
        synthetic static get vInterfaceNoTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
          enclosingElement3: <testLibraryFragment>
          returnType: List<List<dynamic>>
        synthetic static get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          enclosingElement3: <testLibraryFragment>
          returnType: List<List<String>>
        synthetic static get vInterfaceWithTypeArguments2 @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
          enclosingElement3: <testLibraryFragment>
          returnType: List<Map<int, List<String>>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          element: <testLibraryFragment>::@topLevelVariable::vNull#element
          getter2: <testLibraryFragment>::@getter::vNull
        const vDynamic @36
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          element: <testLibraryFragment>::@topLevelVariable::vDynamic#element
          getter2: <testLibraryFragment>::@getter::vDynamic
        const vInterfaceNoTypeParameters @79
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters
          element: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters#element
          getter2: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
        const vInterfaceNoTypeArguments @136
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments
          element: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments#element
          getter2: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
        const vInterfaceWithTypeArguments @186
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments#element
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
        const vInterfaceWithTypeArguments2 @246
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
          element: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2#element
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
      getters
        get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          element: <testLibraryFragment>::@getter::vNull#element
        get vDynamic @-1
          reference: <testLibraryFragment>::@getter::vDynamic
          element: <testLibraryFragment>::@getter::vDynamic#element
        get vInterfaceNoTypeParameters @-1
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
          element: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters#element
        get vInterfaceNoTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments#element
        get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
        get vInterfaceWithTypeArguments2 @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2#element
  topLevelVariables
    const vNull
      firstFragment: <testLibraryFragment>::@topLevelVariable::vNull
      type: List<Null>
      getter: <testLibraryFragment>::@getter::vNull#element
    const vDynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic
      type: List<dynamic>
      getter: <testLibraryFragment>::@getter::vDynamic#element
    const vInterfaceNoTypeParameters
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeParameters
      type: List<int>
      getter: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters#element
    const vInterfaceNoTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceNoTypeArguments
      type: List<List<dynamic>>
      getter: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments#element
    const vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
      type: List<List<String>>
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
    const vInterfaceWithTypeArguments2
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
      type: List<Map<int, List<String>>>
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2#element
  getters
    synthetic static get vNull
      firstFragment: <testLibraryFragment>::@getter::vNull
    synthetic static get vDynamic
      firstFragment: <testLibraryFragment>::@getter::vDynamic
    synthetic static get vInterfaceNoTypeParameters
      firstFragment: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
    synthetic static get vInterfaceNoTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
    synthetic static get vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
    synthetic static get vInterfaceWithTypeArguments2
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: List<C>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @27
              typeArguments: TypeArgumentList
                leftBracket: < @33
                arguments
                  NamedType
                    name: C @34
                    element: package:test/a.dart::<fragment>::@class::C
                    element2: package:test/a.dart::<fragment>::@class::C#element
                    type: C
                rightBracket: > @35
              leftBracket: [ @36
              rightBracket: ] @37
              staticType: List<C>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: List<C>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        const v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<C>
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  libraryImports
    package:test/a.dart as p @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: List<C>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @32
              typeArguments: TypeArgumentList
                leftBracket: < @38
                arguments
                  NamedType
                    importPrefix: ImportPrefixReference
                      name: p @39
                      period: . @40
                      element: <testLibraryFragment>::@prefix::p
                      element2: <testLibraryFragment>::@prefix2::p
                    name: C @41
                    element: package:test/a.dart::<fragment>::@class::C
                    element2: package:test/a.dart::<fragment>::@class::C#element
                    type: C
                rightBracket: > @42
              leftBracket: [ @43
              rightBracket: ] @44
              staticType: List<C>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: List<C>
----------------------------------------
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
        const v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<C>
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @12
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: int Function(String)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional id @21
                type: String
            returnType: int
      topLevelVariables
        static const v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: List<int Function(String)>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ListLiteral
              constKeyword: const @36
              typeArguments: TypeArgumentList
                leftBracket: < @42
                arguments
                  NamedType
                    name: F @43
                    element: <testLibraryFragment>::@typeAlias::F
                    element2: <testLibraryFragment>::@typeAlias::F#element
                    type: int Function(String)
                      alias: <testLibraryFragment>::@typeAlias::F
                rightBracket: > @44
              leftBracket: [ @45
              rightBracket: ] @46
              staticType: List<int Function(String)>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: List<int Function(String)>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @12
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
      topLevelVariables
        const v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: int Function(String)
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<int Function(String)>
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          enclosingElement3: <testLibraryFragment>
          type: Map<dynamic, int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @18
              typeArguments: TypeArgumentList
                leftBracket: < @24
                arguments
                  NamedType
                    name: dynamic @25
                    element: dynamic@-1
                    element2: dynamic@-1
                    type: dynamic
                  NamedType
                    name: int @34
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @37
              leftBracket: { @38
              rightBracket: } @39
              isMap: true
              staticType: Map<dynamic, int>
        static const vDynamic2 @48
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic2
          enclosingElement3: <testLibraryFragment>
          type: Map<int, dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @60
              typeArguments: TypeArgumentList
                leftBracket: < @66
                arguments
                  NamedType
                    name: int @67
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                  NamedType
                    name: dynamic @72
                    element: dynamic@-1
                    element2: dynamic@-1
                    type: dynamic
                rightBracket: > @79
              leftBracket: { @80
              rightBracket: } @81
              isMap: true
              staticType: Map<int, dynamic>
        static const vInterface @90
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          enclosingElement3: <testLibraryFragment>
          type: Map<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @103
              typeArguments: TypeArgumentList
                leftBracket: < @109
                arguments
                  NamedType
                    name: int @110
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                  NamedType
                    name: String @115
                    element: dart:core::<fragment>::@class::String
                    element2: dart:core::<fragment>::@class::String#element
                    type: String
                rightBracket: > @121
              leftBracket: { @122
              rightBracket: } @123
              isMap: true
              staticType: Map<int, String>
        static const vInterfaceWithTypeArguments @132
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          enclosingElement3: <testLibraryFragment>
          type: Map<int, List<String>>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @162
              typeArguments: TypeArgumentList
                leftBracket: < @168
                arguments
                  NamedType
                    name: int @169
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                  NamedType
                    name: List @174
                    typeArguments: TypeArgumentList
                      leftBracket: < @178
                      arguments
                        NamedType
                          name: String @179
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::<fragment>::@class::String#element
                          type: String
                      rightBracket: > @185
                    element: dart:core::<fragment>::@class::List
                    element2: dart:core::<fragment>::@class::List#element
                    type: List<String>
                rightBracket: > @186
              leftBracket: { @187
              rightBracket: } @188
              isMap: true
              staticType: Map<int, List<String>>
      accessors
        synthetic static get vDynamic1 @-1
          reference: <testLibraryFragment>::@getter::vDynamic1
          enclosingElement3: <testLibraryFragment>
          returnType: Map<dynamic, int>
        synthetic static get vDynamic2 @-1
          reference: <testLibraryFragment>::@getter::vDynamic2
          enclosingElement3: <testLibraryFragment>
          returnType: Map<int, dynamic>
        synthetic static get vInterface @-1
          reference: <testLibraryFragment>::@getter::vInterface
          enclosingElement3: <testLibraryFragment>
          returnType: Map<int, String>
        synthetic static get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          enclosingElement3: <testLibraryFragment>
          returnType: Map<int, List<String>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          element: <testLibraryFragment>::@topLevelVariable::vDynamic1#element
          getter2: <testLibraryFragment>::@getter::vDynamic1
        const vDynamic2 @48
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic2
          element: <testLibraryFragment>::@topLevelVariable::vDynamic2#element
          getter2: <testLibraryFragment>::@getter::vDynamic2
        const vInterface @90
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          element: <testLibraryFragment>::@topLevelVariable::vInterface#element
          getter2: <testLibraryFragment>::@getter::vInterface
        const vInterfaceWithTypeArguments @132
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments#element
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      getters
        get vDynamic1 @-1
          reference: <testLibraryFragment>::@getter::vDynamic1
          element: <testLibraryFragment>::@getter::vDynamic1#element
        get vDynamic2 @-1
          reference: <testLibraryFragment>::@getter::vDynamic2
          element: <testLibraryFragment>::@getter::vDynamic2#element
        get vInterface @-1
          reference: <testLibraryFragment>::@getter::vInterface
          element: <testLibraryFragment>::@getter::vInterface#element
        get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  topLevelVariables
    const vDynamic1
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic1
      type: Map<dynamic, int>
      getter: <testLibraryFragment>::@getter::vDynamic1#element
    const vDynamic2
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic2
      type: Map<int, dynamic>
      getter: <testLibraryFragment>::@getter::vDynamic2#element
    const vInterface
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterface
      type: Map<int, String>
      getter: <testLibraryFragment>::@getter::vInterface#element
    const vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
      type: Map<int, List<String>>
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  getters
    synthetic static get vDynamic1
      firstFragment: <testLibraryFragment>::@getter::vDynamic1
    synthetic static get vDynamic2
      firstFragment: <testLibraryFragment>::@getter::vDynamic2
    synthetic static get vInterface
      firstFragment: <testLibraryFragment>::@getter::vInterface
    synthetic static get vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          enclosingElement3: <testLibraryFragment>
          type: Set<dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @18
              typeArguments: TypeArgumentList
                leftBracket: < @24
                arguments
                  NamedType
                    name: dynamic @25
                    element: dynamic@-1
                    element2: dynamic@-1
                    type: dynamic
                rightBracket: > @32
              leftBracket: { @33
              rightBracket: } @34
              isMap: false
              staticType: Set<dynamic>
        static const vInterface @43
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          enclosingElement3: <testLibraryFragment>
          type: Set<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SetOrMapLiteral
              constKeyword: const @56
              typeArguments: TypeArgumentList
                leftBracket: < @62
                arguments
                  NamedType
                    name: int @63
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @66
              leftBracket: { @67
              rightBracket: } @68
              isMap: false
              staticType: Set<int>
        static const vInterfaceWithTypeArguments @77
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          enclosingElement3: <testLibraryFragment>
          type: Set<List<String>>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::<fragment>::@class::String#element
                          type: String
                      rightBracket: > @125
                    element: dart:core::<fragment>::@class::List
                    element2: dart:core::<fragment>::@class::List#element
                    type: List<String>
                rightBracket: > @126
              leftBracket: { @127
              rightBracket: } @128
              isMap: false
              staticType: Set<List<String>>
      accessors
        synthetic static get vDynamic1 @-1
          reference: <testLibraryFragment>::@getter::vDynamic1
          enclosingElement3: <testLibraryFragment>
          returnType: Set<dynamic>
        synthetic static get vInterface @-1
          reference: <testLibraryFragment>::@getter::vInterface
          enclosingElement3: <testLibraryFragment>
          returnType: Set<int>
        synthetic static get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          enclosingElement3: <testLibraryFragment>
          returnType: Set<List<String>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          element: <testLibraryFragment>::@topLevelVariable::vDynamic1#element
          getter2: <testLibraryFragment>::@getter::vDynamic1
        const vInterface @43
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          element: <testLibraryFragment>::@topLevelVariable::vInterface#element
          getter2: <testLibraryFragment>::@getter::vInterface
        const vInterfaceWithTypeArguments @77
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments#element
          getter2: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
      getters
        get vDynamic1 @-1
          reference: <testLibraryFragment>::@getter::vDynamic1
          element: <testLibraryFragment>::@getter::vDynamic1#element
        get vInterface @-1
          reference: <testLibraryFragment>::@getter::vInterface
          element: <testLibraryFragment>::@getter::vInterface#element
        get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          element: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  topLevelVariables
    const vDynamic1
      firstFragment: <testLibraryFragment>::@topLevelVariable::vDynamic1
      type: Set<dynamic>
      getter: <testLibraryFragment>::@getter::vDynamic1#element
    const vInterface
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterface
      type: Set<int>
      getter: <testLibraryFragment>::@getter::vInterface#element
    const vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
      type: Set<List<String>>
      getter: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments#element
  getters
    synthetic static get vDynamic1
      firstFragment: <testLibraryFragment>::@getter::vDynamic1
    synthetic static get vInterface
      firstFragment: <testLibraryFragment>::@getter::vInterface
    synthetic static get vInterfaceWithTypeArguments
      firstFragment: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
''');
  }

  test_const_topLevel_untypedList() async {
    var library = await buildLibrary(r'''
const v = const [1, 2, 3];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: List<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: List<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<int>
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_const_topLevel_untypedMap() async {
    var library = await buildLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: Map<int, String>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Map<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Map<int, String>
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_const_topLevel_untypedSet() async {
    var library = await buildLibrary(r'''
const v = const {0, 1, 2};
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: Set<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Set<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Set<int>
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_const_typeLiteral() async {
    var library = await buildLibrary(r'''
const v = List<int>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            TypeLiteral
              type: NamedType
                name: List @10
                typeArguments: TypeArgumentList
                  leftBracket: < @14
                  arguments
                    NamedType
                      name: int @15
                      element: dart:core::<fragment>::@class::int
                      element2: dart:core::<fragment>::@class::int#element
                      type: int
                  rightBracket: > @18
                element: dart:core::<fragment>::@class::List
                element2: dart:core::<fragment>::@class::List#element
                type: List<int>
              staticType: Type
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Type
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      element: <testLibraryFragment>::@enum::E::@getter::c#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static final vValue @23
          reference: <testLibraryFragment>::@topLevelVariable::vValue
          enclosingElement3: <testLibraryFragment>
          type: E
          shouldUseTypeForInitializerInference: false
        static final vValues @43
          reference: <testLibraryFragment>::@topLevelVariable::vValues
          enclosingElement3: <testLibraryFragment>
          type: List<E>
          shouldUseTypeForInitializerInference: false
        static final vIndex @69
          reference: <testLibraryFragment>::@topLevelVariable::vIndex
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get vValue @-1
          reference: <testLibraryFragment>::@getter::vValue
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static get vValues @-1
          reference: <testLibraryFragment>::@getter::vValues
          enclosingElement3: <testLibraryFragment>
          returnType: List<E>
        synthetic static get vIndex @-1
          reference: <testLibraryFragment>::@getter::vIndex
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibraryFragment>::@enum::E::@field::c#element
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <testLibraryFragment>::@enum::E::@getter::c#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        final vValue @23
          reference: <testLibraryFragment>::@topLevelVariable::vValue
          element: <testLibraryFragment>::@topLevelVariable::vValue#element
          getter2: <testLibraryFragment>::@getter::vValue
        final vValues @43
          reference: <testLibraryFragment>::@topLevelVariable::vValues
          element: <testLibraryFragment>::@topLevelVariable::vValues#element
          getter2: <testLibraryFragment>::@getter::vValues
        final vIndex @69
          reference: <testLibraryFragment>::@topLevelVariable::vIndex
          element: <testLibraryFragment>::@topLevelVariable::vIndex#element
          getter2: <testLibraryFragment>::@getter::vIndex
      getters
        get vValue @-1
          reference: <testLibraryFragment>::@getter::vValue
          element: <testLibraryFragment>::@getter::vValue#element
        get vValues @-1
          reference: <testLibraryFragment>::@getter::vValues
          element: <testLibraryFragment>::@getter::vValues#element
        get vIndex @-1
          reference: <testLibraryFragment>::@getter::vIndex
          element: <testLibraryFragment>::@getter::vIndex#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        static const c
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::c#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    final vValue
      firstFragment: <testLibraryFragment>::@topLevelVariable::vValue
      type: E
      getter: <testLibraryFragment>::@getter::vValue#element
    final vValues
      firstFragment: <testLibraryFragment>::@topLevelVariable::vValues
      type: List<E>
      getter: <testLibraryFragment>::@getter::vValues#element
    final vIndex
      firstFragment: <testLibraryFragment>::@topLevelVariable::vIndex
      type: int
      getter: <testLibraryFragment>::@getter::vIndex#element
  getters
    synthetic static get vValue
      firstFragment: <testLibraryFragment>::@getter::vValue
    synthetic static get vValues
      firstFragment: <testLibraryFragment>::@getter::vValues
    synthetic static get vIndex
      firstFragment: <testLibraryFragment>::@getter::vIndex
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static final vToString @17
          reference: <testLibraryFragment>::@topLevelVariable::vToString
          enclosingElement3: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get vToString @-1
          reference: <testLibraryFragment>::@getter::vToString
          enclosingElement3: <testLibraryFragment>
          returnType: String
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        final vToString @17
          reference: <testLibraryFragment>::@topLevelVariable::vToString
          element: <testLibraryFragment>::@topLevelVariable::vToString#element
          getter2: <testLibraryFragment>::@getter::vToString
      getters
        get vToString @-1
          reference: <testLibraryFragment>::@getter::vToString
          element: <testLibraryFragment>::@getter::vToString#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    final vToString
      firstFragment: <testLibraryFragment>::@topLevelVariable::vToString
      type: String
      getter: <testLibraryFragment>::@getter::vToString#element
  getters
    synthetic static get vToString
      firstFragment: <testLibraryFragment>::@getter::vToString
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            static const a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: b @29
                  staticElement: <testLibraryFragment>::@class::C::@getter::b
                  element: <testLibraryFragment>::@class::C::@getter::b#element
                  staticType: dynamic
            static const b @47
              reference: <testLibraryFragment>::@class::C::@field::b
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
              shouldUseTypeForInitializerInference: false
              constantInitializer
                NullLiteral
                  literal: null @51
                  staticType: Null
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic static get b @-1
              reference: <testLibraryFragment>::@class::C::@getter::b
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              element: <testLibraryFragment>::@class::C::@field::a#element
              getter2: <testLibraryFragment>::@class::C::@getter::a
            b @47
              reference: <testLibraryFragment>::@class::C::@field::b
              element: <testLibraryFragment>::@class::C::@field::b#element
              getter2: <testLibraryFragment>::@class::C::@getter::b
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              element: <testLibraryFragment>::@class::C::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@class::C::@getter::b
              element: <testLibraryFragment>::@class::C::@getter::b#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const a
          firstFragment: <testLibraryFragment>::@class::C::@field::a
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@class::C::@field::b
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::b#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@class::C::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            static const a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic Function()
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: m @29
                  staticElement: <testLibraryFragment>::@class::C::@method::m
                  element: <testLibraryFragment>::@class::C::@method::m#element
                  staticType: dynamic Function()
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic Function()
          methods
            static m @41
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              element: <testLibraryFragment>::@class::C::@field::a#element
              getter2: <testLibraryFragment>::@class::C::@getter::a
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              element: <testLibraryFragment>::@class::C::@getter::a#element
          methods
            m @41
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const a
          firstFragment: <testLibraryFragment>::@class::C::@field::a
          type: dynamic Function()
          getter: <testLibraryFragment>::@class::C::@getter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
      methods
        static m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
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
