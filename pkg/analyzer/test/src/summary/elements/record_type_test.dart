// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordTypeElementTest_keepLinking);
    defineReflectiveTests(RecordTypeElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class RecordTypeElementTest extends ElementsBaseTest {
  test_recordType_class_field() async {
    var library = await buildLibrary('''
class A {
  final (int, String) x;
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
            x @32
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <testLibraryFragment>::@class::A::@field::x#element
              getter2: <testLibraryFragment>::@class::A::@getter::x
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::A::@getter::x
              element: <testLibraryFragment>::@class::A::@getter::x#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final x
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          type: (int, String)
          getter: <testLibraryFragment>::@class::A::@getter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
          returnType: (int, String)
''');
  }

  test_recordType_class_field_fromLiteral() async {
    var library = await buildLibrary('''
class A {
  final x = (0, true);
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
            hasInitializer x @18
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <testLibraryFragment>::@class::A::@field::x#element
              getter2: <testLibraryFragment>::@class::A::@getter::x
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::A::@getter::x
              element: <testLibraryFragment>::@class::A::@getter::x#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final hasInitializer x
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          type: (int, bool)
          getter: <testLibraryFragment>::@class::A::@getter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
          returnType: (int, bool)
''');
  }

  test_recordType_class_method_formalParameter() async {
    var library = await buildLibrary('''
class A {
  void foo((int, String) a) {}
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
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                a @35
                  element: <testLibraryFragment>::@class::A::@method::foo::@parameter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
          formalParameters
            requiredPositional a
              type: (int, String)
          returnType: void
''');
  }

  test_recordType_class_method_returnType() async {
    var library = await buildLibrary('''
class A {
  (int, String) foo() {}
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
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          methods
            foo @26
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibrary>::@class::A::@method::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
          returnType: (int, String)
''');
  }

  test_recordType_class_typeParameter_bound() async {
    var library = await buildLibrary('''
class A<T extends (int, String)> {}
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
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
          bound: (int, String)
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
''');
  }

  test_recordType_extension_onType() async {
    var library = await buildLibrary('''
extension IntStringExtension on (int, String) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension IntStringExtension @10
          reference: <testLibraryFragment>::@extension::IntStringExtension
          element: <testLibrary>::@extension::IntStringExtension
  extensions
    extension IntStringExtension
      reference: <testLibrary>::@extension::IntStringExtension
      firstFragment: <testLibraryFragment>::@extension::IntStringExtension
''');
  }

  test_recordType_functionType_formalParameter() async {
    var library = await buildLibrary('''
void f(void Function((int, String) a) b) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            b @38
              element: <testLibraryFragment>::@function::f::@parameter::b#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional b
          type: void Function((int, String))
      returnType: void
''');
  }

  test_recordType_functionType_returnType() async {
    var library = await buildLibrary('''
void f((int, String) Function() a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            a @32
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional a
          type: (int, String) Function()
      returnType: void
''');
  }

  test_recordType_topFunction_formalParameter() async {
    var library = await buildLibrary('''
void f((int, String) a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            a @21
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional a
          type: (int, String)
      returnType: void
''');
  }

  test_recordType_topFunction_returnType_empty() async {
    var library = await buildLibrary('''
() f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @3
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: ()
''');
  }

  test_recordType_topFunction_returnType_generic() async {
    var library = await buildLibrary('''
(int, T) f<T>() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @9
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @11
              element: T@11
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
      returnType: (int, T)
''');
  }

  test_recordType_topFunction_returnType_mixed() async {
    var library = await buildLibrary('''
(int, String, {bool c}) f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @24
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: (int, String, {bool c})
''');
  }

  test_recordType_topFunction_returnType_named() async {
    var library = await buildLibrary('''
({int a, String b}) f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @20
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: ({int a, String b})
''');
  }

  test_recordType_topFunction_returnType_nested() async {
    var library = await buildLibrary('''
((int, String), (bool, double)) f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @32
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: ((int, String), (bool, double))
''');
  }

  test_recordType_topFunction_returnType_nullable() async {
    var library = await buildLibrary('''
(int, String)? f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @15
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: (int, String)?
''');
  }

  test_recordType_topFunction_returnType_positional() async {
    var library = await buildLibrary('''
(int, String) f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @14
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: (int, String)
''');
  }

  test_recordType_topFunction_returnType_positional_one() async {
    var library = await buildLibrary('''
(int,) f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @7
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: (int,)
''');
  }

  test_recordType_topVariable() async {
    var library = await buildLibrary('''
final (int, String) x;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    final x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: (int, String)
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: (int, String)
''');
  }

  test_recordType_topVariable_fromLiteral() async {
    var library = await buildLibrary('''
final x = (0, true);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: (int, bool)
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: (int, bool)
''');
  }

  test_recordTypeAnnotation_named() async {
    var library = await buildLibrary(r'''
const x = List<({int f1, String f2})>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            TypeLiteral
              type: NamedType
                name: List @10
                typeArguments: TypeArgumentList
                  leftBracket: < @14
                  arguments
                    RecordTypeAnnotation
                      leftParenthesis: ( @15
                      namedFields: RecordTypeAnnotationNamedFields
                        leftBracket: { @16
                        fields
                          RecordTypeAnnotationNamedField
                            type: NamedType
                              name: int @17
                              element2: dart:core::@class::int
                              type: int
                            name: f1 @21
                          RecordTypeAnnotationNamedField
                            type: NamedType
                              name: String @25
                              element2: dart:core::@class::String
                              type: String
                            name: f2 @32
                        rightBracket: } @34
                      rightParenthesis: ) @35
                      type: ({int f1, String f2})
                  rightBracket: > @36
                element2: dart:core::@class::List
                type: List<({int f1, String f2})>
              staticType: Type
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Type
''');
  }

  test_recordTypeAnnotation_positional() async {
    var library = await buildLibrary(r'''
const x = List<(int, String f2)>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            TypeLiteral
              type: NamedType
                name: List @10
                typeArguments: TypeArgumentList
                  leftBracket: < @14
                  arguments
                    RecordTypeAnnotation
                      leftParenthesis: ( @15
                      positionalFields
                        RecordTypeAnnotationPositionalField
                          type: NamedType
                            name: int @16
                            element2: dart:core::@class::int
                            type: int
                        RecordTypeAnnotationPositionalField
                          type: NamedType
                            name: String @21
                            element2: dart:core::@class::String
                            type: String
                          name: f2 @28
                      rightParenthesis: ) @30
                      type: (int, String)
                  rightBracket: > @31
                element2: dart:core::@class::List
                type: List<(int, String)>
              staticType: Type
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Type
''');
  }
}

@reflectiveTest
class RecordTypeElementTest_fromBytes extends RecordTypeElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class RecordTypeElementTest_keepLinking extends RecordTypeElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
