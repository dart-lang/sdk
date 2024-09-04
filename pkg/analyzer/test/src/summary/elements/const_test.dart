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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: num
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @14
              staticType: int
        static const b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            AsExpression
              expression: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                staticType: num
              asOperator: as @29
              type: NamedType
                name: int @32
                element: dart:core::<fragment>::@class::int
                type: int
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: num
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ParenthesizedExpression
              leftParenthesis: ( @23
              expression: AssignmentExpression
                leftHandSide: SimpleIdentifier
                  token: a @24
                  staticElement: <null>
                  staticType: null
                operator: += @26
                rightHandSide: IntegerLiteral
                  literal: 1 @29
                  staticType: int
                readElement: <testLibraryFragment>::@getter::a
                readType: int
                writeElement: <testLibraryFragment>::@getter::a
                writeType: InvalidType
                staticElement: dart:core::<fragment>::@class::num::@method::+
                staticType: int
              rightParenthesis: ) @30
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
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
                    staticType: bool
                  staticType: bool
                MethodInvocation
                  operator: .. @19
                  methodName: SimpleIdentifier
                    token: abs @21
                    staticElement: dart:core::<fragment>::@class::int::@method::abs
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
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            static const f1 @29
              reference: <testLibraryFragment>::@class::C::@field::f1
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 1 @34
                  staticType: int
            static const f2 @56
              reference: <testLibraryFragment>::@class::C::@field::f2
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C @61
                    staticElement: <testLibraryFragment>::@class::C
                    staticType: null
                  period: . @62
                  identifier: SimpleIdentifier
                    token: f1 @63
                    staticElement: <testLibraryFragment>::@class::C::@getter::f1
                    staticType: int
                  staticElement: <testLibraryFragment>::@class::C::@getter::f1
                  staticType: int
            static const f3 @67
              reference: <testLibraryFragment>::@class::C::@field::f3
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: C @72
                    staticElement: <testLibraryFragment>::@class::C
                    staticType: null
                  period: . @73
                  identifier: SimpleIdentifier
                    token: f2 @74
                    staticElement: <testLibraryFragment>::@class::C::@getter::f2
                    staticType: int
                  staticElement: <testLibraryFragment>::@class::C::@getter::f2
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get f1 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f1
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
            synthetic static get f2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f2
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
            synthetic static get f3 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f3
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            f1 @29
              reference: <testLibraryFragment>::@class::C::@field::f1
              enclosingFragment: <testLibraryFragment>::@class::C
            f2 @56
              reference: <testLibraryFragment>::@class::C::@field::f2
              enclosingFragment: <testLibraryFragment>::@class::C
            f3 @67
              reference: <testLibraryFragment>::@class::C::@field::f3
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get f1 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f1
              enclosingFragment: <testLibraryFragment>::@class::C
            get f2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f2
              enclosingFragment: <testLibraryFragment>::@class::C
            get f3 @-1
              reference: <testLibraryFragment>::@class::C::@getter::f3
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const f1
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f1
        static const f2
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f2
        static const f3
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f3
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get f1
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::f1
        synthetic static get f2
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::f2
        synthetic static get f3
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final t @23
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingElement: <testLibraryFragment>::@class::C
              type: T
          constructors
            const @34
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional final this.t @41
                  type: T
                  field: <testLibraryFragment>::@class::C::@field::t
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::C
              periodOffset: 54
              nameEnd: 60
              parameters
                requiredPositional final this.t @66
                  type: T
                  field: <testLibraryFragment>::@class::C::@field::t
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: T
      topLevelVariables
        static const x @85
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              keyword: const @89
              constructorName: ConstructorName
                type: NamedType
                  name: C @95
                  element: <testLibraryFragment>::@class::C
                  type: C<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {T: int}
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
          enclosingElement: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              keyword: const @118
              constructorName: ConstructorName
                type: NamedType
                  name: C @124
                  element: <testLibraryFragment>::@class::C
                  type: C<int>
                period: . @125
                name: SimpleIdentifier
                  token: named @126
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::named
                  substitution: {T: int}
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            t @23
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            const new @34
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 54
              nameEnd: 60
          getters
            get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final t
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: T
          firstFragment: <testLibraryFragment>::@class::C::@field::t
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
      getters
        synthetic get t
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 13
              nameEnd: 19
      topLevelVariables
        static const v @31
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: A Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ConstructorReference
              constructorName: ConstructorName
                type: NamedType
                  name: A @35
                  element: <testLibraryFragment>::@class::A
                  type: null
                period: . @36
                name: SimpleIdentifier
                  token: named @37
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
                  staticType: null
                staticElement: <testLibraryFragment>::@class::A::@constructor::named
              staticType: A Function()
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: A Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::A
              periodOffset: 13
              nameEnd: 19
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            final f @22
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 42 @26
                  staticType: int
          constructors
            const @38
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            f @22
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            const new @38
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @44
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: void Function(int)
          shouldUseTypeForInitializerInference: true
          constantInitializer
            FunctionReference
              function: SimpleIdentifier
                token: f @48
                staticElement: <testLibraryFragment>::@function::f
                staticType: void Function<T>(T)
              staticType: void Function(int)
              typeArgumentTypes
                int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: void Function(int)
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @24
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: void Function(int)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            FunctionReference
              function: SimpleIdentifier
                token: f @28
                staticElement: <testLibraryFragment>::@function::f
                staticType: void Function<T>(T)
              typeArguments: TypeArgumentList
                leftBracket: < @29
                arguments
                  NamedType
                    name: int @30
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @33
              staticType: void Function(int)
              typeArgumentTypes
                int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: void Function(int)
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @25
              staticType: int
        static const c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IndexExpression
              target: SimpleIdentifier
                token: a @38
                staticElement: <testLibraryFragment>::@getter::a
                staticType: List<int>
              leftBracket: [ @39
              index: SimpleIdentifier
                token: b @40
                staticElement: <testLibraryFragment>::@getter::b
                staticType: int
              rightBracket: ] @41
              staticElement: MethodMember
                base: dart:core::<fragment>::@class::List::@method::[]
                substitution: {E: int}
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: List<int>
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class P @6
          reference: <testLibraryFragment>::@class::P
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::P::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::P
        class P1 @35
          reference: <testLibraryFragment>::@class::P1
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @38
              defaultType: dynamic
          supertype: P<T>
          constructors
            const @64
              reference: <testLibraryFragment>::@class::P1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::P1
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
        class P2 @79
          reference: <testLibraryFragment>::@class::P2
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @82
              defaultType: dynamic
          supertype: P<T>
          constructors
            const @108
              reference: <testLibraryFragment>::@class::P2::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::P2
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
      topLevelVariables
        static const values @131
          reference: <testLibraryFragment>::@topLevelVariable::values
          enclosingElement: <testLibraryFragment>
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
                      type: P1<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@class::P1::@constructor::new
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
                            element: dart:core::<fragment>::@class::int
                            type: int
                        rightBracket: > @158
                      element: <testLibraryFragment>::@class::P2
                      type: P2<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@class::P2::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @159
                    rightParenthesis: ) @160
                  staticType: P2<int>
              rightBracket: ] @163
              staticType: List<P<dynamic>>
      accessors
        synthetic static get values @-1
          reference: <testLibraryFragment>::@getter::values
          enclosingElement: <testLibraryFragment>
          returnType: List<P<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class P @6
          reference: <testLibraryFragment>::@class::P
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::P::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::P
        class P1 @35
          reference: <testLibraryFragment>::@class::P1
          constructors
            const new @64
              reference: <testLibraryFragment>::@class::P1::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::P1
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
        class P2 @79
          reference: <testLibraryFragment>::@class::P2
          constructors
            const new @108
              reference: <testLibraryFragment>::@class::P2::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::P2
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::P::@constructor::new
                substitution: {T: T}
  classes
    class P
      reference: <testLibraryFragment>::@class::P
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::P
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::P::@constructor::new
    class P1
      reference: <testLibraryFragment>::@class::P1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::P1
      supertype: P<T>
      constructors
        const new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::P1::@constructor::new
    class P2
      reference: <testLibraryFragment>::@class::P2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::P2
      supertype: P<T>
      constructors
        const new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::P2::@constructor::new
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            static const f @25
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticType: int Function()
                    argumentList: ArgumentList
                      leftParenthesis: ( @36
                      rightParenthesis: ) @37
                    staticInvokeType: int Function()
                    staticType: int
                  staticElement: dart:core::<fragment>::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
      functions
        foo @46
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            f @25
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            final f @18
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
      functions
        foo @39
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            f @18
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              staticType: null
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    staticType: null
                  rightParenthesis: ) @46
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            const new @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    staticType: null
                  rightParenthesis: ) @46
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: b @32
                    staticElement: <null>
                    staticType: InvalidType
                  comma: , @33
                  message: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    staticType: null
                  rightParenthesis: ) @42
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            const new @19
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @25
                  leftParenthesis: ( @31
                  condition: SimpleIdentifier
                    token: b @32
                    staticElement: <null>
                    staticType: InvalidType
                  comma: , @33
                  message: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    staticType: null
                  rightParenthesis: ) @42
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            final foo @26
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement: <testLibraryFragment>::@class::A
              type: Object?
          constructors
            const @39
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @45
                    staticElement: <testLibraryFragment>::@class::A::@field::foo
                    staticType: null
                  equals: = @49
                  expression: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    staticType: null
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: Object?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          fields
            foo @26
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@class::A
          constructors
            const new @39
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @45
                    staticElement: <testLibraryFragment>::@class::A::@field::foo
                    staticType: null
                  equals: = @49
                  expression: SimpleIdentifier
                    token: _notSerializableExpression @-1
                    staticElement: <null>
                    staticType: null
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@class::A
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          type: Object?
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get foo
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              staticType: null
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @27
                  type: Object
                requiredPositional b @37
                  type: Object
            const named @51
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
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
                        staticType: null
                    rightParenthesis: ) @76
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              redirectedConstructor: <testLibraryFragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
            const named @51
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::A
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
                        staticType: null
                    rightParenthesis: ) @76
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              redirectedConstructor: <testLibraryFragment>::@class::A::@constructor::new
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
        const named
          reference: <none>
          redirectedConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @27
                  type: Object
                requiredPositional b @37
                  type: Object
        class B @49
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            const @71
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
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
                        staticType: null
                    rightParenthesis: ) @93
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
        class B @49
          reference: <testLibraryFragment>::@class::B
          constructors
            const new @71
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::B
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
                        staticType: null
                    rightParenthesis: ) @93
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        const new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: (int,)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              staticType: null
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: (int,)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
                  staticType: int Function()
                argumentList: ArgumentList
                  leftParenthesis: ( @17
                  rightParenthesis: ) @18
                staticInvokeType: int Function()
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
      functions
        foo @25
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: _notSerializableExpression @-1
              staticElement: <null>
              staticType: null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @10
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @14
              staticType: int
        static const b @28
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: true
          constantInitializer
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: a @32
                staticElement: <testLibraryFragment>::@getter::a
                staticType: int
              operator: + @34
              rightOperand: IntegerLiteral
                literal: 5 @36
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant K @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          constructors
            const named @26
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::C
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
          enclosingElement: <testLibraryFragment>
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
                        type: int
                      NamedType
                        name: String @68
                        element: dart:core::<fragment>::@class::String
                        type: String
                    rightBracket: > @74
                  element: <testLibraryFragment>::@class::C
                  type: C<int, String>
                period: . @75
                name: SimpleIdentifier
                  token: named @76
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::named
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
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            const named @26
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 25
              nameEnd: 31
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                        type: int
                      NamedType
                        name: String @40
                        element: dart:core::<fragment>::@class::String
                        type: String
                    rightBracket: > @46
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C<int, String>
                period: . @47
                name: SimpleIdentifier
                  token: named @48
                  staticElement: ConstructorMember
                    base: package:test/a.dart::<fragment>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  staticType: null
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::named
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
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element: dart:core::<fragment>::@class::int
                        type: int
                      NamedType
                        name: String @47
                        element: dart:core::<fragment>::@class::String
                        type: String
                    rightBracket: > @53
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C<int, String>
                period: . @54
                name: SimpleIdentifier
                  token: named @55
                  staticElement: ConstructorMember
                    base: package:test/a.dart::<fragment>::@class::C::@constructor::named
                    substitution: {K: int, V: String}
                  staticType: null
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::named
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
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant K @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          constructors
            const @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: C<dynamic, dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @41
              constructorName: ConstructorName
                type: NamedType
                  name: C @47
                  element: <testLibraryFragment>::@class::C
                  type: C<dynamic, dynamic>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {K: dynamic, V: dynamic}
              argumentList: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              staticType: C<dynamic, dynamic>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<dynamic, dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            const new @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final t @23
              reference: <testLibraryFragment>::@class::A::@field::t
              enclosingElement: <testLibraryFragment>::@class::A
              type: T
          constructors
            const @34
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.t @41
                  type: T
                  field: <testLibraryFragment>::@class::A::@field::t
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::A::@getter::t
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: T
      topLevelVariables
        static const a @60
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: Object
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              keyword: const @64
              constructorName: ConstructorName
                type: NamedType
                  name: A @70
                  element: <testLibraryFragment>::@class::A
                  type: A<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: int}
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          fields
            t @23
              reference: <testLibraryFragment>::@class::A::@field::t
              enclosingFragment: <testLibraryFragment>::@class::A
          constructors
            const new @34
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          getters
            get t @-1
              reference: <testLibraryFragment>::@class::A::@getter::t
              enclosingFragment: <testLibraryFragment>::@class::A
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final t
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          type: T
          firstFragment: <testLibraryFragment>::@class::A::@field::t
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get t
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          firstFragment: <testLibraryFragment>::@class::A::@getter::t
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant K @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          constructors
            const @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @37
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                        type: int
                      NamedType
                        name: String @54
                        element: dart:core::<fragment>::@class::String
                        type: String
                    rightBracket: > @60
                  element: <testLibraryFragment>::@class::C
                  type: C<int, String>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @61
                rightParenthesis: ) @62
              staticType: C<int, String>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            const new @24
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                        type: int
                      NamedType
                        name: String @40
                        element: dart:core::<fragment>::@class::String
                        type: String
                    rightBracket: > @46
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C<int, String>
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C<int, String>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  typeArguments: TypeArgumentList
                    leftBracket: < @41
                    arguments
                      NamedType
                        name: int @42
                        element: dart:core::<fragment>::@class::int
                        type: int
                      NamedType
                        name: String @47
                        element: dart:core::<fragment>::@class::String
                        type: String
                    rightBracket: > @53
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C<int, String>
                staticElement: ConstructorMember
                  base: package:test/a.dart::<fragment>::@class::C::@constructor::new
                  substitution: {K: int, V: String}
              argumentList: ArgumentList
                leftParenthesis: ( @54
                rightParenthesis: ) @55
              staticType: C<int, String>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::C
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
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @83
              constructorName: ConstructorName
                type: NamedType
                  name: C @89
                  element: <testLibraryFragment>::@class::C
                  type: C
                period: . @90
                name: SimpleIdentifier
                  token: named @91
                  staticElement: <testLibraryFragment>::@class::C::@constructor::named
                  staticType: null
                staticElement: <testLibraryFragment>::@class::C::@constructor::named
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
                        staticType: null
                      colon: : @110
                    expression: SimpleStringLiteral
                      literal: 'ccc' @112
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: e @119
                        staticElement: <testLibraryFragment>::@class::C::@constructor::named::@parameter::e
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
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 19
              nameEnd: 25
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C
                period: . @34
                name: SimpleIdentifier
                  token: named @35
                  staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @40
                rightParenthesis: ) @41
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @21
              constructorName: ConstructorName
                type: NamedType
                  name: C @27
                  element: <testLibraryFragment>::@class::C
                  type: C
                period: . @28
                name: SimpleIdentifier
                  token: named @29
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: named @18
                  element: <null>
                  type: InvalidType
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @23
                rightParenthesis: ) @24
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  element: <null>
                  type: InvalidType
                period: . @41
                name: SimpleIdentifier
                  token: named @42
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @18
                  element: <null>
                  type: InvalidType
                period: . @19
                name: SimpleIdentifier
                  token: named @20
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @25
                rightParenthesis: ) @26
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @20
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: C<dynamic>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @24
              constructorName: ConstructorName
                type: NamedType
                  name: C @30
                  element: <testLibraryFragment>::@class::C
                  type: C<dynamic>
                period: . @31
                name: SimpleIdentifier
                  token: named @32
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              staticType: C<dynamic>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C<dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            const @18
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @31
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @35
              constructorName: ConstructorName
                type: NamedType
                  name: C @41
                  element: <testLibraryFragment>::@class::C
                  type: C
                staticElement: <testLibraryFragment>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @42
                rightParenthesis: ) @43
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @27
              constructorName: ConstructorName
                type: NamedType
                  name: C @33
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  element: package:test/a.dart::<fragment>::@class::C
                  type: C
                staticElement: package:test/a.dart::<fragment>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: C
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @10
              constructorName: ConstructorName
                type: NamedType
                  name: C @16
                  element: <null>
                  type: InvalidType
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @17
                rightParenthesis: ) @18
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @40
                  element: <null>
                  type: InvalidType
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
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
                  name: C @18
                  element: <null>
                  type: InvalidType
                staticElement: <null>
              argumentList: ArgumentList
                leftParenthesis: ( @19
                rightParenthesis: ) @20
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IsExpression
              expression: SimpleIdentifier
                token: a @23
                staticElement: <testLibraryFragment>::@getter::a
                staticType: int
              isOperator: is @25
              type: NamedType
                name: int @28
                element: dart:core::<fragment>::@class::int
                type: int
              staticType: bool
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            static const F @32
              reference: <testLibraryFragment>::@class::C::@field::F
              enclosingElement: <testLibraryFragment>::@class::C
              type: String
              shouldUseTypeForInitializerInference: true
              constantInitializer
                SimpleStringLiteral
                  literal: '' @36
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: String
      topLevelVariables
        static const v @52
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @56
                  staticElement: <testLibraryFragment>::@class::C
                  staticType: null
                period: . @57
                identifier: SimpleIdentifier
                  token: F @58
                  staticElement: <testLibraryFragment>::@class::C::@getter::F
                  staticType: String
                staticElement: <testLibraryFragment>::@class::C::@getter::F
                staticType: String
              operator: . @59
              propertyName: SimpleIdentifier
                token: length @60
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            F @32
              reference: <testLibraryFragment>::@class::C::@field::F
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const F
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: String
          firstFragment: <testLibraryFragment>::@class::C::@field::F
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get F
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::F
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @27
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @31
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: F @33
                  staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                  staticType: String
                staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                staticType: String
              operator: . @34
              propertyName: SimpleIdentifier
                token: length @35
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @32
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            PropertyAccess
              target: PropertyAccess
                target: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: p @36
                    staticElement: <testLibraryFragment>::@prefix::p
                    staticType: null
                  period: . @37
                  identifier: SimpleIdentifier
                    token: C @38
                    staticElement: package:test/a.dart::<fragment>::@class::C
                    staticType: null
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  staticType: null
                operator: . @39
                propertyName: SimpleIdentifier
                  token: F @40
                  staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                  staticType: String
                staticType: String
              operator: . @41
              propertyName: SimpleIdentifier
                token: length @42
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const S @13
          reference: <testLibraryFragment>::@topLevelVariable::S
          enclosingElement: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SimpleStringLiteral
              literal: 'abc' @17
        static const v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @34
                staticElement: <testLibraryFragment>::@getter::S
                staticType: String
              period: . @35
              identifier: SimpleIdentifier
                token: length @36
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticElement: dart:core::<fragment>::@class::String::@getter::length
              staticType: int
      accessors
        synthetic static get S @-1
          reference: <testLibraryFragment>::@getter::S
          enclosingElement: <testLibraryFragment>
          returnType: String
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: S @27
                staticElement: package:test/a.dart::<fragment>::@getter::S
                staticType: String
              period: . @28
              identifier: SimpleIdentifier
                token: length @29
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticElement: dart:core::<fragment>::@class::String::@getter::length
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: S @34
                  staticElement: package:test/a.dart::<fragment>::@getter::S
                  staticType: String
                staticElement: package:test/a.dart::<fragment>::@getter::S
                staticType: String
              operator: . @35
              propertyName: SimpleIdentifier
                token: length @36
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticType: int
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            static length @23
              reference: <testLibraryFragment>::@class::C::@method::length
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
      topLevelVariables
        static const v @47
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @51
                staticElement: <testLibraryFragment>::@class::C
                staticType: null
              period: . @52
              identifier: SimpleIdentifier
                token: length @53
                staticElement: <testLibraryFragment>::@class::C::@method::length
                staticType: int Function()
              staticElement: <testLibraryFragment>::@class::C::@method::length
              staticType: int Function()
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            length @23
              reference: <testLibraryFragment>::@class::C::@method::length
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static length
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::length
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::<fragment>::@class::int
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::<fragment>::@class::int
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
                          type: int
                        NamedType
                          name: int @43
                          element: dart:core::<fragment>::@class::int
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
                    type: int
                  NamedType
                    name: int @29
                    element: dart:core::<fragment>::@class::int
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
                          type: int
                        NamedType
                          name: int @44
                          element: dart:core::<fragment>::@class::int
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            MethodInvocation
              methodName: SimpleIdentifier
                token: f @28
                staticElement: <testLibraryFragment>::@function::f
                staticType: T Function<T>(T)
              typeArguments: TypeArgumentList
                leftBracket: < @29
                arguments
                  NamedType
                    name: int @30
                    element: dart:core::<fragment>::@class::int
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
          enclosingElement: <testLibraryFragment>
          returnType: int
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            const @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                optionalNamed default final this.x @37
                  reference: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x
                  type: dynamic
                  constantInitializer
                    SimpleIdentifier
                      token: foo @40
                      staticElement: <testLibraryFragment>::@function::foo
                      staticType: int Function()
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
      functions
        foo @53
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            const new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            const @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticInvokeType: num Function(num)
                      staticType: int
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            const new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            const @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticInvokeType: num Function(num)
                      staticType: int
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            x @18
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            const new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            const positional @20
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticInvokeType: num Function(num)
                      staticType: int
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticInvokeType: num Function(num)
                      staticType: int
          methods
            methodPositional @81
              reference: <testLibraryFragment>::@class::C::@method::methodPositional
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticInvokeType: num Function(num)
                      staticType: int
              returnType: void
            methodPositionalWithoutDefault @121
              reference: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default p @153
                  type: dynamic
              returnType: void
            methodNamed @167
              reference: <testLibraryFragment>::@class::C::@method::methodNamed
              enclosingElement: <testLibraryFragment>::@class::C
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
                      staticInvokeType: num Function(num)
                      staticType: int
              returnType: void
            methodNamedWithoutDefault @201
              reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
              enclosingElement: <testLibraryFragment>::@class::C
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
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            const positional @20
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 19
              nameEnd: 30
            const named @55
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 54
              nameEnd: 60
          methods
            methodPositional @81
              reference: <testLibraryFragment>::@class::C::@method::methodPositional
              enclosingFragment: <testLibraryFragment>::@class::C
            methodPositionalWithoutDefault @121
              reference: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
              enclosingFragment: <testLibraryFragment>::@class::C
            methodNamed @167
              reference: <testLibraryFragment>::@class::C::@method::methodNamed
              enclosingFragment: <testLibraryFragment>::@class::C
            methodNamedWithoutDefault @201
              reference: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const positional
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
      methods
        methodPositional
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::methodPositional
        methodPositionalWithoutDefault
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::methodPositionalWithoutDefault
        methodNamed
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::methodNamed
        methodNamedWithoutDefault
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::methodNamedWithoutDefault
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PostfixExpression
              operand: SimpleIdentifier
                token: a @23
                staticElement: <null>
                staticType: null
              operator: ++ @24
              readElement: <testLibraryFragment>::@getter::a
              readType: int
              writeElement: <testLibraryFragment>::@getter::a
              writeType: InvalidType
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @15
              staticType: int
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PostfixExpression
              operand: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                staticType: int?
              operator: ! @29
              staticElement: <null>
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @23
              operand: SimpleIdentifier
                token: a @24
                staticElement: <testLibraryFragment>::@getter::a
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @27
              operand: SimpleIdentifier
                token: a @28
                staticElement: package:test/a.dart::<fragment>::@getter::a
                staticType: Object
              staticElement: package:test/a.dart::<fragment>::@extension::E::@method::unary-
              staticType: int
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: ++ @23
              operand: SimpleIdentifier
                token: a @25
                staticElement: <null>
                staticType: null
              readElement: <testLibraryFragment>::@getter::a
              readType: int
              writeElement: <testLibraryFragment>::@getter::a
              writeType: InvalidType
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: (int, {int a})
          shouldUseTypeForInitializerInference: false
          constantInitializer
            RecordLiteral
              leftParenthesis: ( @23
              fields
                SimpleIdentifier
                  token: a @24
                  staticElement: <testLibraryFragment>::@getter::a
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      token: a @27
                      staticElement: <null>
                      staticType: null
                    colon: : @28
                  expression: SimpleIdentifier
                    token: a @30
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: int
              rightParenthesis: ) @31
              staticType: (int, {int a})
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: (int, {int a})
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
        static const b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
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
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      token: a @33
                      staticElement: <null>
                      staticType: null
                    colon: : @34
                  expression: SimpleIdentifier
                    token: a @36
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: int
              rightParenthesis: ) @37
              staticType: (int, {int a})
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: (int, {int a})
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            static const F @29
              reference: <testLibraryFragment>::@class::C::@field::F
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 42 @33
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
      topLevelVariables
        static const V @45
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @49
                staticElement: <testLibraryFragment>::@class::C
                staticType: null
              period: . @50
              identifier: SimpleIdentifier
                token: F @51
                staticElement: <testLibraryFragment>::@class::C::@getter::F
                staticType: int
              staticElement: <testLibraryFragment>::@class::C::@getter::F
              staticType: int
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            F @29
              reference: <testLibraryFragment>::@class::C::@field::F
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get F @-1
              reference: <testLibraryFragment>::@class::C::@getter::F
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const F
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::F
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get F
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::F
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @27
                staticElement: package:test/a.dart::<fragment>::@class::C
                staticType: null
              period: . @28
              identifier: SimpleIdentifier
                token: F @29
                staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                staticType: int
              staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
              staticType: int
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: C @34
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C
                staticType: null
              operator: . @35
              propertyName: SimpleIdentifier
                token: F @36
                staticElement: package:test/a.dart::<fragment>::@class::C::@getter::F
                staticType: int
              staticType: int
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            static m @23
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional a @29
                  type: int
                requiredPositional b @39
                  type: String
              returnType: int
      topLevelVariables
        static const V @57
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @61
                staticElement: <testLibraryFragment>::@class::C
                staticType: null
              period: . @62
              identifier: SimpleIdentifier
                token: m @63
                staticElement: <testLibraryFragment>::@class::C::@method::m
                staticType: int Function(int, String)
              staticElement: <testLibraryFragment>::@class::C::@method::m
              staticType: int Function(int, String)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            m @23
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::m
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @27
                staticElement: package:test/a.dart::<fragment>::@class::C
                staticType: null
              period: . @28
              identifier: SimpleIdentifier
                token: m @29
                staticElement: package:test/a.dart::<fragment>::@class::C::@method::m
                staticType: int Function(int, String)
              staticElement: package:test/a.dart::<fragment>::@class::C::@method::m
              staticType: int Function(int, String)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: C @34
                  staticElement: package:test/a.dart::<fragment>::@class::C
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::C
                staticType: null
              operator: . @35
              propertyName: SimpleIdentifier
                token: m @36
                staticElement: package:test/a.dart::<fragment>::@class::C::@method::m
                staticType: int Function(int, String)
              staticType: int Function(int, String)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      extensions
        E @21
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          extendedType: A
          methods
            static f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              enclosingElement: <testLibraryFragment>::@extension::E
              returnType: void
      topLevelVariables
        static const x @59
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: void Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: E @63
                staticElement: <testLibraryFragment>::@extension::E
                staticType: null
              period: . @64
              identifier: SimpleIdentifier
                token: f @65
                staticElement: <testLibraryFragment>::@extension::E::@method::f
                staticType: void Function()
              staticElement: <testLibraryFragment>::@extension::E::@method::f
              staticType: void Function()
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: void Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          methods
            f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              enclosingFragment: <testLibraryFragment>::@extension::E
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @15
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @19
              staticElement: <testLibraryFragment>::@function::foo
              staticType: dynamic Function()
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @26
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: R Function<P, R>(P)
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @30
              staticElement: <testLibraryFragment>::@function::foo
              staticType: R Function<P, R>(P)
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: R Function<P, R>(P)
      functions
        foo @2
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @23
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @27
              staticElement: package:test/a.dart::<fragment>::@function::foo
              staticType: dynamic Function()
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @28
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @32
                staticElement: <testLibraryFragment>::@prefix::p
                staticType: null
              period: . @33
              identifier: SimpleIdentifier
                token: foo @34
                staticElement: package:test/a.dart::<fragment>::@function::foo
                staticType: dynamic Function()
              staticElement: package:test/a.dart::<fragment>::@function::foo
              staticType: dynamic Function()
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const A @6
          reference: <testLibraryFragment>::@topLevelVariable::A
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 1 @10
              staticType: int
        static const B @19
          reference: <testLibraryFragment>::@topLevelVariable::B
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @23
                staticElement: <testLibraryFragment>::@getter::A
                staticType: int
              operator: + @25
              rightOperand: IntegerLiteral
                literal: 2 @27
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get A @-1
          reference: <testLibraryFragment>::@getter::A
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get B @-1
          reference: <testLibraryFragment>::@getter::B
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const B @23
          reference: <testLibraryFragment>::@topLevelVariable::B
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: SimpleIdentifier
                token: A @27
                staticElement: package:test/a.dart::<fragment>::@getter::A
                staticType: int
              operator: + @29
              rightOperand: IntegerLiteral
                literal: 2 @31
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get B @-1
          reference: <testLibraryFragment>::@getter::B
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const B @28
          reference: <testLibraryFragment>::@topLevelVariable::B
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BinaryExpression
              leftOperand: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @32
                  staticElement: <testLibraryFragment>::@prefix::p
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: A @34
                  staticElement: package:test/a.dart::<fragment>::@getter::A
                  staticType: int
                staticElement: package:test/a.dart::<fragment>::@getter::A
                staticType: int
              operator: + @36
              rightOperand: IntegerLiteral
                literal: 2 @38
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
      accessors
        synthetic static get B @-1
          reference: <testLibraryFragment>::@getter::B
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @17
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @19
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      enums
        enum E @30
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @33
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @36
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @39
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
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
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: dynamic @87
              staticElement: dynamic@-1
              staticType: Type
        static const vNull @102
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: Null @110
              staticElement: dart:core::<fragment>::@class::Null
              staticType: Type
        static const vObject @122
          reference: <testLibraryFragment>::@topLevelVariable::vObject
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: Object @132
              staticElement: dart:core::<fragment>::@class::Object
              staticType: Type
        static const vClass @146
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: C @155
              staticElement: <testLibraryFragment>::@class::C
              staticType: Type
        static const vGenericClass @164
          reference: <testLibraryFragment>::@topLevelVariable::vGenericClass
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: D @180
              staticElement: <testLibraryFragment>::@class::D
              staticType: Type
        static const vEnum @189
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: E @197
              staticElement: <testLibraryFragment>::@enum::E
              staticType: Type
        static const vFunctionTypeAlias @206
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: F @227
              staticElement: <testLibraryFragment>::@typeAlias::F
              staticType: Type
      accessors
        synthetic static get vDynamic @-1
          reference: <testLibraryFragment>::@getter::vDynamic
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vObject @-1
          reference: <testLibraryFragment>::@getter::vObject
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vGenericClass @-1
          reference: <testLibraryFragment>::@getter::vGenericClass
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          enclosingElement: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
        class D @17
          reference: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::D
      enums
        enum E @30
          reference: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @33
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingFragment: <testLibraryFragment>::@enum::E
            enumConstant b @36
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingFragment: <testLibraryFragment>::@enum::E
            enumConstant c @39
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingFragment: <testLibraryFragment>::@enum::E
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingFragment: <testLibraryFragment>::@enum::E
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingFragment: <testLibraryFragment>::@enum::E
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingFragment: <testLibraryFragment>::@enum::E
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingFragment: <testLibraryFragment>::@enum::E
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingFragment: <testLibraryFragment>::@enum::E
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingFragment: <testLibraryFragment>::@enum::E
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
        static const b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
        static const c
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
        synthetic static const values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement: <testLibrary>
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            final f @31
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: List<dynamic Function()>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
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
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          fields
            f @31
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: List<dynamic Function()>
          firstFragment: <testLibraryFragment>::@class::C::@field::f
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const vClass @23
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: C @32
              staticElement: package:test/a.dart::<fragment>::@class::C
              staticType: Type
        static const vEnum @41
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: E @49
              staticElement: package:test/a.dart::<fragment>::@enum::E
              staticType: Type
        static const vFunctionTypeAlias @58
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: F @79
              staticElement: package:test/a.dart::<fragment>::@typeAlias::F
              staticType: Type
      accessors
        synthetic static get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          enclosingElement: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const vClass @28
          reference: <testLibraryFragment>::@topLevelVariable::vClass
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @37
                staticElement: <testLibraryFragment>::@prefix::p
                staticType: null
              period: . @38
              identifier: SimpleIdentifier
                token: C @39
                staticElement: package:test/a.dart::<fragment>::@class::C
                staticType: Type
              staticElement: package:test/a.dart::<fragment>::@class::C
              staticType: Type
        static const vEnum @48
          reference: <testLibraryFragment>::@topLevelVariable::vEnum
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @56
                staticElement: <testLibraryFragment>::@prefix::p
                staticType: null
              period: . @57
              identifier: SimpleIdentifier
                token: E @58
                staticElement: package:test/a.dart::<fragment>::@enum::E
                staticType: Type
              staticElement: package:test/a.dart::<fragment>::@enum::E
              staticType: Type
        static const vFunctionTypeAlias @67
          reference: <testLibraryFragment>::@topLevelVariable::vFunctionTypeAlias
          enclosingElement: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: p @88
                staticElement: <testLibraryFragment>::@prefix::p
                staticType: null
              period: . @89
              identifier: SimpleIdentifier
                token: F @90
                staticElement: package:test/a.dart::<fragment>::@typeAlias::F
                staticType: Type
              staticElement: package:test/a.dart::<fragment>::@typeAlias::F
              staticType: Type
      accessors
        synthetic static get vClass @-1
          reference: <testLibraryFragment>::@getter::vClass
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vEnum @-1
          reference: <testLibraryFragment>::@getter::vEnum
          enclosingElement: <testLibraryFragment>
          returnType: Type
        synthetic static get vFunctionTypeAlias @-1
          reference: <testLibraryFragment>::@getter::vFunctionTypeAlias
          enclosingElement: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: List<T>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: List<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: List<T>
          firstFragment: <testLibraryFragment>::@class::C::@field::f
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const V @6
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: foo @10
              staticElement: <null>
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const V @17
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: C @21
                staticElement: <testLibraryFragment>::@class::C
                staticType: null
              period: . @22
              identifier: SimpleIdentifier
                token: foo @23
                staticElement: <null>
                staticType: InvalidType
              staticElement: <null>
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @21
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as p @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @21
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const V @30
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: p @34
                  staticElement: <testLibraryFragment>::@prefix::p
                  staticType: null
                period: . @35
                identifier: SimpleIdentifier
                  token: C @36
                  staticElement: package:test/foo.dart::<fragment>::@class::C
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::C
                staticType: null
              operator: . @37
              propertyName: SimpleIdentifier
                token: foo @38
                staticElement: <null>
                staticType: InvalidType
              staticType: InvalidType
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/foo.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @13
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vEqual
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: bool Function(Object)
              staticType: bool
        static const vAnd @29
          reference: <testLibraryFragment>::@topLevelVariable::vAnd
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: null
              staticType: bool
        static const vOr @57
          reference: <testLibraryFragment>::@topLevelVariable::vOr
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: null
              staticType: bool
        static const vBitXor @84
          reference: <testLibraryFragment>::@topLevelVariable::vBitXor
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitAnd @107
          reference: <testLibraryFragment>::@topLevelVariable::vBitAnd
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitOr @130
          reference: <testLibraryFragment>::@topLevelVariable::vBitOr
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitShiftLeft @152
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftLeft
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: int Function(int)
              staticType: int
        static const vBitShiftRight @182
          reference: <testLibraryFragment>::@topLevelVariable::vBitShiftRight
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: int Function(int)
              staticType: int
        static const vAdd @213
          reference: <testLibraryFragment>::@topLevelVariable::vAdd
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: num Function(num)
              staticType: int
        static const vSubtract @233
          reference: <testLibraryFragment>::@topLevelVariable::vSubtract
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: num Function(num)
              staticType: int
        static const vMiltiply @258
          reference: <testLibraryFragment>::@topLevelVariable::vMiltiply
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: num Function(num)
              staticType: int
        static const vDivide @283
          reference: <testLibraryFragment>::@topLevelVariable::vDivide
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: double Function(num)
              staticType: double
        static const vFloorDivide @306
          reference: <testLibraryFragment>::@topLevelVariable::vFloorDivide
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: int Function(num)
              staticType: int
        static const vModulo @335
          reference: <testLibraryFragment>::@topLevelVariable::vModulo
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: num Function(num)
              staticType: int
        static const vGreater @358
          reference: <testLibraryFragment>::@topLevelVariable::vGreater
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: bool Function(num)
              staticType: bool
        static const vGreaterEqual @382
          reference: <testLibraryFragment>::@topLevelVariable::vGreaterEqual
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: bool Function(num)
              staticType: bool
        static const vLess @412
          reference: <testLibraryFragment>::@topLevelVariable::vLess
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: bool Function(num)
              staticType: bool
        static const vLessEqual @433
          reference: <testLibraryFragment>::@topLevelVariable::vLessEqual
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: bool Function(num)
              staticType: bool
      accessors
        synthetic static get vEqual @-1
          reference: <testLibraryFragment>::@getter::vEqual
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vAnd @-1
          reference: <testLibraryFragment>::@getter::vAnd
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vOr @-1
          reference: <testLibraryFragment>::@getter::vOr
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vBitXor @-1
          reference: <testLibraryFragment>::@getter::vBitXor
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vBitAnd @-1
          reference: <testLibraryFragment>::@getter::vBitAnd
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vBitOr @-1
          reference: <testLibraryFragment>::@getter::vBitOr
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vBitShiftLeft @-1
          reference: <testLibraryFragment>::@getter::vBitShiftLeft
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vBitShiftRight @-1
          reference: <testLibraryFragment>::@getter::vBitShiftRight
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vAdd @-1
          reference: <testLibraryFragment>::@getter::vAdd
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vSubtract @-1
          reference: <testLibraryFragment>::@getter::vSubtract
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vMiltiply @-1
          reference: <testLibraryFragment>::@getter::vMiltiply
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vDivide @-1
          reference: <testLibraryFragment>::@getter::vDivide
          enclosingElement: <testLibraryFragment>
          returnType: double
        synthetic static get vFloorDivide @-1
          reference: <testLibraryFragment>::@getter::vFloorDivide
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vModulo @-1
          reference: <testLibraryFragment>::@getter::vModulo
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vGreater @-1
          reference: <testLibraryFragment>::@getter::vGreater
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vGreaterEqual @-1
          reference: <testLibraryFragment>::@getter::vGreaterEqual
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vLess @-1
          reference: <testLibraryFragment>::@getter::vLess
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vLessEqual @-1
          reference: <testLibraryFragment>::@getter::vLessEqual
          enclosingElement: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vConditional @6
          reference: <testLibraryFragment>::@topLevelVariable::vConditional
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vIdentical @6
          reference: <testLibraryFragment>::@topLevelVariable::vIdentical
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vIfNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vIfNull
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: null
              staticType: num
      accessors
        synthetic static get vIfNull @-1
          reference: <testLibraryFragment>::@getter::vIfNull
          enclosingElement: <testLibraryFragment>
          returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @14
              staticType: Null
        static const vBoolFalse @26
          reference: <testLibraryFragment>::@topLevelVariable::vBoolFalse
          enclosingElement: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BooleanLiteral
              literal: false @39
              staticType: bool
        static const vBoolTrue @52
          reference: <testLibraryFragment>::@topLevelVariable::vBoolTrue
          enclosingElement: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            BooleanLiteral
              literal: true @64
              staticType: bool
        static const vIntPositive @76
          reference: <testLibraryFragment>::@topLevelVariable::vIntPositive
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 1 @91
              staticType: int
        static const vIntNegative @100
          reference: <testLibraryFragment>::@topLevelVariable::vIntNegative
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @115
              operand: IntegerLiteral
                literal: 2 @116
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              staticType: int
        static const vIntLong1 @125
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong1
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0x7FFFFFFFFFFFFFFF @137
              staticType: int
        static const vIntLong2 @163
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong2
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0xFFFFFFFFFFFFFFFF @175
              staticType: int
        static const vIntLong3 @201
          reference: <testLibraryFragment>::@topLevelVariable::vIntLong3
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0x8000000000000000 @213
              staticType: int
        static const vDouble @239
          reference: <testLibraryFragment>::@topLevelVariable::vDouble
          enclosingElement: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
          constantInitializer
            DoubleLiteral
              literal: 2.3 @249
              staticType: double
        static const vString @260
          reference: <testLibraryFragment>::@topLevelVariable::vString
          enclosingElement: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleStringLiteral
              literal: 'abc' @270
        static const vStringConcat @283
          reference: <testLibraryFragment>::@topLevelVariable::vStringConcat
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get vBoolFalse @-1
          reference: <testLibraryFragment>::@getter::vBoolFalse
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vBoolTrue @-1
          reference: <testLibraryFragment>::@getter::vBoolTrue
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vIntPositive @-1
          reference: <testLibraryFragment>::@getter::vIntPositive
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vIntNegative @-1
          reference: <testLibraryFragment>::@getter::vIntNegative
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vIntLong1 @-1
          reference: <testLibraryFragment>::@getter::vIntLong1
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vIntLong2 @-1
          reference: <testLibraryFragment>::@getter::vIntLong2
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vIntLong3 @-1
          reference: <testLibraryFragment>::@getter::vIntLong3
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vDouble @-1
          reference: <testLibraryFragment>::@getter::vDouble
          enclosingElement: <testLibraryFragment>
          returnType: double
        synthetic static get vString @-1
          reference: <testLibraryFragment>::@getter::vString
          enclosingElement: <testLibraryFragment>
          returnType: String
        synthetic static get vStringConcat @-1
          reference: <testLibraryFragment>::@getter::vStringConcat
          enclosingElement: <testLibraryFragment>
          returnType: String
        synthetic static get vStringInterpolation @-1
          reference: <testLibraryFragment>::@getter::vStringInterpolation
          enclosingElement: <testLibraryFragment>
          returnType: String
        synthetic static get vSymbol @-1
          reference: <testLibraryFragment>::@getter::vSymbol
          enclosingElement: <testLibraryFragment>
          returnType: Symbol
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @15
              staticType: int
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: String?
          shouldUseTypeForInitializerInference: false
          constantInitializer
            MethodInvocation
              target: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                staticType: int?
              operator: ?. @29
              methodName: SimpleIdentifier
                token: toString @31
                staticElement: dart:core::<fragment>::@class::int::@method::toString
                staticType: String Function()
              argumentList: ArgumentList
                leftParenthesis: ( @39
                rightParenthesis: ) @40
              staticInvokeType: String Function()
              staticType: String?
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: String?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @11
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @15
              staticType: int
        static const b @24
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: false
          constantInitializer
            CascadeExpression
              target: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                staticType: int?
              cascadeSections
                MethodInvocation
                  operator: ?.. @29
                  methodName: SimpleIdentifier
                    token: toString @32
                    staticElement: dart:core::<fragment>::@class::int::@method::toString
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
          enclosingElement: <testLibraryFragment>
          returnType: int?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @14
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: String?
          shouldUseTypeForInitializerInference: true
          constantInitializer
            SimpleStringLiteral
              literal: '' @18
        static const b @40
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
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
                    staticType: String?
                  operator: ?. @49
                  propertyName: SimpleIdentifier
                    token: length @51
                    staticElement: dart:core::<fragment>::@class::String::@getter::length
                    staticType: int
                  staticType: int?
              rightBracket: ] @59
              staticType: List<int?>
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: String?
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: List<int?>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v1 @10
          reference: <testLibraryFragment>::@topLevelVariable::v1
          enclosingElement: <testLibraryFragment>
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
                  staticInvokeType: num Function(num)
                  staticType: int
                rightParenthesis: ) @21
                staticType: int
              operator: * @23
              rightOperand: IntegerLiteral
                literal: 3 @25
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::*
              staticInvokeType: num Function(num)
              staticType: int
        static const v2 @38
          reference: <testLibraryFragment>::@topLevelVariable::v2
          enclosingElement: <testLibraryFragment>
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
                  staticInvokeType: num Function(num)
                  staticType: int
                rightParenthesis: ) @50
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              staticType: int
        static const v3 @63
          reference: <testLibraryFragment>::@topLevelVariable::v3
          enclosingElement: <testLibraryFragment>
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
                  staticInvokeType: String Function(String)
                  staticType: String
                rightParenthesis: ) @82
                staticType: String
              operator: . @83
              propertyName: SimpleIdentifier
                token: length @84
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                staticType: int
              staticType: int
      accessors
        synthetic static get v1 @-1
          reference: <testLibraryFragment>::@getter::v1
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get v2 @-1
          reference: <testLibraryFragment>::@getter::v2
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get v3 @-1
          reference: <testLibraryFragment>::@getter::v3
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vNotEqual @6
          reference: <testLibraryFragment>::@topLevelVariable::vNotEqual
          enclosingElement: <testLibraryFragment>
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
              staticInvokeType: bool Function(Object)
              staticType: bool
        static const vNot @32
          reference: <testLibraryFragment>::@topLevelVariable::vNot
          enclosingElement: <testLibraryFragment>
          type: bool
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: ! @39
              operand: BooleanLiteral
                literal: true @40
                staticType: bool
              staticElement: <null>
              staticType: bool
        static const vNegate @52
          reference: <testLibraryFragment>::@topLevelVariable::vNegate
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: - @62
              operand: IntegerLiteral
                literal: 1 @63
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::unary-
              staticType: int
        static const vComplement @72
          reference: <testLibraryFragment>::@topLevelVariable::vComplement
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixExpression
              operator: ~ @86
              operand: IntegerLiteral
                literal: 1 @87
                staticType: int
              staticElement: dart:core::<fragment>::@class::int::@method::~
              staticType: int
      accessors
        synthetic static get vNotEqual @-1
          reference: <testLibraryFragment>::@getter::vNotEqual
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vNot @-1
          reference: <testLibraryFragment>::@getter::vNot
          enclosingElement: <testLibraryFragment>
          returnType: bool
        synthetic static get vNegate @-1
          reference: <testLibraryFragment>::@getter::vNegate
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get vComplement @-1
          reference: <testLibraryFragment>::@getter::vComplement
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vSuper @6
          reference: <testLibraryFragment>::@topLevelVariable::vSuper
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SuperExpression
              superKeyword: super @15
              staticType: InvalidType
      accessors
        synthetic static get vSuper @-1
          reference: <testLibraryFragment>::@getter::vSuper
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vThis @6
          reference: <testLibraryFragment>::@topLevelVariable::vThis
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            ThisExpression
              thisKeyword: this @14
              staticType: dynamic
      accessors
        synthetic static get vThis @-1
          reference: <testLibraryFragment>::@getter::vThis
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const c @6
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Never
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vNull @6
          reference: <testLibraryFragment>::@topLevelVariable::vNull
          enclosingElement: <testLibraryFragment>
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
                    type: Null
                rightBracket: > @25
              leftBracket: [ @26
              rightBracket: ] @27
              staticType: List<Null>
        static const vDynamic @36
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
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
                    type: List<dynamic>
                rightBracket: > @175
              leftBracket: [ @176
              rightBracket: ] @177
              staticType: List<List<dynamic>>
        static const vInterfaceWithTypeArguments @186
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          enclosingElement: <testLibraryFragment>
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
                          type: String
                      rightBracket: > @234
                    element: dart:core::<fragment>::@class::List
                    type: List<String>
                rightBracket: > @235
              leftBracket: [ @236
              rightBracket: ] @237
              staticType: List<List<String>>
        static const vInterfaceWithTypeArguments2 @246
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments2
          enclosingElement: <testLibraryFragment>
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
                          type: int
                        NamedType
                          name: List @293
                          typeArguments: TypeArgumentList
                            leftBracket: < @297
                            arguments
                              NamedType
                                name: String @298
                                element: dart:core::<fragment>::@class::String
                                type: String
                            rightBracket: > @304
                          element: dart:core::<fragment>::@class::List
                          type: List<String>
                      rightBracket: > @305
                    element: dart:core::<fragment>::@class::Map
                    type: Map<int, List<String>>
                rightBracket: > @306
              leftBracket: [ @307
              rightBracket: ] @308
              staticType: List<Map<int, List<String>>>
      accessors
        synthetic static get vNull @-1
          reference: <testLibraryFragment>::@getter::vNull
          enclosingElement: <testLibraryFragment>
          returnType: List<Null>
        synthetic static get vDynamic @-1
          reference: <testLibraryFragment>::@getter::vDynamic
          enclosingElement: <testLibraryFragment>
          returnType: List<dynamic>
        synthetic static get vInterfaceNoTypeParameters @-1
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeParameters
          enclosingElement: <testLibraryFragment>
          returnType: List<int>
        synthetic static get vInterfaceNoTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceNoTypeArguments
          enclosingElement: <testLibraryFragment>
          returnType: List<List<dynamic>>
        synthetic static get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          enclosingElement: <testLibraryFragment>
          returnType: List<List<String>>
        synthetic static get vInterfaceWithTypeArguments2 @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments2
          enclosingElement: <testLibraryFragment>
          returnType: List<Map<int, List<String>>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
                    type: C
                rightBracket: > @35
              leftBracket: [ @36
              rightBracket: ] @37
              staticType: List<C>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: List<C>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @19
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as p @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @19
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const v @28
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
                    name: C @41
                    element: package:test/a.dart::<fragment>::@class::C
                    type: C
                rightBracket: > @42
              leftBracket: [ @43
              rightBracket: ] @44
              staticType: List<C>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: List<C>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
      enclosingElement: <testLibrary>
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
          enclosingElement: <testLibraryFragment>
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
                    type: int Function(String)
                      alias: <testLibraryFragment>::@typeAlias::F
                rightBracket: > @44
              leftBracket: [ @45
              rightBracket: ] @46
              staticType: List<int Function(String)>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: List<int Function(String)>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          enclosingElement: <testLibraryFragment>
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
                    type: dynamic
                  NamedType
                    name: int @34
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @37
              leftBracket: { @38
              rightBracket: } @39
              isMap: true
              staticType: Map<dynamic, int>
        static const vDynamic2 @48
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic2
          enclosingElement: <testLibraryFragment>
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
                    type: int
                  NamedType
                    name: dynamic @72
                    element: dynamic@-1
                    type: dynamic
                rightBracket: > @79
              leftBracket: { @80
              rightBracket: } @81
              isMap: true
              staticType: Map<int, dynamic>
        static const vInterface @90
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          enclosingElement: <testLibraryFragment>
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
                    type: int
                  NamedType
                    name: String @115
                    element: dart:core::<fragment>::@class::String
                    type: String
                rightBracket: > @121
              leftBracket: { @122
              rightBracket: } @123
              isMap: true
              staticType: Map<int, String>
        static const vInterfaceWithTypeArguments @132
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          enclosingElement: <testLibraryFragment>
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
                    type: int
                  NamedType
                    name: List @174
                    typeArguments: TypeArgumentList
                      leftBracket: < @178
                      arguments
                        NamedType
                          name: String @179
                          element: dart:core::<fragment>::@class::String
                          type: String
                      rightBracket: > @185
                    element: dart:core::<fragment>::@class::List
                    type: List<String>
                rightBracket: > @186
              leftBracket: { @187
              rightBracket: } @188
              isMap: true
              staticType: Map<int, List<String>>
      accessors
        synthetic static get vDynamic1 @-1
          reference: <testLibraryFragment>::@getter::vDynamic1
          enclosingElement: <testLibraryFragment>
          returnType: Map<dynamic, int>
        synthetic static get vDynamic2 @-1
          reference: <testLibraryFragment>::@getter::vDynamic2
          enclosingElement: <testLibraryFragment>
          returnType: Map<int, dynamic>
        synthetic static get vInterface @-1
          reference: <testLibraryFragment>::@getter::vInterface
          enclosingElement: <testLibraryFragment>
          returnType: Map<int, String>
        synthetic static get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          enclosingElement: <testLibraryFragment>
          returnType: Map<int, List<String>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const vDynamic1 @6
          reference: <testLibraryFragment>::@topLevelVariable::vDynamic1
          enclosingElement: <testLibraryFragment>
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
                    type: dynamic
                rightBracket: > @32
              leftBracket: { @33
              rightBracket: } @34
              isMap: false
              staticType: Set<dynamic>
        static const vInterface @43
          reference: <testLibraryFragment>::@topLevelVariable::vInterface
          enclosingElement: <testLibraryFragment>
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
                    type: int
                rightBracket: > @66
              leftBracket: { @67
              rightBracket: } @68
              isMap: false
              staticType: Set<int>
        static const vInterfaceWithTypeArguments @77
          reference: <testLibraryFragment>::@topLevelVariable::vInterfaceWithTypeArguments
          enclosingElement: <testLibraryFragment>
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
                          type: String
                      rightBracket: > @125
                    element: dart:core::<fragment>::@class::List
                    type: List<String>
                rightBracket: > @126
              leftBracket: { @127
              rightBracket: } @128
              isMap: false
              staticType: Set<List<String>>
      accessors
        synthetic static get vDynamic1 @-1
          reference: <testLibraryFragment>::@getter::vDynamic1
          enclosingElement: <testLibraryFragment>
          returnType: Set<dynamic>
        synthetic static get vInterface @-1
          reference: <testLibraryFragment>::@getter::vInterface
          enclosingElement: <testLibraryFragment>
          returnType: Set<int>
        synthetic static get vInterfaceWithTypeArguments @-1
          reference: <testLibraryFragment>::@getter::vInterfaceWithTypeArguments
          enclosingElement: <testLibraryFragment>
          returnType: Set<List<String>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: List<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Map<int, String>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: Set<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
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
                      type: int
                  rightBracket: > @18
                element: dart:core::<fragment>::@class::List
                type: List<int>
              staticType: Type
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static final vValue @23
          reference: <testLibraryFragment>::@topLevelVariable::vValue
          enclosingElement: <testLibraryFragment>
          type: E
          shouldUseTypeForInitializerInference: false
        static final vValues @43
          reference: <testLibraryFragment>::@topLevelVariable::vValues
          enclosingElement: <testLibraryFragment>
          type: List<E>
          shouldUseTypeForInitializerInference: false
        static final vIndex @69
          reference: <testLibraryFragment>::@topLevelVariable::vIndex
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get vValue @-1
          reference: <testLibraryFragment>::@getter::vValue
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static get vValues @-1
          reference: <testLibraryFragment>::@getter::vValues
          enclosingElement: <testLibraryFragment>
          returnType: List<E>
        synthetic static get vIndex @-1
          reference: <testLibraryFragment>::@getter::vIndex
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingFragment: <testLibraryFragment>::@enum::E
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingFragment: <testLibraryFragment>::@enum::E
            enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingFragment: <testLibraryFragment>::@enum::E
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingFragment: <testLibraryFragment>::@enum::E
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingFragment: <testLibraryFragment>::@enum::E
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingFragment: <testLibraryFragment>::@enum::E
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingFragment: <testLibraryFragment>::@enum::E
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingFragment: <testLibraryFragment>::@enum::E
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingFragment: <testLibraryFragment>::@enum::E
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
        static const b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
        static const c
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
        synthetic static const values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static final vToString @17
          reference: <testLibraryFragment>::@topLevelVariable::vToString
          enclosingElement: <testLibraryFragment>
          type: String
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get vToString @-1
          reference: <testLibraryFragment>::@getter::vToString
          enclosingElement: <testLibraryFragment>
          returnType: String
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingFragment: <testLibraryFragment>::@enum::E
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingFragment: <testLibraryFragment>::@enum::E
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingFragment: <testLibraryFragment>::@enum::E
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingFragment: <testLibraryFragment>::@enum::E
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingFragment: <testLibraryFragment>::@enum::E
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
        synthetic static const values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            static const a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: b @29
                  staticElement: <testLibraryFragment>::@class::C::@getter::b
                  staticType: dynamic
            static const b @47
              reference: <testLibraryFragment>::@class::C::@field::b
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
              shouldUseTypeForInitializerInference: false
              constantInitializer
                NullLiteral
                  literal: null @51
                  staticType: Null
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic static get b @-1
              reference: <testLibraryFragment>::@class::C::@getter::b
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingFragment: <testLibraryFragment>::@class::C
            b @47
              reference: <testLibraryFragment>::@class::C::@field::b
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingFragment: <testLibraryFragment>::@class::C
            get b @-1
              reference: <testLibraryFragment>::@class::C::@getter::b
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::a
        static const b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::b
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
        synthetic static get b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            static const a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic Function()
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: m @29
                  staticElement: <testLibraryFragment>::@class::C::@method::m
                  staticType: dynamic Function()
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic Function()
          methods
            static m @41
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            a @25
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            m @41
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic Function()
          firstFragment: <testLibraryFragment>::@class::C::@field::a
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
      methods
        static m
          reference: <none>
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
