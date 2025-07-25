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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 x (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::A::@getter::x
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: (int, String)
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: (int, String)
          variable: <testLibrary>::@class::A::@field::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::A::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::A::@getter::x
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final hasInitializer x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: (int, bool)
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: (int, bool)
          variable: <testLibrary>::@class::A::@field::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 a (nameOffset:35) (firstTokenOffset:21) (offset:35)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:26) (firstTokenOffset:12) (offset:26)
              element: <testLibrary>::@class::A::@method::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: (int, String)
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension IntStringExtension (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::IntStringExtension
  extensions
    extension IntStringExtension
      reference: <testLibrary>::@extension::IntStringExtension
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 b (nameOffset:38) (firstTokenOffset:7) (offset:38)
              element: <testLibrary>::@function::f::@formalParameter::b
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional b
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 a (nameOffset:32) (firstTokenOffset:7) (offset:32)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 a (nameOffset:21) (firstTokenOffset:7) (offset:21)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:3) (firstTokenOffset:0) (offset:3)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:9) (firstTokenOffset:0) (offset:9)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E0 T
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:24) (firstTokenOffset:0) (offset:24)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:20) (firstTokenOffset:0) (offset:20)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:32) (firstTokenOffset:0) (offset:32)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:14) (firstTokenOffset:0) (offset:14)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:7) (firstTokenOffset:0) (offset:7)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 x (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::x
  topLevelVariables
    final x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: (int, String)
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: (int, String)
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::x
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: (int, bool)
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: (int, bool)
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:6) (firstTokenOffset:6) (offset:6)
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
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Type
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:6) (firstTokenOffset:6) (offset:6)
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
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Type
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::x
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
