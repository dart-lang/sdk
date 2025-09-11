// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassElementTest_keepLinking);
    defineReflectiveTests(ClassElementTest_fromBytes);
    defineReflectiveTests(ClassElementTest_augmentation_keepLinking);
    defineReflectiveTests(ClassElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class ClassElementTest extends ElementsBaseTest {
  test_class_abstract() async {
    var library = await buildLibrary('abstract class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_base() async {
    var library = await buildLibrary('base class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    base class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_const() async {
    var library = await buildLibrary('class C { const C(); }');
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:10) (offset:16)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 16
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_const_external() async {
    var library = await buildLibrary('class C { external const C(); }');
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
            #F2 external const new (nameOffset:<null>) (firstTokenOffset:10) (offset:25)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 25
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        external const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_documented() async {
    var library = await buildLibrary('''
class C {
  /**
   * Docs
   */
  C();
}''');
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              documentationComment: /**\n   * Docs\n   */
              typeName: C
              typeNameOffset: 34
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          documentationComment: /**\n   * Docs\n   */
''');
  }

  test_class_constructor_explicit_named() async {
    var library = await buildLibrary('class C { C.foo(); }');
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
            #F2 foo (nameOffset:12) (firstTokenOffset:10) (offset:12)
              element: <testLibrary>::@class::C::@constructor::foo
              typeName: C
              typeNameOffset: 10
              periodOffset: 11
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        foo
          reference: <testLibrary>::@class::C::@constructor::foo
          firstFragment: #F2
''');
  }

  test_class_constructor_explicit_type_params() async {
    var library = await buildLibrary('class C<T, U> { C(); }');
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 16
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_constructor_explicit_unnamed() async {
    var library = await buildLibrary('class C { C(); }');
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 10
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_external() async {
    var library = await buildLibrary('class C { external C(); }');
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
            #F2 external new (nameOffset:<null>) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 19
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        external new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_factory() async {
    var library = await buildLibrary('class C { factory C() => throw 0; }');
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
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:10) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_field_formal_dynamic_dynamic() async {
    var library = await buildLibrary(
      'class C { dynamic x; C(dynamic this.x); }',
    );
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 21
              formalParameters
                #F4 this.x (nameOffset:36) (firstTokenOffset:23) (offset:36)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: dynamic
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_dynamic_typed() async {
    var library = await buildLibrary('class C { dynamic x; C(int this.x); }');
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 21
              formalParameters
                #F4 this.x (nameOffset:32) (firstTokenOffset:23) (offset:32)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_dynamic_untyped() async {
    var library = await buildLibrary('class C { dynamic x; C(this.x); }');
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 21
              formalParameters
                #F4 this.x (nameOffset:28) (firstTokenOffset:23) (offset:28)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F4
              type: dynamic
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_functionTyped_noReturnType() async {
    var library = await buildLibrary(r'''
class C {
  var x;
  C(this.x(double b));
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
            #F2 x (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 21
              formalParameters
                #F4 this.x (nameOffset:28) (firstTokenOffset:23) (offset:28)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  parameters
                    #F5 b (nameOffset:37) (firstTokenOffset:30) (offset:37)
                      element: b@37
          getters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F7 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: dynamic Function(double)
              formalParameters
                #E1 requiredPositional b
                  firstFragment: #F5
                  type: double
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_functionTyped_withReturnType() async {
    var library = await buildLibrary(r'''
class C {
  var x;
  C(int this.x(double b));
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
            #F2 x (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 21
              formalParameters
                #F4 this.x (nameOffset:32) (firstTokenOffset:23) (offset:32)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  parameters
                    #F5 b (nameOffset:41) (firstTokenOffset:34) (offset:41)
                      element: b@41
          getters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F7 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: int Function(double)
              formalParameters
                #E1 requiredPositional b
                  firstFragment: #F5
                  type: double
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_functionTyped_withReturnType_generic() async {
    var library = await buildLibrary(r'''
class C {
  Function() f;
  C(List<U> this.f<T, U>(T t));
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
            #F2 f (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 28
              formalParameters
                #F4 this.f (nameOffset:43) (firstTokenOffset:30) (offset:43)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
                  typeParameters
                    #F5 T (nameOffset:45) (firstTokenOffset:45) (offset:45)
                      element: #E0 T
                    #F6 U (nameOffset:48) (firstTokenOffset:48) (offset:48)
                      element: #E1 U
                  parameters
                    #F7 t (nameOffset:53) (firstTokenOffset:51) (offset:53)
                      element: t@53
          getters
            #F8 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@getter::f
          setters
            #F9 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: dynamic Function()
          getter: <testLibrary>::@class::C::@getter::f
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E2 requiredPositional final f
              firstFragment: #F4
              type: List<U> Function<T, U>(T)
              typeParameters
                #E0 T
                  firstFragment: #F5
                #E1 U
                  firstFragment: #F6
              formalParameters
                #E3 requiredPositional t
                  firstFragment: #F7
                  type: T
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F8
          returnType: dynamic Function()
          variable: <testLibrary>::@class::C::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F9
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F10
              type: dynamic Function()
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_class_constructor_field_formal_multiple_matching_fields() async {
    // This is a compile-time error but it should still analyze consistently.
    var library = await buildLibrary('class C { C(this.x); int x; String x; }');

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
            #F2 x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::x::@def::0
            #F3 x (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@class::C::@field::x::@def::1
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 10
              formalParameters
                #F5 this.x (nameOffset:17) (firstTokenOffset:12) (offset:17)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::x::@def::0
            #F7 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@getter::x::@def::1
          setters
            #F8 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@setter::x::@def::0
              formalParameters
                #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
                  element: <testLibrary>::@class::C::@setter::x::@def::0::@formalParameter::value
            #F10 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@setter::x::@def::1
              formalParameters
                #F11 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
                  element: <testLibrary>::@class::C::@setter::x::@def::1::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x::@def::0
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x::@def::0
          setter: <testLibrary>::@class::C::@setter::x::@def::0
        x
          reference: <testLibrary>::@class::C::@field::x::@def::1
          firstFragment: #F3
          type: String
          getter: <testLibrary>::@class::C::@getter::x::@def::1
          setter: <testLibrary>::@class::C::@setter::x::@def::1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F5
              type: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x::@def::0
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::C::@field::x::@def::0
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x::@def::1
          firstFragment: #F7
          returnType: String
          variable: <testLibrary>::@class::C::@field::x::@def::1
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x::@def::0
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x::@def::0
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x::@def::1
          firstFragment: #F10
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F11
              type: String
          returnType: void
          variable: <testLibrary>::@class::C::@field::x::@def::1
''');
  }

  test_class_constructor_field_formal_no_matching_field() async {
    // This is a compile-time error but it should still analyze consistently.
    var library = await buildLibrary('class C { C(this.x); }');
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 10
              formalParameters
                #F3 this.x (nameOffset:17) (firstTokenOffset:12) (offset:17)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F3
              type: dynamic
''');
  }

  test_class_constructor_field_formal_typed_dynamic() async {
    var library = await buildLibrary('class C { num x; C(dynamic this.x); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:32) (firstTokenOffset:19) (offset:32)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: dynamic
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: num
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: num
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_typed_typed() async {
    var library = await buildLibrary('class C { num x; C(int this.x); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:28) (firstTokenOffset:19) (offset:28)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: num
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: num
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_typed_untyped() async {
    var library = await buildLibrary('class C { num x; C(this.x); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F4
              type: num
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: num
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: num
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_untyped_dynamic() async {
    var library = await buildLibrary('class C { var x; C(dynamic this.x); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:32) (firstTokenOffset:19) (offset:32)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: dynamic
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_untyped_typed() async {
    var library = await buildLibrary('class C { var x; C(int this.x); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:28) (firstTokenOffset:19) (offset:28)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F4
              type: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_field_formal_untyped_untyped() async {
    var library = await buildLibrary('class C { var x; C(this.x); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F4
              type: dynamic
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_fieldFormal_named_noDefault() async {
    var library = await buildLibrary('class C { int x; C({this.x}); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:25) (firstTokenOffset:20) (offset:25)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasImplicitType x
              firstFragment: #F4
              type: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_fieldFormal_named_withDefault() async {
    var library = await buildLibrary('class C { int x; C({this.x: 42}); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:25) (firstTokenOffset:20) (offset:25)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  initializer: expression_0
                    IntegerLiteral
                      literal: 42 @28
                      staticType: int
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasImplicitType x
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_fieldFormal_optional_noDefault() async {
    var library = await buildLibrary('class C { int x; C([this.x]); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:25) (firstTokenOffset:20) (offset:25)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasImplicitType x
              firstFragment: #F4
              type: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_fieldFormal_optional_withDefault() async {
    var library = await buildLibrary('class C { int x; C([this.x = 42]); }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 17
              formalParameters
                #F4 this.x (nameOffset:25) (firstTokenOffset:20) (offset:25)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  initializer: expression_0
                    IntegerLiteral
                      literal: 42 @29
                      staticType: int
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasImplicitType x
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_implicit_type_params() async {
    var library = await buildLibrary('class C<T, U> {}');
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_constructor_initializers_assertInvocation() async {
    var library = await buildLibrary('''
class C {
  const C(int x) : assert(x >= 42);
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
              formalParameters
                #F3 x (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F3
              type: int
          constantInitializers
            AssertInitializer
              assertKeyword: assert @29
              leftParenthesis: ( @35
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: x @36
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  staticType: int
                operator: >= @38
                rightOperand: IntegerLiteral
                  literal: 42 @41
                  staticType: int
                element: dart:core::@class::num::@method::>=
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @43
''');
  }

  test_class_constructor_initializers_assertInvocation_message() async {
    var library = await buildLibrary('''
class C {
  const C(int x) : assert(x >= 42, 'foo');
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
              formalParameters
                #F3 x (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F3
              type: int
          constantInitializers
            AssertInitializer
              assertKeyword: assert @29
              leftParenthesis: ( @35
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: x @36
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  staticType: int
                operator: >= @38
                rightOperand: IntegerLiteral
                  literal: 42 @41
                  staticType: int
                element: dart:core::@class::num::@method::>=
                staticInvokeType: bool Function(num)
                staticType: bool
              comma: , @43
              message: SimpleStringLiteral
                literal: 'foo' @45
              rightParenthesis: ) @50
''');
  }

  test_class_constructor_initializers_field() async {
    var library = await buildLibrary('''
class C {
  final x;
  const C() : x = 42;
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @35
                element: <testLibrary>::@class::C::@field::x
                staticType: null
              equals: = @37
              expression: IntegerLiteral
                literal: 42 @39
                staticType: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_initializers_field_notConst() async {
    var library = await buildLibrary('''
class C {
  final x;
  const C() : x = foo();
}
int foo() => 42;
''');
    // It is OK to keep non-constant initializers.
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
      functions
        #F5 foo (nameOffset:52) (firstTokenOffset:48) (offset:52)
          element: <testLibrary>::@function::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @35
                element: <testLibrary>::@class::C::@field::x
                staticType: null
              equals: = @37
              expression: MethodInvocation
                methodName: SimpleIdentifier
                  token: foo @39
                  element: <testLibrary>::@function::foo
                  staticType: int Function()
                argumentList: ArgumentList
                  leftParenthesis: ( @42
                  rightParenthesis: ) @43
                staticInvokeType: int Function()
                staticType: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      returnType: int
''');
  }

  test_class_constructor_initializers_field_optionalPositionalParameter() async {
    var library = await buildLibrary('''
class A {
  final int _f;
  const A([int f = 0]) : _f = f;
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
            #F2 _f (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::A::@field::_f
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:28) (offset:34)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 34
              formalParameters
                #F4 f (nameOffset:41) (firstTokenOffset:37) (offset:41)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @45
                      staticType: int
          getters
            #F5 synthetic _f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@getter::_f
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final promotable _f
          reference: <testLibrary>::@class::A::@field::_f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::_f
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional f
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: _f @51
                element: <testLibrary>::@class::A::@field::_f
                staticType: null
              equals: = @54
              expression: SimpleIdentifier
                token: f @56
                element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
                staticType: int
      getters
        synthetic _f
          reference: <testLibrary>::@class::A::@getter::_f
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::_f
''');
  }

  test_class_constructor_initializers_field_recordLiteral() async {
    var library = await buildLibrary('''
class C {
  final Object x;
  const C(int a) : x = (0, a);
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
            #F2 x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:30) (offset:36)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 36
              formalParameters
                #F4 a (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: Object
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: int
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @47
                element: <testLibrary>::@class::C::@field::x
                staticType: null
              equals: = @49
              expression: RecordLiteral
                leftParenthesis: ( @51
                fields
                  IntegerLiteral
                    literal: 0 @52
                    staticType: int
                  SimpleIdentifier
                    token: a @55
                    element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
                    staticType: int
                rightParenthesis: ) @56
                staticType: (int, int)
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: Object
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_initializers_field_stringInterpolation_expression() async {
    var library = await buildLibrary(r'''
class C {
  final f;
  const C() : f = '${42}';
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
            #F2 f (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: f @35
                element: <testLibrary>::@class::C::@field::f
                staticType: null
              equals: = @37
              expression: StringInterpolation
                elements
                  InterpolationString
                    contents: ' @39
                  InterpolationExpression
                    leftBracket: ${ @40
                    expression: IntegerLiteral
                      literal: 42 @42
                      staticType: int
                    rightBracket: } @44
                  InterpolationString
                    contents: ' @45
                staticType: String
                stringValue: null
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_class_constructor_initializers_field_stringInterpolation_identifier() async {
    var library = await buildLibrary(r'''
class C {
  final f;
  const C(int x) : f = '$x';
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
            #F2 f (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                #F4 x (nameOffset:35) (firstTokenOffset:31) (offset:35)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          getters
            #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F4
              type: int
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: f @40
                element: <testLibrary>::@class::C::@field::f
                staticType: null
              equals: = @42
              expression: StringInterpolation
                elements
                  InterpolationString
                    contents: ' @44
                  InterpolationExpression
                    leftBracket: $ @45
                    expression: SimpleIdentifier
                      token: x @46
                      element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                      staticType: int
                  InterpolationString
                    contents: ' @47
                staticType: String
                stringValue: null
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_class_constructor_initializers_field_withParameter() async {
    var library = await buildLibrary('''
class C {
  final x;
  const C(int p) : x = 1 + p;
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
              formalParameters
                #F4 p (nameOffset:35) (firstTokenOffset:31) (offset:35)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::p
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional p
              firstFragment: #F4
              type: int
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @40
                element: <testLibrary>::@class::C::@field::x
                staticType: null
              equals: = @42
              expression: BinaryExpression
                leftOperand: IntegerLiteral
                  literal: 1 @44
                  staticType: int
                operator: + @46
                rightOperand: SimpleIdentifier
                  token: p @48
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::p
                  staticType: int
                element: dart:core::@class::num::@method::+
                staticInvokeType: num Function(num)
                staticType: int
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_constructor_initializers_genericFunctionType() async {
    var library = await buildLibrary('''
class A<T> {
  const A();
}
class B {
  const B(dynamic x);
  const B.f()
   : this(A<Function()>());
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
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
        #F4 class B (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::B
          constructors
            #F5 const new (nameOffset:<null>) (firstTokenOffset:40) (offset:46)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 46
              formalParameters
                #F6 x (nameOffset:56) (firstTokenOffset:48) (offset:56)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::x
            #F7 const f (nameOffset:70) (firstTokenOffset:62) (offset:70)
              element: <testLibrary>::@class::B::@constructor::f
              typeName: B
              typeNameOffset: 68
              periodOffset: 69
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional x
              firstFragment: #F6
              type: dynamic
        const f
          reference: <testLibrary>::@class::B::@constructor::f
          firstFragment: #F7
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @79
              argumentList: ArgumentList
                leftParenthesis: ( @83
                arguments
                  InstanceCreationExpression
                    constructorName: ConstructorName
                      type: NamedType
                        name: A @84
                        typeArguments: TypeArgumentList
                          leftBracket: < @85
                          arguments
                            GenericFunctionType
                              functionKeyword: Function @86
                              parameters: FormalParameterList
                                leftParenthesis: ( @94
                                rightParenthesis: ) @95
                              declaredElement: GenericFunctionTypeElement
                                parameters
                                returnType: dynamic
                                type: dynamic Function()
                              type: dynamic Function()
                          rightBracket: > @96
                        element2: <testLibrary>::@class::A
                        type: A<dynamic Function()>
                      element: ConstructorMember
                        baseElement: <testLibrary>::@class::A::@constructor::new
                        substitution: {T: dynamic Function()}
                    argumentList: ArgumentList
                      leftParenthesis: ( @97
                      rightParenthesis: ) @98
                    staticType: A<dynamic Function()>
                rightParenthesis: ) @99
              element: <testLibrary>::@class::B::@constructor::new
          redirectedConstructor: <testLibrary>::@class::B::@constructor::new
''');
  }

  test_class_constructor_initializers_superInvocation_argumentContextType() async {
    var library = await buildLibrary('''
class A {
  const A(List<String> values);
}
class B extends A {
  const B() : super(const []);
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                #F3 values (nameOffset:33) (firstTokenOffset:20) (offset:33)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::values
        #F4 class B (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::B
          constructors
            #F5 const new (nameOffset:<null>) (firstTokenOffset:66) (offset:72)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 72
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional values
              firstFragment: #F3
              type: List<String>
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @78
              argumentList: ArgumentList
                leftParenthesis: ( @83
                arguments
                  ListLiteral
                    constKeyword: const @84
                    leftBracket: [ @90
                    rightBracket: ] @91
                    staticType: List<String>
                rightParenthesis: ) @92
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_initializers_superInvocation_named() async {
    var library = await buildLibrary('''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.aaa(42);
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
            #F2 const aaa (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::aaa
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                #F3 p (nameOffset:28) (firstTokenOffset:24) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::aaa::@formalParameter::p
        #F4 class C (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::C
          constructors
            #F5 const new (nameOffset:<null>) (firstTokenOffset:56) (offset:62)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 62
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const aaa
          reference: <testLibrary>::@class::A::@constructor::aaa
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional p
              firstFragment: #F3
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: A
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @68
              period: . @73
              constructorName: SimpleIdentifier
                token: aaa @74
                element: <testLibrary>::@class::A::@constructor::aaa
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @77
                arguments
                  IntegerLiteral
                    literal: 42 @78
                    staticType: int
                rightParenthesis: ) @80
              element: <testLibrary>::@class::A::@constructor::aaa
          superConstructor: <testLibrary>::@class::A::@constructor::aaa
''');
  }

  test_class_constructor_initializers_superInvocation_named_underscore() async {
    var library = await buildLibrary('''
class A {
  const A._();
}
class B extends A {
  const B() : super._();
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
            #F2 const _ (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::_
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
        #F3 class B (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::B
          constructors
            #F4 const new (nameOffset:<null>) (firstTokenOffset:49) (offset:55)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 55
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const _
          reference: <testLibrary>::@class::A::@constructor::_
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @61
              period: . @66
              constructorName: SimpleIdentifier
                token: _ @67
                element: <testLibrary>::@class::A::@constructor::_
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @68
                rightParenthesis: ) @69
              element: <testLibrary>::@class::A::@constructor::_
          superConstructor: <testLibrary>::@class::A::@constructor::_
''');
  }

  test_class_constructor_initializers_superInvocation_namedExpression() async {
    var library = await buildLibrary('''
class A {
  const A.aaa(a, {int b});
}
class C extends A {
  const C() : super.aaa(1, b: 2);
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
            #F2 const aaa (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::aaa
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                #F3 a (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: <testLibrary>::@class::A::@constructor::aaa::@formalParameter::a
                #F4 b (nameOffset:32) (firstTokenOffset:28) (offset:32)
                  element: <testLibrary>::@class::A::@constructor::aaa::@formalParameter::b
        #F5 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
          constructors
            #F6 const new (nameOffset:<null>) (firstTokenOffset:61) (offset:67)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 67
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const aaa
          reference: <testLibrary>::@class::A::@constructor::aaa
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F3
              type: dynamic
            #E1 optionalNamed b
              firstFragment: #F4
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      supertype: A
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @73
              period: . @78
              constructorName: SimpleIdentifier
                token: aaa @79
                element: <testLibrary>::@class::A::@constructor::aaa
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @82
                arguments
                  IntegerLiteral
                    literal: 1 @83
                    staticType: int
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: b @86
                        element: <testLibrary>::@class::A::@constructor::aaa::@formalParameter::b
                        staticType: null
                      colon: : @87
                    expression: IntegerLiteral
                      literal: 2 @89
                      staticType: int
                rightParenthesis: ) @90
              element: <testLibrary>::@class::A::@constructor::aaa
          superConstructor: <testLibrary>::@class::A::@constructor::aaa
''');
  }

  test_class_constructor_initializers_superInvocation_unnamed() async {
    var library = await buildLibrary('''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                #F3 p (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
        #F4 class C (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::C
          constructors
            #F5 const ccc (nameOffset:60) (firstTokenOffset:52) (offset:60)
              element: <testLibrary>::@class::C::@constructor::ccc
              typeName: C
              typeNameOffset: 58
              periodOffset: 59
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional p
              firstFragment: #F3
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: A
      constructors
        const ccc
          reference: <testLibrary>::@class::C::@constructor::ccc
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @68
              argumentList: ArgumentList
                leftParenthesis: ( @73
                arguments
                  IntegerLiteral
                    literal: 42 @74
                    staticType: int
                rightParenthesis: ) @76
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_initializers_thisInvocation_argumentContextType() async {
    var library = await buildLibrary('''
class A {
  const A(List<String> values);
  const A.empty() : this(const []);
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                #F3 values (nameOffset:33) (firstTokenOffset:20) (offset:33)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::values
            #F4 const empty (nameOffset:52) (firstTokenOffset:44) (offset:52)
              element: <testLibrary>::@class::A::@constructor::empty
              typeName: A
              typeNameOffset: 50
              periodOffset: 51
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional values
              firstFragment: #F3
              type: List<String>
        const empty
          reference: <testLibrary>::@class::A::@constructor::empty
          firstFragment: #F4
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @62
              argumentList: ArgumentList
                leftParenthesis: ( @66
                arguments
                  ListLiteral
                    constKeyword: const @67
                    leftBracket: [ @73
                    rightBracket: ] @74
                    staticType: List<String>
                rightParenthesis: ) @75
              element: <testLibrary>::@class::A::@constructor::new
          redirectedConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_initializers_thisInvocation_named() async {
    var library = await buildLibrary('''
class C {
  const C() : this.named(1, 'bbb');
  const C.named(int a, String b);
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
            #F3 const named (nameOffset:56) (firstTokenOffset:48) (offset:56)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 54
              periodOffset: 55
              formalParameters
                #F4 a (nameOffset:66) (firstTokenOffset:62) (offset:66)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::a
                #F5 b (nameOffset:76) (firstTokenOffset:69) (offset:76)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @24
              period: . @28
              constructorName: SimpleIdentifier
                token: named @29
                element: <testLibrary>::@class::C::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @34
                arguments
                  IntegerLiteral
                    literal: 1 @35
                    staticType: int
                  SimpleStringLiteral
                    literal: 'bbb' @38
                rightParenthesis: ) @43
              element: <testLibrary>::@class::C::@constructor::named
          redirectedConstructor: <testLibrary>::@class::C::@constructor::named
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: int
            #E1 requiredPositional b
              firstFragment: #F5
              type: String
''');
  }

  test_class_constructor_initializers_thisInvocation_namedExpression() async {
    var library = await buildLibrary('''
class C {
  const C() : this.named(1, b: 2);
  const C.named(a, {int b});
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
            #F3 const named (nameOffset:55) (firstTokenOffset:47) (offset:55)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 53
              periodOffset: 54
              formalParameters
                #F4 a (nameOffset:61) (firstTokenOffset:61) (offset:61)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::a
                #F5 b (nameOffset:69) (firstTokenOffset:65) (offset:69)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @24
              period: . @28
              constructorName: SimpleIdentifier
                token: named @29
                element: <testLibrary>::@class::C::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @34
                arguments
                  IntegerLiteral
                    literal: 1 @35
                    staticType: int
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: b @38
                        element: <testLibrary>::@class::C::@constructor::named::@formalParameter::b
                        staticType: null
                      colon: : @39
                    expression: IntegerLiteral
                      literal: 2 @41
                      staticType: int
                rightParenthesis: ) @42
              element: <testLibrary>::@class::C::@constructor::named
          redirectedConstructor: <testLibrary>::@class::C::@constructor::named
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F4
              type: dynamic
            #E1 optionalNamed b
              firstFragment: #F5
              type: int
''');
  }

  test_class_constructor_initializers_thisInvocation_unnamed() async {
    var library = await buildLibrary('''
class C {
  const C.named() : this(1, 'bbb');
  const C(int a, String b);
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
            #F2 const named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 18
              periodOffset: 19
            #F3 const new (nameOffset:<null>) (firstTokenOffset:48) (offset:54)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 54
              formalParameters
                #F4 a (nameOffset:60) (firstTokenOffset:56) (offset:60)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
                #F5 b (nameOffset:70) (firstTokenOffset:63) (offset:70)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F2
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @30
              argumentList: ArgumentList
                leftParenthesis: ( @34
                arguments
                  IntegerLiteral
                    literal: 1 @35
                    staticType: int
                  SimpleStringLiteral
                    literal: 'bbb' @38
                rightParenthesis: ) @43
              element: <testLibrary>::@class::C::@constructor::new
          redirectedConstructor: <testLibrary>::@class::C::@constructor::new
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: int
            #E1 requiredPositional b
              firstFragment: #F5
              type: String
''');
  }

  test_class_constructor_parameters_super_explicitType_function() async {
    var library = await buildLibrary('''
class A {
  A(Object? a);
}

class B extends A {
  B(int super.a<T extends num>(T d)?);
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:22) (firstTokenOffset:14) (offset:22)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class B (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:51) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 51
              formalParameters
                #F6 super.a (nameOffset:63) (firstTokenOffset:53) (offset:63)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
                  typeParameters
                    #F7 T (nameOffset:65) (firstTokenOffset:65) (offset:65)
                      element: #E0 T
                  parameters
                    #F8 d (nameOffset:82) (firstTokenOffset:80) (offset:82)
                      element: d@82
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F3
              type: Object?
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional final a
              firstFragment: #F6
              type: int Function<T extends num>(T)?
              typeParameters
                #E0 T
                  firstFragment: #F7
                  bound: num
              formalParameters
                #E3 requiredPositional d
                  firstFragment: #F8
                  type: T
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_explicitType_interface() async {
    var library = await buildLibrary('''
class A {
  A(num a);
}

class B extends A {
  B(int super.a);
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:47) (offset:47)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 47
              formalParameters
                #F6 super.a (nameOffset:59) (firstTokenOffset:49) (offset:59)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: num
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final a
              firstFragment: #F6
              type: int
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_explicitType_interface_nullable() async {
    var library = await buildLibrary('''
class A {
  A(num? a);
}

class B extends A {
  B(int? super.a);
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:19) (firstTokenOffset:14) (offset:19)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class B (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:48) (offset:48)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 48
              formalParameters
                #F6 super.a (nameOffset:61) (firstTokenOffset:50) (offset:61)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: num?
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final a
              firstFragment: #F6
              type: int?
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_invalid_topFunction() async {
    var library = await buildLibrary('''
void f(super.a) {}
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
            #F2 super.a (nameOffset:13) (firstTokenOffset:7) (offset:13)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional final hasImplicitType a
          firstFragment: #F2
          type: dynamic
      returnType: void
''');
  }

  test_class_constructor_parameters_super_optionalNamed() async {
    var library = await buildLibrary('''
class A {
  A({required int a, required double b});
}

class B extends A {
  B({String o1, super.a, String o2, super.b}) : super();
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:28) (firstTokenOffset:15) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 b (nameOffset:47) (firstTokenOffset:31) (offset:47)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
        #F5 class B (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::B
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 77
              formalParameters
                #F7 o1 (nameOffset:87) (firstTokenOffset:80) (offset:87)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o1
                #F8 super.a (nameOffset:97) (firstTokenOffset:91) (offset:97)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
                #F9 o2 (nameOffset:107) (firstTokenOffset:100) (offset:107)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o2
                #F10 super.b (nameOffset:117) (firstTokenOffset:111) (offset:117)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredNamed a
              firstFragment: #F3
              type: int
            #E1 requiredNamed b
              firstFragment: #F4
              type: double
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 optionalNamed o1
              firstFragment: #F7
              type: String
            #E3 optionalNamed final hasImplicitType a
              firstFragment: #F8
              type: int
            #E4 optionalNamed o2
              firstFragment: #F9
              type: String
            #E5 optionalNamed final hasImplicitType b
              firstFragment: #F10
              type: double
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_optionalNamed_defaultValue() async {
    var library = await buildLibrary('''
class A {
  A({int a = 0});
}

class B extends A {
  B({super.a});
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:19) (firstTokenOffset:15) (offset:19)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
        #F4 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 53
              formalParameters
                #F6 super.a (nameOffset:62) (firstTokenOffset:56) (offset:62)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 optionalNamed a
              firstFragment: #F3
              type: int
              constantInitializer
                fragment: #F3
                expression: expression_0
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed final hasImplicitType a
              firstFragment: #F6
              type: int
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_optionalNamed_unresolved() async {
    var library = await buildLibrary('''
class A {
  A({required int a});
}

class B extends A {
  B({super.b});
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:28) (firstTokenOffset:15) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class B (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 58
              formalParameters
                #F6 super.b (nameOffset:67) (firstTokenOffset:61) (offset:67)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredNamed a
              firstFragment: #F3
              type: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed final hasImplicitType b
              firstFragment: #F6
              type: dynamic
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_optionalNamed_unresolved2() async {
    var library = await buildLibrary('''
class A {
  A(int a);
}

class B extends A {
  B({super.a});
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:47) (offset:47)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 47
              formalParameters
                #F6 super.a (nameOffset:56) (firstTokenOffset:50) (offset:56)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed final hasImplicitType a
              firstFragment: #F6
              type: dynamic
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_optionalPositional() async {
    var library = await buildLibrary('''
class A {
  A(int a, double b);
}

class B extends A {
  B([String o1, super.a, String o2, super.b]) : super();
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 b (nameOffset:28) (firstTokenOffset:21) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
        #F5 class B (nameOffset:41) (firstTokenOffset:35) (offset:41)
          element: <testLibrary>::@class::B
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 57
              formalParameters
                #F7 o1 (nameOffset:67) (firstTokenOffset:60) (offset:67)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o1
                #F8 super.a (nameOffset:77) (firstTokenOffset:71) (offset:77)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
                #F9 o2 (nameOffset:87) (firstTokenOffset:80) (offset:87)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o2
                #F10 super.b (nameOffset:97) (firstTokenOffset:91) (offset:97)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
            #E1 requiredPositional b
              firstFragment: #F4
              type: double
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 optionalPositional o1
              firstFragment: #F7
              type: String
            #E3 optionalPositional final hasImplicitType a
              firstFragment: #F8
              type: int
            #E4 optionalPositional o2
              firstFragment: #F9
              type: String
            #E5 optionalPositional final hasImplicitType b
              firstFragment: #F10
              type: double
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredNamed() async {
    var library = await buildLibrary('''
class A {
  A({required int a, required double b});
}

class B extends A {
  B({
    required String o1,
    required super.a,
    required String o2,
    required super.b,
  }) : super();
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:28) (firstTokenOffset:15) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 b (nameOffset:47) (firstTokenOffset:31) (offset:47)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
        #F5 class B (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::B
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 77
              formalParameters
                #F7 o1 (nameOffset:101) (firstTokenOffset:85) (offset:101)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o1
                #F8 super.a (nameOffset:124) (firstTokenOffset:109) (offset:124)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
                #F9 o2 (nameOffset:147) (firstTokenOffset:131) (offset:147)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o2
                #F10 super.b (nameOffset:170) (firstTokenOffset:155) (offset:170)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredNamed a
              firstFragment: #F3
              type: int
            #E1 requiredNamed b
              firstFragment: #F4
              type: double
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 requiredNamed o1
              firstFragment: #F7
              type: String
            #E3 requiredNamed final hasImplicitType a
              firstFragment: #F8
              type: int
            #E4 requiredNamed o2
              firstFragment: #F9
              type: String
            #E5 requiredNamed final hasImplicitType b
              firstFragment: #F10
              type: double
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredNamed_defaultValue() async {
    var library = await buildLibrary('''
class A {
  A({int a = 0});
}

class B extends A {
  B({required super.a});
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:19) (firstTokenOffset:15) (offset:19)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
        #F4 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 53
              formalParameters
                #F6 super.a (nameOffset:71) (firstTokenOffset:56) (offset:71)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 optionalNamed a
              firstFragment: #F3
              type: int
              constantInitializer
                fragment: #F3
                expression: expression_0
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredNamed final hasImplicitType a
              firstFragment: #F6
              type: int
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredPositional() async {
    var library = await buildLibrary('''
class A {
  A(int a, double b);
}

class B extends A {
  B(String o1, super.a, String o2, super.b) : super();
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 b (nameOffset:28) (firstTokenOffset:21) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
        #F5 class B (nameOffset:41) (firstTokenOffset:35) (offset:41)
          element: <testLibrary>::@class::B
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 57
              formalParameters
                #F7 o1 (nameOffset:66) (firstTokenOffset:59) (offset:66)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o1
                #F8 super.a (nameOffset:76) (firstTokenOffset:70) (offset:76)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
                #F9 o2 (nameOffset:86) (firstTokenOffset:79) (offset:86)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::o2
                #F10 super.b (nameOffset:96) (firstTokenOffset:90) (offset:96)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
            #E1 requiredPositional b
              firstFragment: #F4
              type: double
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional o1
              firstFragment: #F7
              type: String
            #E3 requiredPositional final hasImplicitType a
              firstFragment: #F8
              type: int
            #E4 requiredPositional o2
              firstFragment: #F9
              type: String
            #E5 requiredPositional final hasImplicitType b
              firstFragment: #F10
              type: double
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredPositional_inferenceOrder() async {
    // It is important that `B` is declared after `C`, so that we check that
    // inference happens in order - first `B`, then `C`.
    var library = await buildLibrary('''
abstract class A {
  A(int a);
}

class C extends B {
  C(super.a);
}

class B extends A {
  B(super.a);
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
              formalParameters
                #F3 a (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class C (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::C
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 56
              formalParameters
                #F6 super.a (nameOffset:64) (firstTokenOffset:58) (offset:64)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
        #F7 class B (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::B
          constructors
            #F8 new (nameOffset:<null>) (firstTokenOffset:93) (offset:93)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 93
              formalParameters
                #F9 super.a (nameOffset:101) (firstTokenOffset:95) (offset:101)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: B
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType a
              firstFragment: #F6
              type: int
          superConstructor: <testLibrary>::@class::B::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          formalParameters
            #E2 requiredPositional final hasImplicitType a
              firstFragment: #F9
              type: int
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredPositional_inferenceOrder_generic() async {
    // It is important that `C` is declared before `B`, so that we check that
    // inference happens in order - first `B`, then `C`.
    var library = await buildLibrary('''
class A {
  A(int a);
}

class C extends B<String> {
  C(super.a);
}

class B<T> extends A {
  B(super.a);
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class C (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::C
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 55
              formalParameters
                #F6 super.a (nameOffset:63) (firstTokenOffset:57) (offset:63)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
        #F7 class B (nameOffset:76) (firstTokenOffset:70) (offset:76)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:78) (firstTokenOffset:78) (offset:78)
              element: #E0 T
          constructors
            #F9 new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 95
              formalParameters
                #F10 super.a (nameOffset:103) (firstTokenOffset:97) (offset:103)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F3
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: B<String>
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional final hasImplicitType a
              firstFragment: #F6
              type: int
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {T: String}
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E0 T
          firstFragment: #F8
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          formalParameters
            #E3 requiredPositional final hasImplicitType a
              firstFragment: #F10
              type: int
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredPositional_unresolved() async {
    var library = await buildLibrary('''
class A {}

class B extends A {
  B(super.a);
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
        #F3 class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 34
              formalParameters
                #F5 super.a (nameOffset:42) (firstTokenOffset:36) (offset:42)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional final hasImplicitType a
              firstFragment: #F5
              type: dynamic
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_parameters_super_requiredPositional_unresolved2() async {
    var library = await buildLibrary('''
class A {
  A({required int a})
}

class B extends A {
  B(super.a);
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:28) (firstTokenOffset:15) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        #F4 class B (nameOffset:41) (firstTokenOffset:35) (offset:41)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 57
              formalParameters
                #F6 super.a (nameOffset:65) (firstTokenOffset:59) (offset:65)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredNamed a
              firstFragment: #F3
              type: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType a
              firstFragment: #F6
              type: dynamic
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_params() async {
    var library = await buildLibrary('class C { C(x, int y); }');
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 10
              formalParameters
                #F3 x (nameOffset:12) (firstTokenOffset:12) (offset:12)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                #F4 y (nameOffset:19) (firstTokenOffset:15) (offset:19)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::y
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType x
              firstFragment: #F3
              type: dynamic
            #E1 requiredPositional y
              firstFragment: #F4
              type: int
''');
  }

  test_class_constructor_redirected_factory_named() async {
    var library = await buildLibrary('''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named() : super._();
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
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 20
            #F3 _ (nameOffset:39) (firstTokenOffset:37) (offset:39)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 37
              periodOffset: 38
        #F4 class D (nameOffset:52) (firstTokenOffset:46) (offset:52)
          element: <testLibrary>::@class::D
          constructors
            #F5 named (nameOffset:70) (firstTokenOffset:68) (offset:70)
              element: <testLibrary>::@class::D::@constructor::named
              typeName: D
              typeNameOffset: 68
              periodOffset: 69
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: <testLibrary>::@class::D::@constructor::named
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      supertype: C
      constructors
        named
          reference: <testLibrary>::@class::D::@constructor::named
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::C::@constructor::_
''');
  }

  test_class_constructor_redirected_factory_named_generic() async {
    var library = await buildLibrary('''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named() : super._();
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:18) (offset:26)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 26
            #F5 _ (nameOffset:51) (firstTokenOffset:49) (offset:51)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 49
              periodOffset: 50
        #F6 class D (nameOffset:64) (firstTokenOffset:58) (offset:64)
          element: <testLibrary>::@class::D
          typeParameters
            #F7 T (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: #E2 T
            #F8 U (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: #E3 U
          constructors
            #F9 named (nameOffset:94) (firstTokenOffset:92) (offset:94)
              element: <testLibrary>::@class::D::@constructor::named
              typeName: D
              typeNameOffset: 92
              periodOffset: 93
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::D::@constructor::named
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      typeParameters
        #E2 T
          firstFragment: #F7
        #E3 U
          firstFragment: #F8
      supertype: C<U, T>
      constructors
        named
          reference: <testLibrary>::@class::D::@constructor::named
          firstFragment: #F9
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::C::@constructor::_
            substitution: {T: U, U: T}
''');
  }

  test_class_constructor_redirected_factory_named_generic_inference() async {
    var library = await buildLibrary('''
class A<T, U> implements B<T, U> {
  A.named();
}

class B<T2, U2> {
  factory B() = A.named;
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 named (nameOffset:39) (firstTokenOffset:37) (offset:39)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 37
              periodOffset: 38
        #F5 class B (nameOffset:57) (firstTokenOffset:51) (offset:57)
          element: <testLibrary>::@class::B
          typeParameters
            #F6 T2 (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E2 T2
            #F7 U2 (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: #E3 U2
          constructors
            #F8 factory new (nameOffset:<null>) (firstTokenOffset:71) (offset:79)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 79
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      interfaces
        B<T, U>
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F4
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      typeParameters
        #E2 T2
          firstFragment: #F6
        #E3 U2
          firstFragment: #F7
      constructors
        factory new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::named
            substitution: {T: T2, U: U2}
''');
  }

  test_class_constructor_redirected_factory_named_generic_viaTypeAlias() async {
    var library = await buildLibrary('''
typedef A<T, U> = C<T, U>;
class B<T, U> {
  factory B() = A<U, T>.named;
  B._();
}
class C<T, U> extends A<U, T> {
  C.named() : super._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: #E0 T
            #F3 U (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:45) (offset:53)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 53
            #F5 _ (nameOffset:78) (firstTokenOffset:76) (offset:78)
              element: <testLibrary>::@class::B::@constructor::_
              typeName: B
              typeNameOffset: 76
              periodOffset: 77
        #F6 class C (nameOffset:91) (firstTokenOffset:85) (offset:91)
          element: <testLibrary>::@class::C
          typeParameters
            #F7 T (nameOffset:93) (firstTokenOffset:93) (offset:93)
              element: #E2 T
            #F8 U (nameOffset:96) (firstTokenOffset:96) (offset:96)
              element: #E3 U
          constructors
            #F9 named (nameOffset:121) (firstTokenOffset:119) (offset:121)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 119
              periodOffset: 120
      typeAliases
        #F10 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F11 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E4 T
            #F12 U (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: #E5 U
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::C::@constructor::named
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::B::@constructor::_
          firstFragment: #F5
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F6
      typeParameters
        #E2 T
          firstFragment: #F7
        #E3 U
          firstFragment: #F8
      constructors
        named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F9
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F10
      typeParameters
        #E4 T
          firstFragment: #F11
        #E5 U
          firstFragment: #F12
      aliasedType: C<T, U>
''');
  }

  test_class_constructor_redirected_factory_named_imported() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:31) (offset:39)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 39
            #F3 _ (nameOffset:58) (firstTokenOffset:56) (offset:58)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 56
              periodOffset: 57
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: package:test/foo.dart::@class::D::@constructor::named
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_named_imported_generic() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: #E0 T
            #F3 U (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:37) (offset:45)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 45
            #F5 _ (nameOffset:70) (firstTokenOffset:68) (offset:70)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 68
              periodOffset: 69
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: package:test/foo.dart::@class::D::@constructor::named
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
''');
  }

  test_class_constructor_redirected_factory_named_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:38) (offset:46)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 46
            #F3 _ (nameOffset:69) (firstTokenOffset:67) (offset:69)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 67
              periodOffset: 68
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: package:test/foo.dart::@class::D::@constructor::named
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_named_prefixed_generic() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E0 T
            #F3 U (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:44) (offset:52)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 52
            #F5 _ (nameOffset:81) (firstTokenOffset:79) (offset:81)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 79
              periodOffset: 80
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: package:test/foo.dart::@class::D::@constructor::named
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
''');
  }

  test_class_constructor_redirected_factory_named_unresolved_class() async {
    var library = await buildLibrary('''
class C<E> {
  factory C() = D.named<E>;
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
            #F2 E (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 E
          constructors
            #F3 factory new (nameOffset:<null>) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 23
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_named_unresolved_constructor() async {
    var library = await buildLibrary('''
class D {}
class C<E> {
  factory C() = D.named<E>;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class D (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::D
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F3 class C (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::C
          typeParameters
            #F4 E (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: #E0 E
          constructors
            #F5 factory new (nameOffset:<null>) (firstTokenOffset:26) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 34
  classes
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F2
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      typeParameters
        #E0 E
          firstFragment: #F4
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_class_constructor_redirected_factory_unnamed() async {
    var library = await buildLibrary('''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D() : super._();
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
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 20
            #F3 _ (nameOffset:33) (firstTokenOffset:31) (offset:33)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 31
              periodOffset: 32
        #F4 class D (nameOffset:46) (firstTokenOffset:40) (offset:46)
          element: <testLibrary>::@class::D
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:62) (offset:62)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
              typeNameOffset: 62
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: <testLibrary>::@class::D::@constructor::new
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      supertype: C
      constructors
        new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::C::@constructor::_
''');
  }

  test_class_constructor_redirected_factory_unnamed_generic() async {
    var library = await buildLibrary('''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D() : super._();
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:18) (offset:26)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 26
            #F5 _ (nameOffset:45) (firstTokenOffset:43) (offset:45)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 43
              periodOffset: 44
        #F6 class D (nameOffset:58) (firstTokenOffset:52) (offset:58)
          element: <testLibrary>::@class::D
          typeParameters
            #F7 T (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: #E2 T
            #F8 U (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: #E3 U
          constructors
            #F9 new (nameOffset:<null>) (firstTokenOffset:86) (offset:86)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
              typeNameOffset: 86
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::D::@constructor::new
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      typeParameters
        #E2 T
          firstFragment: #F7
        #E3 U
          firstFragment: #F8
      supertype: C<U, T>
      constructors
        new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::C::@constructor::_
            substitution: {T: U, U: T}
''');
  }

  test_class_constructor_redirected_factory_unnamed_generic_inference() async {
    var library = await buildLibrary('''
class A<T, U> implements B<T, U> {
  A();
}

class B<T2, U2> {
  factory B() = A;
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 37
        #F5 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          typeParameters
            #F6 T2 (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: #E2 T2
            #F7 U2 (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E3 U2
          constructors
            #F8 factory new (nameOffset:<null>) (firstTokenOffset:65) (offset:73)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 73
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      interfaces
        B<T, U>
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      typeParameters
        #E2 T2
          firstFragment: #F6
        #E3 U2
          firstFragment: #F7
      constructors
        factory new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: T2, U: U2}
''');
  }

  test_class_constructor_redirected_factory_unnamed_generic_inference_self() async {
    var library = await buildLibrary('''
class A<T> {
  A();
  factory A.redirected() = A;
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
            #F3 new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 15
            #F4 factory redirected (nameOffset:32) (firstTokenOffset:22) (offset:32)
              element: <testLibrary>::@class::A::@constructor::redirected
              typeName: A
              typeNameOffset: 30
              periodOffset: 31
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
        factory redirected
          reference: <testLibrary>::@class::A::@constructor::redirected
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: T}
''');
  }

  test_class_constructor_redirected_factory_unnamed_generic_viaTypeAlias() async {
    var library = await buildLibrary('''
typedef A<T, U> = C<T, U>;
class B<T, U> {
  factory B() = A<U, T>;
  B_();
}
class C<T, U> extends B<U, T> {
  C() : super._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: #E0 T
            #F3 U (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:45) (offset:53)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 53
          methods
            #F5 B_ (nameOffset:70) (firstTokenOffset:70) (offset:70)
              element: <testLibrary>::@class::B::@method::B_
        #F6 class C (nameOffset:84) (firstTokenOffset:78) (offset:84)
          element: <testLibrary>::@class::C
          typeParameters
            #F7 T (nameOffset:86) (firstTokenOffset:86) (offset:86)
              element: #E2 T
            #F8 U (nameOffset:89) (firstTokenOffset:89) (offset:89)
              element: #E3 U
          constructors
            #F9 new (nameOffset:<null>) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 112
      typeAliases
        #F10 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F11 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E4 T
            #F12 U (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: #E5 U
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::C::@constructor::new
            substitution: {T: U, U: T}
      methods
        abstract B_
          reference: <testLibrary>::@class::B::@method::B_
          firstFragment: #F5
          returnType: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F6
      typeParameters
        #E2 T
          firstFragment: #F7
        #E3 U
          firstFragment: #F8
      supertype: B<U, T>
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F9
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F10
      typeParameters
        #E4 T
          firstFragment: #F11
        #E5 U
          firstFragment: #F12
      aliasedType: C<T, U>
''');
  }

  test_class_constructor_redirected_factory_unnamed_imported() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:31) (offset:39)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 39
            #F3 _ (nameOffset:52) (firstTokenOffset:50) (offset:52)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 50
              periodOffset: 51
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: package:test/foo.dart::@class::D::@constructor::new
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_unnamed_imported_generic() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: #E0 T
            #F3 U (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:37) (offset:45)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 45
            #F5 _ (nameOffset:64) (firstTokenOffset:62) (offset:64)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 62
              periodOffset: 63
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: package:test/foo.dart::@class::D::@constructor::new
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
''');
  }

  test_class_constructor_redirected_factory_unnamed_imported_viaTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
typedef A = B;
class B extends C {
  B() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart';
class C {
  factory C() = A;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:31) (offset:39)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 39
            #F3 _ (nameOffset:52) (firstTokenOffset:50) (offset:52)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 50
              periodOffset: 51
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: package:test/foo.dart::@class::B::@constructor::new
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_unnamed_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:38) (offset:46)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 46
            #F3 _ (nameOffset:63) (firstTokenOffset:61) (offset:63)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 61
              periodOffset: 62
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: package:test/foo.dart::@class::D::@constructor::new
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_unnamed_prefixed_generic() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E0 T
            #F3 U (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E1 U
          constructors
            #F4 factory new (nameOffset:<null>) (firstTokenOffset:44) (offset:52)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 52
            #F5 _ (nameOffset:75) (firstTokenOffset:73) (offset:75)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 73
              periodOffset: 74
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          redirectedConstructor: ConstructorMember
            baseElement: package:test/foo.dart::@class::D::@constructor::new
            substitution: {T: U, U: T}
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
''');
  }

  test_class_constructor_redirected_factory_unnamed_prefixed_viaTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', '''
import 'test.dart';
typedef A = B;
class B extends C {
  B() : super._();
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.A;
  C._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:38) (offset:46)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 46
            #F3 _ (nameOffset:63) (firstTokenOffset:61) (offset:63)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 61
              periodOffset: 62
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: package:test/foo.dart::@class::B::@constructor::new
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_unnamed_unresolved() async {
    var library = await buildLibrary('''
class C<E> {
  factory C() = D<E>;
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
            #F2 E (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 E
          constructors
            #F3 factory new (nameOffset:<null>) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 23
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 E
          firstFragment: #F2
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_constructor_redirected_factory_unnamed_viaTypeAlias() async {
    var library = await buildLibrary('''
typedef A = C;
class B {
  factory B() = A;
  B._();
}
class C extends B {
  C() : super._();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::B
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:27) (offset:35)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 35
            #F3 _ (nameOffset:48) (firstTokenOffset:46) (offset:48)
              element: <testLibrary>::@class::B::@constructor::_
              typeName: B
              typeNameOffset: 46
              periodOffset: 47
        #F4 class C (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::C
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:77) (offset:77)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 77
      typeAliases
        #F6 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          redirectedConstructor: <testLibrary>::@class::C::@constructor::new
        _
          reference: <testLibrary>::@class::B::@constructor::_
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: B
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::B::@constructor::_
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F6
      aliasedType: C
''');
  }

  test_class_constructor_redirected_thisInvocation_named() async {
    var library = await buildLibrary('''
class C {
  const C.named();
  const C() : this.named();
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
            #F2 const named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 18
              periodOffset: 19
            #F3 const new (nameOffset:<null>) (firstTokenOffset:31) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 37
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F2
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @43
              period: . @47
              constructorName: SimpleIdentifier
                token: named @48
                element: <testLibrary>::@class::C::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @53
                rightParenthesis: ) @54
              element: <testLibrary>::@class::C::@constructor::named
          redirectedConstructor: <testLibrary>::@class::C::@constructor::named
''');
  }

  test_class_constructor_redirected_thisInvocation_named_generic() async {
    var library = await buildLibrary('''
class C<T> {
  const C.named();
  const C() : this.named();
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
          constructors
            #F3 const named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 21
              periodOffset: 22
            #F4 const new (nameOffset:<null>) (firstTokenOffset:34) (offset:40)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 40
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F3
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @46
              period: . @50
              constructorName: SimpleIdentifier
                token: named @51
                element: <testLibrary>::@class::C::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @56
                rightParenthesis: ) @57
              element: <testLibrary>::@class::C::@constructor::named
          redirectedConstructor: <testLibrary>::@class::C::@constructor::named
''');
  }

  test_class_constructor_redirected_thisInvocation_named_notConst() async {
    var library = await buildLibrary('''
class C {
  C.named();
  C() : this.named();
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
            #F2 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 12
              periodOffset: 13
            #F3 new (nameOffset:<null>) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 25
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F2
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          redirectedConstructor: <testLibrary>::@class::C::@constructor::named
''');
  }

  test_class_constructor_redirected_thisInvocation_unnamed() async {
    var library = await buildLibrary('''
class C {
  const C();
  const C.named() : this();
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 18
            #F3 const named (nameOffset:33) (firstTokenOffset:25) (offset:33)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 31
              periodOffset: 32
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F3
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @43
              argumentList: ArgumentList
                leftParenthesis: ( @47
                rightParenthesis: ) @48
              element: <testLibrary>::@class::C::@constructor::new
          redirectedConstructor: <testLibrary>::@class::C::@constructor::new
''');
  }

  test_class_constructor_redirected_thisInvocation_unnamed_generic() async {
    var library = await buildLibrary('''
class C<T> {
  const C();
  const C.named() : this();
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
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 21
            #F4 const named (nameOffset:36) (firstTokenOffset:28) (offset:36)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 34
              periodOffset: 35
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F4
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @46
              argumentList: ArgumentList
                leftParenthesis: ( @50
                rightParenthesis: ) @51
              element: <testLibrary>::@class::C::@constructor::new
          redirectedConstructor: <testLibrary>::@class::C::@constructor::new
''');
  }

  test_class_constructor_redirected_thisInvocation_unnamed_notConst() async {
    var library = await buildLibrary('''
class C {
  C();
  C.named() : this();
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 12
            #F3 named (nameOffset:21) (firstTokenOffset:19) (offset:21)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 19
              periodOffset: 20
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
        named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F3
          redirectedConstructor: <testLibrary>::@class::C::@constructor::new
''');
  }

  test_class_constructor_redirectedConstructor_generic01() async {
    // Note, this code has compile-time errors.
    // `A` returned  by the redirected constructor is not `B<U>`.
    // But we still have some element model.
    var library = await buildLibrary(r'''
class A implements B<int> {}

class B<U> implements C<U> {
  factory B() = A;
}

class C<V> {
  factory C() = B<V>;
}
''');

    configuration
      ..forClassConstructors(classNames: {'C'})
      ..elementPrinterConfiguration.withRedirectedConstructors = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:87) (firstTokenOffset:81) (offset:87)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:96) (offset:104)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 104
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {U: V}
            redirectedConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_redirectedConstructor_generic11() async {
    var library = await buildLibrary(r'''
class A<T> implements B<T> {}

class B<U> implements C<U> {
  factory B() = A<U>;
}

class C<V> {
  factory C() = B<V>;
}
''');

    configuration
      ..forClassConstructors(classNames: {'C'})
      ..elementPrinterConfiguration.withRedirectedConstructors = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:91) (firstTokenOffset:85) (offset:91)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:100) (offset:108)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 108
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          redirectedConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {U: V}
            redirectedConstructor: ConstructorMember
              baseElement: <testLibrary>::@class::A::@constructor::new
              substitution: {T: V}
              redirectedConstructor: <null>
''');
  }

  test_class_constructor_superConstructor_generic01() async {
    var library = await buildLibrary(r'''
class A {}
class B<U> extends A {}
class C extends B<int> {}
''');

    configuration
      ..forClassConstructors(classNames: {'C'})
      ..elementPrinterConfiguration.withSuperConstructors = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:41) (firstTokenOffset:35) (offset:41)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: B<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {U: int}
            superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_superConstructor_generic11() async {
    var library = await buildLibrary(r'''
class A<T> {}
class B<U> extends A<String> {}
class C extends B<int> {}
''');

    configuration
      ..forClassConstructors(classNames: {'C'})
      ..elementPrinterConfiguration.withSuperConstructors = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:52) (firstTokenOffset:46) (offset:52)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: B<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {U: int}
            superConstructor: ConstructorMember
              baseElement: <testLibrary>::@class::A::@constructor::new
              substitution: {T: String}
              superConstructor: dart:core::@class::Object::@constructor::new
''');
  }

  test_class_constructor_superConstructor_generic_named() async {
    var library = await buildLibrary('''
class A<T> {
  A.named(T a);
}
class B extends A<int> {
  B() : super.named(0);
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
            #F3 named (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F4 a (nameOffset:25) (firstTokenOffset:23) (offset:25)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
        #F5 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 58
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F4
              type: T
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A<int>
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::named
            substitution: {T: int}
''');
  }

  test_class_constructor_superConstructor_notGeneric_named() async {
    var library = await buildLibrary('''
class A {
  A.named();
}
class B extends A {
  B() : super.named();
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
            #F2 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F3 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:47) (offset:47)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 47
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::named
''');
  }

  test_class_constructor_superConstructor_notGeneric_unnamed_explicit() async {
    var library = await buildLibrary('''
class A {}
class B extends A {
  B() : super();
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
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 33
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_superConstructor_notGeneric_unnamed_implicit() async {
    var library = await buildLibrary('''
class A {}
class B extends A {
  B();
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
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 33
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_superConstructor_notGeneric_unnamed_implicit2() async {
    var library = await buildLibrary('''
class A {}
class B extends A {}
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
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_unnamed_implicit() async {
    var library = await buildLibrary('class C {}');
    configuration.withDisplayName = true;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructor_withCycles_const() async {
    var library = await buildLibrary('''
class C {
  final x;
  const C() : x = const D();
}
class D {
  final x;
  const D() : x = const C();
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:23) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
        #F5 class D (nameOffset:58) (firstTokenOffset:52) (offset:58)
          element: <testLibrary>::@class::D
          fields
            #F6 x (nameOffset:70) (firstTokenOffset:70) (offset:70)
              element: <testLibrary>::@class::D::@field::x
          constructors
            #F7 const new (nameOffset:<null>) (firstTokenOffset:75) (offset:81)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
              typeNameOffset: 81
          getters
            #F8 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::D::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @35
                element: <testLibrary>::@class::C::@field::x
                staticType: null
              equals: = @37
              expression: InstanceCreationExpression
                keyword: const @39
                constructorName: ConstructorName
                  type: NamedType
                    name: D @45
                    element2: <testLibrary>::@class::D
                    type: D
                  element: <testLibrary>::@class::D::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @46
                  rightParenthesis: ) @47
                staticType: D
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      fields
        final x
          reference: <testLibrary>::@class::D::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@class::D::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @87
                element: <testLibrary>::@class::D::@field::x
                staticType: null
              equals: = @89
              expression: InstanceCreationExpression
                keyword: const @91
                constructorName: ConstructorName
                  type: NamedType
                    name: C @97
                    element2: <testLibrary>::@class::C
                    type: C
                  element: <testLibrary>::@class::C::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @98
                  rightParenthesis: ) @99
                staticType: C
      getters
        synthetic x
          reference: <testLibrary>::@class::D::@getter::x
          firstFragment: #F8
          returnType: dynamic
          variable: <testLibrary>::@class::D::@field::x
''');
  }

  test_class_constructor_withCycles_nonConst() async {
    var library = await buildLibrary('''
class C {
  final x;
  C() : x = new D();
}
class D {
  final x;
  D() : x = new C();
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
            #F2 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 23
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
        #F5 class D (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::D
          fields
            #F6 x (nameOffset:62) (firstTokenOffset:62) (offset:62)
              element: <testLibrary>::@class::D::@field::x
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
              typeNameOffset: 67
          getters
            #F8 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::D::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      fields
        final x
          reference: <testLibrary>::@class::D::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@class::D::@getter::x
      constructors
        new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
      getters
        synthetic x
          reference: <testLibrary>::@class::D::@getter::x
          firstFragment: #F8
          returnType: dynamic
          variable: <testLibrary>::@class::D::@field::x
''');
  }

  test_class_constructors_named() async {
    var library = await buildLibrary('''
class C {
  C.foo();
}
''');
    configuration.withDisplayName = true;
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
            #F2 foo (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::C::@constructor::foo
              typeName: C
              typeNameOffset: 12
              periodOffset: 13
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        foo
          reference: <testLibrary>::@class::C::@constructor::foo
          firstFragment: #F2
''');
  }

  test_class_constructors_unnamed() async {
    var library = await buildLibrary('''
class C {
  C();
}
''');
    configuration.withDisplayName = true;
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 12
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_constructors_unnamed_new() async {
    var library = await buildLibrary('''
class C {
  C.new();
}
''');
    configuration.withDisplayName = true;
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
            #F2 new (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 12
              periodOffset: 13
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_cycle_interfaces() async {
    var library = await buildLibrary(r'''
class A implements B {}
class B implements A {}
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
        #F3 class B (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_cycle_mixins() async {
    var library = await buildLibrary(r'''
class A with B {}
class B with A {}
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
        #F3 class B (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_cycle_supertype() async {
    var library = await buildLibrary(r'''
class A extends B {}
class B extends A {}
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
        #F3 class B (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_documented() async {
    var library = await buildLibrary('''
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:0) (offset:22)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_documented_mix() async {
    var library = await buildLibrary('''
/**
 * aaa
 */
/**
 * bbb
 */
class A {}

/**
 * aaa
 */
/// bbb
/// ccc
class B {}

/// aaa
/// bbb
/**
 * ccc
 */
class C {}

/// aaa
/// bbb
/**
 * ccc
 */
/// ddd
class D {}

/**
 * aaa
 */
// bbb
class E {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:36) (firstTokenOffset:15) (offset:36)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:79) (firstTokenOffset:57) (offset:79)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C (nameOffset:122) (firstTokenOffset:101) (offset:122)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:122)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F7 class D (nameOffset:173) (firstTokenOffset:159) (offset:173)
          element: <testLibrary>::@class::D
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:173)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F9 class E (nameOffset:207) (firstTokenOffset:179) (offset:207)
          element: <testLibrary>::@class::E
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:207)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      documentationComment: /**\n * bbb\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      documentationComment: /// bbb\n/// ccc
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      documentationComment: /**\n * ccc\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      documentationComment: /// ddd
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F9
      documentationComment: /**\n * aaa\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F10
''');
  }

  test_class_documented_tripleSlash() async {
    var library = await buildLibrary('''
/// first
/// second
/// third
class C {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:37) (firstTokenOffset:0) (offset:37)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /// first\n/// second\n/// third
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_documented_with_references() async {
    var library = await buildLibrary('''
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:47) (firstTokenOffset:0) (offset:47)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /**\n * Docs referring to [D] and [E]\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_documented_with_windows_line_endings() async {
    var library = await buildLibrary('/**\r\n * Docs\r\n */\r\nclass C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:0) (offset:25)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_documented_withLeadingNotDocumentation() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:66) (firstTokenOffset:44) (offset:66)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_documented_withMetadata() async {
    var library = await buildLibrary('''
/// Comment 1
/// Comment 2
@Annotation()
class BeforeMeta {}

/// Comment 1
/// Comment 2
@Annotation.named()
class BeforeMetaNamed {}

@Annotation()
/// Comment 1
/// Comment 2
class AfterMeta {}

/// Comment 1
@Annotation()
/// Comment 2
class AroundMeta {}

/// Doc comment.
@Annotation()
// Not doc comment.
class DocBeforeMetaNotDocAfter {}

class Annotation {
  const Annotation();
  const Annotation.named();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class BeforeMeta (nameOffset:48) (firstTokenOffset:0) (offset:48)
          element: <testLibrary>::@class::BeforeMeta
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::BeforeMeta::@constructor::new
              typeName: BeforeMeta
        #F3 class BeforeMetaNamed (nameOffset:117) (firstTokenOffset:63) (offset:117)
          element: <testLibrary>::@class::BeforeMetaNamed
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:117)
              element: <testLibrary>::@class::BeforeMetaNamed::@constructor::new
              typeName: BeforeMetaNamed
        #F5 class AfterMeta (nameOffset:185) (firstTokenOffset:137) (offset:185)
          element: <testLibrary>::@class::AfterMeta
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:185)
              element: <testLibrary>::@class::AfterMeta::@constructor::new
              typeName: AfterMeta
        #F7 class AroundMeta (nameOffset:247) (firstTokenOffset:213) (offset:247)
          element: <testLibrary>::@class::AroundMeta
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:247)
              element: <testLibrary>::@class::AroundMeta::@constructor::new
              typeName: AroundMeta
        #F9 class DocBeforeMetaNotDocAfter (nameOffset:319) (firstTokenOffset:262) (offset:319)
          element: <testLibrary>::@class::DocBeforeMetaNotDocAfter
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:319)
              element: <testLibrary>::@class::DocBeforeMetaNotDocAfter::@constructor::new
              typeName: DocBeforeMetaNotDocAfter
        #F11 class Annotation (nameOffset:354) (firstTokenOffset:348) (offset:354)
          element: <testLibrary>::@class::Annotation
          constructors
            #F12 const new (nameOffset:<null>) (firstTokenOffset:369) (offset:375)
              element: <testLibrary>::@class::Annotation::@constructor::new
              typeName: Annotation
              typeNameOffset: 375
            #F13 const named (nameOffset:408) (firstTokenOffset:391) (offset:408)
              element: <testLibrary>::@class::Annotation::@constructor::named
              typeName: Annotation
              typeNameOffset: 397
              periodOffset: 407
  classes
    class BeforeMeta
      reference: <testLibrary>::@class::BeforeMeta
      firstFragment: #F1
      documentationComment: /// Comment 1\n/// Comment 2
      constructors
        synthetic new
          reference: <testLibrary>::@class::BeforeMeta::@constructor::new
          firstFragment: #F2
    class BeforeMetaNamed
      reference: <testLibrary>::@class::BeforeMetaNamed
      firstFragment: #F3
      documentationComment: /// Comment 1\n/// Comment 2
      constructors
        synthetic new
          reference: <testLibrary>::@class::BeforeMetaNamed::@constructor::new
          firstFragment: #F4
    class AfterMeta
      reference: <testLibrary>::@class::AfterMeta
      firstFragment: #F5
      documentationComment: /// Comment 1\n/// Comment 2
      constructors
        synthetic new
          reference: <testLibrary>::@class::AfterMeta::@constructor::new
          firstFragment: #F6
    class AroundMeta
      reference: <testLibrary>::@class::AroundMeta
      firstFragment: #F7
      documentationComment: /// Comment 2
      constructors
        synthetic new
          reference: <testLibrary>::@class::AroundMeta::@constructor::new
          firstFragment: #F8
    class DocBeforeMetaNotDocAfter
      reference: <testLibrary>::@class::DocBeforeMetaNotDocAfter
      firstFragment: #F9
      documentationComment: /// Doc comment.
      constructors
        synthetic new
          reference: <testLibrary>::@class::DocBeforeMetaNotDocAfter::@constructor::new
          firstFragment: #F10
    class Annotation
      reference: <testLibrary>::@class::Annotation
      firstFragment: #F11
      constructors
        const new
          reference: <testLibrary>::@class::Annotation::@constructor::new
          firstFragment: #F12
        const named
          reference: <testLibrary>::@class::Annotation::@constructor::named
          firstFragment: #F13
''');
  }

  test_class_field_abstract() async {
    var library = await buildLibrary('''
abstract class C {
  abstract int i;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          fields
            #F2 i (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@class::C::@field::i
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@getter::i
          setters
            #F5 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@setter::i
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::C::@setter::i::@formalParameter::value
  classes
    abstract hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        abstract i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::i
          setter: <testLibrary>::@class::C::@setter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic abstract i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
      setters
        synthetic abstract i
          reference: <testLibrary>::@class::C::@setter::i
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::i
''');
  }

  test_class_field_const() async {
    var library = await buildLibrary('class C { static const int i = 0; }');
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
            #F2 hasInitializer i (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::C::@field::i
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @31
                  staticType: int
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@getter::i
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasInitializer i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
''');
  }

  test_class_field_const_late() async {
    var library = await buildLibrary(
      'class C { static late const int i = 0; }',
    );
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
            #F2 hasInitializer i (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: <testLibrary>::@class::C::@field::i
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @36
                  staticType: int
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@getter::i
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static late const hasInitializer i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
''');
  }

  test_class_field_covariant() async {
    var library = await buildLibrary('''
class C {
  covariant int x;
}''');
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
            #F2 x (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        covariant x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional covariant value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_documented() async {
    var library = await buildLibrary('''
class C {
  /**
   * Docs
   */
  var x;
}''');
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
            #F2 x (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_duplicate_getter() async {
    var library = await buildLibrary('''
class C {
  int foo = 0;
  int get foo => 0;
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
            #F2 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::foo::@def::0
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo::@def::1
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::foo::@def::0
            #F6 foo (nameOffset:35) (firstTokenOffset:27) (offset:35)
              element: <testLibrary>::@class::C::@getter::foo::@def::1
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::C::@field::foo::@def::0
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo::@def::0
          setter: <testLibrary>::@class::C::@setter::foo
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo::@def::1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::C::@getter::foo::@def::1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo::@def::0
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo::@def::0
        foo
          reference: <testLibrary>::@class::C::@getter::foo::@def::1
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo::@def::1
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo::@def::0
''');
  }

  test_class_field_duplicate_setter() async {
    var library = await buildLibrary('''
class C {
  int foo = 0;
  set foo(int _) {}
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
            #F2 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::foo::@def::0
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo::@def::1
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::foo::@def::0
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::foo::@def::0::@formalParameter::value
            #F8 foo (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@class::C::@setter::foo::@def::1
              formalParameters
                #F9 _ (nameOffset:39) (firstTokenOffset:35) (offset:39)
                  element: <testLibrary>::@class::C::@setter::foo::@def::1::@formalParameter::_
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::C::@field::foo::@def::0
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo::@def::0
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo::@def::1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::C::@setter::foo::@def::1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo::@def::0
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo::@def::0
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo::@def::0
        foo
          reference: <testLibrary>::@class::C::@setter::foo::@def::1
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo::@def::1
''');
  }

  test_class_field_external() async {
    var library = await buildLibrary('''
abstract class C {
  external int i;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          fields
            #F2 i (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@class::C::@field::i
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@getter::i
          setters
            #F5 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@setter::i
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::C::@setter::i::@formalParameter::value
  classes
    abstract hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        external i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::i
          setter: <testLibrary>::@class::C::@setter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
      setters
        synthetic i
          reference: <testLibrary>::@class::C::@setter::i
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::i
''');
  }

  test_class_field_final_hasInitializer_hasConstConstructor() async {
    var library = await buildLibrary('''
class C {
  final x = 42;
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
            #F2 hasInitializer x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
              initializer: expression_0
                IntegerLiteral
                  literal: 42 @22
                  staticType: int
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:28) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 34
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_final_hasInitializer_hasConstConstructor_genericFunctionType() async {
    var library = await buildLibrary('''
class A<T> {
  const A();
}
class B {
  final f = const A<int Function(double a)>();
  const B();
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
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
        #F4 class B (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::B
          fields
            #F5 hasInitializer f (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@class::B::@field::f
              initializer: expression_0
                InstanceCreationExpression
                  keyword: const @50
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @56
                      typeArguments: TypeArgumentList
                        leftBracket: < @57
                        arguments
                          GenericFunctionType
                            returnType: NamedType
                              name: int @58
                              element2: dart:core::@class::int
                              type: int
                            functionKeyword: Function @62
                            parameters: FormalParameterList
                              leftParenthesis: ( @70
                              parameter: SimpleFormalParameter
                                type: NamedType
                                  name: double @71
                                  element2: dart:core::@class::double
                                  type: double
                                name: a @78
                                declaredElement: <testLibraryFragment> a@78
                                  element: isPublic
                                    type: double
                              rightParenthesis: ) @79
                            declaredElement: GenericFunctionTypeElement
                              parameters
                                a
                                  kind: required positional
                                  element:
                                    type: double
                              returnType: int
                              type: int Function(double)
                            type: int Function(double)
                        rightBracket: > @80
                      element2: <testLibrary>::@class::A
                      type: A<int Function(double)>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@class::A::@constructor::new
                      substitution: {T: int Function(double)}
                  argumentList: ArgumentList
                    leftParenthesis: ( @81
                    rightParenthesis: ) @82
                  staticType: A<int Function(double)>
          constructors
            #F6 const new (nameOffset:<null>) (firstTokenOffset:87) (offset:93)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 93
          getters
            #F7 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::B::@getter::f
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      fields
        final hasInitializer f
          reference: <testLibrary>::@class::B::@field::f
          firstFragment: #F5
          type: A<int Function(double)>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@class::B::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      getters
        synthetic f
          reference: <testLibrary>::@class::B::@getter::f
          firstFragment: #F7
          returnType: A<int Function(double)>
          variable: <testLibrary>::@class::B::@field::f
''');
  }

  test_class_field_final_hasInitializer_noConstConstructor() async {
    var library = await buildLibrary('''
class C {
  final x = 42;
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
            #F2 hasInitializer x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_final_withSetter() async {
    var library = await buildLibrary(r'''
class A {
  final int foo;
  A(this.foo);
  set foo(int newValue) {}
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
            #F2 foo (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 29
              formalParameters
                #F4 this.foo (nameOffset:36) (firstTokenOffset:31) (offset:36)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F6 foo (nameOffset:48) (firstTokenOffset:44) (offset:48)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 newValue (nameOffset:56) (firstTokenOffset:52) (offset:56)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::newValue
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType foo
              firstFragment: #F4
              type: int
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional newValue
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_class_field_formal_param_inferred_type_implicit() async {
    var library = await buildLibrary(
      'class C extends D { var v; C(this.v); }'
      ' abstract class D { int get v; }',
    );
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
            #F2 v (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 27
              formalParameters
                #F4 this.v (nameOffset:34) (firstTokenOffset:29) (offset:34)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::v
          getters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F6 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
        #F8 class D (nameOffset:55) (firstTokenOffset:40) (offset:55)
          element: <testLibrary>::@class::D
          fields
            #F9 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@class::D::@field::v
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F11 v (nameOffset:67) (firstTokenOffset:59) (offset:67)
              element: <testLibrary>::@class::D::@getter::v
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType v
              firstFragment: #F4
              type: int
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      fields
        synthetic v
          reference: <testLibrary>::@class::D::@field::v
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@class::D::@getter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F10
      getters
        abstract v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::D::@field::v
''');
  }

  test_class_field_implicit_type() async {
    var library = await buildLibrary('class C { var x; }');
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
            #F2 x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_implicit_type_late() async {
    var library = await buildLibrary('class C { late var x; }');
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
            #F2 x (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        late x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_inferred_type_nonStatic_explicit_initialized() async {
    var library = await buildLibrary('class C { num v = 0; }');
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
            #F2 hasInitializer v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: num
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: num
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
''');
  }

  test_class_field_inferred_type_nonStatic_implicit_initialized() async {
    var library = await buildLibrary('class C { var v = 0; }');
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
            #F2 hasInitializer v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
''');
  }

  test_class_field_inferred_type_nonStatic_implicit_uninitialized() async {
    var library = await buildLibrary(
      'class C extends D { var v; } abstract class D { int get v; }',
    );
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
            #F2 v (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
        #F7 class D (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@class::D
          fields
            #F8 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::D::@field::v
          constructors
            #F9 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F10 v (nameOffset:56) (firstTokenOffset:48) (offset:56)
              element: <testLibrary>::@class::D::@getter::v
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      fields
        synthetic v
          reference: <testLibrary>::@class::D::@field::v
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::D::@getter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
      getters
        abstract v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::D::@field::v
''');
  }

  test_class_field_inferred_type_nonStatic_inherited_resolveInitializer() async {
    var library = await buildLibrary(r'''
const a = 0;
abstract class A {
  const A();
  List<int> get f;
}
class B extends A {
  const B();
  final f = [a];
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:28) (firstTokenOffset:13) (offset:28)
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:34) (offset:40)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 40
          getters
            #F4 f (nameOffset:61) (firstTokenOffset:47) (offset:61)
              element: <testLibrary>::@class::A::@getter::f
        #F5 class B (nameOffset:72) (firstTokenOffset:66) (offset:72)
          element: <testLibrary>::@class::B
          fields
            #F6 hasInitializer f (nameOffset:107) (firstTokenOffset:107) (offset:107)
              element: <testLibrary>::@class::B::@field::f
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @111
                  elements
                    SimpleIdentifier
                      token: a @112
                      element: <testLibrary>::@getter::a
                      staticType: int
                  rightBracket: ] @113
                  staticType: List<int>
          constructors
            #F7 const new (nameOffset:<null>) (firstTokenOffset:88) (offset:94)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 94
          getters
            #F8 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:107)
              element: <testLibrary>::@class::B::@getter::f
      topLevelVariables
        #F9 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_1
            IntegerLiteral
              literal: 0 @10
              staticType: int
      getters
        #F10 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: List<int>
          getter: <testLibrary>::@class::A::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: List<int>
          variable: <testLibrary>::@class::A::@field::f
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      fields
        final hasInitializer f
          reference: <testLibrary>::@class::B::@field::f
          firstFragment: #F6
          type: List<int>
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@class::B::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        synthetic f
          reference: <testLibrary>::@class::B::@getter::f
          firstFragment: #F8
          returnType: List<int>
          variable: <testLibrary>::@class::B::@field::f
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_1
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_field_inferred_type_static_implicit_initialized() async {
    var library = await buildLibrary('class C { static var v = 0; }');
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
            #F2 hasInitializer v (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static hasInitializer v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic static v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
''');
  }

  test_class_field_inheritedContextType_double() async {
    var library = await buildLibrary('''
abstract class A {
  const A();
  double get foo;
}
class B extends A {
  const B();
  final foo = 2;
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:21) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
          getters
            #F4 foo (nameOffset:45) (firstTokenOffset:34) (offset:45)
              element: <testLibrary>::@class::A::@getter::foo
        #F5 class B (nameOffset:58) (firstTokenOffset:52) (offset:58)
          element: <testLibrary>::@class::B
          fields
            #F6 hasInitializer foo (nameOffset:93) (firstTokenOffset:93) (offset:93)
              element: <testLibrary>::@class::B::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 2 @99
                  staticType: double
          constructors
            #F7 const new (nameOffset:<null>) (firstTokenOffset:74) (offset:80)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 80
          getters
            #F8 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@class::B::@getter::foo
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: double
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: double
          variable: <testLibrary>::@class::A::@field::foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      fields
        final hasInitializer foo
          reference: <testLibrary>::@class::B::@field::foo
          firstFragment: #F6
          type: double
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@class::B::@getter::foo
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        synthetic foo
          reference: <testLibrary>::@class::B::@getter::foo
          firstFragment: #F8
          returnType: double
          variable: <testLibrary>::@class::B::@field::foo
''');
  }

  test_class_field_isPromotable_abstractGetter() async {
    var library = await buildLibrary(r'''
abstract class A {
  int? get _foo;
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
            #F2 synthetic _foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::_foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 _foo (nameOffset:30) (firstTokenOffset:21) (offset:30)
              element: <testLibrary>::@class::A::@getter::_foo
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract _foo
          reference: <testLibrary>::@class::A::@getter::_foo
          firstFragment: #F4
          returnType: int?
          variable: <testLibrary>::@class::A::@field::_foo
''');
  }

  test_class_field_isPromotable_hasGetter() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  int? get _foo => 0;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingGetters
        <testLibrary>::@class::B::@getter::_foo
''');
  }

  test_class_field_isPromotable_hasGetter_abstract() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

abstract class B {
  int? get _foo;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_hasGetter_inPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class B {
  int? get _foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class A {
  final int? _foo;
  A(this._foo);
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingGetters
        <testLibrary>::@class::B::@getter::_foo
''');
  }

  test_class_field_isPromotable_hasGetter_static() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  static int? get _foo => 0;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_hasNotFinalField() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  int? _foo;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingFields
        <testLibrary>::@class::B::@field::_foo
''');
  }

  test_class_field_isPromotable_hasNotFinalField_static() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  static int? _foo;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_hasSetter() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  set _field(int? _) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_language217() async {
    var library = await buildLibrary(r'''
// @dart = 2.19
class A {
  final int? _foo;
  A(this._foo);
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_field() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  final int? _foo = 0;
}

/// Implicitly implements `_foo` as a getter that forwards to [noSuchMethod].
class C implements B {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingNsmClasses
        <testLibrary>::@class::C
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_field_implementedInMixin() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

mixin M {
  final int? _foo = 0;
}

class B {
  final int? _foo = 0;
}

/// `_foo` is implemented in [M].
class C with M implements B {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(
      classNames: {'A', 'B'},
      mixinNames: {'M'},
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      fields
        final promotable hasInitializer _foo
          reference: <testLibrary>::@class::B::@field::_foo
          firstFragment: #F3
          type: int?
          getter: <testLibrary>::@class::B::@getter::_foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F4
      superclassConstraints
        Object
      fields
        final promotable hasInitializer _foo
          reference: <testLibrary>::@mixin::M::@field::_foo
          firstFragment: #F5
          type: int?
          getter: <testLibrary>::@mixin::M::@getter::_foo
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_field_implementedInSuperclass() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  final int? _foo = 0;
}

class C {
  final int? _foo = 0;
}

/// `_foo` is implemented in [B].
class D extends B implements C {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A', 'B'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      fields
        final promotable hasInitializer _foo
          reference: <testLibrary>::@class::B::@field::_foo
          firstFragment: #F3
          type: int?
          getter: <testLibrary>::@class::B::@getter::_foo
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_field_inClassTypeAlias() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  final int? _foo = 0;
}

mixin M {
  dynamic noSuchMethod(Invocation invocation) {}
}

/// Implicitly implements `_foo` as a getter that forwards to [noSuchMethod].
class E = Object with M implements B;
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingNsmClasses
        <testLibrary>::@class::E
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_field_inEnum() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B {
  final int? _foo = 0;
}

/// Implicitly implements `_foo` as a getter that forwards to [noSuchMethod].
enum E implements B {
  v;
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A', 'B'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      fields
        final hasInitializer _foo
          reference: <testLibrary>::@class::B::@field::_foo
          firstFragment: #F3
          type: int?
          getter: <testLibrary>::@class::B::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingNsmClasses
        <testLibrary>::@enum::E
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_getter() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

abstract class B {
  int? get _foo;
}

/// Implicitly implements `_foo` as a getter that forwards to [noSuchMethod].
class C implements B {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingNsmClasses
        <testLibrary>::@class::C
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_inDifferentLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class B {
  int? get _foo => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

class A {
  final int? _foo;
  A(this._foo);
}

/// Has a noSuchMethod thrower for B._field, but since private names in
/// different libraries are distinct, this has no effect on promotion of
/// C._field.
class C implements B {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_inheritedInterface() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

class B extends A {
  A(super.value);
}

/// Implicitly implements `_foo` as a getter that forwards to [noSuchMethod].
class C implements B {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingNsmClasses
        <testLibrary>::@class::C
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_mixedInterface() async {
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

mixin M {
  final int? _foo = 0;
}

class B with M {}

/// Implicitly implements `_foo` as a getter that forwards to [noSuchMethod].
class C implements B {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'}, mixinNames: {'M'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F2
      superclassConstraints
        Object
      fields
        final hasInitializer _foo
          reference: <testLibrary>::@mixin::M::@field::_foo
          firstFragment: #F3
          type: int?
          getter: <testLibrary>::@mixin::M::@getter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingNsmClasses
        <testLibrary>::@class::C
''');
  }

  test_class_field_isPromotable_noSuchMethodForwarder_unusedMixin() async {
    // Mixins are implicitly abstract so the presence of a mixin that inherits
    // a field into its interface, and doesn't implement it, doesn't mean that
    // a noSuchMethod forwarder created for it. So,  this does not block that
    // field from promoting.
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  A(this._foo);
}

mixin M implements A {
  dynamic noSuchMethod(Invocation invocation) {}
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
''');
  }

  test_class_field_isPromotable_notFinal() async {
    var library = await buildLibrary(r'''
class A {
  int? _foo;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
          setter: <testLibrary>::@class::A::@setter::_foo
  fieldNameNonPromotabilityInfo
    _foo
      conflictingFields
        <testLibrary>::@class::A::@field::_foo
''');
  }

  test_class_field_isPromotable_notPrivate() async {
    var library = await buildLibrary(r'''
class A {
  int? field;
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        field
          reference: <testLibrary>::@class::A::@field::field
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::field
          setter: <testLibrary>::@class::A::@setter::field
''');
  }

  test_class_field_isPromotable_typeInference() async {
    // We decide that `_foo` is promotable before inferring the type of `bar`.
    var library = await buildLibrary(r'''
class A {
  final int? _foo;
  final bar = _foo != null ? _foo : 0;
  A(this._foo);
}
''');

    configuration.forPromotableFields(classNames: {'A'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      fields
        final promotable _foo
          reference: <testLibrary>::@class::A::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@class::A::@getter::_foo
        final hasInitializer bar
          reference: <testLibrary>::@class::A::@field::bar
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::bar
''');
  }

  test_class_field_missingName() async {
    var library = await buildLibrary('''
abstract class C {
  Object a,;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          fields
            #F2 a (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@class::C::@field::a
            #F3 <null-name> (nameOffset:<null>) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@class::C::@field::0
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::C::@getter::a
            #F6 synthetic <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::C::@getter::1
          setters
            #F7 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::C::@setter::a
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
                  element: <testLibrary>::@class::C::@setter::a::@formalParameter::value
            #F9 synthetic <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::C::@setter::2
              formalParameters
                #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
                  element: <testLibrary>::@class::C::@setter::2::@formalParameter::value
  classes
    abstract hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F2
          type: Object
          getter: <testLibrary>::@class::C::@getter::a
          setter: <testLibrary>::@class::C::@setter::a
        <null-name>
          reference: <testLibrary>::@class::C::@field::0
          firstFragment: #F3
          type: Object
          getter: <testLibrary>::@class::C::@getter::1
          setter: <testLibrary>::@class::C::@setter::2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F5
          returnType: Object
          variable: <testLibrary>::@class::C::@field::a
        synthetic <null-name>
          reference: <testLibrary>::@class::C::@getter::1
          firstFragment: #F6
          returnType: Object
          variable: <testLibrary>::@class::C::@field::0
      setters
        synthetic a
          reference: <testLibrary>::@class::C::@setter::a
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: Object
          returnType: void
          variable: <testLibrary>::@class::C::@field::a
        synthetic <null-name>
          reference: <testLibrary>::@class::C::@setter::2
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F10
              type: Object
          returnType: void
          variable: <testLibrary>::@class::C::@field::0
''');
  }

  test_class_field_ofGeneric_refEnclosingTypeParameter_false() async {
    var library = await buildLibrary('''
class C<T> {
  late int foo;
}
''');
    configuration.withConstructors = false;
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
            #F3 foo (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@class::C::@field::foo
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        late foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_field_ofGeneric_refEnclosingTypeParameter_true() async {
    var library = await buildLibrary('''
class C<T> {
  late T foo;
}
''');
    configuration.withConstructors = false;
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
            #F3 foo (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::C::@field::foo
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        late foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F6
              type: T
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_field_propagatedType_const_noDep() async {
    var library = await buildLibrary('''
class C {
  static const x = 0;
}''');
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
            #F2 hasInitializer x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::x
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @29
                  staticType: int
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static const hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_propagatedType_final_dep_inLib() async {
    newFile('$testPackageLibPath/a.dart', 'final a = 1;');
    var library = await buildLibrary('''
import "a.dart";
class C {
  final b = a / 2;
}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer b (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@class::C::@field::b
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@getter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasInitializer b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F2
          type: double
          getter: <testLibrary>::@class::C::@getter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F4
          returnType: double
          variable: <testLibrary>::@class::C::@field::b
''');
  }

  test_class_field_propagatedType_final_dep_inPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of lib; final a = 1;');
    var library = await buildLibrary('''
library lib;
part "a.dart";
class C {
  final b = a / 2;
}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: lib
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 13
          unit: #F1
      classes
        #F2 class C (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::C
          fields
            #F3 hasInitializer b (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@class::C::@field::b
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::C::@getter::b
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F6 hasInitializer a (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F7 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
      fields
        final hasInitializer b
          reference: <testLibrary>::@class::C::@field::b
          firstFragment: #F3
          type: double
          getter: <testLibrary>::@class::C::@getter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic b
          reference: <testLibrary>::@class::C::@getter::b
          firstFragment: #F5
          returnType: double
          variable: <testLibrary>::@class::C::@field::b
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F6
      type: int
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_field_propagatedType_final_noDep_instance() async {
    var library = await buildLibrary('''
class C {
  final x = 0;
}''');
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
            #F2 hasInitializer x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_propagatedType_final_noDep_static() async {
    var library = await buildLibrary('''
class C {
  static final x = 0;
}''');
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
            #F2 hasInitializer x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static final hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_static() async {
    var library = await buildLibrary('class C { static int i; }');
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
            #F2 i (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::i
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::i
          setters
            #F5 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@setter::i
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: <testLibrary>::@class::C::@setter::i::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::i
          setter: <testLibrary>::@class::C::@setter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
      setters
        synthetic static i
          reference: <testLibrary>::@class::C::@setter::i
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::i
''');
  }

  test_class_field_static_final_hasConstConstructor() async {
    var library = await buildLibrary('''
class C {
  static final f = 0;
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
            #F2 hasInitializer f (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:34) (offset:40)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 40
          getters
            #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static final hasInitializer f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_class_field_static_final_untyped() async {
    var library = await buildLibrary('class C { static final x = 0; }');
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
            #F2 hasInitializer x (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static final hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_static_late() async {
    var library = await buildLibrary('class C { static late int i; }');
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
            #F2 i (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::C::@field::i
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::C::@getter::i
          setters
            #F5 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::C::@setter::i
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::C::@setter::i::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        static late i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::i
          setter: <testLibrary>::@class::C::@setter::i
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic static i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
      setters
        synthetic static i
          reference: <testLibrary>::@class::C::@setter::i
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::i
''');
  }

  test_class_field_type_explicit() async {
    var library = await buildLibrary(r'''
class C {
  int a = 0;
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
            #F2 hasInitializer a (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::a
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::a
          setters
            #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::a
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::a::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::a
          setter: <testLibrary>::@class::C::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::C::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::a
''');
  }

  test_class_field_type_inferred_fromInitializer() async {
    var library = await buildLibrary(r'''
class C {
  var foo = 0;
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
            #F2 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_field_type_inferred_fromSuper() async {
    var library = await buildLibrary(r'''
abstract class A {
  int get foo;
}

class B extends A {
  final foo = 0;
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 foo (nameOffset:29) (firstTokenOffset:21) (offset:29)
              element: <testLibrary>::@class::A::@getter::foo
        #F5 class B (nameOffset:43) (firstTokenOffset:37) (offset:43)
          element: <testLibrary>::@class::B
          fields
            #F6 hasInitializer foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@class::B::@field::foo
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@class::B::@getter::foo
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        abstract foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      fields
        final hasInitializer foo
          reference: <testLibrary>::@class::B::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::B::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        synthetic foo
          reference: <testLibrary>::@class::B::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::B::@field::foo
''');
  }

  test_class_field_type_inferred_Never() async {
    var library = await buildLibrary(r'''
class C {
  var a = throw 42;
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
            #F2 hasInitializer a (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::a
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::a
          setters
            #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::a
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::a::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F2
          type: Never
          getter: <testLibrary>::@class::C::@getter::a
          setter: <testLibrary>::@class::C::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F4
          returnType: Never
          variable: <testLibrary>::@class::C::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::C::@setter::a
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: Never
          returnType: void
          variable: <testLibrary>::@class::C::@field::a
''');
  }

  test_class_field_typed() async {
    var library = await buildLibrary('class C { int x = 0; }');
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
            #F2 hasInitializer x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_field_untyped() async {
    var library = await buildLibrary('class C { var x = 0; }');
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
            #F2 hasInitializer x (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_fields() async {
    var library = await buildLibrary('class C { int i; int j; }');
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
            #F2 i (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::C::@field::i
            #F3 j (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::j
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@getter::i
            #F6 synthetic j (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::j
          setters
            #F7 synthetic i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::C::@setter::i
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::C::@setter::i::@formalParameter::value
            #F9 synthetic j (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@setter::j
              formalParameters
                #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: <testLibrary>::@class::C::@setter::j::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        i
          reference: <testLibrary>::@class::C::@field::i
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::i
          setter: <testLibrary>::@class::C::@setter::i
        j
          reference: <testLibrary>::@class::C::@field::j
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::C::@getter::j
          setter: <testLibrary>::@class::C::@setter::j
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic i
          reference: <testLibrary>::@class::C::@getter::i
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::i
        synthetic j
          reference: <testLibrary>::@class::C::@getter::j
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::C::@field::j
      setters
        synthetic i
          reference: <testLibrary>::@class::C::@setter::i
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::i
        synthetic j
          reference: <testLibrary>::@class::C::@setter::j
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::j
''');
  }

  test_class_fields_late() async {
    var library = await buildLibrary('''
class C {
  late int foo;
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
            #F2 foo (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        late foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_fields_late_final() async {
    var library = await buildLibrary('''
class C {
  late final int foo;
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
            #F2 foo (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        late final foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_fields_late_final_initialized() async {
    var library = await buildLibrary('''
class C {
  late final int foo = 0;
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
            #F2 hasInitializer foo (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@getter::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        late final hasInitializer foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_fields_late_inference_usingSuper_methodInvocation() async {
    var library = await buildLibrary('''
class A {
  int foo() => 0;
}

class B extends A {
  late var f = super.foo();
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
            #F3 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@method::foo
        #F4 class B (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::B
          fields
            #F5 hasInitializer f (nameOffset:62) (firstTokenOffset:62) (offset:62)
              element: <testLibrary>::@class::B::@field::f
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F7 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::B::@getter::f
          setters
            #F8 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::B::@setter::f
              formalParameters
                #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
                  element: <testLibrary>::@class::B::@setter::f::@formalParameter::value
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
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      fields
        late hasInitializer f
          reference: <testLibrary>::@class::B::@field::f
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::B::@getter::f
          setter: <testLibrary>::@class::B::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        synthetic f
          reference: <testLibrary>::@class::B::@getter::f
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::B::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::B::@setter::f
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::f
''');
  }

  test_class_fields_late_inference_usingSuper_propertyAccess() async {
    var library = await buildLibrary('''
class A {
  int get foo => 0;
}

class B extends A {
  late var f = super.foo;
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
        #F5 class B (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::B
          fields
            #F6 hasInitializer f (nameOffset:64) (firstTokenOffset:64) (offset:64)
              element: <testLibrary>::@class::B::@field::f
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F8 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@class::B::@getter::f
          setters
            #F9 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@class::B::@setter::f
              formalParameters
                #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
                  element: <testLibrary>::@class::B::@setter::f::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      fields
        late hasInitializer f
          reference: <testLibrary>::@class::B::@field::f
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::B::@getter::f
          setter: <testLibrary>::@class::B::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        synthetic f
          reference: <testLibrary>::@class::B::@getter::f
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::B::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::B::@setter::f
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::B::@field::f
''');
  }

  test_class_final() async {
    var library = await buildLibrary('final class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    final class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_fragmentOrder_g1_s2_s1() async {
    var library = await buildLibrary(r'''
class A {
  int get a => 0;
  set b(int _) {}
  set a(int _) {}
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
            #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::a
            #F3 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::b
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 a (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::a
          setters
            #F6 b (nameOffset:34) (firstTokenOffset:30) (offset:34)
              element: <testLibrary>::@class::A::@setter::b
              formalParameters
                #F7 _ (nameOffset:40) (firstTokenOffset:36) (offset:40)
                  element: <testLibrary>::@class::A::@setter::b::@formalParameter::_
            #F8 a (nameOffset:52) (firstTokenOffset:48) (offset:52)
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F9 _ (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
        synthetic b
          reference: <testLibrary>::@class::A::@field::b
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::a
      setters
        b
          reference: <testLibrary>::@class::A::@setter::b
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::b
        a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
''');
  }

  test_class_fragmentOrder_s1_g2_g1() async {
    var library = await buildLibrary(r'''
class A {
  set a(int _) {}
  int get b => 0;
  int get a => 0;
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
            #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::a
            #F3 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::b
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 b (nameOffset:38) (firstTokenOffset:30) (offset:38)
              element: <testLibrary>::@class::A::@getter::b
            #F6 a (nameOffset:56) (firstTokenOffset:48) (offset:56)
              element: <testLibrary>::@class::A::@getter::a
          setters
            #F7 a (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::a
              formalParameters
                #F8 _ (nameOffset:22) (firstTokenOffset:18) (offset:22)
                  element: <testLibrary>::@class::A::@setter::a::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::a
          setter: <testLibrary>::@class::A::@setter::a
        synthetic b
          reference: <testLibrary>::@class::A::@field::b
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::b
        a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::a
      setters
        a
          reference: <testLibrary>::@class::A::@setter::a
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::a
''');
  }

  test_class_getter_abstract() async {
    var library = await buildLibrary('abstract class C { int get x; }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:27) (firstTokenOffset:19) (offset:27)
              element: <testLibrary>::@class::C::@getter::x
  classes
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        abstract x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_getter_external() async {
    var library = await buildLibrary('class C { external int get x; }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:27) (firstTokenOffset:10) (offset:27)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        external x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_getter_implicit_return_type() async {
    var library = await buildLibrary('class C { get x => null; }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_getter_invokesSuperSelf_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo {
    super.foo;
  }
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_class_getter_invokesSuperSelf_getter_nestedInAssignment() async {
    var library = await buildLibrary(r'''
class A {
  int get foo {
    (super.foo).foo = 0;
  }
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_class_getter_invokesSuperSelf_setter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo {
    super.foo = 0;
  }
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_class_getter_missingName() async {
    var library = await buildLibrary('''
class A {
  get () => 0;
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
            #F3 get (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@method::get
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        get
          reference: <testLibrary>::@class::A::@method::get
          firstFragment: #F3
          returnType: dynamic
''');
  }

  test_class_getter_native() async {
    var library = await buildLibrary('''
class C {
  int get x() native;
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        external x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_getter_ofGeneric_refEnclosingTypeParameter_false() async {
    var library = await buildLibrary('''
class C<T> {
  int get foo {}
}
''');
    configuration.withConstructors = false;
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
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo
          getters
            #F4 foo (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::C::@getter::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
      getters
        foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_getter_ofGeneric_refEnclosingTypeParameter_true() async {
    var library = await buildLibrary('''
class C<T> {
  T get foo {}
}
''');
    configuration.withConstructors = false;
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
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo
          getters
            #F4 foo (nameOffset:21) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::C::@getter::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::C::@getter::foo
      getters
        foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_getter_static() async {
    var library = await buildLibrary('class C { static int get x => null; }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:25) (firstTokenOffset:10) (offset:25)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic static x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        static x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_getters() async {
    var library = await buildLibrary(
      'class C { int get x => null; get y => null; }',
    );
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
            #F3 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::y
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 x (nameOffset:18) (firstTokenOffset:10) (offset:18)
              element: <testLibrary>::@class::C::@getter::x
            #F6 y (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@class::C::@getter::y
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
        synthetic y
          reference: <testLibrary>::@class::C::@field::y
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
        y
          reference: <testLibrary>::@class::C::@getter::y
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::y
''');
  }

  test_class_implicitField_getterFirst() async {
    var library = await buildLibrary('''
class C {
  int get x => 0;
  void set x(int value) {}
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 x (nameOffset:39) (firstTokenOffset:30) (offset:39)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:45) (firstTokenOffset:41) (offset:45)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_implicitField_setterFirst() async {
    var library = await buildLibrary('''
class C {
  void set x(int value) {}
  int get x => 0;
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 x (nameOffset:47) (firstTokenOffset:39) (offset:47)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 x (nameOffset:21) (firstTokenOffset:12) (offset:21)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_interface() async {
    var library = await buildLibrary('interface class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:16) (firstTokenOffset:0) (offset:16)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    interface class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_interfaces() async {
    var library = await buildLibrary('''
class C implements D, E {}
class D {}
class E {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      interfaces
        D
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_interfaces_extensionType() async {
    var library = await buildLibrary('''
class A {}
extension type B(int it) {}
class C {}
class D implements A, B, C {}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
        #F3 class D (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@class::D
      extensionTypes
        #F4 extension type B (nameOffset:26) (firstTokenOffset:11) (offset:26)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:32) (firstTokenOffset:27) (offset:32)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@extensionType::B::@getter::it
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      interfaces
        A
        C
  extensionTypes
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_class_interfaces_Function() async {
    var library = await buildLibrary('''
class A {}
class B {}
class C implements A, Function, B {}
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
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      interfaces
        A
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_interfaces_unresolved() async {
    var library = await buildLibrary(
      'class C implements X, Y, Z {} class X {} class Z {}',
    );
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class X (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::X
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
        #F5 class Z (nameOffset:47) (firstTokenOffset:41) (offset:47)
          element: <testLibrary>::@class::Z
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      interfaces
        X
        Z
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F4
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_lazy_constructors() async {
    var library = await buildLibrary('''
class A {
  A.named();
}
''');

    var constructors = library.getClass('A')!.constructors;
    expect(constructors, hasLength(1));
  }

  test_class_lazy_fields() async {
    var library = await buildLibrary('''
class A {
  int foo = 0;
}
''');

    var fields = library.getClass('A')!.fields;
    expect(fields, hasLength(1));
  }

  test_class_lazy_getters() async {
    var library = await buildLibrary('''
class A {
  int foo = 0;
}
''');

    var getters = library.getClass('A')!.getters;
    expect(getters, hasLength(1));
  }

  test_class_lazy_methods() async {
    var library = await buildLibrary('''
class A {
  void foo() {}
}
''');

    var methods = library.getClass('A')!.methods;
    expect(methods, hasLength(1));
  }

  test_class_lazy_setters() async {
    var library = await buildLibrary('''
class A {
  int foo = 0;
}
''');

    var setters = library.getClass('A')!.setters;
    expect(setters, hasLength(1));
  }

  test_class_method_abstract() async {
    var library = await buildLibrary('abstract class C { f(); }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@class::C::@method::f
  classes
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        abstract f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: dynamic
''');
  }

  test_class_method_async() async {
    var library = await buildLibrary(r'''
import 'dart:async';
class C {
  Future f() async {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      classes
        #F1 class C (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:40) (firstTokenOffset:33) (offset:40) async
              element: <testLibrary>::@class::C::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: Future<dynamic>
''');
  }

  test_class_method_asyncStar() async {
    var library = await buildLibrary(r'''
import 'dart:async';
class C {
  Stream f() async* {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      classes
        #F1 class C (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:40) (firstTokenOffset:33) (offset:40) async*
              element: <testLibrary>::@class::C::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: Stream<dynamic>
''');
  }

  test_class_method_documented() async {
    var library = await buildLibrary('''
class C {
  /**
   * Docs
   */
  f() {}
}''');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:34) (firstTokenOffset:12) (offset:34)
              element: <testLibrary>::@class::C::@method::f
              documentationComment: /**\n   * Docs\n   */
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          documentationComment: /**\n   * Docs\n   */
          returnType: dynamic
''');
  }

  test_class_method_external() async {
    var library = await buildLibrary('class C { external f(); }');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        external f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: dynamic
''');
  }

  test_class_method_hasImplicitReturnType_false() async {
    var library = await buildLibrary('''
class C {
  int m() => 0;
}
''');
    var c = library.firstFragment.classes.single;
    var m = c.methods.single;
    expect(m.hasImplicitReturnType, isFalse);
  }

  test_class_method_hasImplicitReturnType_true() async {
    var library = await buildLibrary('''
class C {
  m() => 0;
}
''');
    var c = library.firstFragment.classes.single;
    var m = c.methods.single;
    expect(m.hasImplicitReturnType, isTrue);
  }

  test_class_method_inferred_type_nonStatic_implicit_param() async {
    var library = await buildLibrary(
      'class C extends D { void f(value) {} }'
      ' abstract class D { void f(int value); }',
    );
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 value (nameOffset:27) (firstTokenOffset:27) (offset:27)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::value
        #F5 class D (nameOffset:54) (firstTokenOffset:39) (offset:54)
          element: <testLibrary>::@class::D
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F7 f (nameOffset:63) (firstTokenOffset:58) (offset:63)
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F8 value (nameOffset:69) (firstTokenOffset:65) (offset:69)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::D::@constructor::new
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType value
              firstFragment: #F4
              type: int
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
      methods
        abstract f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
''');
  }

  test_class_method_inferred_type_nonStatic_implicit_return() async {
    var library = await buildLibrary('''
class C extends D {
  f() => null;
}
abstract class D {
  int f();
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::C::@method::f
        #F4 class D (nameOffset:52) (firstTokenOffset:37) (offset:52)
          element: <testLibrary>::@class::D
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F6 f (nameOffset:62) (firstTokenOffset:58) (offset:62)
              element: <testLibrary>::@class::D::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::D::@constructor::new
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: int
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
      methods
        abstract f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: #F6
          returnType: int
''');
  }

  test_class_method_invokesSuperSelf() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {
    super.foo();
  }
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
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17) invokesSuperSelf
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
          returnType: void
''');
  }

  test_class_method_missingName() async {
    var library = await buildLibrary('''
class A {
  () {}
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
            #F3 <null-name> (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@method::0
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        <null-name>
          reference: <testLibrary>::@class::A::@method::0
          firstFragment: #F3
          returnType: dynamic
''');
  }

  test_class_method_namedAsSupertype() async {
    var library = await buildLibrary(r'''
class A {}
class B extends A {
  void A() {}
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
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F5 A (nameOffset:38) (firstTokenOffset:33) (offset:38)
              element: <testLibrary>::@class::B::@method::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        A
          reference: <testLibrary>::@class::B::@method::A
          firstFragment: #F5
          returnType: void
''');
  }

  test_class_method_native() async {
    var library = await buildLibrary('''
class C {
  int m() native;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 m (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::C::@method::m
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        external m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          returnType: int
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_false_hide() async {
    var library = await buildLibrary('''
class C<T> {
  void foo<T>(T _) {}
}
''');
    configuration.withConstructors = false;
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
          methods
            #F3 foo (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::C::@method::foo
              typeParameters
                #F4 T (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E1 T
              formalParameters
                #F5 _ (nameOffset:29) (firstTokenOffset:27) (offset:29)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::_
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F3
          typeParameters
            #E1 T
              firstFragment: #F4
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F5
              type: T
          returnType: void
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_true_formalParameter() async {
    var library = await buildLibrary('''
class C<T> {
  void foo(T _) {}
}
''');
    configuration.withConstructors = false;
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
          methods
            #F3 foo (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F4 _ (nameOffset:26) (firstTokenOffset:24) (offset:26)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::_
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
          returnType: void
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_true_formalParameter2() async {
    var library = await buildLibrary('''
class C<T> {
  void foo(void Function(T) _) {}
}
''');
    configuration.withConstructors = false;
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
          methods
            #F3 foo (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F4 _ (nameOffset:41) (firstTokenOffset:24) (offset:41)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::_
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: void Function(T)
          returnType: void
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_true_inferred() async {
    var library = await buildLibrary('''
class A<U> {
  U foo() {}
}

class B<T> extends A<T> {
  foo() {}
}
''');
    configuration.withConstructors = false;
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
            #F2 U (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 U
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F4 class B (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E1 T
          methods
            #F6 foo (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::B::@method::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          returnType: U
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      supertype: A<T>
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_true_returnType() async {
    var library = await buildLibrary('''
class C<T> {
  T foo() {}
}
''');
    configuration.withConstructors = false;
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
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@class::C::@method::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_true_typeAlias() async {
    var library = await buildLibrary('''
typedef MyInt<U> = int;

class C<T> {
  MyInt<T> foo() {}
}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: #E0 T
          methods
            #F3 foo (nameOffset:49) (firstTokenOffset:40) (offset:49)
              element: <testLibrary>::@class::C::@method::foo
      typeAliases
        #F4 MyInt (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::MyInt
          typeParameters
            #F5 U (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: #E1 U
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          returnType: int
            alias: <testLibrary>::@typeAlias::MyInt
              typeArguments
                T
  typeAliases
    MyInt
      reference: <testLibrary>::@typeAlias::MyInt
      firstFragment: #F4
      typeParameters
        #E1 U
          firstFragment: #F5
      aliasedType: int
''');
  }

  test_class_method_ofGeneric_refEnclosingTypeParameter_true_typeParameter() async {
    var library = await buildLibrary('''
class C<T> {
  void foo<U extends T>() {}
}
''');
    configuration.withConstructors = false;
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
          methods
            #F3 foo (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::C::@method::foo
              typeParameters
                #F4 U (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E1 U
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          typeParameters
            #E1 U
              firstFragment: #F4
              bound: T
          returnType: void
''');
  }

  test_class_method_params() async {
    var library = await buildLibrary('class C { f(x, y) {} }');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 x (nameOffset:12) (firstTokenOffset:12) (offset:12)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 y (nameOffset:15) (firstTokenOffset:15) (offset:15)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::y
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType x
              firstFragment: #F4
              type: dynamic
            #E1 requiredPositional hasImplicitType y
              firstFragment: #F5
              type: dynamic
          returnType: dynamic
''');
  }

  test_class_method_static() async {
    var library = await buildLibrary('class C { static f() {} }');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:17) (firstTokenOffset:10) (offset:17)
              element: <testLibrary>::@class::C::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        static f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: dynamic
''');
  }

  test_class_method_syncStar() async {
    var library = await buildLibrary(r'''
class C {
  Iterable<int> f() sync* {
    yield 42;
  }
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:26) (firstTokenOffset:12) (offset:26) sync*
              element: <testLibrary>::@class::C::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: Iterable<int>
''');
  }

  test_class_method_type_parameter() async {
    var library = await buildLibrary('class C { T f<T, U>(U u) => null; }');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:12) (firstTokenOffset:10) (offset:12)
              element: <testLibrary>::@class::C::@method::f
              typeParameters
                #F4 T (nameOffset:14) (firstTokenOffset:14) (offset:14)
                  element: #E0 T
                #F5 U (nameOffset:17) (firstTokenOffset:17) (offset:17)
                  element: #E1 U
              formalParameters
                #F6 u (nameOffset:22) (firstTokenOffset:20) (offset:22)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::u
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F4
            #E1 U
              firstFragment: #F5
          formalParameters
            #E2 requiredPositional u
              firstFragment: #F6
              type: U
          returnType: T
''');
  }

  test_class_method_type_parameter_in_generic_class() async {
    var library = await buildLibrary('''
class C<T, U> {
  V f<V, W>(T t, U u, W w) => null;
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F5 f (nameOffset:20) (firstTokenOffset:18) (offset:20)
              element: <testLibrary>::@class::C::@method::f
              typeParameters
                #F6 V (nameOffset:22) (firstTokenOffset:22) (offset:22)
                  element: #E2 V
                #F7 W (nameOffset:25) (firstTokenOffset:25) (offset:25)
                  element: #E3 W
              formalParameters
                #F8 t (nameOffset:30) (firstTokenOffset:28) (offset:30)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::t
                #F9 u (nameOffset:35) (firstTokenOffset:33) (offset:35)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::u
                #F10 w (nameOffset:40) (firstTokenOffset:38) (offset:40)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::w
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          typeParameters
            #E2 V
              firstFragment: #F6
            #E3 W
              firstFragment: #F7
          formalParameters
            #E4 requiredPositional t
              firstFragment: #F8
              type: T
            #E5 requiredPositional u
              firstFragment: #F9
              type: U
            #E6 requiredPositional w
              firstFragment: #F10
              type: W
          returnType: V
''');
  }

  test_class_method_type_parameter_with_function_typed_parameter() async {
    var library = await buildLibrary('class C { void f<T, U>(T x(U u)) {} }');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:15) (firstTokenOffset:10) (offset:15)
              element: <testLibrary>::@class::C::@method::f
              typeParameters
                #F4 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
                  element: #E0 T
                #F5 U (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: #E1 U
              formalParameters
                #F6 x (nameOffset:25) (firstTokenOffset:23) (offset:25)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                  parameters
                    #F7 u (nameOffset:29) (firstTokenOffset:27) (offset:29)
                      element: u@29
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F4
            #E1 U
              firstFragment: #F5
          formalParameters
            #E2 requiredPositional x
              firstFragment: #F6
              type: T Function(U)
              formalParameters
                #E3 requiredPositional u
                  firstFragment: #F7
                  type: U
          returnType: void
''');
  }

  test_class_methods() async {
    var library = await buildLibrary('class C { f() {} g() {} }');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@class::C::@method::f
            #F4 g (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@method::g
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          returnType: dynamic
        g
          reference: <testLibrary>::@class::C::@method::g
          firstFragment: #F4
          returnType: dynamic
''');
  }

  test_class_missingName() async {
    configuration.withExportScope = true;
    var library = await buildLibrary(r'''
class {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@class::0
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@class::0::@constructor::new
              typeName: null
  classes
    class <null-name>
      reference: <testLibrary>::@class::0
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::0::@constructor::new
          firstFragment: #F2
  exportedReferences
  exportNamespace
''');
  }

  test_class_mixin_class() async {
    var library = await buildLibrary('mixin class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    mixin class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_mixins() async {
    var library = await buildLibrary('''
class C extends D with E, F, G {}
class D {}
class E {}
class F {}
class G {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
        #F7 class F (nameOffset:62) (firstTokenOffset:56) (offset:62)
          element: <testLibrary>::@class::F
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::F::@constructor::new
              typeName: F
        #F9 class G (nameOffset:73) (firstTokenOffset:67) (offset:73)
          element: <testLibrary>::@class::G
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@class::G::@constructor::new
              typeName: G
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      mixins
        E
        F
        G
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
    class F
      reference: <testLibrary>::@class::F
      firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::F::@constructor::new
          firstFragment: #F8
    class G
      reference: <testLibrary>::@class::G
      firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::G::@constructor::new
          firstFragment: #F10
''');
  }

  test_class_mixins_extensionType() async {
    var library = await buildLibrary('''
mixin A {}
extension type B(int it) {}
mixin C {}
class D extends Object with A, B, C {}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class D (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@class::D
      extensionTypes
        #F2 extension type B (nameOffset:26) (firstTokenOffset:11) (offset:26)
          element: <testLibrary>::@extensionType::B
          fields
            #F3 it (nameOffset:32) (firstTokenOffset:27) (offset:32)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@extensionType::B::@getter::it
      mixins
        #F5 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
        #F6 mixin C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@mixin::C
  classes
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F1
      supertype: Object
      mixins
        A
        C
  extensionTypes
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F2
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F5
      superclassConstraints
        Object
    mixin C
      reference: <testLibrary>::@mixin::C
      firstFragment: #F6
      superclassConstraints
        Object
''');
  }

  test_class_mixins_generic() async {
    var library = await buildLibrary('''
class Z extends A with B<int>, C<double> {}
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class Z (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::Z
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
        #F3 class A (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::A
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F5 class B (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::B
          typeParameters
            #F6 B1 (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: #E0 B1
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F8 class C (nameOffset:76) (firstTokenOffset:70) (offset:76)
          element: <testLibrary>::@class::C
          typeParameters
            #F9 C1 (nameOffset:78) (firstTokenOffset:78) (offset:78)
              element: #E1 C1
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F1
      supertype: A
      mixins
        B<int>
        C<double>
      constructors
        synthetic new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      typeParameters
        #E0 B1
          firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F8
      typeParameters
        #E1 C1
          firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
''');
  }

  test_class_mixins_generic_superAfter() async {
    var library = await buildLibrary('''
mixin M<T extends num> {}
mixin M2<T extends num> on M<T> {}
class Z extends S with M2 {}
class S with M<int> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class Z (nameOffset:67) (firstTokenOffset:61) (offset:67)
          element: <testLibrary>::@class::Z
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
        #F3 class S (nameOffset:96) (firstTokenOffset:90) (offset:96)
          element: <testLibrary>::@class::S
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@class::S::@constructor::new
              typeName: S
      mixins
        #F5 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F6 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
        #F7 mixin M2 (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F8 T (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: #E1 T
  classes
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F1
      supertype: S
      mixins
        M2<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::S::@constructor::new
    class S
      reference: <testLibrary>::@class::S
      firstFragment: #F3
      supertype: Object
      mixins
        M<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::S::@constructor::new
          firstFragment: #F4
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F5
      typeParameters
        #E0 T
          firstFragment: #F6
          bound: num
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F7
      typeParameters
        #E1 T
          firstFragment: #F8
          bound: num
      superclassConstraints
        M<T>
''');
  }

  test_class_mixins_genericMixin_tooManyArguments() async {
    var library = await buildLibrary('''
mixin M<T> {}
class A extends Object with M<int, String> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      mixins
        #F3 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F4 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      supertype: Object
      mixins
        M<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      superclassConstraints
        Object
''');
  }

  test_class_mixins_typeParameter() async {
    var library = await buildLibrary('''
mixin M1 {}
mixin M2 {}
class A<T> extends Object with M1, T<int>, M2 {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      mixins
        #F4 mixin M1 (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M1
        #F5 mixin M2 (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@mixin::M2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Object
      mixins
        M1
        M2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F4
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F5
      superclassConstraints
        Object
''');
  }

  test_class_mixins_unresolved() async {
    var library = await buildLibrary(
      'class C extends Object with X, Y, Z {} class X {} class Z {}',
    );
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class X (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::X
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
        #F5 class Z (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@class::Z
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: Object
      mixins
        X
        Z
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F4
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_notSimplyBounded_circularity_via_typeAlias_recordType() async {
    var library = await buildLibrary('''
class C<T extends A> {}
typedef A = (C, int);
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 A (nameOffset:32) (firstTokenOffset:24) (offset:32)
          element: <testLibrary>::@typeAlias::A
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F4
      aliasedType: (C<dynamic>, int)
''');
  }

  test_class_notSimplyBounded_circularity_via_typedef() async {
    // C's type parameter T is not simply bounded because its bound, F, expands
    // to `dynamic F(C)`, which refers to C.
    var library = await buildLibrary('''
class C<T extends F> {}
typedef F(C value);
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F (nameOffset:32) (firstTokenOffset:24) (offset:32)
          element: <testLibrary>::@typeAlias::F
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: dynamic Function(C<dynamic>)
''');
  }

  test_class_notSimplyBounded_circularity_with_type_params() async {
    // C's type parameter T is simply bounded because even though it refers to
    // C, it specifies a bound.
    var library = await buildLibrary('''
class C<T extends C<dynamic>> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_notSimplyBounded_complex_by_cycle_class() async {
    var library = await buildLibrary('''
class C<T extends D> {}
class D<T extends C> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E1 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: D<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    notSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
          bound: C<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_notSimplyBounded_complex_by_cycle_typedef_functionType() async {
    var library = await buildLibrary('''
typedef C<T extends D> = void Function();
typedef D<T extends C> = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 C (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::C
          typeParameters
            #F2 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E0 T
        #F3 D (nameOffset:50) (firstTokenOffset:42) (offset:50)
          element: <testLibrary>::@typeAlias::D
          typeParameters
            #F4 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E1 T
  typeAliases
    notSimplyBounded C
      reference: <testLibrary>::@typeAlias::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      aliasedType: void Function()
    notSimplyBounded D
      reference: <testLibrary>::@typeAlias::D
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
          bound: dynamic
      aliasedType: void Function()
''');
  }

  test_class_notSimplyBounded_complex_by_cycle_typedef_interfaceType() async {
    var library = await buildLibrary('''
typedef C<T extends D> = List<T>;
typedef D<T extends C> = List<T>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 C (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::C
          typeParameters
            #F2 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E0 T
        #F3 D (nameOffset:42) (firstTokenOffset:34) (offset:42)
          element: <testLibrary>::@typeAlias::D
          typeParameters
            #F4 T (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: #E1 T
  typeAliases
    notSimplyBounded C
      reference: <testLibrary>::@typeAlias::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      aliasedType: List<T>
    notSimplyBounded D
      reference: <testLibrary>::@typeAlias::D
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
          bound: dynamic
      aliasedType: List<T>
''');
  }

  test_class_notSimplyBounded_complex_by_reference_to_cycle() async {
    var library = await buildLibrary('''
class C<T extends D> {}
class D<T extends D> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E1 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: D<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    notSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
          bound: D<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_notSimplyBounded_complex_by_use_of_parameter() async {
    var library = await buildLibrary('''
class C<T extends D<T>> {}
class D<T> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: #E1 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: D<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_notSimplyBounded_dependency_with_type_params() async {
    // C's type parameter T is simply bounded because even though it refers to
    // non-simply-bounded type D, it specifies a bound.
    var library = await buildLibrary('''
class C<T extends D<dynamic>> {}
class D<T extends D<T>> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:41) (firstTokenOffset:41) (offset:41)
              element: #E1 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: D<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    notSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
          bound: D<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_notSimplyBounded_function_typed_bound_complex_via_parameter_type() async {
    var library = await buildLibrary('''
class C<T extends void Function(T)> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: void Function(T)
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_notSimplyBounded_function_typed_bound_complex_via_return_type() async {
    var library = await buildLibrary('''
class C<T extends T Function()> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: T Function()
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_notSimplyBounded_function_typed_bound_simple() async {
    var library = await buildLibrary('''
class C<T extends void Function()> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: void Function()
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_notSimplyBounded_refers_to_circular_typedef() async {
    // C's type parameter T has a bound of F, which is a circular typedef.  This
    // is illegal in Dart, but we need to make sure it doesn't lead to a crash
    // or infinite loop.
    var library = await buildLibrary('''
class C<T extends F> {}
typedef F(G value);
typedef G(F value);
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F (nameOffset:32) (firstTokenOffset:24) (offset:32)
          element: <testLibrary>::@typeAlias::F
        #F5 G (nameOffset:52) (firstTokenOffset:44) (offset:52)
          element: <testLibrary>::@typeAlias::G
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: dynamic Function(dynamic)
    notSimplyBounded G
      reference: <testLibrary>::@typeAlias::G
      firstFragment: #F5
      aliasedType: dynamic Function(dynamic)
''');
  }

  test_class_notSimplyBounded_self() async {
    var library = await buildLibrary('''
class C<T extends C> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_notSimplyBounded_simple_because_non_generic() async {
    // If no type parameters are specified, then the class is simply bounded, so
    // there is no reason to assign it a slot.
    var library = await buildLibrary('''
class C {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_notSimplyBounded_simple_by_lack_of_cycles() async {
    var library = await buildLibrary('''
class C<T extends D> {}
class D<T> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E1 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: D<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_notSimplyBounded_simple_by_syntax() async {
    // If no bounds are specified, then the class is simply bounded by syntax
    // alone, so there is no reason to assign it a slot.
    var library = await buildLibrary('''
class C<T> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_operator() async {
    var library = await buildLibrary(
      'class C { C operator+(C other) => null; }',
    );
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 + (nameOffset:20) (firstTokenOffset:10) (offset:20)
              element: <testLibrary>::@class::C::@method::+
              formalParameters
                #F4 other (nameOffset:24) (firstTokenOffset:22) (offset:24)
                  element: <testLibrary>::@class::C::@method::+::@formalParameter::other
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        +
          reference: <testLibrary>::@class::C::@method::+
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional other
              firstFragment: #F4
              type: C
          returnType: C
''');
  }

  test_class_operator_equal() async {
    var library = await buildLibrary('''
class C {
  bool operator==(Object other) => false;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 == (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::C::@method::==
              formalParameters
                #F4 other (nameOffset:35) (firstTokenOffset:28) (offset:35)
                  element: <testLibrary>::@class::C::@method::==::@formalParameter::other
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        ==
          reference: <testLibrary>::@class::C::@method::==
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional other
              firstFragment: #F4
              type: Object
          returnType: bool
''');
  }

  test_class_operator_external() async {
    var library = await buildLibrary(
      'class C { external C operator+(C other); }',
    );
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 + (nameOffset:29) (firstTokenOffset:10) (offset:29)
              element: <testLibrary>::@class::C::@method::+
              formalParameters
                #F4 other (nameOffset:33) (firstTokenOffset:31) (offset:33)
                  element: <testLibrary>::@class::C::@method::+::@formalParameter::other
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        external +
          reference: <testLibrary>::@class::C::@method::+
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional other
              firstFragment: #F4
              type: C
          returnType: C
''');
  }

  test_class_operator_greater_equal() async {
    var library = await buildLibrary('''
class C {
  bool operator>=(C other) => false;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 >= (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::C::@method::>=
              formalParameters
                #F4 other (nameOffset:30) (firstTokenOffset:28) (offset:30)
                  element: <testLibrary>::@class::C::@method::>=::@formalParameter::other
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        >=
          reference: <testLibrary>::@class::C::@method::>=
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional other
              firstFragment: #F4
              type: C
          returnType: bool
''');
  }

  test_class_operator_index() async {
    var library = await buildLibrary(
      'class C { bool operator[](int i) => null; }',
    );
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 [] (nameOffset:23) (firstTokenOffset:10) (offset:23)
              element: <testLibrary>::@class::C::@method::[]
              formalParameters
                #F4 i (nameOffset:30) (firstTokenOffset:26) (offset:30)
                  element: <testLibrary>::@class::C::@method::[]::@formalParameter::i
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        []
          reference: <testLibrary>::@class::C::@method::[]
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional i
              firstFragment: #F4
              type: int
          returnType: bool
''');
  }

  test_class_operator_index_set() async {
    var library = await buildLibrary('''
class C {
  void operator[]=(int i, bool v) {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 []= (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::C::@method::[]=
              formalParameters
                #F4 i (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@class::C::@method::[]=::@formalParameter::i
                #F5 v (nameOffset:41) (firstTokenOffset:36) (offset:41)
                  element: <testLibrary>::@class::C::@method::[]=::@formalParameter::v
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        []=
          reference: <testLibrary>::@class::C::@method::[]=
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional i
              firstFragment: #F4
              type: int
            #E1 requiredPositional v
              firstFragment: #F5
              type: bool
          returnType: void
''');
  }

  test_class_operator_less_equal() async {
    var library = await buildLibrary('''
class C {
  bool operator<=(C other) => false;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 <= (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::C::@method::<=
              formalParameters
                #F4 other (nameOffset:30) (firstTokenOffset:28) (offset:30)
                  element: <testLibrary>::@class::C::@method::<=::@formalParameter::other
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        <=
          reference: <testLibrary>::@class::C::@method::<=
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional other
              firstFragment: #F4
              type: C
          returnType: bool
''');
  }

  test_class_operator_minus() async {
    var library = await buildLibrary('''
class A {
  int operator -(int other) => 0;
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
            #F3 - (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::A::@method::-
              formalParameters
                #F4 other (nameOffset:31) (firstTokenOffset:27) (offset:31)
                  element: <testLibrary>::@class::A::@method::-::@formalParameter::other
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        -
          reference: <testLibrary>::@class::A::@method::-
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional other
              firstFragment: #F4
              type: int
          returnType: int
''');
  }

  test_class_operator_minus_unary() async {
    var library = await buildLibrary('''
class A {
  int operator -() => 0;
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
            #F3 - (nameOffset:25) (firstTokenOffset:12) (offset:25)
              element: <testLibrary>::@class::A::@method::unary-
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        -
          reference: <testLibrary>::@class::A::@method::unary-
          firstFragment: #F3
          returnType: int
''');
  }

  test_class_ref_nullability_none() async {
    var library = await buildLibrary('''
class C {}
C c;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 c (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::c
      setters
        #F5 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::c
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_class_ref_nullability_question() async {
    var library = await buildLibrary('''
class C {}
C? c;
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 c (nameOffset:14) (firstTokenOffset:14) (offset:14)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
          element: <testLibrary>::@getter::c
      setters
        #F5 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
          element: <testLibrary>::@setter::c
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: C?
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C?
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: C?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_class_sealed() async {
    var library = await buildLibrary('sealed class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    abstract sealed class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_sealed_induced_base_extends_base() async {
    var library = await buildLibrary('''
base class A {}
sealed class B extends A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    base class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    abstract sealed base class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_sealed_induced_base_implements_base() async {
    var library = await buildLibrary('''
base class A {}
sealed class B implements A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    base class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    abstract sealed base class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      interfaces
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_sealed_induced_base_implements_final() async {
    var library = await buildLibrary('''
final class A {}
sealed class B implements A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    final class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    abstract sealed base class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      interfaces
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_sealed_induced_final_extends_final() async {
    var library = await buildLibrary('''
final class A {}
sealed class B extends A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    final class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    abstract sealed final class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_sealed_induced_final_with_base_mixin() async {
    var library = await buildLibrary('''
base mixin A {}
interface class B {}
sealed class C extends B with A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:32) (firstTokenOffset:16) (offset:32)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F3 class C (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@class::C
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F5 mixin A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@mixin::A
  classes
    interface class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
    abstract sealed final class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      supertype: B
      mixins
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::B::@constructor::new
  mixins
    base mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F5
      superclassConstraints
        Object
''');
  }

  test_class_sealed_induced_interface_extends_interface() async {
    var library = await buildLibrary('''
interface class A {}
sealed class B extends A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:16) (firstTokenOffset:0) (offset:16)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:34) (firstTokenOffset:21) (offset:34)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    interface class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    abstract sealed interface class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_sealed_induced_none_implements_interface() async {
    var library = await buildLibrary('''
interface class A {}
sealed class B implements A {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:16) (firstTokenOffset:0) (offset:16)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:34) (firstTokenOffset:21) (offset:34)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    interface class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    abstract sealed class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      interfaces
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_setter_abstract() async {
    var library = await buildLibrary(
      'abstract class C { void set x(int value); }',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:28) (firstTokenOffset:19) (offset:28)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:34) (firstTokenOffset:30) (offset:34)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        abstract x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_covariant() async {
    var library = await buildLibrary(
      'class C { void set x(covariant int value); }',
    );
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:35) (firstTokenOffset:21) (offset:35)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        abstract x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional covariant value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_external() async {
    var library = await buildLibrary(
      'class C { external void set x(int value); }',
    );
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:28) (firstTokenOffset:10) (offset:28)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:34) (firstTokenOffset:30) (offset:34)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        external x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_implicit_param_type() async {
    var library = await buildLibrary('class C { void set x(value) {} }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType value
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_implicit_return_type() async {
    var library = await buildLibrary('class C { set x(int value) {} }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:20) (firstTokenOffset:16) (offset:20)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_inferred_type_conflictingInheritance() async {
    var library = await buildLibrary('''
class A {
  int t;
}
class B extends A {
  double t;
}
class C extends A implements B {
}
class D extends C {
  void set t(p) {}
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
            #F2 t (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::t
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::t
          setters
            #F5 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::t
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::t::@formalParameter::value
        #F7 class B (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::B
          fields
            #F8 t (nameOffset:50) (firstTokenOffset:50) (offset:50)
              element: <testLibrary>::@class::B::@field::t
          constructors
            #F9 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@getter::t
          setters
            #F11 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@setter::t
              formalParameters
                #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
                  element: <testLibrary>::@class::B::@setter::t::@formalParameter::value
        #F13 class C (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::C
          constructors
            #F14 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F15 class D (nameOffset:96) (firstTokenOffset:90) (offset:96)
          element: <testLibrary>::@class::D
          fields
            #F16 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@class::D::@field::t
          constructors
            #F17 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          setters
            #F18 t (nameOffset:121) (firstTokenOffset:112) (offset:121)
              element: <testLibrary>::@class::D::@setter::t
              formalParameters
                #F19 p (nameOffset:123) (firstTokenOffset:123) (offset:123)
                  element: <testLibrary>::@class::D::@setter::t::@formalParameter::p
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        t
          reference: <testLibrary>::@class::A::@field::t
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::t
          setter: <testLibrary>::@class::A::@setter::t
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic t
          reference: <testLibrary>::@class::A::@getter::t
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::t
      setters
        synthetic t
          reference: <testLibrary>::@class::A::@setter::t
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::t
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      supertype: A
      fields
        t
          reference: <testLibrary>::@class::B::@field::t
          firstFragment: #F8
          type: double
          getter: <testLibrary>::@class::B::@getter::t
          setter: <testLibrary>::@class::B::@setter::t
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          superConstructor: <testLibrary>::@class::A::@constructor::new
      getters
        synthetic t
          reference: <testLibrary>::@class::B::@getter::t
          firstFragment: #F10
          returnType: double
          variable: <testLibrary>::@class::B::@field::t
      setters
        synthetic t
          reference: <testLibrary>::@class::B::@setter::t
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: double
          returnType: void
          variable: <testLibrary>::@class::B::@field::t
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      supertype: A
      interfaces
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
          superConstructor: <testLibrary>::@class::A::@constructor::new
    hasNonFinalField class D
      reference: <testLibrary>::@class::D
      firstFragment: #F15
      supertype: C
      fields
        synthetic t
          reference: <testLibrary>::@class::D::@field::t
          firstFragment: #F16
          type: dynamic
          setter: <testLibrary>::@class::D::@setter::t
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F17
          superConstructor: <testLibrary>::@class::C::@constructor::new
      setters
        t
          reference: <testLibrary>::@class::D::@setter::t
          firstFragment: #F18
          formalParameters
            #E2 requiredPositional hasImplicitType p
              firstFragment: #F19
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::D::@field::t
''');
  }

  test_class_setter_inferred_type_nonStatic_implicit_param() async {
    var library = await buildLibrary(
      'class C extends D { void set f(value) {} }'
      ' abstract class D { void set f(int value); }',
    );
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
            #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 f (nameOffset:29) (firstTokenOffset:20) (offset:29)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F5 value (nameOffset:31) (firstTokenOffset:31) (offset:31)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
        #F6 class D (nameOffset:58) (firstTokenOffset:43) (offset:58)
          element: <testLibrary>::@class::D
          fields
            #F7 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::D::@field::f
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          setters
            #F9 f (nameOffset:71) (firstTokenOffset:62) (offset:71)
              element: <testLibrary>::@class::D::@setter::f
              formalParameters
                #F10 value (nameOffset:77) (firstTokenOffset:73) (offset:77)
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        synthetic f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::D::@constructor::new
      setters
        f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      fields
        synthetic f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@class::D::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
      setters
        abstract f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::D::@field::f
''');
  }

  test_class_setter_inferred_type_static_implicit_return() async {
    var library = await buildLibrary('''
class C {
  static set f(int value) {}
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
            #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 f (nameOffset:23) (firstTokenOffset:12) (offset:23)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F5 value (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic static f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        static f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_class_setter_invalid_named_parameter() async {
    var library = await buildLibrary('class C { void set x({a}) {} }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 a (nameOffset:22) (firstTokenOffset:22) (offset:22)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_invalid_no_parameter() async {
    var library = await buildLibrary('class C { void set x() {} }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 <null-name> (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::<null-name>
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType <null-name>
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_invalid_optional_parameter() async {
    var library = await buildLibrary('class C { void set x([a]) {} }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 a (nameOffset:22) (firstTokenOffset:22) (offset:22)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_invalid_too_many_parameters() async {
    var library = await buildLibrary('class C { void set x(a, b) {} }');
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:19) (firstTokenOffset:10) (offset:19)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 a (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_invokesSuperSelf_getter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {
    super.foo;
  }
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F5 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_class_setter_invokesSuperSelf_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {
    super.foo = 0;
  }
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
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F5 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_class_setter_missingName() async {
    var library = await buildLibrary('''
class A {
  set (int _) {}
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
            #F3 set (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@method::set
              formalParameters
                #F4 _ (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@class::A::@method::set::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        set
          reference: <testLibrary>::@class::A::@method::set
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F4
              type: int
          returnType: dynamic
''');
  }

  test_class_setter_native() async {
    var library = await buildLibrary('''
class C {
  void set x(int value) native;
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:21) (firstTokenOffset:12) (offset:21)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        external x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setter_ofGeneric_refEnclosingTypeParameter_false() async {
    var library = await buildLibrary('''
class C<T> {
  set foo(int _) {}
}
''');
    configuration.withConstructors = false;
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
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo
          setters
            #F4 foo (nameOffset:19) (firstTokenOffset:15) (offset:19)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F5 _ (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::C::@setter::foo
      setters
        foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_setter_ofGeneric_refEnclosingTypeParameter_true() async {
    var library = await buildLibrary('''
class C<T> {
  set foo(T _) {}
}
''');
    configuration.withConstructors = false;
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
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo
          setters
            #F4 foo (nameOffset:19) (firstTokenOffset:15) (offset:19)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F5 _ (nameOffset:25) (firstTokenOffset:23) (offset:25)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          setter: <testLibrary>::@class::C::@setter::foo
      setters
        foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F5
              type: T
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
''');
  }

  test_class_setter_static() async {
    var library = await buildLibrary(
      'class C { static void set x(int value) {} }',
    );
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:26) (firstTokenOffset:10) (offset:26)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 value (nameOffset:32) (firstTokenOffset:28) (offset:32)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic static x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        static x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_class_setters() async {
    var library = await buildLibrary('''
class C {
  void set x(int value) {}
  set y(value) {}
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
            #F3 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::y
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F5 x (nameOffset:21) (firstTokenOffset:12) (offset:21)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
            #F7 y (nameOffset:43) (firstTokenOffset:39) (offset:43)
              element: <testLibrary>::@class::C::@setter::y
              formalParameters
                #F8 value (nameOffset:45) (firstTokenOffset:45) (offset:45)
                  element: <testLibrary>::@class::C::@setter::y::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::x
        synthetic y
          reference: <testLibrary>::@class::C::@field::y
          firstFragment: #F3
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
        y
          reference: <testLibrary>::@class::C::@setter::y
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional hasImplicitType value
              firstFragment: #F8
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::y
''');
  }

  test_class_supertype() async {
    var library = await buildLibrary('''
class A {}
class B extends A {}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: A
''');
  }

  test_class_supertype_dynamic() async {
    var library = await buildLibrary('''
class A extends dynamic {}
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
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_supertype_extensionType() async {
    var library = await buildLibrary('''
extension type A(int it) {}
class B extends A {}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::B
      extensionTypes
        #F2 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_class_supertype_genericClass() async {
    var library = await buildLibrary('''
class C extends D<int, double> {}
class D<T1, T2> {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::D
          typeParameters
            #F4 T1 (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T1
            #F5 T2 (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E1 T2
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D<int, double>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::D::@constructor::new
            substitution: {T1: int, T2: double}
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      typeParameters
        #E0 T1
          firstFragment: #F4
        #E1 T2
          firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_supertype_genericClass_tooManyArguments() async {
    var library = await buildLibrary('''
class A<T> {}
class B extends A<int, String> {}
''');
    configuration.withConstructors = false;
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
        #F3 class B (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A<dynamic>
''');
  }

  test_class_supertype_typeArguments_self() async {
    var library = await buildLibrary('''
class A<T> {}
class B extends A<B> {}
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
        #F4 class B (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
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
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A<B>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: B}
''');
  }

  test_class_supertype_typeParameter() async {
    var library = await buildLibrary('''
class A<T> extends T<int> {}
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
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_supertype_unresolved() async {
    var library = await buildLibrary('class C extends D {}');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_class_typeParameters() async {
    var library = await buildLibrary('class C<T, U> {}');
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
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_typeParameters_bound() async {
    var library = await buildLibrary('''
class C<T extends Object, U extends D> {}
class D {}
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
            #F3 U (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F5 class D (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::D
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: Object
        #E1 U
          firstFragment: #F3
          bound: D
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_class_typeParameters_cycle_1of1() async {
    var library = await buildLibrary('class C<T extends T> {}');
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_cycle_2of3() async {
    var library = await buildLibrary(r'''
class C<T extends V, U, V extends T> {}
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
            #F3 U (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: #E1 U
            #F4 V (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: #E2 V
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
        #E1 U
          firstFragment: #F3
        #E2 V
          firstFragment: #F4
          bound: dynamic
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_class_typeParameters_defaultType_cycle_genericFunctionType() async {
    var library = await buildLibrary(r'''
class A<T extends void Function(A)> {}
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
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: void Function(A<dynamic>)
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_defaultType_cycle_genericFunctionType2() async {
    var library = await buildLibrary(r'''
class C<T extends void Function<U extends C>()> {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: void Function<U extends C<dynamic>>()
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_contravariant() async {
    var library = await buildLibrary(r'''
typedef F<X> = void Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 X (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F4 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F5 X (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 X
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: void Function(X)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                X
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      typeParameters
        #E1 X
          firstFragment: #F5
      aliasedType: void Function(X)
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_covariant() async {
    var library = await buildLibrary(r'''
typedef F<X> = X Function();

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 X (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F4 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F5 X (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 X
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: X Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                X
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      typeParameters
        #E1 X
          firstFragment: #F5
      aliasedType: X Function()
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_invariant() async {
    var library = await buildLibrary(r'''
typedef F<X> = X Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 X (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F4 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F5 X (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 X
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: X Function(X)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                X
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      typeParameters
        #E1 X
          firstFragment: #F5
      aliasedType: X Function(X)
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_invariant_legacy() async {
    var library = await buildLibrary(r'''
typedef F<X> = X Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 X (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F4 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F5 X (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 X
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: X Function(X)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                X
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      typeParameters
        #E1 X
          firstFragment: #F5
      aliasedType: X Function(X)
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_both() async {
    var library = await buildLibrary(r'''
class A<X extends X Function(X)> {}
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
            #F2 X (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: X Function(X)
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_contravariant() async {
    var library = await buildLibrary(r'''
class A<X extends void Function(X)> {}
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
            #F2 X (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: void Function(X)
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_covariant() async {
    var library = await buildLibrary(r'''
class A<X extends X Function()> {}
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
            #F2 X (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: X Function()
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_covariant_legacy() async {
    var library = await buildLibrary(r'''
class A<X extends X Function()> {}
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
            #F2 X (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: X Function()
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_defaultType_typeAlias_interface_contravariant() async {
    var library = await buildLibrary(r'''
typedef A<X> = List<void Function(X)>;

class B<X extends A<X>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:46) (firstTokenOffset:40) (offset:46)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 X (nameOffset:48) (firstTokenOffset:48) (offset:48)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      typeAliases
        #F4 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F5 X (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 X
  classes
    notSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: List<void Function(X)>
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                X
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F4
      typeParameters
        #E1 X
          firstFragment: #F5
      aliasedType: List<void Function(X)>
''');
  }

  test_class_typeParameters_defaultType_typeAlias_interface_covariant() async {
    var library = await buildLibrary(r'''
typedef A<X> = Map<X, int>;

class B<X extends A<X>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 X (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      typeAliases
        #F4 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F5 X (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 X
  classes
    notSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: Map<X, int>
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                X
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F4
      typeParameters
        #E1 X
          firstFragment: #F5
      aliasedType: Map<X, int>
''');
  }

  test_class_typeParameters_f_bound_complex() async {
    var library = await buildLibrary('class C<T extends List<U>, U> {}');
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
            #F3 U (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: List<U>
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_typeParameters_f_bound_simple() async {
    var library = await buildLibrary('class C<T extends U, U> {}');
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
            #F3 U (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: U
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_typeParameters_missingName() async {
    var library = await buildLibrary(r'''
class A<T,> {}
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
            #F3 <null-name> (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
              element: #E1 <null-name>
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 <null-name>
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
''');
  }

  test_class_typeParameters_variance_contravariant() async {
    var library = await buildLibrary('class C<in T> {}');
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
            #F2 T (nameOffset:11) (firstTokenOffset:8) (offset:11)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_variance_covariant() async {
    var library = await buildLibrary('class C<out T> {}');
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
            #F2 T (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_variance_invariant() async {
    var library = await buildLibrary('class C<inout T> {}');
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
            #F2 T (nameOffset:14) (firstTokenOffset:8) (offset:14)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
''');
  }

  test_class_typeParameters_variance_multiple() async {
    var library = await buildLibrary('class C<inout T, in U, out V> {}');
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
            #F2 T (nameOffset:14) (firstTokenOffset:8) (offset:14)
              element: #E0 T
            #F3 U (nameOffset:20) (firstTokenOffset:17) (offset:20)
              element: #E1 U
            #F4 V (nameOffset:27) (firstTokenOffset:23) (offset:27)
              element: #E2 V
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
        #E2 V
          firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_classAlias() async {
    var library = await buildLibrary('''
class C = D with E, F, G;
class D {}
class E {}
class F {}
class G {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:43) (firstTokenOffset:37) (offset:43)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
        #F7 class F (nameOffset:54) (firstTokenOffset:48) (offset:54)
          element: <testLibrary>::@class::F
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::F::@constructor::new
              typeName: F
        #F9 class G (nameOffset:65) (firstTokenOffset:59) (offset:65)
          element: <testLibrary>::@class::G
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@class::G::@constructor::new
              typeName: G
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      mixins
        E
        F
        G
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
    class F
      reference: <testLibrary>::@class::F
      firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::F::@constructor::new
          firstFragment: #F8
    class G
      reference: <testLibrary>::@class::G
      firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::G::@constructor::new
          firstFragment: #F10
''');
  }

  test_classAlias_abstract() async {
    var library = await buildLibrary('''
abstract class C = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:46) (firstTokenOffset:40) (offset:46)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    abstract class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_classAlias_base() async {
    var library = await buildLibrary('''
base class C = Object with M;
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F3 mixin M (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@mixin::M
  classes
    base class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: Object
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_classAlias_constructors_beforeOtherProperties() async {
    // https://github.com/dart-lang/sdk/issues/57035
    var library = await buildLibrary('''
abstract mixin class A {}
mixin M {}
class X = A with M;
''');

    var X = library.getClass('X')!;
    expect(X.constructors, hasLength(1));
  }

  test_classAlias_constructors_chain_backward() async {
    var library = await buildLibrary('''
class A {
  A.named();
}
class C = B with M;
class B = A with M;
mixin M {}
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
            #F2 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F3 class C (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::C
          constructors
            #F4 synthetic named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
        #F5 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::named
              typeName: B
      mixins
        #F7 mixin M (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      supertype: B
      mixins
        M
      constructors
        synthetic named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F4
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @-1
                element: <testLibrary>::@class::B::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::B::@constructor::named
          superConstructor: <testLibrary>::@class::B::@constructor::named
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      mixins
        M
      constructors
        synthetic named
          reference: <testLibrary>::@class::B::@constructor::named
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @-1
                element: <testLibrary>::@class::A::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::named
          superConstructor: <testLibrary>::@class::A::@constructor::named
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F7
      superclassConstraints
        Object
''');
  }

  test_classAlias_constructors_chain_forward() async {
    var library = await buildLibrary('''
class A {
  A.named();
}
class B = A with M;
class C = B with M;
mixin M {}
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
            #F2 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F3 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::B::@constructor::named
              typeName: B
        #F5 class C (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
      mixins
        #F7 mixin M (nameOffset:71) (firstTokenOffset:65) (offset:71)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      mixins
        M
      constructors
        synthetic named
          reference: <testLibrary>::@class::B::@constructor::named
          firstFragment: #F4
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @-1
                element: <testLibrary>::@class::A::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::named
          superConstructor: <testLibrary>::@class::A::@constructor::named
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      supertype: B
      mixins
        M
      constructors
        synthetic named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @-1
                element: <testLibrary>::@class::B::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::B::@constructor::named
          superConstructor: <testLibrary>::@class::B::@constructor::named
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F7
      superclassConstraints
        Object
''');
  }

  test_classAlias_constructors_default() async {
    var library = await buildLibrary('''
class A {}
mixin class M {}
class X = A with M;
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
        #F3 class M (nameOffset:23) (firstTokenOffset:11) (offset:23)
          element: <testLibrary>::@class::M
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F5 class X (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::X
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    mixin class M
      reference: <testLibrary>::@class::M
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F4
    class alias X
      reference: <testLibrary>::@class::X
      firstFragment: #F5
      supertype: A
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_classAlias_constructors_dependencies() async {
    var library = await buildLibrary('''
class A {
  A(int i);
}
mixin class M1 {}
mixin class M2 {}

class C2 = C1 with M2;
class C1 = A with M1;
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 i (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::i
        #F4 class M1 (nameOffset:36) (firstTokenOffset:24) (offset:36)
          element: <testLibrary>::@class::M1
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::M1::@constructor::new
              typeName: M1
        #F6 class M2 (nameOffset:54) (firstTokenOffset:42) (offset:54)
          element: <testLibrary>::@class::M2
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::M2::@constructor::new
              typeName: M2
        #F8 class C2 (nameOffset:67) (firstTokenOffset:61) (offset:67)
          element: <testLibrary>::@class::C2
          constructors
            #F9 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@class::C2::@constructor::new
              typeName: C2
              formalParameters
                #F10 i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
                  element: <testLibrary>::@class::C2::@constructor::new::@formalParameter::i
        #F11 class C1 (nameOffset:90) (firstTokenOffset:84) (offset:90)
          element: <testLibrary>::@class::C1
          constructors
            #F12 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
              element: <testLibrary>::@class::C1::@constructor::new
              typeName: C1
              formalParameters
                #F13 i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:90)
                  element: <testLibrary>::@class::C1::@constructor::new::@formalParameter::i
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional i
              firstFragment: #F3
              type: int
    mixin class M1
      reference: <testLibrary>::@class::M1
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::M1::@constructor::new
          firstFragment: #F5
    mixin class M2
      reference: <testLibrary>::@class::M2
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::M2::@constructor::new
          firstFragment: #F7
    class alias C2
      reference: <testLibrary>::@class::C2
      firstFragment: #F8
      supertype: C1
      mixins
        M2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C2::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional i
              firstFragment: #F10
              type: int
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: i @-1
                    element: <testLibrary>::@class::C2::@constructor::new::@formalParameter::i
                    staticType: int
                rightParenthesis: ) @0
              element: <testLibrary>::@class::C1::@constructor::new
          superConstructor: <testLibrary>::@class::C1::@constructor::new
    class alias C1
      reference: <testLibrary>::@class::C1
      firstFragment: #F11
      supertype: A
      mixins
        M1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C1::@constructor::new
          firstFragment: #F12
          formalParameters
            #E2 requiredPositional i
              firstFragment: #F13
              type: int
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: i @-1
                    element: <testLibrary>::@class::C1::@constructor::new::@formalParameter::i
                    staticType: int
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_classAlias_constructors_optionalParameters() async {
    var library = await buildLibrary('''
class A {
  A.c1(int a);
  A.c2(int a, [int? b, int c = 0]);
  A.c3(int a, {int? b, int c = 0});
}

mixin M {}

class C = A with M;
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
            #F2 c1 (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::c1
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
              formalParameters
                #F3 a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@class::A::@constructor::c1::@formalParameter::a
            #F4 c2 (nameOffset:29) (firstTokenOffset:27) (offset:29)
              element: <testLibrary>::@class::A::@constructor::c2
              typeName: A
              typeNameOffset: 27
              periodOffset: 28
              formalParameters
                #F5 a (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@class::A::@constructor::c2::@formalParameter::a
                #F6 b (nameOffset:45) (firstTokenOffset:40) (offset:45)
                  element: <testLibrary>::@class::A::@constructor::c2::@formalParameter::b
                #F7 c (nameOffset:52) (firstTokenOffset:48) (offset:52)
                  element: <testLibrary>::@class::A::@constructor::c2::@formalParameter::c
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @56
                      staticType: int
            #F8 c3 (nameOffset:65) (firstTokenOffset:63) (offset:65)
              element: <testLibrary>::@class::A::@constructor::c3
              typeName: A
              typeNameOffset: 63
              periodOffset: 64
              formalParameters
                #F9 a (nameOffset:72) (firstTokenOffset:68) (offset:72)
                  element: <testLibrary>::@class::A::@constructor::c3::@formalParameter::a
                #F10 b (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@class::A::@constructor::c3::@formalParameter::b
                #F11 c (nameOffset:88) (firstTokenOffset:84) (offset:88)
                  element: <testLibrary>::@class::A::@constructor::c3::@formalParameter::c
                  initializer: expression_1
                    IntegerLiteral
                      literal: 0 @92
                      staticType: int
        #F12 class C (nameOffset:118) (firstTokenOffset:112) (offset:118)
          element: <testLibrary>::@class::C
          constructors
            #F13 synthetic c1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::C::@constructor::c1
              typeName: C
              formalParameters
                #F14 a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c1::@formalParameter::a
            #F15 synthetic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::C::@constructor::c2
              typeName: C
              formalParameters
                #F16 a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c2::@formalParameter::a
                #F17 b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c2::@formalParameter::b
                #F18 c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c2::@formalParameter::c
                  initializer: expression_0
            #F19 synthetic c3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
              element: <testLibrary>::@class::C::@constructor::c3
              typeName: C
              formalParameters
                #F20 a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c3::@formalParameter::a
                #F21 b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c3::@formalParameter::b
                #F22 c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: <testLibrary>::@class::C::@constructor::c3::@formalParameter::c
                  initializer: expression_1
      mixins
        #F23 mixin M (nameOffset:106) (firstTokenOffset:100) (offset:106)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        c1
          reference: <testLibrary>::@class::A::@constructor::c1
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
        c2
          reference: <testLibrary>::@class::A::@constructor::c2
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F5
              type: int
            #E2 optionalPositional b
              firstFragment: #F6
              type: int?
            #E3 optionalPositional c
              firstFragment: #F7
              type: int
              constantInitializer
                fragment: #F7
                expression: expression_0
        c3
          reference: <testLibrary>::@class::A::@constructor::c3
          firstFragment: #F8
          formalParameters
            #E4 requiredPositional a
              firstFragment: #F9
              type: int
            #E5 optionalNamed b
              firstFragment: #F10
              type: int?
            #E6 optionalNamed c
              firstFragment: #F11
              type: int
              constantInitializer
                fragment: #F11
                expression: expression_1
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F12
      supertype: A
      mixins
        M
      constructors
        synthetic c1
          reference: <testLibrary>::@class::C::@constructor::c1
          firstFragment: #F13
          formalParameters
            #E7 requiredPositional a
              firstFragment: #F14
              type: int
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: c1 @-1
                element: <testLibrary>::@class::A::@constructor::c1
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: a @-1
                    element: <testLibrary>::@class::C::@constructor::c1::@formalParameter::a
                    staticType: int
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::c1
          superConstructor: <testLibrary>::@class::A::@constructor::c1
        synthetic c2
          reference: <testLibrary>::@class::C::@constructor::c2
          firstFragment: #F15
          formalParameters
            #E8 requiredPositional a
              firstFragment: #F16
              type: int
            #E9 optionalPositional b
              firstFragment: #F17
              type: int?
            #E10 optionalPositional c
              firstFragment: #F18
              type: int
              constantInitializer
                fragment: #F18
                expression: expression_0
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: c2 @-1
                element: <testLibrary>::@class::A::@constructor::c2
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: a @-1
                    element: <testLibrary>::@class::C::@constructor::c2::@formalParameter::a
                    staticType: int
                  SimpleIdentifier
                    token: b @-1
                    element: <testLibrary>::@class::C::@constructor::c2::@formalParameter::b
                    staticType: int?
                  SimpleIdentifier
                    token: c @-1
                    element: <testLibrary>::@class::C::@constructor::c2::@formalParameter::c
                    staticType: int
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::c2
          superConstructor: <testLibrary>::@class::A::@constructor::c2
        synthetic c3
          reference: <testLibrary>::@class::C::@constructor::c3
          firstFragment: #F19
          formalParameters
            #E11 requiredPositional a
              firstFragment: #F20
              type: int
            #E12 optionalNamed b
              firstFragment: #F21
              type: int?
            #E13 optionalNamed c
              firstFragment: #F22
              type: int
              constantInitializer
                fragment: #F22
                expression: expression_1
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: c3 @-1
                element: <testLibrary>::@class::A::@constructor::c3
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: a @-1
                    element: <testLibrary>::@class::C::@constructor::c3::@formalParameter::a
                    staticType: int
                  SimpleIdentifier
                    token: b @-1
                    element: <testLibrary>::@class::C::@constructor::c3::@formalParameter::b
                    staticType: int?
                  SimpleIdentifier
                    token: c @-1
                    element: <testLibrary>::@class::C::@constructor::c3::@formalParameter::c
                    staticType: int
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::c3
          superConstructor: <testLibrary>::@class::A::@constructor::c3
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F23
      superclassConstraints
        Object
''');
  }

  test_classAlias_constructors_reading() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin M {}

class A {
  const A.named();
}

class B = A with M;
''');

    var library = await buildLibrary('''
import 'a.dart';
const x = B.named();
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
        #F1 hasInitializer x (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: B @27
                  element2: package:test/a.dart::@class::B
                  type: B
                period: . @28
                name: SimpleIdentifier
                  token: named @29
                  element: package:test/a.dart::@class::B::@constructor::named
                  staticType: null
                element: package:test/a.dart::@class::B::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @34
                rightParenthesis: ) @35
              staticType: B
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: B
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: B
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_classAlias_constructors_requiredParameters() async {
    var library = await buildLibrary('''
class A<T extends num> {
  A(T x, T y);
}

mixin M {}

class B<E extends num> = A<E> with M;
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
            #F3 new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F4 x (nameOffset:31) (firstTokenOffset:29) (offset:31)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                #F5 y (nameOffset:36) (firstTokenOffset:34) (offset:36)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::y
        #F6 class B (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::B
          typeParameters
            #F7 E (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: #E1 E
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              formalParameters
                #F9 x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::x
                #F10 y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::y
      mixins
        #F11 mixin M (nameOffset:49) (firstTokenOffset:43) (offset:49)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E2 requiredPositional x
              firstFragment: #F4
              type: T
            #E3 requiredPositional y
              firstFragment: #F5
              type: T
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 E
          firstFragment: #F7
          bound: num
      supertype: A<E>
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          formalParameters
            #E4 requiredPositional x
              firstFragment: #F9
              type: E
            #E5 requiredPositional y
              firstFragment: #F10
              type: E
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: x @-1
                    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::x
                    staticType: E
                  SimpleIdentifier
                    token: y @-1
                    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::y
                    staticType: E
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: E}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F11
      superclassConstraints
        Object
''');
  }

  test_classAlias_documented() async {
    var library = await buildLibrary('''
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:0) (offset:22)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:43) (firstTokenOffset:37) (offset:43)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:54) (firstTokenOffset:48) (offset:54)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_classAlias_documented_tripleSlash() async {
    var library = await buildLibrary('''
/// aaa
/// b
/// cc
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:27) (firstTokenOffset:0) (offset:27)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /// aaa\n/// b\n/// cc
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_classAlias_documented_withLeadingNonDocumentation() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:66) (firstTokenOffset:44) (offset:66)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:87) (firstTokenOffset:81) (offset:87)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:87)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:98) (firstTokenOffset:92) (offset:98)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_classAlias_final() async {
    var library = await buildLibrary('''
final class C = Object with M;
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F3 mixin M (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@mixin::M
  classes
    final class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: Object
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_classAlias_generic() async {
    var library = await buildLibrary('''
class Z = A with B<int>, C<double>;
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class Z (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::Z
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
        #F3 class A (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::A
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F5 class B (nameOffset:53) (firstTokenOffset:47) (offset:53)
          element: <testLibrary>::@class::B
          typeParameters
            #F6 B1 (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 B1
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F8 class C (nameOffset:68) (firstTokenOffset:62) (offset:68)
          element: <testLibrary>::@class::C
          typeParameters
            #F9 C1 (nameOffset:70) (firstTokenOffset:70) (offset:70)
              element: #E1 C1
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class alias Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F1
      supertype: A
      mixins
        B<int>
        C<double>
      constructors
        synthetic new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      typeParameters
        #E0 B1
          firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F8
      typeParameters
        #E1 C1
          firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
''');
  }

  test_classAlias_interface() async {
    var library = await buildLibrary('''
interface class C = Object with M;
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:16) (firstTokenOffset:0) (offset:16)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F3 mixin M (nameOffset:41) (firstTokenOffset:35) (offset:41)
          element: <testLibrary>::@mixin::M
  classes
    interface class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: Object
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_classAlias_invalid_extendsEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E { v }
mixin M {}
''');

    var library = await buildLibrary('''
import 'a.dart';
class A = E with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 class A (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    class alias A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      supertype: Object
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
''');
  }

  test_classAlias_invalid_extendsMixin() async {
    var library = await buildLibrary('''
mixin M1 {}
mixin M2 {}
class A = M1 with M2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      mixins
        #F3 mixin M1 (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M1
        #F4 mixin M2 (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@mixin::M2
  classes
    class alias A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      supertype: Object
      mixins
        M2
      constructors
        synthetic const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F3
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F4
      superclassConstraints
        Object
''');
  }

  test_classAlias_mixin_class() async {
    var library = await buildLibrary('''
mixin class C = Object with M;
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F3 mixin M (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@mixin::M
  classes
    mixin class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: Object
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_classAlias_notSimplyBounded_self() async {
    var library = await buildLibrary('''
class C<T extends C> = D with E;
class D {}
class E {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::D
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F6 class E (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::E
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    notSimplyBounded class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<dynamic>
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F7
''');
  }

  test_classAlias_notSimplyBounded_simple_no_type_parameter_bound() async {
    // If no bounds are specified, then the class is simply bounded by syntax
    // alone, so there is no reason to assign it a slot.
    var library = await buildLibrary('''
class C<T> = D with E;
class D {}
class E {}
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:29) (firstTokenOffset:23) (offset:29)
          element: <testLibrary>::@class::D
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F6 class E (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::E
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F7
''');
  }

  test_classAlias_notSimplyBounded_simple_non_generic() async {
    // If no type parameters are specified, then the class is simply bounded, so
    // there is no reason to assign it a slot.
    var library = await buildLibrary('''
class C = D with E;
class D {}
class E {}
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:26) (firstTokenOffset:20) (offset:26)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
''');
  }

  test_classAlias_sealed() async {
    var library = await buildLibrary('''
sealed class C = Object with M;
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F3 mixin M (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@mixin::M
  classes
    abstract sealed class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: Object
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_classAlias_with_const_constructors() async {
    newFile('$testPackageLibPath/a.dart', r'''
class Base {
  const Base._priv();
  const Base();
  const Base.named();
}
''');
    var library = await buildLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 class M (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::M
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F3 class MixinApp (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::MixinApp
          constructors
            #F4 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::new
              typeName: MixinApp
            #F5 synthetic const named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::named
              typeName: MixinApp
  classes
    class M
      reference: <testLibrary>::@class::M
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F2
    class alias MixinApp
      reference: <testLibrary>::@class::MixinApp
      firstFragment: #F3
      supertype: Base
      mixins
        M
      constructors
        synthetic const new
          reference: <testLibrary>::@class::MixinApp::@constructor::new
          firstFragment: #F4
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::new
          superConstructor: package:test/a.dart::@class::Base::@constructor::new
        synthetic const named
          reference: <testLibrary>::@class::MixinApp::@constructor::named
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @-1
                element: package:test/a.dart::@class::Base::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::named
          superConstructor: package:test/a.dart::@class::Base::@constructor::named
''');
  }

  test_classAlias_with_forwarding_constructors() async {
    newFile('$testPackageLibPath/a.dart', r'''
class Base {
  bool x = true;
  Base._priv();
  Base();
  Base.noArgs();
  Base.requiredArg(x);
  Base.positionalArg([bool x = true]);
  Base.positionalArg2([this.x = true]);
  Base.namedArg({int x = 42});
  Base.namedArg2({this.x = true});
  factory Base.fact() => Base();
  factory Base.fact2() = Base.noArgs;
}
''');
    var library = await buildLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 class M (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::M
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F3 class MixinApp (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::MixinApp
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::new
              typeName: MixinApp
            #F5 synthetic noArgs (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::noArgs
              typeName: MixinApp
            #F6 synthetic requiredArg (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::requiredArg
              typeName: MixinApp
              formalParameters
                #F7 x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::MixinApp::@constructor::requiredArg::@formalParameter::x
            #F8 synthetic positionalArg (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::positionalArg
              typeName: MixinApp
              formalParameters
                #F9 x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::MixinApp::@constructor::positionalArg::@formalParameter::x
                  initializer: expression_0
                    BooleanLiteral
                      literal: true @127
                      staticType: bool
            #F10 synthetic positionalArg2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::positionalArg2
              typeName: MixinApp
              formalParameters
                #F11 x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::MixinApp::@constructor::positionalArg2::@formalParameter::x
                  initializer: expression_1
                    BooleanLiteral
                      literal: true @167
                      staticType: bool
            #F12 synthetic namedArg (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::namedArg
              typeName: MixinApp
              formalParameters
                #F13 x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::MixinApp::@constructor::namedArg::@formalParameter::x
                  initializer: expression_2
                    IntegerLiteral
                      literal: 42 @200
                      staticType: int
            #F14 synthetic namedArg2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::MixinApp::@constructor::namedArg2
              typeName: MixinApp
              formalParameters
                #F15 x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::MixinApp::@constructor::namedArg2::@formalParameter::x
                  initializer: expression_3
                    BooleanLiteral
                      literal: true @233
                      staticType: bool
  classes
    class M
      reference: <testLibrary>::@class::M
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F2
    hasNonFinalField class alias MixinApp
      reference: <testLibrary>::@class::MixinApp
      firstFragment: #F3
      supertype: Base
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::MixinApp::@constructor::new
          firstFragment: #F4
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::new
          superConstructor: package:test/a.dart::@class::Base::@constructor::new
        synthetic noArgs
          reference: <testLibrary>::@class::MixinApp::@constructor::noArgs
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: noArgs @-1
                element: package:test/a.dart::@class::Base::@constructor::noArgs
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::noArgs
          superConstructor: package:test/a.dart::@class::Base::@constructor::noArgs
        synthetic requiredArg
          reference: <testLibrary>::@class::MixinApp::@constructor::requiredArg
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F7
              type: dynamic
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: requiredArg @-1
                element: package:test/a.dart::@class::Base::@constructor::requiredArg
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: x @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::requiredArg::@formalParameter::x
                    staticType: dynamic
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::requiredArg
          superConstructor: package:test/a.dart::@class::Base::@constructor::requiredArg
        synthetic positionalArg
          reference: <testLibrary>::@class::MixinApp::@constructor::positionalArg
          firstFragment: #F8
          formalParameters
            #E1 optionalPositional x
              firstFragment: #F9
              type: bool
              constantInitializer
                fragment: #F9
                expression: expression_0
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: positionalArg @-1
                element: package:test/a.dart::@class::Base::@constructor::positionalArg
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: x @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::positionalArg::@formalParameter::x
                    staticType: bool
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::positionalArg
          superConstructor: package:test/a.dart::@class::Base::@constructor::positionalArg
        synthetic positionalArg2
          reference: <testLibrary>::@class::MixinApp::@constructor::positionalArg2
          firstFragment: #F10
          formalParameters
            #E2 optionalPositional final x
              firstFragment: #F11
              type: bool
              constantInitializer
                fragment: #F11
                expression: expression_1
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: positionalArg2 @-1
                element: package:test/a.dart::@class::Base::@constructor::positionalArg2
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: x @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::positionalArg2::@formalParameter::x
                    staticType: bool
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::positionalArg2
          superConstructor: package:test/a.dart::@class::Base::@constructor::positionalArg2
        synthetic namedArg
          reference: <testLibrary>::@class::MixinApp::@constructor::namedArg
          firstFragment: #F12
          formalParameters
            #E3 optionalNamed x
              firstFragment: #F13
              type: int
              constantInitializer
                fragment: #F13
                expression: expression_2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: namedArg @-1
                element: package:test/a.dart::@class::Base::@constructor::namedArg
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: x @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::namedArg::@formalParameter::x
                    staticType: int
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::namedArg
          superConstructor: package:test/a.dart::@class::Base::@constructor::namedArg
        synthetic namedArg2
          reference: <testLibrary>::@class::MixinApp::@constructor::namedArg2
          firstFragment: #F14
          formalParameters
            #E4 optionalNamed final x
              firstFragment: #F15
              type: bool
              constantInitializer
                fragment: #F15
                expression: expression_3
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: namedArg2 @-1
                element: package:test/a.dart::@class::Base::@constructor::namedArg2
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: x @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::namedArg2::@formalParameter::x
                    staticType: bool
                rightParenthesis: ) @0
              element: package:test/a.dart::@class::Base::@constructor::namedArg2
          superConstructor: package:test/a.dart::@class::Base::@constructor::namedArg2
''');
  }

  test_classAlias_with_forwarding_constructors_type_substitution() async {
    var library = await buildLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class Base (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::Base
          typeParameters
            #F2 T (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E0 T
          constructors
            #F3 ctor (nameOffset:23) (firstTokenOffset:18) (offset:23)
              element: <testLibrary>::@class::Base::@constructor::ctor
              typeName: Base
              typeNameOffset: 18
              periodOffset: 22
              formalParameters
                #F4 t (nameOffset:30) (firstTokenOffset:28) (offset:30)
                  element: <testLibrary>::@class::Base::@constructor::ctor::@formalParameter::t
                #F5 l (nameOffset:41) (firstTokenOffset:33) (offset:41)
                  element: <testLibrary>::@class::Base::@constructor::ctor::@formalParameter::l
        #F6 class M (nameOffset:53) (firstTokenOffset:47) (offset:53)
          element: <testLibrary>::@class::M
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F8 class MixinApp (nameOffset:64) (firstTokenOffset:58) (offset:64)
          element: <testLibrary>::@class::MixinApp
          constructors
            #F9 synthetic ctor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@class::MixinApp::@constructor::ctor
              typeName: MixinApp
              formalParameters
                #F10 t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
                  element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::t
                #F11 l (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
                  element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::l
  classes
    class Base
      reference: <testLibrary>::@class::Base
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        ctor
          reference: <testLibrary>::@class::Base::@constructor::ctor
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional t
              firstFragment: #F4
              type: T
            #E2 requiredPositional l
              firstFragment: #F5
              type: List<T>
    class M
      reference: <testLibrary>::@class::M
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F7
    class alias MixinApp
      reference: <testLibrary>::@class::MixinApp
      firstFragment: #F8
      supertype: Base<dynamic>
      mixins
        M
      constructors
        synthetic ctor
          reference: <testLibrary>::@class::MixinApp::@constructor::ctor
          firstFragment: #F9
          formalParameters
            #E3 requiredPositional t
              firstFragment: #F10
              type: dynamic
            #E4 requiredPositional l
              firstFragment: #F11
              type: List<dynamic>
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: ctor @-1
                element: <testLibrary>::@class::Base::@constructor::ctor
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: t @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::t
                    staticType: dynamic
                  SimpleIdentifier
                    token: l @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::l
                    staticType: List<dynamic>
                rightParenthesis: ) @0
              element: <testLibrary>::@class::Base::@constructor::ctor
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::Base::@constructor::ctor
            substitution: {T: dynamic}
''');
  }

  test_classAlias_with_forwarding_constructors_type_substitution_complex() async {
    var library = await buildLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp<U> = Base<List<U>> with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class Base (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::Base
          typeParameters
            #F2 T (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E0 T
          constructors
            #F3 ctor (nameOffset:23) (firstTokenOffset:18) (offset:23)
              element: <testLibrary>::@class::Base::@constructor::ctor
              typeName: Base
              typeNameOffset: 18
              periodOffset: 22
              formalParameters
                #F4 t (nameOffset:30) (firstTokenOffset:28) (offset:30)
                  element: <testLibrary>::@class::Base::@constructor::ctor::@formalParameter::t
                #F5 l (nameOffset:41) (firstTokenOffset:33) (offset:41)
                  element: <testLibrary>::@class::Base::@constructor::ctor::@formalParameter::l
        #F6 class M (nameOffset:53) (firstTokenOffset:47) (offset:53)
          element: <testLibrary>::@class::M
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F8 class MixinApp (nameOffset:64) (firstTokenOffset:58) (offset:64)
          element: <testLibrary>::@class::MixinApp
          typeParameters
            #F9 U (nameOffset:73) (firstTokenOffset:73) (offset:73)
              element: #E1 U
          constructors
            #F10 synthetic ctor (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@class::MixinApp::@constructor::ctor
              typeName: MixinApp
              formalParameters
                #F11 t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
                  element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::t
                #F12 l (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
                  element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::l
  classes
    class Base
      reference: <testLibrary>::@class::Base
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        ctor
          reference: <testLibrary>::@class::Base::@constructor::ctor
          firstFragment: #F3
          formalParameters
            #E2 requiredPositional t
              firstFragment: #F4
              type: T
            #E3 requiredPositional l
              firstFragment: #F5
              type: List<T>
    class M
      reference: <testLibrary>::@class::M
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F7
    class alias MixinApp
      reference: <testLibrary>::@class::MixinApp
      firstFragment: #F8
      typeParameters
        #E1 U
          firstFragment: #F9
      supertype: Base<List<U>>
      mixins
        M
      constructors
        synthetic ctor
          reference: <testLibrary>::@class::MixinApp::@constructor::ctor
          firstFragment: #F10
          formalParameters
            #E4 requiredPositional t
              firstFragment: #F11
              type: List<U>
            #E5 requiredPositional l
              firstFragment: #F12
              type: List<List<U>>
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: ctor @-1
                element: <testLibrary>::@class::Base::@constructor::ctor
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: t @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::t
                    staticType: List<U>
                  SimpleIdentifier
                    token: l @-1
                    element: <testLibrary>::@class::MixinApp::@constructor::ctor::@formalParameter::l
                    staticType: List<List<U>>
                rightParenthesis: ) @0
              element: <testLibrary>::@class::Base::@constructor::ctor
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::Base::@constructor::ctor
            substitution: {T: List<U>}
''');
  }

  test_classAlias_with_mixin_members() async {
    var library = await buildLibrary('''
class C = D with E;
class D {}
class E {
  int get a => null;
  void set b(int i) {}
  void f() {}
  int x;
}''');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:26) (firstTokenOffset:20) (offset:26)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::E
          fields
            #F6 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::E::@field::a
            #F7 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::E::@field::b
            #F8 x (nameOffset:105) (firstTokenOffset:105) (offset:105)
              element: <testLibrary>::@class::E::@field::x
          constructors
            #F9 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
          getters
            #F10 a (nameOffset:51) (firstTokenOffset:43) (offset:51)
              element: <testLibrary>::@class::E::@getter::a
            #F11 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
              element: <testLibrary>::@class::E::@getter::x
          setters
            #F12 b (nameOffset:73) (firstTokenOffset:64) (offset:73)
              element: <testLibrary>::@class::E::@setter::b
              formalParameters
                #F13 i (nameOffset:79) (firstTokenOffset:75) (offset:79)
                  element: <testLibrary>::@class::E::@setter::b::@formalParameter::i
            #F14 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
              element: <testLibrary>::@class::E::@setter::x
              formalParameters
                #F15 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:105)
                  element: <testLibrary>::@class::E::@setter::x::@formalParameter::value
          methods
            #F16 f (nameOffset:92) (firstTokenOffset:87) (offset:92)
              element: <testLibrary>::@class::E::@method::f
  classes
    hasNonFinalField class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      mixins
        E
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    hasNonFinalField class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      fields
        synthetic a
          reference: <testLibrary>::@class::E::@field::a
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::E::@getter::a
        synthetic b
          reference: <testLibrary>::@class::E::@field::b
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@class::E::@setter::b
        x
          reference: <testLibrary>::@class::E::@field::x
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::E::@getter::x
          setter: <testLibrary>::@class::E::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F9
      getters
        a
          reference: <testLibrary>::@class::E::@getter::a
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::E::@field::a
        synthetic x
          reference: <testLibrary>::@class::E::@getter::x
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::E::@field::x
      setters
        b
          reference: <testLibrary>::@class::E::@setter::b
          firstFragment: #F12
          formalParameters
            #E0 requiredPositional i
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@class::E::@field::b
        synthetic x
          reference: <testLibrary>::@class::E::@setter::x
          firstFragment: #F14
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@class::E::@field::x
      methods
        f
          reference: <testLibrary>::@class::E::@method::f
          firstFragment: #F16
          returnType: void
''');
  }

  test_classes() async {
    var library = await buildLibrary('class C {} class D {}');
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
''');
  }

  test_implicitConstructor_named_const() async {
    var library = await buildLibrary('''
class C {
  final Object x;
  const C.named(this.x);
}
const x = C.named(42);
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
            #F2 x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 const named (nameOffset:38) (firstTokenOffset:30) (offset:38)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 36
              periodOffset: 37
              formalParameters
                #F4 this.x (nameOffset:49) (firstTokenOffset:44) (offset:49)
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@getter::x
      topLevelVariables
        #F6 hasInitializer x (nameOffset:61) (firstTokenOffset:61) (offset:61)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: C @65
                  element2: <testLibrary>::@class::C
                  type: C
                period: . @66
                name: SimpleIdentifier
                  token: named @67
                  element: <testLibrary>::@class::C::@constructor::named
                  staticType: null
                element: <testLibrary>::@class::C::@constructor::named
              argumentList: ArgumentList
                leftParenthesis: ( @72
                arguments
                  IntegerLiteral
                    literal: 42 @73
                    staticType: int
                rightParenthesis: ) @75
              staticType: C
      getters
        #F7 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
          element: <testLibrary>::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: Object
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F4
              type: Object
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: Object
          variable: <testLibrary>::@class::C::@field::x
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F6
      type: C
      constantInitializer
        fragment: #F6
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F7
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_invalid_setterParameter_fieldFormalParameter() async {
    var library = await buildLibrary('''
class C {
  int foo;
  void set bar(this.foo) {}
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
            #F2 foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::foo
            #F3 synthetic bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::bar
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
            #F8 bar (nameOffset:32) (firstTokenOffset:23) (offset:32)
              element: <testLibrary>::@class::C::@setter::bar
              formalParameters
                #F9 this.foo (nameOffset:41) (firstTokenOffset:36) (offset:41)
                  element: <testLibrary>::@class::C::@setter::bar::@formalParameter::foo
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
        synthetic bar
          reference: <testLibrary>::@class::C::@field::bar
          firstFragment: #F3
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::bar
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
        bar
          reference: <testLibrary>::@class::C::@setter::bar
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final hasImplicitType foo
              firstFragment: #F9
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::bar
''');
  }

  test_invalid_setterParameter_fieldFormalParameter_self() async {
    var library = await buildLibrary('''
class C {
  set x(this.x) {}
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
            #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 x (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F5 this.x (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_unused_type_parameter() async {
    var library = await buildLibrary('''
class C<T> {
  void f() {}
}
C<int> c;
var v = c.f;
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 f (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@class::C::@method::f
      topLevelVariables
        #F5 c (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c
        #F6 hasInitializer v (nameOffset:43) (firstTokenOffset:43) (offset:43)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c
        #F8 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@getter::v
      setters
        #F9 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F11 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
          element: <testLibrary>::@setter::v
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@setter::v::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F4
          returnType: void
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<int>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F6
      type: void Function()
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
      returnType: C<int>
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F8
      returnType: void Function()
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: C<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: void Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }
}

abstract class ClassElementTest_augmentation extends ElementsBaseTest {
  test_augmentation_constField_hasConstConstructor() async {
    var library = await buildLibrary(r'''
class A {
  const A();
}

augment class A {
  static const int foo = 0;
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
          nextFragment: #F2
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 hasInitializer foo (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @69
                  staticType: int
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static const hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic static foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmentation_constField_noConstConstructor() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  static const int foo = 0;
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 hasInitializer foo (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @55
                  staticType: int
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static const hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic static foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmentation_finalField_hasConstConstructor() async {
    var library = await buildLibrary(r'''
class A {
  const A();
}

augment class A {
  final int foo = 0;
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
          nextFragment: #F2
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 hasInitializer foo (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @62
                  staticType: int
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmentation_finalField_noConstConstructor() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  final int foo = 0;
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 hasInitializer foo (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmentationTarget() async {
    newFile('$testPackageLibPath/a1.dart', r'''
part of 'test.dart';
part 'a11.dart';
part 'a12.dart';
augment class A {}
''');

    newFile('$testPackageLibPath/a11.dart', r'''
part of 'a1.dart';
augment class A {}
''');

    newFile('$testPackageLibPath/a12.dart', r'''
part of 'a1.dart';
augment class A {}
''');

    newFile('$testPackageLibPath/a2.dart', r'''
part of 'test.dart';
part 'a21.dart';
part 'a22.dart';
augment class A {}
''');

    newFile('$testPackageLibPath/a21.dart', r'''
part of 'a2.dart';
augment class A {}
''');

    newFile('$testPackageLibPath/a22.dart', r'''
part of 'a2.dart';
augment class A {}
''');

    configuration.withExportScope = true;
    var library = await buildLibrary(r'''
part 'a1.dart';
part 'a2.dart';
class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a1.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/a2.dart
          partKeywordOffset: 16
          unit: #F2
      classes
        #F3 class A (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
    #F1 package:test/a1.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F6
      parts
        part_2
          uri: package:test/a11.dart
          partKeywordOffset: 21
          unit: #F6
        part_3
          uri: package:test/a12.dart
          partKeywordOffset: 38
          unit: #F7
      classes
        #F4 class A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          nextFragment: #F8
    #F6 package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      nextFragment: #F7
      classes
        #F8 class A (nameOffset:33) (firstTokenOffset:19) (offset:33)
          element: <testLibrary>::@class::A
          previousFragment: #F4
          nextFragment: #F9
    #F7 package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F6
      nextFragment: #F2
      classes
        #F9 class A (nameOffset:33) (firstTokenOffset:19) (offset:33)
          element: <testLibrary>::@class::A
          previousFragment: #F8
          nextFragment: #F10
    #F2 package:test/a2.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F7
      nextFragment: #F11
      parts
        part_4
          uri: package:test/a21.dart
          partKeywordOffset: 21
          unit: #F11
        part_5
          uri: package:test/a22.dart
          partKeywordOffset: 38
          unit: #F12
      classes
        #F10 class A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@class::A
          previousFragment: #F9
          nextFragment: #F13
    #F11 package:test/a21.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F2
      nextFragment: #F12
      classes
        #F13 class A (nameOffset:33) (firstTokenOffset:19) (offset:33)
          element: <testLibrary>::@class::A
          previousFragment: #F10
          nextFragment: #F14
    #F12 package:test/a22.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F11
      classes
        #F14 class A (nameOffset:33) (firstTokenOffset:19) (offset:33)
          element: <testLibrary>::@class::A
          previousFragment: #F13
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
  exportedReferences
    declared <testLibrary>::@class::A
  exportNamespace
    A: <testLibrary>::@class::A
''');
  }

  test_augmentationTarget_augmentationThenDeclaration() async {
    var library = await buildLibrary(r'''
augment class A {
  void foo1() {}
}

class A {
  void foo2() {}
}

augment class A {
  void foo3() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:14) (firstTokenOffset:0) (offset:14)
          element: <testLibrary>::@class::A::@def::0
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::A::@def::0::@constructor::new
              typeName: A
          methods
            #F3 foo1 (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@class::A::@def::0::@method::foo1
        #F4 class A (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::A::@def::1
          nextFragment: #F5
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::A::@def::1::@constructor::new
              typeName: A
          methods
            #F7 foo2 (nameOffset:55) (firstTokenOffset:50) (offset:55)
              element: <testLibrary>::@class::A::@def::1::@method::foo2
        #F5 class A (nameOffset:82) (firstTokenOffset:68) (offset:82)
          element: <testLibrary>::@class::A::@def::1
          previousFragment: #F4
          methods
            #F8 foo3 (nameOffset:93) (firstTokenOffset:88) (offset:93)
              element: <testLibrary>::@class::A::@def::1::@method::foo3
  classes
    class A
      reference: <testLibrary>::@class::A::@def::0
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::0::@constructor::new
          firstFragment: #F2
      methods
        foo1
          reference: <testLibrary>::@class::A::@def::0::@method::foo1
          firstFragment: #F3
          returnType: void
    class A
      reference: <testLibrary>::@class::A::@def::1
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::1::@constructor::new
          firstFragment: #F6
      methods
        foo2
          reference: <testLibrary>::@class::A::@def::1::@method::foo2
          firstFragment: #F7
          returnType: void
        foo3
          reference: <testLibrary>::@class::A::@def::1::@method::foo3
          firstFragment: #F8
          returnType: void
''');
  }

  test_augmentationTarget_no2() async {
    var library = await buildLibrary(r'''
part 'a.dart';
class B {}

augment class A {
  void foo1() {}
}

augment class A {
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: source 'package:test/a.dart'
          partKeywordOffset: 0
      classes
        #F1 class B (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F3 class A (nameOffset:41) (firstTokenOffset:27) (offset:41)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 foo1 (nameOffset:52) (firstTokenOffset:47) (offset:52)
              element: <testLibrary>::@class::A::@method::foo1
        #F4 class A (nameOffset:79) (firstTokenOffset:65) (offset:79)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          methods
            #F7 foo2 (nameOffset:90) (firstTokenOffset:85) (offset:90)
              element: <testLibrary>::@class::A::@method::foo2
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        foo1
          reference: <testLibrary>::@class::A::@method::foo1
          firstFragment: #F6
          returnType: void
        foo2
          reference: <testLibrary>::@class::A::@method::foo2
          firstFragment: #F7
          returnType: void
''');
  }

  test_augmented_constructor_augment_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment A.foo();
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F7 augment foo (nameOffset:58) (firstTokenOffset:48) (offset:58)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 56
              periodOffset: 57
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F7
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_constructor_augment_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment A.foo();
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F5 augment foo (nameOffset:63) (firstTokenOffset:53) (offset:63)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 61
              periodOffset: 62
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F5
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_constructor_augment_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  augment A.foo();
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
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F4 augment foo (nameOffset:59) (firstTokenOffset:49) (offset:59)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 57
              periodOffset: 58
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F4
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          returnType: void
''');
  }

  test_augmented_constructor_augment_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

augment class A {
  augment A.foo();
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          setters
            #F4 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F5 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F6 augment foo (nameOffset:63) (firstTokenOffset:53) (offset:63)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 61
              periodOffset: 62
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F6
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_constructors_add_named() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  A.named();
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
          nextFragment: #F2
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F3 named (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 32
              periodOffset: 33
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
''');
  }

  test_augmented_constructors_add_named_generic() async {
    var library = await buildLibrary(r'''
class A<T> {}

augment class A<T> {
  A.named(T  a);
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:29) (firstTokenOffset:15) (offset:29)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: #E0 T
              previousFragment: #F3
          constructors
            #F5 named (nameOffset:40) (firstTokenOffset:38) (offset:40)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 38
              periodOffset: 39
              formalParameters
                #F6 a (nameOffset:49) (firstTokenOffset:46) (offset:49)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F6
              type: T
''');
  }

  test_augmented_constructors_add_named_hasUnnamed() async {
    var library = await buildLibrary(r'''
class A {
  A();
}

augment class A {
  A.named();
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
          nextFragment: #F2
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
        #F2 class A (nameOffset:34) (firstTokenOffset:20) (offset:34)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F4 named (nameOffset:42) (firstTokenOffset:40) (offset:42)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 40
              periodOffset: 41
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F4
''');
  }

  test_augmented_constructors_add_unnamed() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  A();
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
          nextFragment: #F2
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:32) (offset:32)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 32
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
    var library = await buildLibrary(r'''
class A {
  A.named();
}

augment class A {
  A();
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
          nextFragment: #F2
          constructors
            #F3 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 46
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
''');
  }

  test_augmented_constructors_add_useFieldFormal() async {
    var library = await buildLibrary(r'''
class A {
  final int f;
}

augment class A {
  A.named(this.f);
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
          nextFragment: #F2
          fields
            #F3 f (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::A::@field::f
          getters
            #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@getter::f
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F5 named (nameOffset:50) (firstTokenOffset:48) (offset:50)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 48
              periodOffset: 49
              formalParameters
                #F6 this.f (nameOffset:61) (firstTokenOffset:56) (offset:61)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::f
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType f
              firstFragment: #F6
              type: int
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
''');
  }

  test_augmented_constructors_add_useFieldInitializer() async {
    var library = await buildLibrary(r'''
class A {
  final int f;
}

augment class A {
  const A.named() : f = 0;
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
          nextFragment: #F2
          fields
            #F3 f (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::A::@field::f
          getters
            #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@getter::f
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F5 const named (nameOffset:56) (firstTokenOffset:48) (offset:56)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 54
              periodOffset: 55
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::f
      constructors
        const named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F5
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: f @66
                element: <testLibrary>::@class::A::@field::f
                staticType: null
              equals: = @68
              expression: IntegerLiteral
                literal: 0 @70
                staticType: int
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
''');
  }

  test_augmented_field_augment_constructor() async {
    var library = await buildLibrary(r'''
class A {
  A.foo();
}

augment class A {
  augment int foo = 1;
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
          nextFragment: #F2
          constructors
            #F3 foo (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F2 class A (nameOffset:38) (firstTokenOffset:24) (offset:38)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment int foo = 1;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment int foo = 1;
}

augment class A {
  augment int foo = 2;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F9
          fields
            #F4 augment hasInitializer foo (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
              nextFragment: #F10
        #F9 class A (nameOffset:86) (firstTokenOffset:72) (offset:86)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          fields
            #F10 augment hasInitializer foo (nameOffset:104) (firstTokenOffset:104) (offset:104)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F4
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment int get foo => 1;
}

augment class A {
  augment int foo = 2;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
              nextFragment: #F7
          setters
            #F8 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F10
          getters
            #F7 augment foo (nameOffset:64) (firstTokenOffset:48) (offset:64)
              element: <testLibrary>::@class::A::@getter::foo
              previousFragment: #F6
        #F10 class A (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          fields
            #F4 augment hasInitializer foo (nameOffset:109) (firstTokenOffset:109) (offset:109)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment set foo(int _) {}
}

augment class A {
  augment int foo = 2;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
              nextFragment: #F9
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F10
          setters
            #F9 augment foo (nameOffset:60) (firstTokenOffset:48) (offset:60)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F11 _ (nameOffset:68) (firstTokenOffset:64) (offset:68)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
              previousFragment: #F7
        #F10 class A (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          fields
            #F4 augment hasInitializer foo (nameOffset:109) (firstTokenOffset:109) (offset:109)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field_augmentedInvocation() async {
    // This is invalid code, but it should not crash.
    var library = await buildLibrary(r'''
class A {
  static const int foo = 0;
}

augment class A {;
  augment static const int foo = augmented();
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @35
                  staticType: null
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::A::@getter::foo
        #F2 class A (nameOffset:55) (firstTokenOffset:41) (offset:55)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:87) (firstTokenOffset:87) (offset:87)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_1
                MethodInvocation
                  methodName: SimpleIdentifier
                    token: augmented @93
                    element: <null>
                    staticType: InvalidType
                  argumentList: ArgumentList
                    leftParenthesis: ( @102
                    rightParenthesis: ) @103
                  staticInvokeType: InvalidType
                  staticType: InvalidType
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static const hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic static foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment double foo = 1.2;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_field_plus() async {
    var library = await buildLibrary(r'''
class A {
  final int foo = 0;
  const A();
}

augment class A {
  augment final int foo = augmented + 1;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @28
                  staticType: null
              nextFragment: #F4
          constructors
            #F5 const new (nameOffset:<null>) (firstTokenOffset:33) (offset:39)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 39
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@getter::foo
        #F2 class A (nameOffset:61) (firstTokenOffset:47) (offset:61)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:85) (firstTokenOffset:85) (offset:85)
              element: <testLibrary>::@class::A::@field::foo
              initializer: expression_1
                BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: augmented @91
                    element: <null>
                    staticType: InvalidType
                  operator: + @101
                  rightOperand: IntegerLiteral
                    literal: 1 @103
                    staticType: int
                  element: <null>
                  staticInvokeType: null
                  staticType: InvalidType
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment int foo = 1;
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_field_augment_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  augment int foo = 1;
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F5 augment hasInitializer foo (nameOffset:61) (firstTokenOffset:61) (offset:61)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

augment class A {
  augment int foo = 1;
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F6 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@class::A::@field::foo
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
    var library = await buildLibrary(r'''
class A {
  int foo1 = 0;
}

augment class A {
  int foo2 = 0;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo1 (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo1
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo1
          setters
            #F6 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo1
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo1::@formalParameter::value
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F8 hasInitializer foo2 (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@class::A::@field::foo2
          getters
            #F9 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::A::@getter::foo2
          setters
            #F10 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::A::@setter::foo2
              formalParameters
                #F11 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
                  element: <testLibrary>::@class::A::@setter::foo2::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo1
          setter: <testLibrary>::@class::A::@setter::foo1
        hasInitializer foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::A::@getter::foo2
          setter: <testLibrary>::@class::A::@setter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo1
          reference: <testLibrary>::@class::A::@getter::foo1
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@getter::foo2
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo2
      setters
        synthetic foo1
          reference: <testLibrary>::@class::A::@setter::foo1
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@setter::foo2
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmented_fields_add_generic() async {
    var library = await buildLibrary(r'''
class A<T> {
  T foo1;
}

augment class A<T> {
  T foo2;
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 foo1 (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::A::@field::foo1
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F7 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@getter::foo1
          setters
            #F8 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@setter::foo1
              formalParameters
                #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::A::@setter::foo1::@formalParameter::value
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
          fields
            #F10 foo2 (nameOffset:51) (firstTokenOffset:51) (offset:51)
              element: <testLibrary>::@class::A::@field::foo2
          getters
            #F11 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::A::@getter::foo2
          setters
            #F12 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::A::@setter::foo2
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
                  element: <testLibrary>::@class::A::@setter::foo2::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      fields
        foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::foo1
          setter: <testLibrary>::@class::A::@setter::foo1
        foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::foo2
          setter: <testLibrary>::@class::A::@setter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        synthetic foo1
          reference: <testLibrary>::@class::A::@getter::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@getter::foo2
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::foo2
      setters
        synthetic foo1
          reference: <testLibrary>::@class::A::@setter::foo1
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F9
              type: T
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@setter::foo2
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F13
              type: T
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmented_fields_add_useFieldFormal() async {
    var library = await buildLibrary(r'''
class A {
  A(this.foo);
}

augment class A {
  final int foo;
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
          nextFragment: #F2
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F4 this.foo (nameOffset:19) (firstTokenOffset:14) (offset:19)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F5 foo (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType foo
              firstFragment: #F4
              type: int
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_fields_add_useFieldInitializer() async {
    var library = await buildLibrary(r'''
class A {
  const A() : foo = 0;
}

augment class A {
  final int foo;
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
          nextFragment: #F2
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
        #F2 class A (nameOffset:50) (firstTokenOffset:36) (offset:50)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 foo (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: foo @24
                element: <testLibrary>::@class::A::@field::foo
                staticType: null
              equals: = @28
              expression: IntegerLiteral
                literal: 0 @30
                staticType: int
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_getter_augments_constructor() async {
    var library = await buildLibrary(r'''
class A {
  A.foo();
}

augment class A {
  augment int get foo => 0;
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
          nextFragment: #F2
          constructors
            #F3 foo (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F2 class A (nameOffset:38) (firstTokenOffset:24) (offset:38)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F5 augment foo (nameOffset:60) (firstTokenOffset:44) (offset:60)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_getter_augments_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  augment int get foo => 0;
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F6 augment foo (nameOffset:65) (firstTokenOffset:49) (offset:65)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_getter_augments_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

augment class A {
  augment int get foo => 0;
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F5 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F6 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          getters
            #F7 augment foo (nameOffset:69) (firstTokenOffset:53) (offset:69)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_getters_add() async {
    var library = await buildLibrary(r'''
class A {
  int get foo1 => 0;
}

augment class A {
  int get foo2 => 0;
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
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo1
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 foo1 (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo1
        #F2 class A (nameOffset:48) (firstTokenOffset:34) (offset:48)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F6 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::A::@field::foo2
          getters
            #F7 foo2 (nameOffset:62) (firstTokenOffset:54) (offset:62)
              element: <testLibrary>::@class::A::@getter::foo2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::A::@getter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        foo1
          reference: <testLibrary>::@class::A::@getter::foo1
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo1
        foo2
          reference: <testLibrary>::@class::A::@getter::foo2
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    var library = await buildLibrary(r'''
class A<T> {
  T get foo1;
}

augment class A<T> {
  T get foo2;
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo1
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F7 foo1 (nameOffset:21) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@getter::foo1
        #F2 class A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E0 T
              previousFragment: #F3
          fields
            #F8 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::A::@field::foo2
          getters
            #F9 foo2 (nameOffset:59) (firstTokenOffset:53) (offset:59)
              element: <testLibrary>::@class::A::@getter::foo2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      fields
        synthetic foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        abstract foo1
          reference: <testLibrary>::@class::A::@getter::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::foo1
        abstract foo2
          reference: <testLibrary>::@class::A::@getter::foo2
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment int get foo => 0;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
              nextFragment: #F6
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          getters
            #F6 augment foo (nameOffset:64) (firstTokenOffset:48) (offset:64)
              element: <testLibrary>::@class::A::@getter::foo
              previousFragment: #F5
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment int get foo => 0;
}

augment class A {
  augment int get foo => 0;
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
              nextFragment: #F6
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F9
          getters
            #F6 augment foo (nameOffset:64) (firstTokenOffset:48) (offset:64)
              element: <testLibrary>::@class::A::@getter::foo
              previousFragment: #F5
              nextFragment: #F10
        #F9 class A (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          getters
            #F10 augment foo (nameOffset:113) (firstTokenOffset:97) (offset:113)
              element: <testLibrary>::@class::A::@getter::foo
              previousFragment: #F6
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo1 => 0;
  int get foo2 => 0;
}

augment class A {
  augment int get foo1 => 0;
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
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo1
            #F4 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo2
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 foo1 (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo1
              nextFragment: #F7
            #F8 foo2 (nameOffset:41) (firstTokenOffset:33) (offset:41)
              element: <testLibrary>::@class::A::@getter::foo2
        #F2 class A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          getters
            #F7 augment foo1 (nameOffset:91) (firstTokenOffset:75) (offset:91)
              element: <testLibrary>::@class::A::@getter::foo1
              previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        foo1
          reference: <testLibrary>::@class::A::@getter::foo1
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo1
        foo2
          reference: <testLibrary>::@class::A::@getter::foo2
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmented_getters_augment_getter2_oneLib_oneTop() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment int get foo => 0;
  augment int get foo => 0;
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
              nextFragment: #F6
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          getters
            #F6 augment foo (nameOffset:69) (firstTokenOffset:53) (offset:69)
              element: <testLibrary>::@class::A::@getter::foo
              previousFragment: #F5
              nextFragment: #F7
            #F7 augment foo (nameOffset:97) (firstTokenOffset:81) (offset:97)
              element: <testLibrary>::@class::A::@getter::foo
              previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_getters_augment_nothing() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  augment int get foo => 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@field::foo
          getters
            #F4 augment foo (nameOffset:48) (firstTokenOffset:32) (offset:48)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_interfaces() async {
    var library = await buildLibrary(r'''
class A implements I1 {}
class I1 {}

augment class A implements I2 {}
class I2 {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class I1 (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::I1
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F2 class A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@class::A
          previousFragment: #F1
        #F6 class I2 (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::I2
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      interfaces
        I1
        I2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F5
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F7
''');
  }

  test_augmented_interfaces_chain() async {
    var library = await buildLibrary(r'''
class A implements I1 {}
class I1 {}

augment class A implements I2 {}
class I2 {}

augment class A implements I3 {}
class I3 {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class I1 (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::I1
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F2 class A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F6
        #F7 class I2 (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::I2
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
        #F6 class A (nameOffset:98) (firstTokenOffset:84) (offset:98)
          element: <testLibrary>::@class::A
          previousFragment: #F2
        #F9 class I3 (nameOffset:123) (firstTokenOffset:117) (offset:123)
          element: <testLibrary>::@class::I3
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:123)
              element: <testLibrary>::@class::I3::@constructor::new
              typeName: I3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      interfaces
        I1
        I2
        I3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F5
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F8
    class I3
      reference: <testLibrary>::@class::I3
      firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::I3::@constructor::new
          firstFragment: #F10
''');
  }

  test_augmented_interfaces_generic() async {
    var library = await buildLibrary(r'''
class A<T> implements I1 {}
class I1 {}

augment class A<T> implements I2<T> {}
class I2<E> {}
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F6 class I1 (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::I1
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F2 class A (nameOffset:55) (firstTokenOffset:41) (offset:55)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E0 T
              previousFragment: #F3
        #F8 class I2 (nameOffset:86) (firstTokenOffset:80) (offset:86)
          element: <testLibrary>::@class::I2
          typeParameters
            #F9 E (nameOffset:89) (firstTokenOffset:89) (offset:89)
              element: #E1 E
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:86)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      interfaces
        I1
        I2<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F7
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F8
      typeParameters
        #E1 E
          firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F10
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
    var library = await buildLibrary(r'''
class A<T> implements I1 {}
class I1 {}

augment class A<T, T2> implements I2<T2> {}
class I2<E> {}
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F6 class I1 (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::I1
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F2 class A (nameOffset:55) (firstTokenOffset:41) (offset:55)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E0 T
              previousFragment: #F3
        #F8 class I2 (nameOffset:91) (firstTokenOffset:85) (offset:91)
          element: <testLibrary>::@class::I2
          typeParameters
            #F9 E (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: #E1 E
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      interfaces
        I1
        I2<InvalidType>
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F7
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F8
      typeParameters
        #E1 E
          firstFragment: #F9
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F10
''');
  }

  test_augmented_method_augments_constructor() async {
    var library = await buildLibrary(r'''
class A {
  A.foo();
}

augment class A {
  augment void foo() {}
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
          nextFragment: #F2
          constructors
            #F3 foo (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F2 class A (nameOffset:38) (firstTokenOffset:24) (offset:38)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:57) (firstTokenOffset:44) (offset:57)
              element: <testLibrary>::@class::A::@method::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_method_augments_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment void foo() {}
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F8 augment foo (nameOffset:61) (firstTokenOffset:48) (offset:61)
              element: <testLibrary>::@class::A::@method::foo
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F8
          returnType: void
''');
  }

  test_augmented_method_augments_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment void foo() {}
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F6 augment foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@class::A::@method::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          returnType: void
''');
  }

  test_augmented_method_augments_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

augment class A {
  augment void foo() {}
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F5 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F6 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F7 augment foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@class::A::@method::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F7
          returnType: void
''');
  }

  test_augmented_methods() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  void bar() {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F5 bar (nameOffset:54) (firstTokenOffset:49) (offset:54)
              element: <testLibrary>::@class::A::@method::bar
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
        bar
          reference: <testLibrary>::@class::A::@method::bar
          firstFragment: #F5
          returnType: void
''');
  }

  test_augmented_methods_add_withDefaultValue() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  void foo([int x = 42]) {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 foo (nameOffset:37) (firstTokenOffset:32) (offset:37)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F5 x (nameOffset:46) (firstTokenOffset:42) (offset:46)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  initializer: expression_0
                    IntegerLiteral
                      literal: 42 @50
                      staticType: int
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional x
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
          returnType: void
''');
  }

  test_augmented_methods_augment() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
  void bar() {}
}

augment class A {
  augment void foo();
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F5
            #F6 bar (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: <testLibrary>::@class::A::@method::bar
        #F2 class A (nameOffset:59) (firstTokenOffset:45) (offset:59)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F5 augment foo (nameOffset:78) (firstTokenOffset:65) (offset:78)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
        bar
          reference: <testLibrary>::@class::A::@method::bar
          firstFragment: #F6
          returnType: void
''');
  }

  test_augmented_methods_augment2_oneTop() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo() {}
  augment void foo() {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F5
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F5 augment foo (nameOffset:62) (firstTokenOffset:49) (offset:62)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
              nextFragment: #F6
            #F6 augment foo (nameOffset:86) (firstTokenOffset:73) (offset:86)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_methods_augment2_twoTop() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo() {}
}

augment class A {
  augment void foo() {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F5
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F6
          methods
            #F5 augment foo (nameOffset:62) (firstTokenOffset:49) (offset:62)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
              nextFragment: #F7
        #F6 class A (nameOffset:88) (firstTokenOffset:74) (offset:88)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          methods
            #F7 augment foo (nameOffset:107) (firstTokenOffset:94) (offset:107)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_methods_generic() async {
    var library = await buildLibrary(r'''
class A<T> {
  T foo() => throw 0;
}

augment class A<T> {
  T bar() => throw 0;
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 foo (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F2 class A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: #E0 T
              previousFragment: #F3
          methods
            #F7 bar (nameOffset:63) (firstTokenOffset:61) (offset:63)
              element: <testLibrary>::@class::A::@method::bar
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
        bar
          reference: <testLibrary>::@class::A::@method::bar
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_generic_augment() async {
    var library = await buildLibrary(r'''
class A<T> {
  T foo() => throw 0;
}

augment class A<T> {
  augment T foo() => throw 0;
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 foo (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F7
        #F2 class A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: #E0 T
              previousFragment: #F3
          methods
            #F7 augment foo (nameOffset:71) (firstTokenOffset:61) (offset:71)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_mixins() async {
    var library = await buildLibrary(r'''
class A with M1 {}
mixin M1 {}

augment class A with M2 {}
mixin M2 {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      mixins
        #F4 mixin M1 (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@mixin::M1
        #F5 mixin M2 (nameOffset:65) (firstTokenOffset:59) (offset:65)
          element: <testLibrary>::@mixin::M2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      supertype: Object
      mixins
        M1
        M2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F4
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F5
      superclassConstraints
        Object
''');
  }

  test_augmented_mixins_inferredTypeArguments() async {
    var library = await buildLibrary(r'''
class B<S> {}
class A<T> extends B<T> with M1 {}
mixin M1<U1> on B<U1> {}

augment class A<T> with M2 {}
mixin M2<U2> on M1<U2> {}

augment class A<T> with M3 {}
mixin M3<U3> on M2<U3> {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 S (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 S
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F4 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F5
          typeParameters
            #F6 T (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 T
              nextFragment: #F7
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F5 class A (nameOffset:89) (firstTokenOffset:75) (offset:89)
          element: <testLibrary>::@class::A
          previousFragment: #F4
          nextFragment: #F9
          typeParameters
            #F7 T (nameOffset:91) (firstTokenOffset:91) (offset:91)
              element: #E1 T
              previousFragment: #F6
              nextFragment: #F10
        #F9 class A (nameOffset:146) (firstTokenOffset:132) (offset:146)
          element: <testLibrary>::@class::A
          previousFragment: #F5
          typeParameters
            #F10 T (nameOffset:148) (firstTokenOffset:148) (offset:148)
              element: #E1 T
              previousFragment: #F7
      mixins
        #F11 mixin M1 (nameOffset:55) (firstTokenOffset:49) (offset:55)
          element: <testLibrary>::@mixin::M1
          typeParameters
            #F12 U1 (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: #E2 U1
        #F13 mixin M2 (nameOffset:111) (firstTokenOffset:105) (offset:111)
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F14 U2 (nameOffset:114) (firstTokenOffset:114) (offset:114)
              element: #E3 U2
        #F15 mixin M3 (nameOffset:168) (firstTokenOffset:162) (offset:168)
          element: <testLibrary>::@mixin::M3
          typeParameters
            #F16 U3 (nameOffset:171) (firstTokenOffset:171) (offset:171)
              element: #E4 U3
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 S
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F6
      supertype: B<T>
      mixins
        M1<T>
        M2<T>
        M3<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F8
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::B::@constructor::new
            substitution: {S: T}
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F11
      typeParameters
        #E2 U1
          firstFragment: #F12
      superclassConstraints
        B<U1>
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F13
      typeParameters
        #E3 U2
          firstFragment: #F14
      superclassConstraints
        M1<U2>
    mixin M3
      reference: <testLibrary>::@mixin::M3
      firstFragment: #F15
      typeParameters
        #E4 U3
          firstFragment: #F16
      superclassConstraints
        M2<U3>
''');
  }

  test_augmented_setter_augments_constructor() async {
    var library = await buildLibrary(r'''
class A {
  A.foo();
}

augment class A {
  augment set foo(int _) {}
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
          nextFragment: #F2
          constructors
            #F3 foo (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::foo
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
        #F2 class A (nameOffset:38) (firstTokenOffset:24) (offset:38)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::A::@field::foo
          setters
            #F5 augment foo (nameOffset:56) (firstTokenOffset:44) (offset:56)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F6 _ (nameOffset:64) (firstTokenOffset:60) (offset:64)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        foo
          reference: <testLibrary>::@class::A::@constructor::foo
          firstFragment: #F3
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_setter_augments_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment set foo(int _) {}
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
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          setters
            #F6 augment foo (nameOffset:65) (firstTokenOffset:53) (offset:65)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 _ (nameOffset:73) (firstTokenOffset:69) (offset:73)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_setter_augments_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

augment class A {
  augment set foo(int _) {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
        #F2 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::A::@field::foo
          setters
            #F6 augment foo (nameOffset:61) (firstTokenOffset:49) (offset:61)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 _ (nameOffset:69) (firstTokenOffset:65) (offset:69)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_setters_add() async {
    var library = await buildLibrary(r'''
class A {
  set foo1(int _) {}
}

augment class A {
  set foo2(int _) {}
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
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo1
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F5 foo1 (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo1
              formalParameters
                #F6 _ (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@setter::foo1::@formalParameter::_
        #F2 class A (nameOffset:48) (firstTokenOffset:34) (offset:48)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F7 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::A::@field::foo2
          setters
            #F8 foo2 (nameOffset:58) (firstTokenOffset:54) (offset:58)
              element: <testLibrary>::@class::A::@setter::foo2
              formalParameters
                #F9 _ (nameOffset:67) (firstTokenOffset:63) (offset:67)
                  element: <testLibrary>::@class::A::@setter::foo2::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@class::A::@setter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      setters
        foo1
          reference: <testLibrary>::@class::A::@setter::foo1
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo1
        foo2
          reference: <testLibrary>::@class::A::@setter::foo2
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmented_setters_augment_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}

augment class A {
  augment set foo(int _) {}
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
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
              nextFragment: #F8
        #F2 class A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          setters
            #F8 augment foo (nameOffset:60) (firstTokenOffset:48) (offset:60)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F9 _ (nameOffset:68) (firstTokenOffset:64) (offset:68)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
              previousFragment: #F6
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_setters_augment_nothing() async {
    var library = await buildLibrary(r'''
class A {}

augment class A {
  augment set foo(int _) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@field::foo
          setters
            #F4 augment foo (nameOffset:44) (firstTokenOffset:32) (offset:44)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F5 _ (nameOffset:52) (firstTokenOffset:48) (offset:52)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_augmented_setters_augment_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo1(int _) {}
  set foo2(int _) {}
}

augment class A {
  augment set foo1(int _) {}
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
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo1
            #F4 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo2
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F6 foo1 (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo1
              formalParameters
                #F7 _ (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@class::A::@setter::foo1::@formalParameter::_
              nextFragment: #F8
            #F9 foo2 (nameOffset:37) (firstTokenOffset:33) (offset:37)
              element: <testLibrary>::@class::A::@setter::foo2
              formalParameters
                #F10 _ (nameOffset:46) (firstTokenOffset:42) (offset:46)
                  element: <testLibrary>::@class::A::@setter::foo2::@formalParameter::_
        #F2 class A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          setters
            #F8 augment foo1 (nameOffset:87) (firstTokenOffset:75) (offset:87)
              element: <testLibrary>::@class::A::@setter::foo1
              formalParameters
                #F11 _ (nameOffset:96) (firstTokenOffset:92) (offset:96)
                  element: <testLibrary>::@class::A::@setter::foo1::@formalParameter::_
              previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo1
          reference: <testLibrary>::@class::A::@field::foo1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@class::A::@setter::foo1
        synthetic foo2
          reference: <testLibrary>::@class::A::@field::foo2
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@class::A::@setter::foo2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      setters
        foo1
          reference: <testLibrary>::@class::A::@setter::foo1
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo1
        foo2
          reference: <testLibrary>::@class::A::@setter::foo2
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo2
''');
  }

  test_augmentedBy_mixin2() async {
    var library = await buildLibrary(r'''
class A {}

augment mixin A {}

augment mixin A {}
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
      mixins
        #F3 mixin A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@mixin::A
          nextFragment: #F4
        #F4 mixin A (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@mixin::A
          previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  /// Invalid augmentation of class with mixin does not "own" the name.
  /// When a valid class augmentation follows, it can use the name.
  test_augmentedBy_mixin_class() async {
    var library = await buildLibrary(r'''
class A {}

augment mixin A {}

augment class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A::@def::0
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@def::0::@constructor::new
              typeName: A
        #F3 class A (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@class::A::@def::1
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::A::@def::1::@constructor::new
              typeName: A
      mixins
        #F5 mixin A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@mixin::A
  classes
    class A
      reference: <testLibrary>::@class::A::@def::0
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::0::@constructor::new
          firstFragment: #F2
    class A
      reference: <testLibrary>::@class::A::@def::1
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::1::@constructor::new
          firstFragment: #F4
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F5
      superclassConstraints
        Object
''');
  }

  test_constructors_augment2() async {
    var library = await buildLibrary(r'''
class A {
  A.named();
}

augment class A {
  augment A.named();
}

augment class A {
  augment A.named();
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
          nextFragment: #F2
          constructors
            #F3 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
              nextFragment: #F4
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F5
          constructors
            #F4 augment named (nameOffset:56) (firstTokenOffset:46) (offset:56)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 54
              periodOffset: 55
              nextFragment: #F6
              previousFragment: #F3
        #F5 class A (nameOffset:82) (firstTokenOffset:68) (offset:82)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          constructors
            #F6 augment named (nameOffset:98) (firstTokenOffset:88) (offset:98)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 96
              periodOffset: 97
              previousFragment: #F4
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
''');
  }

  test_constructors_augment_named() async {
    var library = await buildLibrary(r'''
class A {
  A.named();
}

augment class A {
  augment A.named();
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
          nextFragment: #F2
          constructors
            #F3 named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
              nextFragment: #F4
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F4 augment named (nameOffset:56) (firstTokenOffset:46) (offset:56)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 54
              periodOffset: 55
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
''');
  }

  test_constructors_augment_unnamed() async {
    var library = await buildLibrary(r'''
class A {
  A();
}

augment class A {
  augment A();
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
          nextFragment: #F2
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              nextFragment: #F4
        #F2 class A (nameOffset:34) (firstTokenOffset:20) (offset:34)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F4 augment new (nameOffset:<null>) (firstTokenOffset:40) (offset:48)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 48
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_inferTypes_method_ofAugment() async {
    var library = await buildLibrary(r'''
class B extends A {}

class A {
  int foo(String a) => 0;
}

augment class B {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F4 class A (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::A
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 foo (nameOffset:38) (firstTokenOffset:34) (offset:38)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F7 a (nameOffset:49) (firstTokenOffset:42) (offset:49)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        #F2 class B (nameOffset:75) (firstTokenOffset:61) (offset:75)
          element: <testLibrary>::@class::B
          previousFragment: #F1
          methods
            #F8 foo (nameOffset:81) (firstTokenOffset:81) (offset:81)
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F9 a (nameOffset:85) (firstTokenOffset:85) (offset:85)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: String
          returnType: int
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F7
              type: String
          returnType: int
''');
  }

  test_inferTypes_method_usingAugmentation_interface() async {
    var library = await buildLibrary(r'''
class B {
  foo(a) => 0;
}

class A {
  int foo(String a) => 0;
}

augment class B implements A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F4 foo (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F5 a (nameOffset:16) (firstTokenOffset:16) (offset:16)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
        #F6 class A (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::A
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F8 foo (nameOffset:44) (firstTokenOffset:40) (offset:44)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F9 a (nameOffset:55) (firstTokenOffset:48) (offset:55)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        #F2 class B (nameOffset:81) (firstTokenOffset:67) (offset:81)
          element: <testLibrary>::@class::B
          previousFragment: #F1
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      interfaces
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F5
              type: String
          returnType: int
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F7
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F9
              type: String
          returnType: int
''');
  }

  test_inferTypes_method_usingAugmentation_mixin() async {
    var library = await buildLibrary(r'''
class B {
  foo(a) => 0;
}

mixin A {
  int foo(String a) => 0;
}

augment class B with A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F4 foo (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F5 a (nameOffset:16) (firstTokenOffset:16) (offset:16)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
        #F2 class B (nameOffset:81) (firstTokenOffset:67) (offset:81)
          element: <testLibrary>::@class::B
          previousFragment: #F1
      mixins
        #F6 mixin A (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@mixin::A
          methods
            #F7 foo (nameOffset:44) (firstTokenOffset:40) (offset:44)
              element: <testLibrary>::@mixin::A::@method::foo
              formalParameters
                #F8 a (nameOffset:55) (firstTokenOffset:48) (offset:55)
                  element: <testLibrary>::@mixin::A::@method::foo::@formalParameter::a
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: Object
      mixins
        A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F5
              type: String
          returnType: int
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F6
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F8
              type: String
          returnType: int
''');
  }

  test_inferTypes_method_withAugment() async {
    var library = await buildLibrary(r'''
class B extends A {
  foo(a) => 0;
}

class A {
  int foo(String a) => 0;
}

augment class B {
  augment foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F4 foo (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::B::@method::foo
              nextFragment: #F5
              formalParameters
                #F6 a (nameOffset:26) (firstTokenOffset:26) (offset:26)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
        #F7 class A (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::A
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F9 foo (nameOffset:54) (firstTokenOffset:50) (offset:54)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F10 a (nameOffset:65) (firstTokenOffset:58) (offset:65)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        #F2 class B (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@class::B
          previousFragment: #F1
          methods
            #F5 augment foo (nameOffset:105) (firstTokenOffset:97) (offset:105)
              element: <testLibrary>::@class::B::@method::foo
              previousFragment: #F4
              formalParameters
                #F11 a (nameOffset:109) (firstTokenOffset:109) (offset:109)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F6
              type: String
          returnType: int
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F8
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F10
              type: String
          returnType: int
''');
  }

  test_method_typeParameters_111() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T>(){}
}
augment class A {
  augment void foo<T>(){}
}
augment class A {
  augment void foo<T>(){}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 class A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F7
          methods
            #F4 augment foo (nameOffset:63) (firstTokenOffset:50) (offset:63)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              nextFragment: #F8
              typeParameters
                #F6 T (nameOffset:67) (firstTokenOffset:67) (offset:67)
                  element: #E0 T
                  previousFragment: #F5
                  nextFragment: #F9
        #F7 class A (nameOffset:90) (firstTokenOffset:76) (offset:90)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          methods
            #F8 augment foo (nameOffset:109) (firstTokenOffset:96) (offset:109)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
              typeParameters
                #F9 T (nameOffset:113) (firstTokenOffset:113) (offset:113)
                  element: #E0 T
                  previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
          returnType: void
''');
  }

  test_method_typeParameters_121() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T>(){}
}
augment class A {
  augment void foo<T, U>(){}
}
augment class A {
  augment void foo<T>(){}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 class A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F7
          methods
            #F4 augment foo (nameOffset:63) (firstTokenOffset:50) (offset:63)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              nextFragment: #F8
              typeParameters
                #F6 T (nameOffset:67) (firstTokenOffset:67) (offset:67)
                  element: #E0 T
                  previousFragment: #F5
                  nextFragment: #F9
        #F7 class A (nameOffset:93) (firstTokenOffset:79) (offset:93)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          methods
            #F8 augment foo (nameOffset:112) (firstTokenOffset:99) (offset:112)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
              typeParameters
                #F9 T (nameOffset:116) (firstTokenOffset:116) (offset:116)
                  element: #E0 T
                  previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
          returnType: void
''');
  }

  test_method_typeParameters_212() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T, U>(){}
}
augment class A {
  augment void foo<T>(){}
}
augment class A {
  augment void foo<T, U>(){}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
                #F7 U (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E1 U
                  nextFragment: #F8
        #F2 class A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F9
          methods
            #F4 augment foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              nextFragment: #F10
              typeParameters
                #F6 T (nameOffset:70) (firstTokenOffset:70) (offset:70)
                  element: #E0 T
                  previousFragment: #F5
                  nextFragment: #F11
                #F8 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
                  element: #E1 U
                  previousFragment: #F7
                  nextFragment: #F12
        #F9 class A (nameOffset:93) (firstTokenOffset:79) (offset:93)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          methods
            #F10 augment foo (nameOffset:112) (firstTokenOffset:99) (offset:112)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
              typeParameters
                #F11 T (nameOffset:116) (firstTokenOffset:116) (offset:116)
                  element: #E0 T
                  previousFragment: #F6
                #F12 U (nameOffset:119) (firstTokenOffset:119) (offset:119)
                  element: #E1 U
                  previousFragment: #F8
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
            #E1 U
              firstFragment: #F7
          returnType: void
''');
  }

  test_method_typeParameters_bounds_bounds_int_int() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T extends int>() {}
}
augment class A {
  augment void foo<T extends int>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 class A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: #E0 T
                  previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
              bound: int
          returnType: void
''');
  }

  test_method_typeParameters_bounds_int_nothing() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T extends int>() {}
}
augment class A {
  augment void foo<T>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 class A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: #E0 T
                  previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
              bound: int
          returnType: void
''');
  }

  test_method_typeParameters_bounds_int_string() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T extends int>() {}
}
augment class A {
  augment void foo<T extends String>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 class A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: #E0 T
                  previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
              bound: int
          returnType: void
''');
  }

  test_method_typeParameters_bounds_nothing_int() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T>() {}
}
augment class A {
  augment void foo<T extends int>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 class A (nameOffset:45) (firstTokenOffset:31) (offset:45)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:64) (firstTokenOffset:51) (offset:64)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:68) (firstTokenOffset:68) (offset:68)
                  element: #E0 T
                  previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
          returnType: void
''');
  }

  test_method_typeParameters_differentNames() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T, U>() {}
}

augment class A {
  augment void foo<U, T>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
                #F7 U (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E1 U
                  nextFragment: #F8
        #F2 class A (nameOffset:49) (firstTokenOffset:35) (offset:49)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:68) (firstTokenOffset:55) (offset:68)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 U (nameOffset:72) (firstTokenOffset:72) (offset:72)
                  element: #E0 T
                  previousFragment: #F5
                #F8 T (nameOffset:75) (firstTokenOffset:75) (offset:75)
                  element: #E1 U
                  previousFragment: #F7
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
            #E1 U
              firstFragment: #F7
          returnType: void
''');
  }

  test_modifiers_abstract() async {
    var library = await buildLibrary(r'''
abstract class A {}

augment abstract class A {}
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
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:44) (firstTokenOffset:21) (offset:44)
          element: <testLibrary>::@class::A
          previousFragment: #F1
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_modifiers_base() async {
    var library = await buildLibrary(r'''
base class A {}

augment base class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:36) (firstTokenOffset:17) (offset:36)
          element: <testLibrary>::@class::A
          previousFragment: #F1
  classes
    base class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_modifiers_final() async {
    var library = await buildLibrary(r'''
final class A {}

augment final class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:38) (firstTokenOffset:18) (offset:38)
          element: <testLibrary>::@class::A
          previousFragment: #F1
  classes
    final class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_modifiers_interface() async {
    var library = await buildLibrary(r'''
interface class A {}

augment interface class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:16) (firstTokenOffset:0) (offset:16)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:46) (firstTokenOffset:22) (offset:46)
          element: <testLibrary>::@class::A
          previousFragment: #F1
  classes
    interface class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_modifiers_mixin() async {
    var library = await buildLibrary(r'''
mixin class A {}

augment mixin class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:38) (firstTokenOffset:18) (offset:38)
          element: <testLibrary>::@class::A
          previousFragment: #F1
  classes
    mixin class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_modifiers_sealed() async {
    var library = await buildLibrary(r'''
sealed class A {}

augment sealed class A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:40) (firstTokenOffset:19) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
  classes
    abstract sealed class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_notAugmented_interfaces() async {
    var library = await buildLibrary(r'''
class A implements I {}
class I {}
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
        #F3 class I (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::I
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      interfaces
        I
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F4
''');
  }

  test_notAugmented_mixins() async {
    var library = await buildLibrary(r'''
class A implements M {}
mixin M {}
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
      mixins
        #F3 mixin M (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      interfaces
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_notSimplyBounded_self() async {
    var library = await buildLibrary(r'''
class A<T extends A> {}

augment class A<T extends A> {}
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
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F2 class A (nameOffset:39) (firstTokenOffset:25) (offset:39)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:41) (firstTokenOffset:41) (offset:41)
              element: #E0 T
              previousFragment: #F3
  classes
    notSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: A<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
''');
  }

  test_supertype_fromAugmentation() async {
    var library = await buildLibrary(r'''
class A<T> {}
class B<T> {}

augment class B<T> extends A<T> {}
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
        #F4 class B (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::B
          nextFragment: #F5
          typeParameters
            #F6 T (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 T
              nextFragment: #F7
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class B (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::B
          previousFragment: #F4
          typeParameters
            #F7 T (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E1 T
              previousFragment: #F6
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
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F6
      supertype: A<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: T}
''');
  }

  test_supertype_fromAugmentation2() async {
    // `extends B` should be ignored, we already have `extends A`
    var library = await buildLibrary(r'''
class A {}
class B {}
class C {}

augment class C extends A {}
augment class C extends B {}
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
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::C
          nextFragment: #F6
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F6 class C (nameOffset:48) (firstTokenOffset:34) (offset:48)
          element: <testLibrary>::@class::C
          previousFragment: #F5
          nextFragment: #F8
        #F8 class C (nameOffset:77) (firstTokenOffset:63) (offset:77)
          element: <testLibrary>::@class::C
          previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
          superConstructor: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_typeParameters_111() async {
    var library = await buildLibrary(r'''
class A<T> {}
augment class A<T> {}
augment class A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:28) (firstTokenOffset:14) (offset:28)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 class A (nameOffset:50) (firstTokenOffset:36) (offset:50)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E0 T
              previousFragment: #F4
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
''');
  }

  test_typeParameters_121() async {
    var library = await buildLibrary(r'''
class A<T> {}
augment class A<T, U> {}
augment class A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:28) (firstTokenOffset:14) (offset:28)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 class A (nameOffset:53) (firstTokenOffset:39) (offset:53)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F4
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
''');
  }

  test_typeParameters_212() async {
    var library = await buildLibrary(r'''
class A<T, U> {}
augment class A<T> {}
augment class A<T, U> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
              nextFragment: #F6
        #F2 class A (nameOffset:31) (firstTokenOffset:17) (offset:31)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          nextFragment: #F7
          typeParameters
            #F4 T (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F8
            #F6 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F9
        #F7 class A (nameOffset:53) (firstTokenOffset:39) (offset:53)
          element: <testLibrary>::@class::A
          previousFragment: #F2
          typeParameters
            #F8 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F4
            #F9 U (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: #E1 U
              previousFragment: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
''');
  }

  test_typeParameters_bounds_int_int() async {
    var library = await buildLibrary(r'''
class A<T extends int> {}
augment class A<T extends int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
''');
  }

  test_typeParameters_bounds_int_nothing() async {
    var library = await buildLibrary(r'''
class A<T extends int> {}
augment class A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
''');
  }

  test_typeParameters_bounds_int_string() async {
    var library = await buildLibrary(r'''
class A<T extends int> {}
augment class A<T extends String> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
''');
  }

  test_typeParameters_bounds_nothing_int() async {
    var library = await buildLibrary(r'''
class A<T> {}
augment class A<T extends int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 class A (nameOffset:28) (firstTokenOffset:14) (offset:28)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E0 T
              previousFragment: #F3
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
''');
  }

  test_typeParameters_differentNames() async {
    var library = await buildLibrary(r'''
class A<T, U> {}
augment class A<U, T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
              nextFragment: #F6
        #F2 class A (nameOffset:31) (firstTokenOffset:17) (offset:31)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          typeParameters
            #F4 U (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: #E0 T
              previousFragment: #F3
            #F6 T (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: #E1 U
              previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
''');
  }
}

@reflectiveTest
class ClassElementTest_augmentation_fromBytes
    extends ClassElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ClassElementTest_augmentation_keepLinking
    extends ClassElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class ClassElementTest_fromBytes extends ClassElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ClassElementTest_keepLinking extends ClassElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
