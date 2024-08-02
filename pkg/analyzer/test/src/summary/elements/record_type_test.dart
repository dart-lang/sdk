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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            final x @32
              reference: <testLibraryFragment>::@class::A::@field::x
              enclosingElement: <testLibraryFragment>::@class::A
              type: (int, String)
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              enclosingElement: <testLibraryFragment>::@class::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            final x @18
              reference: <testLibraryFragment>::@class::A::@field::x
              enclosingElement: <testLibraryFragment>::@class::A
              type: (int, bool)
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              enclosingElement: <testLibraryFragment>::@class::A
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
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @35
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
          methods
            foo @26
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement: <testLibraryFragment>::@class::A
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
              bound: (int, String)
              defaultType: (int, String)
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
''');
  }

  test_recordType_extension_onType() async {
    var library = await buildLibrary('''
extension IntStringExtension on (int, String) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        IntStringExtension @10
          reference: <testLibraryFragment>::@extension::IntStringExtension
          enclosingElement: <testLibraryFragment>
          extendedType: (int, String)
''');
  }

  test_recordType_functionType_formalParameter() async {
    var library = await buildLibrary('''
void f(void Function((int, String) a) b) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional b @38
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @32
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @21
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @3
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @9
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @11
              defaultType: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @24
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @20
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @32
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @15
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @14
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @7
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static final x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: (int, String)
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static final x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: (int, bool)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
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
                    RecordTypeAnnotation
                      leftParenthesis: ( @15
                      namedFields: RecordTypeAnnotationNamedFields
                        leftBracket: { @16
                        fields
                          RecordTypeAnnotationNamedField
                            type: NamedType
                              name: int @17
                              element: dart:core::<fragment>::@class::int
                              type: int
                            name: f1 @21
                          RecordTypeAnnotationNamedField
                            type: NamedType
                              name: String @25
                              element: dart:core::<fragment>::@class::String
                              type: String
                            name: f2 @32
                        rightBracket: } @34
                      rightParenthesis: ) @35
                      type: ({int f1, String f2})
                  rightBracket: > @36
                element: dart:core::<fragment>::@class::List
                type: List<({int f1, String f2})>
              staticType: Type
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
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
                    RecordTypeAnnotation
                      leftParenthesis: ( @15
                      positionalFields
                        RecordTypeAnnotationPositionalField
                          type: NamedType
                            name: int @16
                            element: dart:core::<fragment>::@class::int
                            type: int
                        RecordTypeAnnotationPositionalField
                          type: NamedType
                            name: String @21
                            element: dart:core::<fragment>::@class::String
                            type: String
                          name: f2 @28
                      rightParenthesis: ) @30
                      type: (int, String)
                  rightBracket: > @31
                element: dart:core::<fragment>::@class::List
                type: List<(int, String)>
              staticType: Type
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
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
