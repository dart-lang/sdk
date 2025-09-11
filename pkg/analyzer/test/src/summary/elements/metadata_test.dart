// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataElementTest_keepLinking);
    defineReflectiveTests(MetadataElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class MetadataElementTest extends ElementsBaseTest {
  test_annotationArgument_recordLiteral() async {
    var library = await buildLibrary('''
@A((2, a: 3))
class C {}
class A {
  const A(o);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:20) (firstTokenOffset:0) (offset:20)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class A (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::A
          constructors
            #F4 const new (nameOffset:<null>) (firstTokenOffset:37) (offset:43)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 43
              formalParameters
                #F5 o (nameOffset:45) (firstTokenOffset:45) (offset:45)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType o
              firstFragment: #F5
              type: dynamic
''');
  }

  test_annotationArgument_recordLiteral_withConst() async {
    var library = await buildLibrary('''
@A(const ('',))
class C {}
class A {
  const A(o);
}
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
        #F3 class A (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::A
          constructors
            #F4 const new (nameOffset:<null>) (firstTokenOffset:39) (offset:45)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 45
              formalParameters
                #F5 o (nameOffset:47) (firstTokenOffset:47) (offset:47)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType o
              firstFragment: #F5
              type: dynamic
''');
  }

  test_invalid_annotation_prefixed_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}
''');
    var library = await buildLibrary('''
import "a.dart" as a;
@a.A.named
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @19
      classes
        #F1 class C (nameOffset:39) (firstTokenOffset:22) (offset:39)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
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

  test_invalid_annotation_unprefixed_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}
''');
    var library = await buildLibrary('''
import "a.dart";
@A.named
class C {}
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
        #F1 class C (nameOffset:32) (firstTokenOffset:17) (offset:32)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
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

  test_metadata_class_field_first() async {
    var library = await buildLibrary(r'''
const a = 0;
class C {
  @a
  int x = 0;
}
''');
    // Check metadata without asking any other properties.
    var x = library.getClass('C')!.getField('x')!;
    expect(x.metadata.annotations, hasLength(1));
    // Check details.
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
            #F2 hasInitializer x (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
      getters
        #F8 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
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
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_class_scope() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
class C<@foo T> {
  static const foo = 1;
  @foo
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
        #F1 class C (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          fields
            #F3 hasInitializer foo (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@class::C::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::C::@getter::foo
          methods
            #F6 bar (nameOffset:77) (firstTokenOffset:65) (offset:77)
              element: <testLibrary>::@class::C::@method::bar
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    element: <testLibrary>::@class::C::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@class::C::@getter::foo
      topLevelVariables
        #F7 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F8 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      fields
        static const hasInitializer foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@class::C::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic static foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      methods
        bar
          reference: <testLibrary>::@class::C::@method::bar
          firstFragment: #F6
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                element: <testLibrary>::@class::C::@getter::foo
                staticType: null
              element2: <testLibrary>::@class::C::@getter::foo
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_classDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;
@a
@b
class C {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:44) (firstTokenOffset:32) (offset:44)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F4 hasInitializer b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
      getters
        #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F6 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: dynamic
      constantInitializer
        fragment: #F4
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_classTypeAlias() async {
    var library = await buildLibrary(
      'const a = null; @a class C = D with E; class D {} class E {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@class::E
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
      topLevelVariables
        #F7 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F8 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
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
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: dynamic
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_constructor_call_named() async {
    var library = await buildLibrary('''
class A {
  const A.named(int _);
}
@A.named(0)
class C {}
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
            #F2 const named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                #F3 _ (nameOffset:30) (firstTokenOffset:26) (offset:30)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::_
        #F4 class C (nameOffset:54) (firstTokenOffset:36) (offset:54)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F3
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_named_generic_inference() async {
    var library = await buildLibrary('''
class A<T> {
  const A.named(T _);
}

@A.named(0)
class C {}
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
            #F3 const named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
              formalParameters
                #F4 _ (nameOffset:31) (firstTokenOffset:29) (offset:31)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::_
        #F5 class C (nameOffset:56) (firstTokenOffset:38) (offset:56)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_metadata_constructor_call_named_generic_typeArguments() async {
    var library = await buildLibrary('''
class A<T> {
  const A.named();
}

@A<int>.named()
class C {}
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
            #F3 const named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
        #F4 class C (nameOffset:57) (firstTokenOffset:35) (offset:57)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_named_generic_typeArguments_disabledGenericMetadata() async {
    var library = await buildLibrary('''
class A<T> {
  const A.named();
}

@A<int>.named()
class C {}
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
            #F3 const named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
        #F4 class C (nameOffset:57) (firstTokenOffset:35) (offset:57)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_named_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', '''
class A {
  const A.named(int _);
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
@foo.A.named(0)
class C {}
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
        #F1 class C (nameOffset:48) (firstTokenOffset:26) (offset:48)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
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

  test_metadata_constructor_call_named_prefixed_generic_inference() async {
    newFile('$testPackageLibPath/foo.dart', '''
class A<T> {
  const A.named(T _);
}
''');
    var library = await buildLibrary('''
import "foo.dart" as foo;
@foo.A.named(0)
class C {}
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
        #F1 class C (nameOffset:48) (firstTokenOffset:26) (offset:48)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
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

  test_metadata_constructor_call_named_prefixed_generic_typeArguments() async {
    newFile('$testPackageLibPath/foo.dart', '''
class A<T> {
  const A.named();
}
''');
    var library = await buildLibrary('''
import "foo.dart" as foo;
@foo.A<int>.named()
class C {}
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
        #F1 class C (nameOffset:52) (firstTokenOffset:26) (offset:52)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
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

  test_metadata_constructor_call_named_synthetic_ofClassAlias_generic() async {
    var library = await buildLibrary('''
class A {
  const A.named();
}

mixin B {}

class C<T> = A with B;

@C.named()
class D {}
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
            #F2 const named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
        #F3 class C (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::C
          typeParameters
            #F4 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E0 T
          constructors
            #F5 synthetic const named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
        #F6 class D (nameOffset:85) (firstTokenOffset:68) (offset:85)
          element: <testLibrary>::@class::D
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      mixins
        #F8 mixin B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@mixin::B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      supertype: A
      mixins
        B
      constructors
        synthetic const named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F5
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
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F8
      superclassConstraints
        Object
''');
  }

  test_metadata_constructor_call_unnamed() async {
    var library = await buildLibrary('''
class A {
  const A(int _);
}
@A(0)
class C {}
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
                #F3 _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F4 class C (nameOffset:42) (firstTokenOffset:30) (offset:42)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F3
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_unnamed_generic_inference() async {
    var library = await buildLibrary('''
class A<T> {
  const A(T _);
}

@A(0)
class C {}
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
              formalParameters
                #F4 _ (nameOffset:25) (firstTokenOffset:23) (offset:25)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F5 class C (nameOffset:44) (firstTokenOffset:32) (offset:44)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
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
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_metadata_constructor_call_unnamed_generic_typeArguments() async {
    var library = await buildLibrary('''
class A<T> {
  const A();
}

@A<int>()
class C {}
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
        #F4 class C (nameOffset:45) (firstTokenOffset:29) (offset:45)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
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
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_unnamed_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', 'class A { const A(_); }');
    var library = await buildLibrary(
      'import "foo.dart" as foo; @foo.A(0) class C {}',
    );
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
        #F1 class C (nameOffset:42) (firstTokenOffset:26) (offset:42)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
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

  test_metadata_constructor_call_unnamed_prefixed_generic_inference() async {
    newFile('$testPackageLibPath/foo.dart', '''
class A<T> {
  const A(T _);
}
''');
    var library = await buildLibrary('''
import "foo.dart" as foo;
@foo.A(0)
class C {}
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
        #F1 class C (nameOffset:42) (firstTokenOffset:26) (offset:42)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
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

  test_metadata_constructor_call_unnamed_prefixed_generic_typeArguments() async {
    newFile('$testPackageLibPath/foo.dart', '''
class A<T> {
  const A();
}
''');
    var library = await buildLibrary('''
import "foo.dart" as foo;
@foo.A<int>()
class C {}
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
        #F1 class C (nameOffset:46) (firstTokenOffset:26) (offset:46)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
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

  test_metadata_constructor_call_unnamed_synthetic_ofClassAlias_generic() async {
    var library = await buildLibrary('''
class A {
  const A();
}

mixin B {}

class C<T> = A with B;

@C()
class D {}
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
        #F3 class C (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::C
          typeParameters
            #F4 T (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E0 T
          constructors
            #F5 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F6 class D (nameOffset:73) (firstTokenOffset:62) (offset:73)
          element: <testLibrary>::@class::D
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      mixins
        #F8 mixin B (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@mixin::B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      supertype: A
      mixins
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F8
      superclassConstraints
        Object
''');
  }

  test_metadata_constructor_call_with_args() async {
    var library = await buildLibrary(
      'class A { const A(x); } @A(null) class C {}',
    );
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
            #F2 const new (nameOffset:<null>) (firstTokenOffset:10) (offset:16)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 16
              formalParameters
                #F3 x (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
        #F4 class C (nameOffset:39) (firstTokenOffset:24) (offset:39)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType x
              firstFragment: #F3
              type: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_namedArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A({required int value});
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
@A(value: 42)
void f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      functions
        #F1 f (nameOffset:36) (firstTokenOffset:17) (offset:36)
          element: <testLibrary>::@function::f
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: A @18
                element: package:test/a.dart::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @19
                arguments
                  NamedExpression
                    name: Label
                      label: SimpleIdentifier
                        token: value @20
                        element: package:test/a.dart::@class::A::@constructor::new::@formalParameter::value
                        staticType: null
                      colon: : @25
                    expression: IntegerLiteral
                      literal: 42 @27
                      staticType: int
                rightParenthesis: ) @29
              element2: package:test/a.dart::@class::A::@constructor::new
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      metadata
        Annotation
          atSign: @ @17
          name: SimpleIdentifier
            token: A @18
            element: package:test/a.dart::@class::A
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @19
            arguments
              NamedExpression
                name: Label
                  label: SimpleIdentifier
                    token: value @20
                    element: package:test/a.dart::@class::A::@constructor::new::@formalParameter::value
                    staticType: null
                  colon: : @25
                expression: IntegerLiteral
                  literal: 42 @27
                  staticType: int
            rightParenthesis: ) @29
          element2: package:test/a.dart::@class::A::@constructor::new
      returnType: void
''');
  }

  test_metadata_constructorDeclaration_named() async {
    var library = await buildLibrary(
      'const a = null; class C { @a C.named(); }',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          constructors
            #F2 named (nameOffset:31) (firstTokenOffset:26) (offset:31)
              element: <testLibrary>::@class::C::@constructor::named
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              typeName: C
              typeNameOffset: 29
              periodOffset: 30
      topLevelVariables
        #F3 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await buildLibrary('const a = null; class C { @a C(); }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:26) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              typeName: C
              typeNameOffset: 29
      topLevelVariables
        #F3 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_exportDirective() async {
    newFile('$testPackageLibPath/foo.dart', '');

    var library = await buildLibrary('''
@a
export 'foo.dart';
const a = 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element2: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo.dart
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      topLevelVariables
        #F1 hasInitializer a (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @32
              staticType: int
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await buildLibrary('const a = null; class C { @a int x; }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          fields
            #F2 x (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F8 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
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
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: dynamic
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_fieldFormalParameter() async {
    var library = await buildLibrary('''
const a = null;
class C {
  var x;
  C(@a this.x);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          fields
            #F2 x (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 37
              formalParameters
                #F4 this.x (nameOffset:47) (firstTokenOffset:39) (offset:47)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  metadata
                    Annotation
                      atSign: @ @39
                      name: SimpleIdentifier
                        token: a @40
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element2: <testLibrary>::@getter::a
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F8 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F9 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
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
              metadata
                Annotation
                  atSign: @ @39
                  name: SimpleIdentifier
                    token: a @40
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
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
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: dynamic
      constantInitializer
        fragment: #F8
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    var library = await buildLibrary(
      'const a = null; class C { var x; C([@a this.x = null]); }',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          fields
            #F2 x (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 33
              formalParameters
                #F4 this.x (nameOffset:44) (firstTokenOffset:36) (offset:44)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  metadata
                    Annotation
                      atSign: @ @36
                      name: SimpleIdentifier
                        token: a @37
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element2: <testLibrary>::@getter::a
                  initializer: expression_0
                    NullLiteral
                      literal: null @48
                      staticType: Null
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F8 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_1
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F9 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
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
            #E0 optionalPositional final hasImplicitType x
              firstFragment: #F4
              type: dynamic
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: a @37
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              constantInitializer
                fragment: #F4
                expression: expression_0
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
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: dynamic
      constantInitializer
        fragment: #F8
        expression: expression_1
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_functionDeclaration_function() async {
    var library = await buildLibrary('''
const a = null;
@a
f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      functions
        #F3 f (nameOffset:19) (firstTokenOffset:16) (offset:19)
          element: <testLibrary>::@function::f
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await buildLibrary('const a = null; @a get f => null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 f (nameOffset:23) (firstTokenOffset:16) (offset:23)
          element: <testLibrary>::@getter::f
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    synthetic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::f
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F4
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await buildLibrary('const a = null; @a set f(value) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      setters
        #F4 f (nameOffset:23) (firstTokenOffset:16) (offset:23)
          element: <testLibrary>::@setter::f
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          formalParameters
            #F5 value (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    synthetic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F2
      type: dynamic
      setter: <testLibrary>::@setter::f
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F4
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
      formalParameters
        #E0 requiredPositional hasImplicitType value
          firstFragment: #F5
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_metadata_functionTypeAlias() async {
    var library = await buildLibrary('const a = null; @a typedef F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      topLevelVariables
        #F2 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
      aliasedType: dynamic Function()
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await buildLibrary('const a = null; f(@a g()) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      functions
        #F3 f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 g (nameOffset:21) (firstTokenOffset:18) (offset:21)
              element: <testLibrary>::@function::f::@formalParameter::g
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F4
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await buildLibrary('const a = null; f([@a g() = null]) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      functions
        #F3 f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 g (nameOffset:22) (firstTokenOffset:19) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::g
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              initializer: expression_1
                NullLiteral
                  literal: null @28
                  staticType: Null
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 optionalPositional g
          firstFragment: #F4
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          constantInitializer
            fragment: #F4
            expression: expression_1
      returnType: dynamic
''');
  }

  test_metadata_genericTypeAlias() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;
@a
@b
typedef F = void Function();''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                element: <testLibrary>::@getter::b
                staticType: null
              element2: <testLibrary>::@getter::b
      topLevelVariables
        #F2 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F3 hasInitializer b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      metadata
        Annotation
          atSign: @ @32
          name: SimpleIdentifier
            token: a @33
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
        Annotation
          atSign: @ @35
          name: SimpleIdentifier
            token: b @36
            element: <testLibrary>::@getter::b
            staticType: null
          element2: <testLibrary>::@getter::b
      aliasedType: void Function()
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_importDirective() async {
    newFile('$testPackageLibPath/foo.dart', '');

    var library = await buildLibrary('''
@a
import 'foo.dart';
const a = 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element2: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      topLevelVariables
        #F1 hasInitializer a (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @32
              staticType: int
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_inAliasedElement_formalParameter() async {
    var library = await buildLibrary('''
const a = 42;
typedef F = void Function(@a int first)
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int)
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_inAliasedElement_formalParameter2() async {
    var library = await buildLibrary('''
const a = 42;
typedef F = void Function(int foo(@a int bar))
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int Function(int))
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_inAliasedElement_typeParameter() async {
    var library = await buildLibrary('''
const a = 42;
typedef F = void Function<@a T>(int first)
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function<T>(int)
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_invalid_classDeclaration() async {
    var library = await buildLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:21) (firstTokenOffset:8) (offset:21)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      functions
        #F3 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 _ (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: <testLibrary>::@function::f::@formalParameter::_
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional hasImplicitType _
          firstFragment: #F4
          type: dynamic
      returnType: dynamic
''');
  }

  test_metadata_library_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    var library = await buildLibrary('''
@deprecated
part 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: deprecated @1
        element: dart:core::@getter::deprecated
        staticType: null
      element2: dart:core::@getter::deprecated
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 12
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: deprecated @1
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
''');
  }

  /// Even though the target is not a part, metadata is available.
  test_metadata_library_part_notPart() async {
    var library = await buildLibrary('''
@deprecated
part 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: deprecated @1
        element: dart:core::@getter::deprecated
        staticType: null
      element2: dart:core::@getter::deprecated
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: source 'dart:math'
          partKeywordOffset: 12
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: deprecated @1
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
''');
  }

  test_metadata_libraryDirective() async {
    var library = await buildLibrary('@a library L; const a = null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: L
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element2: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:11)
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @24
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_methodDeclaration_getter() async {
    var library = await buildLibrary(
      'const a = null; class C { @a get m => null; }',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@field::m
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 m (nameOffset:33) (firstTokenOffset:26) (offset:33)
              element: <testLibrary>::@class::C::@getter::m
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
      topLevelVariables
        #F5 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F6 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic m
          reference: <testLibrary>::@class::C::@field::m
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::m
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        m
          reference: <testLibrary>::@class::C::@getter::m
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::m
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F5
      type: dynamic
      constantInitializer
        fragment: #F5
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_methodDeclaration_method() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;
class C {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 m (nameOffset:54) (firstTokenOffset:44) (offset:54)
              element: <testLibrary>::@class::C::@method::m
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    element: <testLibrary>::@getter::b
                    staticType: null
                  element2: <testLibrary>::@getter::b
      topLevelVariables
        #F4 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F5 hasInitializer b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
      getters
        #F6 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F7 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          metadata
            Annotation
              atSign: @ @44
              name: SimpleIdentifier
                token: a @45
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                element: <testLibrary>::@getter::b
                staticType: null
              element2: <testLibrary>::@getter::b
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: dynamic
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: dynamic
      constantInitializer
        fragment: #F5
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_methodDeclaration_method_mixin() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;
mixin M {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@mixin::M
          methods
            #F2 m (nameOffset:54) (firstTokenOffset:44) (offset:54)
              element: <testLibrary>::@mixin::M::@method::m
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    element: <testLibrary>::@getter::b
                    staticType: null
                  element2: <testLibrary>::@getter::b
      topLevelVariables
        #F3 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F4 hasInitializer b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
      getters
        #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F6 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        m
          reference: <testLibrary>::@mixin::M::@method::m
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @44
              name: SimpleIdentifier
                token: a @45
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                element: <testLibrary>::@getter::b
                staticType: null
              element2: <testLibrary>::@getter::b
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: dynamic
      constantInitializer
        fragment: #F4
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_methodDeclaration_setter() async {
    var library = await buildLibrary('''
const a = null;
class C {
  @a
  set m(value) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@field::m
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 m (nameOffset:37) (firstTokenOffset:28) (offset:37)
              element: <testLibrary>::@class::C::@setter::m
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: a @29
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              formalParameters
                #F5 value (nameOffset:39) (firstTokenOffset:39) (offset:39)
                  element: <testLibrary>::@class::C::@setter::m::@formalParameter::value
      topLevelVariables
        #F6 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F7 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic m
          reference: <testLibrary>::@class::C::@field::m
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::m
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        m
          reference: <testLibrary>::@class::C::@setter::m
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: a @29
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          formalParameters
            #E0 requiredPositional hasImplicitType value
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::m
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F6
      type: dynamic
      constantInitializer
        fragment: #F6
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_mixin_scope() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
mixin M<@foo T> {
  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          fields
            #F3 hasInitializer foo (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@mixin::M::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@mixin::M::@getter::foo
          methods
            #F5 bar (nameOffset:77) (firstTokenOffset:65) (offset:77)
              element: <testLibrary>::@mixin::M::@method::bar
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    element: <testLibrary>::@mixin::M::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@mixin::M::@getter::foo
      topLevelVariables
        #F6 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      superclassConstraints
        Object
      fields
        static const hasInitializer foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        synthetic static foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
      methods
        bar
          reference: <testLibrary>::@mixin::M::@method::bar
          firstFragment: #F5
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                element: <testLibrary>::@mixin::M::@getter::foo
                staticType: null
              element2: <testLibrary>::@mixin::M::@getter::foo
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer
        fragment: #F6
        expression: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_mixinDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;
@a
@b
mixin M {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:44) (firstTokenOffset:32) (offset:44)
          element: <testLibrary>::@mixin::M
      topLevelVariables
        #F2 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F3 hasInitializer b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_1
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_offsets_onClass() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
class A<@foo T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F4 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F4
      type: int
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassConstructor() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  A(@foo int a);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:28) (offset:35)
              element: <testLibrary>::@class::A::@constructor::new
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
              typeName: A
              typeNameOffset: 35
              formalParameters
                #F3 a (nameOffset:46) (firstTokenOffset:37) (offset:46)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                  metadata
                    Annotation
                      atSign: @ @37
                      name: SimpleIdentifier
                        token: foo @38
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F4 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F4
      type: int
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassGetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  int get getter => 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic getter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@field::getter
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 getter (nameOffset:43) (firstTokenOffset:28) (offset:43)
              element: <testLibrary>::@class::A::@getter::getter
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F5 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic getter
          reference: <testLibrary>::@class::A::@field::getter
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::getter
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        getter
          reference: <testLibrary>::@class::A::@getter::getter
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          returnType: int
          variable: <testLibrary>::@class::A::@field::getter
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F5
      type: int
      constantInitializer
        fragment: #F5
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassMethod() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  void method<@foo T>(@foo int a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 method (nameOffset:40) (firstTokenOffset:28) (offset:40)
              element: <testLibrary>::@class::A::@method::method
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
              typeParameters
                #F4 T (nameOffset:52) (firstTokenOffset:47) (offset:52)
                  element: #E0 T
                  metadata
                    Annotation
                      atSign: @ @47
                      name: SimpleIdentifier
                        token: foo @48
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element2: <testLibrary>::@getter::foo
              formalParameters
                #F5 a (nameOffset:64) (firstTokenOffset:55) (offset:64)
                  element: <testLibrary>::@class::A::@method::method::@formalParameter::a
                  metadata
                    Annotation
                      atSign: @ @55
                      name: SimpleIdentifier
                        token: foo @56
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F6 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        method
          reference: <testLibrary>::@class::A::@method::method
          firstFragment: #F3
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          typeParameters
            #E0 T
              firstFragment: #F4
              metadata
                Annotation
                  atSign: @ @47
                  name: SimpleIdentifier
                    token: foo @48
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F5
              type: int
              metadata
                Annotation
                  atSign: @ @55
                  name: SimpleIdentifier
                    token: foo @56
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer
        fragment: #F6
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassSetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  set setter(@foo int a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic setter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@field::setter
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 setter (nameOffset:39) (firstTokenOffset:28) (offset:39)
              element: <testLibrary>::@class::A::@setter::setter
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
              formalParameters
                #F5 a (nameOffset:55) (firstTokenOffset:46) (offset:55)
                  element: <testLibrary>::@class::A::@setter::setter::@formalParameter::a
                  metadata
                    Annotation
                      atSign: @ @46
                      name: SimpleIdentifier
                        token: foo @47
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F6 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic setter
          reference: <testLibrary>::@class::A::@field::setter
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::setter
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        setter
          reference: <testLibrary>::@class::A::@setter::setter
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
              metadata
                Annotation
                  atSign: @ @46
                  name: SimpleIdentifier
                    token: foo @47
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          returnType: void
          variable: <testLibrary>::@class::A::@field::setter
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer
        fragment: #F6
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassTypeAlias() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {}
mixin M {}

@foo
class B<@foo T> = A with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:50) (firstTokenOffset:39) (offset:50)
          element: <testLibrary>::@class::B
          typeParameters
            #F4 T (nameOffset:57) (firstTokenOffset:52) (offset:57)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @52
                  name: SimpleIdentifier
                    token: foo @53
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F6 mixin M (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@mixin::M
      topLevelVariables
        #F7 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F8 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @52
              name: SimpleIdentifier
                token: foo @53
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      supertype: A
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      superclassConstraints
        Object
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onEnum() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
enum E {
  @foo e1,
  e2,
  @foo e3,
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:26) (firstTokenOffset:16) (offset:26)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer e1 (nameOffset:37) (firstTokenOffset:32) (offset:37)
              element: <testLibrary>::@enum::E::@field::e1
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
            #F3 hasInitializer e2 (nameOffset:43) (firstTokenOffset:43) (offset:43)
              element: <testLibrary>::@enum::E::@field::e2
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
            #F4 hasInitializer e3 (nameOffset:54) (firstTokenOffset:49) (offset:54)
              element: <testLibrary>::@enum::E::@field::e3
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
            #F5 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: e1 @-1
                      element: <testLibrary>::@enum::E::@getter::e1
                      staticType: E
                    SimpleIdentifier
                      token: e2 @-1
                      element: <testLibrary>::@enum::E::@getter::e2
                      staticType: E
                    SimpleIdentifier
                      token: e3 @-1
                      element: <testLibrary>::@enum::E::@getter::e3
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F6 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic e1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::E::@getter::e1
            #F8 synthetic e2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::E::@getter::e2
            #F9 synthetic e3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@enum::E::@getter::e3
            #F10 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F11 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_4
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer e1
          reference: <testLibrary>::@enum::E::@field::e1
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::e1
        static const enumConstant hasInitializer e2
          reference: <testLibrary>::@enum::E::@field::e2
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::e2
        static const enumConstant hasInitializer e3
          reference: <testLibrary>::@enum::E::@field::e3
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::e3
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static e1
          reference: <testLibrary>::@enum::E::@getter::e1
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::e1
        synthetic static e2
          reference: <testLibrary>::@enum::E::@getter::e2
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::e2
        synthetic static e3
          reference: <testLibrary>::@enum::E::@getter::e3
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::e3
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_4
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onExtension() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
extension E<@foo T> on List<T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:38) (firstTokenOffset:33) (offset:38)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: foo @34
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      extendedType: List<T>
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onFieldDeclaration() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  static isStatic = 1;

  @foo
  static const isStaticConst = 2;

  @foo
  var isInstance = 3;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer isStatic (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@class::A::@field::isStatic
            #F3 hasInitializer isStaticConst (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: <testLibrary>::@class::A::@field::isStaticConst
              initializer: expression_0
                IntegerLiteral
                  literal: 2 @95
                  staticType: int
            #F4 hasInitializer isInstance (nameOffset:112) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@class::A::@field::isInstance
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic isStatic (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@getter::isStatic
            #F7 synthetic isStaticConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
              element: <testLibrary>::@class::A::@getter::isStaticConst
            #F8 synthetic isInstance (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@class::A::@getter::isInstance
          setters
            #F9 synthetic isStatic (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@setter::isStatic
              formalParameters
                #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
                  element: <testLibrary>::@class::A::@setter::isStatic::@formalParameter::value
            #F11 synthetic isInstance (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@class::A::@setter::isInstance
              formalParameters
                #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
                  element: <testLibrary>::@class::A::@setter::isInstance::@formalParameter::value
      topLevelVariables
        #F13 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F14 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static hasInitializer isStatic
          reference: <testLibrary>::@class::A::@field::isStatic
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::isStatic
          setter: <testLibrary>::@class::A::@setter::isStatic
        static const hasInitializer isStaticConst
          reference: <testLibrary>::@class::A::@field::isStaticConst
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::isStaticConst
        hasInitializer isInstance
          reference: <testLibrary>::@class::A::@field::isInstance
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::A::@getter::isInstance
          setter: <testLibrary>::@class::A::@setter::isInstance
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic static isStatic
          reference: <testLibrary>::@class::A::@getter::isStatic
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::isStatic
        synthetic static isStaticConst
          reference: <testLibrary>::@class::A::@getter::isStaticConst
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::A::@field::isStaticConst
        synthetic isInstance
          reference: <testLibrary>::@class::A::@getter::isInstance
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::isInstance
      setters
        synthetic static isStatic
          reference: <testLibrary>::@class::A::@setter::isStatic
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::isStatic
        synthetic isInstance
          reference: <testLibrary>::@class::A::@setter::isInstance
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::isInstance
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F13
      type: int
      constantInitializer
        fragment: #F13
        expression: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onLibrary() async {
    var library = await buildLibrary('''
/// Some documentation.
@foo
library my.lib;

const foo = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
  documentationComment: /// Some documentation.
  metadata
    Annotation
      atSign: @ @24
      name: SimpleIdentifier
        token: foo @25
        element: <testLibrary>::@getter::foo
        staticType: null
      element2: <testLibrary>::@getter::foo
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:37)
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @58
              staticType: int
      getters
        #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onMixin() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
mixin A<@foo T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@mixin::A
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      superclassConstraints
        Object
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onTypeAlias_classic() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
typedef void F<@foo T>(@foo int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:34) (firstTokenOffset:16) (offset:34)
          element: <testLibrary>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:41) (firstTokenOffset:36) (offset:41)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: foo @37
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @36
              name: SimpleIdentifier
                token: foo @37
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      aliasedType: void Function(int)
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onTypeAlias_genericFunctionType() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
typedef A<@foo T> = void Function<@foo U>(@foo int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@typeAlias::A
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:36) (firstTokenOffset:31) (offset:36)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @31
              name: SimpleIdentifier
                token: foo @32
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      aliasedType: void Function<U>(int)
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onUnit() async {
    newFile('$testPackageLibPath/a.dart', '''
part of my.lib;
''');

    newFile('$testPackageLibPath/b.dart', '''
part of my.lib;
''');

    var library = await buildLibrary('''
library my.lib;

@foo
part 'a.dart';

@foo
part 'b.dart';

const foo = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 22
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: foo @18
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 43
          metadata
            Annotation
              atSign: @ @38
              name: SimpleIdentifier
                token: foo @39
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          unit: #F2
      topLevelVariables
        #F3 hasInitializer foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @71
              staticType: int
      getters
        #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
          element: <testLibrary>::@getter::foo
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onUnitFunction() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
void f<@foo T>({@foo int? a = 42}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
      functions
        #F3 f (nameOffset:26) (firstTokenOffset:16) (offset:26)
          element: <testLibrary>::@function::f
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          typeParameters
            #F4 T (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          formalParameters
            #F5 a (nameOffset:47) (firstTokenOffset:37) (offset:47)
              element: <testLibrary>::@function::f::@formalParameter::a
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
              initializer: expression_1
                IntegerLiteral
                  literal: 42 @51
                  staticType: int
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      typeParameters
        #E0 T
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      formalParameters
        #E1 optionalNamed a
          firstFragment: #F5
          type: int?
          metadata
            Annotation
              atSign: @ @37
              name: SimpleIdentifier
                token: foo @38
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          constantInitializer
            fragment: #F5
            expression: expression_1
      returnType: void
''');
  }

  test_metadata_offsets_onUnitGetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
int get getter => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
        #F2 synthetic getter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@topLevelVariable::getter
      getters
        #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
        #F4 getter (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@getter::getter
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
    synthetic getter
      reference: <testLibrary>::@topLevelVariable::getter
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::getter
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
    static getter
      reference: <testLibrary>::@getter::getter
      firstFragment: #F4
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      returnType: int
      variable: <testLibrary>::@topLevelVariable::getter
''');
  }

  test_metadata_offsets_onUnitSetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
set setter(@foo int a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
        #F2 synthetic setter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@topLevelVariable::setter
      getters
        #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
      setters
        #F4 setter (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::setter
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          formalParameters
            #F5 a (nameOffset:41) (firstTokenOffset:32) (offset:41)
              element: <testLibrary>::@setter::setter::@formalParameter::a
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
    synthetic setter
      reference: <testLibrary>::@topLevelVariable::setter
      firstFragment: #F2
      type: int
      setter: <testLibrary>::@setter::setter
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static setter
      reference: <testLibrary>::@setter::setter
      firstFragment: #F4
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F5
          type: int
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: foo @33
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
      returnType: void
      variable: <testLibrary>::@topLevelVariable::setter
''');
  }

  test_metadata_offsets_onUnitVariable() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
var isNotConst = 1;

@foo
const isConst = 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
        #F2 hasInitializer isNotConst (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::isNotConst
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
        #F3 hasInitializer isConst (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::isConst
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                element: <testLibrary>::@getter::foo
                staticType: null
              element2: <testLibrary>::@getter::foo
          initializer: expression_1
            IntegerLiteral
              literal: 2 @63
              staticType: int
      getters
        #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
        #F5 synthetic isNotConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::isNotConst
        #F6 synthetic isConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::isConst
      setters
        #F7 synthetic isNotConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::isNotConst
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::isNotConst::@formalParameter::value
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
    hasInitializer isNotConst
      reference: <testLibrary>::@topLevelVariable::isNotConst
      firstFragment: #F2
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      type: int
      getter: <testLibrary>::@getter::isNotConst
      setter: <testLibrary>::@setter::isNotConst
    const hasInitializer isConst
      reference: <testLibrary>::@topLevelVariable::isConst
      firstFragment: #F3
      metadata
        Annotation
          atSign: @ @42
          name: SimpleIdentifier
            token: foo @43
            element: <testLibrary>::@getter::foo
            staticType: null
          element2: <testLibrary>::@getter::foo
      type: int
      constantInitializer
        fragment: #F3
        expression: expression_1
      getter: <testLibrary>::@getter::isConst
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
    synthetic static isNotConst
      reference: <testLibrary>::@getter::isNotConst
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::isNotConst
    synthetic static isConst
      reference: <testLibrary>::@getter::isConst
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::isConst
  setters
    synthetic static isNotConst
      reference: <testLibrary>::@setter::isNotConst
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::isNotConst
''');
  }

  test_metadata_partDirective() async {
    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary('''
@a
part 'foo.dart';
const a = 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element2: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo.dart
          partKeywordOffset: 3
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          unit: #F1
      topLevelVariables
        #F2 hasInitializer a (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @30
              staticType: int
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::a
    #F1 package:test/foo.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_partDirective2() async {
    newFile('$testPackageLibPath/foo.dart', 'part of L;');
    var library = await buildLibrary('''
library L;
@a
part 'foo.dart';
const a = null;''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: L
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo.dart
          partKeywordOffset: 14
          metadata
            Annotation
              atSign: @ @11
              name: SimpleIdentifier
                token: a @12
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          unit: #F1
      topLevelVariables
        #F2 hasInitializer a (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @41
              staticType: Null
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::a
    #F1 package:test/foo.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_partDirective3() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');
    var library = await buildLibrary('''
part 'a.dart';
part 'b.dart';
''');

    // The difference with the test above is that we ask the part first.
    // There was a bug that we were not loading library directives.
    expect(library.firstFragment.parts[0].metadata.annotations, isEmpty);
  }

  test_metadata_partOf_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
class A {}
''');
    var library = await buildLibrary('''
part 'a.dart';
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
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F2 class A (nameOffset:39) (firstTokenOffset:21) (offset:39)
          element: <testLibrary>::@class::A
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_metadata_partOf_exportLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
export 'dart:math';
''');
    var library = await buildLibrary('''
part 'a.dart';
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
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryExports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
''');
  }

  test_metadata_partOf_importLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
import 'dart:math';
''');
    var library = await buildLibrary('''
part 'a.dart';
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
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
''');
  }

  test_metadata_partOf_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
@deprecated
part 'a.dart';
''');

    var library = await buildLibrary('''
part 'b.dart';
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
          uri: package:test/b.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      parts
        part_1
          uri: package:test/a.dart
          partKeywordOffset: 33
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
          unit: #F2
    #F2 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
''');
  }

  test_metadata_prefixed_variable() async {
    newFile('$testPackageLibPath/a.dart', 'const b = null;');
    var library = await buildLibrary('import "a.dart" as a; @a.b class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @19
      classes
        #F1 class C (nameOffset:33) (firstTokenOffset:22) (offset:33)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
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

  test_metadata_simpleFormalParameter() async {
    var library = await buildLibrary('const a = null; f(@a x) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      functions
        #F3 f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 x (nameOffset:21) (firstTokenOffset:18) (offset:21)
              element: <testLibrary>::@function::f::@formalParameter::x
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional hasImplicitType x
          firstFragment: #F4
          type: dynamic
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_simpleFormalParameter_method() async {
    var library = await buildLibrary('''
const a = null;

class C {
  m(@a x) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 m (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F4 x (nameOffset:34) (firstTokenOffset:31) (offset:34)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::x
                  metadata
                    Annotation
                      atSign: @ @31
                      name: SimpleIdentifier
                        token: a @32
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element2: <testLibrary>::@getter::a
      topLevelVariables
        #F5 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F6 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType x
              firstFragment: #F4
              type: dynamic
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: a @32
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F5
      type: dynamic
      constantInitializer
        fragment: #F5
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_unit_setter() async {
    var library = await buildLibrary('''
const a = null;

set foo(@a int x) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      setters
        #F4 foo (nameOffset:21) (firstTokenOffset:17) (offset:21)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 x (nameOffset:32) (firstTokenOffset:25) (offset:32)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F2
      type: int
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F5
          type: int
          metadata
            Annotation
              atSign: @ @25
              name: SimpleIdentifier
                token: a @26
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await buildLibrary('const a = null; f([@a x = null]) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      functions
        #F3 f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 x (nameOffset:22) (firstTokenOffset:19) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::x
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              initializer: expression_1
                NullLiteral
                  literal: null @26
                  staticType: Null
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 optionalPositional hasImplicitType x
          firstFragment: #F4
          type: dynamic
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          constantInitializer
            fragment: #F4
            expression: expression_1
      returnType: dynamic
''');
  }

  test_metadata_superFormalParameter() async {
    var library = await buildLibrary('''
const a = null;

class A {
  A(int x);
}

class B extends A {
  B(@a super.x);
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
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 29
              formalParameters
                #F3 x (nameOffset:35) (firstTokenOffset:31) (offset:35)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
        #F4 class B (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::B
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:64) (offset:64)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 64
              formalParameters
                #F6 super.x (nameOffset:75) (firstTokenOffset:66) (offset:75)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::x
                  metadata
                    Annotation
                      atSign: @ @66
                      name: SimpleIdentifier
                        token: a @67
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element2: <testLibrary>::@getter::a
      topLevelVariables
        #F7 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F8 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional x
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
            #E1 requiredPositional final hasImplicitType x
              firstFragment: #F6
              type: int
              metadata
                Annotation
                  atSign: @ @66
                  name: SimpleIdentifier
                    token: a @67
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
          superConstructor: <testLibrary>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: dynamic
      constantInitializer
        fragment: #F7
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await buildLibrary('const a = null; @a int v;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
        #F2 v (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::v
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::v
      setters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::v
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F2
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await buildLibrary('const a = null; class C<@a T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:27) (firstTokenOffset:24) (offset:27)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F4 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: dynamic
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_typeParameter_ofClassTypeAlias() async {
    var library = await buildLibrary('''
const a = null;
class C<@a T> = D with E;
class D {}
class E {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:27) (firstTokenOffset:24) (offset:27)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::D
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F6 class E (nameOffset:59) (firstTokenOffset:53) (offset:59)
          element: <testLibrary>::@class::E
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
      topLevelVariables
        #F8 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F9 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
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
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: dynamic
      constantInitializer
        fragment: #F8
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await buildLibrary('const a = null; f<@a T>() {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
      functions
        #F3 f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          typeParameters
            #F4 T (nameOffset:21) (firstTokenOffset:18) (offset:21)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await buildLibrary('const a = null; typedef F<@a T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:24) (firstTokenOffset:16) (offset:24)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:29) (firstTokenOffset:26) (offset:29)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
      topLevelVariables
        #F3 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      aliasedType: dynamic Function()
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer
        fragment: #F3
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_unit_topLevelVariable_first() async {
    var library = await buildLibrary(r'''
const a = 0;
@a
int x = 0;
''');
    // Check metadata without asking any other properties.
    var x = library.getTopLevelVariable('x')!;
    expect(x.metadata.annotations, hasLength(1));
    // Check details.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
        #F2 hasInitializer x (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::x
          metadata
            Annotation
              atSign: @ @13
              name: SimpleIdentifier
                token: a @14
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::x
      setters
        #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::x
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F2
      metadata
        Annotation
          atSign: @ @13
          name: SimpleIdentifier
            token: a @14
            element: <testLibrary>::@getter::a
            staticType: null
          element2: <testLibrary>::@getter::a
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_metadata_value_class_staticField() async {
    var library = await buildLibrary('''
class A {
  static const x = 0;
}
@A.x
class C {}
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
            #F2 hasInitializer x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @29
                  staticType: int
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
        #F5 class C (nameOffset:45) (firstTokenOffset:34) (offset:45)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static const hasInitializer x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic static x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_metadata_value_enum_constant() async {
    var library = await buildLibrary('''
enum E {a, b, c}
@E.b
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:28) (firstTokenOffset:17) (offset:28)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F3 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer a (nameOffset:8) (firstTokenOffset:8) (offset:8)
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
            #F5 hasInitializer b (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F6 hasInitializer c (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
            #F7 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F8 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F9 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::E::@getter::a
            #F10 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::b
            #F11 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::c
            #F12 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F5
          type: E
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasInitializer c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F10
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        synthetic static c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F11
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F12
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_metadata_value_extension_staticField() async {
    var library = await buildLibrary('''
extension E on int {
  static const x = 0;
}
@E.x
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:56) (firstTokenOffset:45) (offset:56)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      extensions
        #F3 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          fields
            #F4 hasInitializer x (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@extension::E::@field::x
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @40
                  staticType: int
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@extension::E::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: int
      fields
        static const hasInitializer x
          reference: <testLibrary>::@extension::E::@field::x
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@extension::E::@getter::x
      getters
        synthetic static x
          reference: <testLibrary>::@extension::E::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::E::@field::x
''');
  }

  test_metadata_value_extension_staticField_unnamed() async {
    var library = await buildLibrary('''
extension on Object {
  @foo
  static const foo = 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@extension::0
          fields
            #F2 hasInitializer foo (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@extension::0::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @50
                  staticType: int
          getters
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extension::0::@getter::foo
  extensions
    extension <null-name>
      reference: <testLibrary>::@extension::0
      firstFragment: #F1
      extendedType: Object
      fields
        static const hasInitializer foo
          reference: <testLibrary>::@extension::0::@field::foo
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@extension::0::@getter::foo
      getters
        synthetic static foo
          reference: <testLibrary>::@extension::0::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extension::0::@field::foo
''');
  }

  test_metadata_value_prefix_extension_staticField() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on int {
  static const x = 0;
}
''');
    var library = await buildLibrary('''
import 'foo.dart' as foo;
@foo.E.x
class C {}
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
        #F1 class C (nameOffset:41) (firstTokenOffset:26) (offset:41)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
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

  test_unresolved_annotation_instanceCreation_argument_super() async {
    var library = await buildLibrary('''
class A {
  const A(_);
}

@A(super)
class C {}
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
                #F3 _ (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F4 class C (nameOffset:43) (firstTokenOffset:27) (offset:43)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType _
              firstFragment: #F3
              type: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_unresolved_annotation_instanceCreation_argument_this() async {
    var library = await buildLibrary('''
class A {
  const A(_);
}

@A(this)
class C {}
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
                #F3 _ (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F4 class C (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType _
              firstFragment: #F3
              type: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    var library = await buildLibrary('@foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:17) (firstTokenOffset:0) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
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

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    var library = await buildLibrary('@String.foo() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:20) (firstTokenOffset:0) (offset:20)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
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

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    var library = await buildLibrary('@foo.bar class C {}');
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
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    var library = await buildLibrary(
      'import "dart:async" as foo; @foo.bar class C {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:43) (firstTokenOffset:28) (offset:43)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
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

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    var library = await buildLibrary('@foo.bar.baz() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
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

  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    var library = await buildLibrary(
      'import "dart:async" as foo; @foo.bar.baz() class C {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:49) (firstTokenOffset:28) (offset:49)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
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

  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    var library = await buildLibrary(
      'import "dart:async" as foo; @foo.Future.bar() class C {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:52) (firstTokenOffset:28) (offset:52)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
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

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    var library = await buildLibrary('@foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:17) (firstTokenOffset:0) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
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

  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    var library = await buildLibrary(
      'import "dart:async" as foo; @foo.bar() class C {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:45) (firstTokenOffset:28) (offset:45)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
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

  test_unresolved_annotation_simpleIdentifier() async {
    var library = await buildLibrary('@foo class C {}');
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
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_simpleIdentifier_multiplyDefined() async {
    if (!keepLinkingLibraries) return;

    newFile('$testPackageLibPath/a.dart', 'const v = 0;');
    newFile('$testPackageLibPath/b.dart', 'const v = 0;');
    var library = await buildLibrary('''
import 'a.dart';
import 'b.dart';

@v
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      classes
        #F1 class C (nameOffset:44) (firstTokenOffset:35) (offset:44)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
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

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    var library = await buildLibrary('@foo() class C {}');
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
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }
}

@reflectiveTest
class MetadataElementTest_fromBytes extends MetadataElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MetadataElementTest_keepLinking extends MetadataElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
