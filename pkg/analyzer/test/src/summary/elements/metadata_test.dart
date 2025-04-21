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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class A @31
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 43
              formalParameters
                o @45
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::o#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional hasImplicitType o
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 45
              formalParameters
                o @47
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::o#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional hasImplicitType o
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a @19
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @19
      classes
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    var x = library.getClass2('C')!.getField2('x')!;
    expect(x.metadata2.annotations, hasLength(1));
    // Check details.
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
            hasInitializer x @34
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            synthetic set x
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        hasInitializer x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::x#element
          setter: <testLibraryFragment>::@class::C::@setter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: int
      setters
        synthetic set x
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: int
          returnType: void
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @27
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @34
              element: T@34
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          fields
            hasInitializer foo @54
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <testLibraryFragment>::@class::C::@field::foo#element
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
              getter2: <testLibraryFragment>::@class::C::@getter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@class::C::@getter::foo
              element: <testLibraryFragment>::@class::C::@getter::foo#element
          methods
            bar @77
              reference: <testLibraryFragment>::@class::C::@method::bar
              element: <testLibraryFragment>::@class::C::@method::bar#element
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    element: <testLibraryFragment>::@class::C::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@class::C::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      fields
        static const hasInitializer foo
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::C::@field::foo
            expression: expression_0
          getter: <testLibraryFragment>::@class::C::@getter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
          returnType: int
      methods
        bar
          firstFragment: <testLibraryFragment>::@class::C::@method::bar
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                element: <testLibraryFragment>::@class::C::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@class::C::@getter::foo#element
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_1
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @25
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class D @45
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
        class E @56
          reference: <testLibraryFragment>::@class::E
          element: <testLibrary>::@class::E
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::E::@constructor::new
              element: <testLibraryFragment>::@class::E::@constructor::new#element
              typeName: E
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      mixins
        E
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibraryFragment>::@class::D::@constructor::new#element
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
    class E
      reference: <testLibrary>::@class::E
      firstFragment: <testLibraryFragment>::@class::E
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::E::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                _ @30
                  element: <testLibraryFragment>::@class::A::@constructor::named::@parameter::_#element
        class C @54
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
          formalParameters
            requiredPositional _
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
              formalParameters
                _ @31
                  element: <testLibraryFragment>::@class::A::@constructor::named::@parameter::_#element
        class C @56
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
          formalParameters
            requiredPositional _
              type: T
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
        class C @50
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @52
              element: T@52
          constructors
            synthetic const named
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              typeName: C
        class D @85
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
      mixins
        mixin B @38
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibrary>::@mixin::B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      supertype: A
      mixins
        B
      constructors
        synthetic const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @-1
                element: <testLibraryFragment>::@class::A::@constructor::named#element
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibraryFragment>::@class::A::@constructor::named#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::named#element
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 18
              formalParameters
                _ @24
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional _
              type: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
              formalParameters
                _ @25
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional _
              type: T
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @46
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 18
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @46
              element: T@46
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class D @73
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibrary>::@mixin::B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      supertype: A
      mixins
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 16
              formalParameters
                x @18
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::x#element
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional hasImplicitType x
              type: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            named @31
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
              typeName: C
              typeNameOffset: 29
              periodOffset: 30
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await buildLibrary('const a = null; class C { @a C(); }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
              typeName: C
              typeNameOffset: 29
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_exportDirective() async {
    newFile('$testPackageLibPath/foo.dart', '');
    var library = await buildLibrary('@a export "foo.dart"; const a = null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element2: <testLibraryFragment>::@getter::a#element
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @28
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @32
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await buildLibrary('const a = null; class C { @a int x; }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            x @33
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            synthetic set x
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::x#element
          setter: <testLibraryFragment>::@class::C::@setter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: int
      setters
        synthetic set x
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: int
          returnType: void
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            x @32
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 37
              formalParameters
                this.x @47
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @39
                      name: SimpleIdentifier
                        token: a @40
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::a#element
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            synthetic set x
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
          setter: <testLibraryFragment>::@class::C::@setter::x#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @39
                  name: SimpleIdentifier
                    token: a @40
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
      setters
        synthetic set x
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: dynamic
          returnType: void
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            x @30
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 33
              formalParameters
                default this.x @44
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @36
                      name: SimpleIdentifier
                        token: a @37
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::a#element
                  initializer: expression_0
                    NullLiteral
                      literal: null @48
                      staticType: Null
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            synthetic set x
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_1
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
          setter: <testLibraryFragment>::@class::C::@setter::x#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalPositional final hasImplicitType x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: a @37
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
              constantInitializer
                expression: expression_0
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
      setters
        synthetic set x
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: dynamic
          returnType: void
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_1
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
      returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await buildLibrary('const a = null; @a get f => null;');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        synthetic f (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get f @23
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    synthetic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic
      getter: <testLibraryFragment>::@getter::f#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    static get f
      firstFragment: <testLibraryFragment>::@getter::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
      returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await buildLibrary('const a = null; @a set f(value) {}');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        synthetic f (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        set f @23
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          formalParameters
            value @25
              element: <testLibraryFragment>::@setter::f::@parameter::value#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    synthetic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  setters
    static set f
      firstFragment: <testLibraryFragment>::@setter::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
      formalParameters
        requiredPositional hasImplicitType value
          type: dynamic
      returnType: void
''');
  }

  test_metadata_functionTypeAlias() async {
    var library = await buildLibrary('const a = null; @a typedef F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @27
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
      aliasedType: dynamic Function()
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await buildLibrary('const a = null; f(@a g()) {}');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            g @21
              element: <testLibraryFragment>::@function::f::@parameter::g#element
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional g
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await buildLibrary('const a = null; f([@a g() = null]) {}');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default g @22
              element: <testLibraryFragment>::@function::f::@parameter::g#element
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
              initializer: expression_1
                NullLiteral
                  literal: null @28
                  staticType: null
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalPositional g
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          constantInitializer
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @46
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element2: <testLibraryFragment>::@getter::b#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      metadata
        Annotation
          atSign: @ @32
          name: SimpleIdentifier
            token: a @33
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
        Annotation
          atSign: @ @35
          name: SimpleIdentifier
            token: b @36
            element: <testLibraryFragment>::@getter::b#element
            staticType: null
          element2: <testLibraryFragment>::@getter::b#element
      aliasedType: void Function()
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function(int)
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

  test_metadata_inAliasedElement_formalParameter2() async {
    var library = await buildLibrary('''
const a = 42;
typedef F = void Function(int foo(@a int bar))
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function(int Function(int))
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

  test_metadata_inAliasedElement_typeParameter() async {
    var library = await buildLibrary('''
const a = 42;
typedef F = void Function<@a T>(int first)
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function<T>(int)
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

  test_metadata_invalid_classDeclaration() async {
    var library = await buildLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            _ @2
              element: <testLibraryFragment>::@function::f::@parameter::_#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional hasImplicitType _
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
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
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element2: <testLibraryFragment>::@getter::a#element
  fragments
    <testLibraryFragment> (offset=11)
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @20
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @24
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            synthetic m
              reference: <testLibraryFragment>::@class::C::@field::m
              element: <testLibraryFragment>::@class::C::@field::m#element
              getter2: <testLibraryFragment>::@class::C::@getter::m
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            get m @33
              reference: <testLibraryFragment>::@class::C::@getter::m
              element: <testLibraryFragment>::@class::C::@getter::m#element
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic m
          firstFragment: <testLibraryFragment>::@class::C::@field::m
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::m#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get m
          firstFragment: <testLibraryFragment>::@class::C::@getter::m
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            m @54
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    element: <testLibraryFragment>::@getter::b#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::b#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          metadata
            Annotation
              atSign: @ @44
              name: SimpleIdentifier
                token: a @45
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element2: <testLibraryFragment>::@getter::b#element
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @38
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
          methods
            m @54
              reference: <testLibraryFragment>::@mixin::M::@method::m
              element: <testLibraryFragment>::@mixin::M::@method::m#element
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    element: <testLibraryFragment>::@getter::b#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::b#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      methods
        m
          firstFragment: <testLibraryFragment>::@mixin::M::@method::m
          metadata
            Annotation
              atSign: @ @44
              name: SimpleIdentifier
                token: a @45
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element2: <testLibraryFragment>::@getter::b#element
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            synthetic m
              reference: <testLibraryFragment>::@class::C::@field::m
              element: <testLibraryFragment>::@class::C::@field::m#element
              setter2: <testLibraryFragment>::@class::C::@setter::m
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          setters
            set m @37
              reference: <testLibraryFragment>::@class::C::@setter::m
              element: <testLibraryFragment>::@class::C::@setter::m#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: a @29
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
              formalParameters
                value @39
                  element: <testLibraryFragment>::@class::C::@setter::m::@parameter::value#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic m
          firstFragment: <testLibraryFragment>::@class::C::@field::m
          type: dynamic
          setter: <testLibraryFragment>::@class::C::@setter::m#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set m
          firstFragment: <testLibraryFragment>::@class::C::@setter::m
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: a @29
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          formalParameters
            requiredPositional hasImplicitType value
              type: dynamic
          returnType: void
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @27
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
          typeParameters
            T @34
              element: T@34
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          fields
            hasInitializer foo @54
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <testLibraryFragment>::@mixin::M::@getter::foo#element
          methods
            bar @77
              reference: <testLibraryFragment>::@mixin::M::@method::bar
              element: <testLibraryFragment>::@mixin::M::@method::bar#element
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    element: <testLibraryFragment>::@mixin::M::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@mixin::M::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      superclassConstraints
        Object
      fields
        static const hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@mixin::M::@field::foo
            expression: expression_0
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
      getters
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
          returnType: int
      methods
        bar
          firstFragment: <testLibraryFragment>::@mixin::M::@method::bar
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                element: <testLibraryFragment>::@mixin::M::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@mixin::M::@getter::foo#element
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_1
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @44
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          initializer: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    const hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::b
        expression: expression_1
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @34
              element: T@34
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
              typeName: A
              typeNameOffset: 35
              formalParameters
                a @46
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                  metadata
                    Annotation
                      atSign: @ @37
                      name: SimpleIdentifier
                        token: foo @38
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            requiredPositional a
              type: int
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            synthetic getter
              reference: <testLibraryFragment>::@class::A::@field::getter
              element: <testLibraryFragment>::@class::A::@field::getter#element
              getter2: <testLibraryFragment>::@class::A::@getter::getter
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            get getter @43
              reference: <testLibraryFragment>::@class::A::@getter::getter
              element: <testLibraryFragment>::@class::A::@getter::getter#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic getter
          firstFragment: <testLibraryFragment>::@class::A::@field::getter
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::getter#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        get getter
          firstFragment: <testLibraryFragment>::@class::A::@getter::getter
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          returnType: int
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          methods
            method @40
              reference: <testLibraryFragment>::@class::A::@method::method
              element: <testLibraryFragment>::@class::A::@method::method#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
              typeParameters
                T @52
                  element: T@52
                  metadata
                    Annotation
                      atSign: @ @47
                      name: SimpleIdentifier
                        token: foo @48
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::foo#element
              formalParameters
                a @64
                  element: <testLibraryFragment>::@class::A::@method::method::@parameter::a#element
                  metadata
                    Annotation
                      atSign: @ @55
                      name: SimpleIdentifier
                        token: foo @56
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        method
          firstFragment: <testLibraryFragment>::@class::A::@method::method
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T
              metadata
                Annotation
                  atSign: @ @47
                  name: SimpleIdentifier
                    token: foo @48
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            requiredPositional a
              type: int
              metadata
                Annotation
                  atSign: @ @55
                  name: SimpleIdentifier
                    token: foo @56
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            synthetic setter
              reference: <testLibraryFragment>::@class::A::@field::setter
              element: <testLibraryFragment>::@class::A::@field::setter#element
              setter2: <testLibraryFragment>::@class::A::@setter::setter
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          setters
            set setter @39
              reference: <testLibraryFragment>::@class::A::@setter::setter
              element: <testLibraryFragment>::@class::A::@setter::setter#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
              formalParameters
                a @55
                  element: <testLibraryFragment>::@class::A::@setter::setter::@parameter::a#element
                  metadata
                    Annotation
                      atSign: @ @46
                      name: SimpleIdentifier
                        token: foo @47
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic setter
          firstFragment: <testLibraryFragment>::@class::A::@field::setter
          type: int
          setter: <testLibraryFragment>::@class::A::@setter::setter#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      setters
        set setter
          firstFragment: <testLibraryFragment>::@class::A::@setter::setter
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            requiredPositional a
              type: int
              metadata
                Annotation
                  atSign: @ @46
                  name: SimpleIdentifier
                    token: foo @47
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
        class B @50
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @57
              element: T@57
              metadata
                Annotation
                  atSign: @ @52
                  name: SimpleIdentifier
                    token: foo @53
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
      mixins
        mixin M @33
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @52
              name: SimpleIdentifier
                token: foo @53
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      supertype: A
      mixins
        M
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer e1 @37
              reference: <testLibraryFragment>::@enum::E::@field::e1
              element: <testLibraryFragment>::@enum::E::@field::e1#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::e1
            hasInitializer e2 @43
              reference: <testLibraryFragment>::@enum::E::@field::e2
              element: <testLibraryFragment>::@enum::E::@field::e2#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::e2
            hasInitializer e3 @54
              reference: <testLibraryFragment>::@enum::E::@field::e3
              element: <testLibraryFragment>::@enum::E::@field::e3#element
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::e3
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: e1 @-1
                      element: <testLibraryFragment>::@enum::E::@getter::e1#element
                      staticType: E
                    SimpleIdentifier
                      token: e2 @-1
                      element: <testLibraryFragment>::@enum::E::@getter::e2#element
                      staticType: E
                    SimpleIdentifier
                      token: e3 @-1
                      element: <testLibraryFragment>::@enum::E::@getter::e3#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get e1
              reference: <testLibraryFragment>::@enum::E::@getter::e1
              element: <testLibraryFragment>::@enum::E::@getter::e1#element
            synthetic get e2
              reference: <testLibraryFragment>::@enum::E::@getter::e2
              element: <testLibraryFragment>::@enum::E::@getter::e2#element
            synthetic get e3
              reference: <testLibraryFragment>::@enum::E::@getter::e3
              element: <testLibraryFragment>::@enum::E::@getter::e3#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_4
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer e1
          firstFragment: <testLibraryFragment>::@enum::E::@field::e1
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::e1
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::e1#element
        static const enumConstant hasInitializer e2
          firstFragment: <testLibraryFragment>::@enum::E::@field::e2
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::e2
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::e2#element
        static const enumConstant hasInitializer e3
          firstFragment: <testLibraryFragment>::@enum::E::@field::e3
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::e3
            expression: expression_2
          getter: <testLibraryFragment>::@enum::E::@getter::e3#element
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
        synthetic static get e1
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e1
          returnType: E
        synthetic static get e2
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e2
          returnType: E
        synthetic static get e3
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e3
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_4
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension E @31
          reference: <testLibraryFragment>::@extension::E
          element: <testLibrary>::@extension::E
          typeParameters
            T @38
              element: T@38
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: foo @34
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer isStatic @42
              reference: <testLibraryFragment>::@class::A::@field::isStatic
              element: <testLibraryFragment>::@class::A::@field::isStatic#element
              getter2: <testLibraryFragment>::@class::A::@getter::isStatic
              setter2: <testLibraryFragment>::@class::A::@setter::isStatic
            hasInitializer isStaticConst @79
              reference: <testLibraryFragment>::@class::A::@field::isStaticConst
              element: <testLibraryFragment>::@class::A::@field::isStaticConst#element
              initializer: expression_0
                IntegerLiteral
                  literal: 2 @95
                  staticType: int
              getter2: <testLibraryFragment>::@class::A::@getter::isStaticConst
            hasInitializer isInstance @112
              reference: <testLibraryFragment>::@class::A::@field::isInstance
              element: <testLibraryFragment>::@class::A::@field::isInstance#element
              getter2: <testLibraryFragment>::@class::A::@getter::isInstance
              setter2: <testLibraryFragment>::@class::A::@setter::isInstance
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get isStatic
              reference: <testLibraryFragment>::@class::A::@getter::isStatic
              element: <testLibraryFragment>::@class::A::@getter::isStatic#element
            synthetic get isStaticConst
              reference: <testLibraryFragment>::@class::A::@getter::isStaticConst
              element: <testLibraryFragment>::@class::A::@getter::isStaticConst#element
            synthetic get isInstance
              reference: <testLibraryFragment>::@class::A::@getter::isInstance
              element: <testLibraryFragment>::@class::A::@getter::isInstance#element
          setters
            synthetic set isStatic
              reference: <testLibraryFragment>::@class::A::@setter::isStatic
              element: <testLibraryFragment>::@class::A::@setter::isStatic#element
              formalParameters
                _isStatic
                  element: <testLibraryFragment>::@class::A::@setter::isStatic::@parameter::_isStatic#element
            synthetic set isInstance
              reference: <testLibraryFragment>::@class::A::@setter::isInstance
              element: <testLibraryFragment>::@class::A::@setter::isInstance#element
              formalParameters
                _isInstance
                  element: <testLibraryFragment>::@class::A::@setter::isInstance::@parameter::_isInstance#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static hasInitializer isStatic
          firstFragment: <testLibraryFragment>::@class::A::@field::isStatic
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::isStatic#element
          setter: <testLibraryFragment>::@class::A::@setter::isStatic#element
        static const hasInitializer isStaticConst
          firstFragment: <testLibraryFragment>::@class::A::@field::isStaticConst
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::A::@field::isStaticConst
            expression: expression_0
          getter: <testLibraryFragment>::@class::A::@getter::isStaticConst#element
        hasInitializer isInstance
          firstFragment: <testLibraryFragment>::@class::A::@field::isInstance
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::isInstance#element
          setter: <testLibraryFragment>::@class::A::@setter::isInstance#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get isStatic
          firstFragment: <testLibraryFragment>::@class::A::@getter::isStatic
          returnType: int
        synthetic static get isStaticConst
          firstFragment: <testLibraryFragment>::@class::A::@getter::isStaticConst
          returnType: int
        synthetic get isInstance
          firstFragment: <testLibraryFragment>::@class::A::@getter::isInstance
          returnType: int
      setters
        synthetic static set isStatic
          firstFragment: <testLibraryFragment>::@class::A::@setter::isStatic
          formalParameters
            requiredPositional _isStatic
              type: int
          returnType: void
        synthetic set isInstance
          firstFragment: <testLibraryFragment>::@class::A::@setter::isInstance
          formalParameters
            requiredPositional _isInstance
              type: int
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_1
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
        element: <testLibraryFragment>::@getter::foo#element
        staticType: null
      element2: <testLibraryFragment>::@getter::foo#element
  fragments
    <testLibraryFragment> (offset=37)
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @52
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @58
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin A @27
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          typeParameters
            T @34
              element: T@34
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      superclassConstraints
        Object
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @34
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T @41
              element: T@41
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: foo @37
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @36
              name: SimpleIdentifier
                token: foo @37
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      aliasedType: void Function(int)
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @29
          reference: <testLibraryFragment>::@typeAlias::A
          element: <testLibrary>::@typeAlias::A
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T @36
              element: T@36
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  typeAliases
    A
      firstFragment: <testLibraryFragment>::@typeAlias::A
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @31
              name: SimpleIdentifier
                token: foo @32
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      aliasedType: void Function<U>(int)
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        hasInitializer foo @65
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @71
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T @33
              element: T@33
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            default a @47
              reference: <testLibraryFragment>::@function::f::@parameter::a
              element: <testLibraryFragment>::@function::f::@parameter::a#element
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
              initializer: expression_1
                IntegerLiteral
                  literal: 42 @51
                  staticType: int
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      formalParameters
        optionalNamed a
          firstFragment: <testLibraryFragment>::@function::f::@parameter::a
          type: int?
          metadata
            Annotation
              atSign: @ @37
              name: SimpleIdentifier
                token: foo @38
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          constantInitializer
            fragment: <testLibraryFragment>::@function::f::@parameter::a
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
        synthetic getter (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::getter
          element: <testLibrary>::@topLevelVariable::getter
          getter2: <testLibraryFragment>::@getter::getter
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
        get getter @29
          reference: <testLibraryFragment>::@getter::getter
          element: <testLibraryFragment>::@getter::getter#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
    synthetic getter
      reference: <testLibrary>::@topLevelVariable::getter
      firstFragment: <testLibraryFragment>::@topLevelVariable::getter
      type: int
      getter: <testLibraryFragment>::@getter::getter#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
    static get getter
      firstFragment: <testLibraryFragment>::@getter::getter
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
        synthetic setter (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::setter
          element: <testLibrary>::@topLevelVariable::setter
          setter2: <testLibraryFragment>::@setter::setter
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set setter @25
          reference: <testLibraryFragment>::@setter::setter
          element: <testLibraryFragment>::@setter::setter#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            a @41
              element: <testLibraryFragment>::@setter::setter::@parameter::a#element
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
    synthetic setter
      reference: <testLibrary>::@topLevelVariable::setter
      firstFragment: <testLibraryFragment>::@topLevelVariable::setter
      type: int
      setter: <testLibraryFragment>::@setter::setter#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
  setters
    static set setter
      firstFragment: <testLibraryFragment>::@setter::setter
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      formalParameters
        requiredPositional a
          type: int
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: foo @33
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
      returnType: void
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          getter2: <testLibraryFragment>::@getter::foo
        hasInitializer isNotConst @25
          reference: <testLibraryFragment>::@topLevelVariable::isNotConst
          element: <testLibrary>::@topLevelVariable::isNotConst
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          getter2: <testLibraryFragment>::@getter::isNotConst
          setter2: <testLibraryFragment>::@setter::isNotConst
        hasInitializer isConst @53
          reference: <testLibraryFragment>::@topLevelVariable::isConst
          element: <testLibrary>::@topLevelVariable::isConst
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element2: <testLibraryFragment>::@getter::foo#element
          initializer: expression_1
            IntegerLiteral
              literal: 2 @63
              staticType: int
          getter2: <testLibraryFragment>::@getter::isConst
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
        synthetic get isNotConst
          reference: <testLibraryFragment>::@getter::isNotConst
          element: <testLibraryFragment>::@getter::isNotConst#element
        synthetic get isConst
          reference: <testLibraryFragment>::@getter::isConst
          element: <testLibraryFragment>::@getter::isConst#element
      setters
        synthetic set isNotConst
          reference: <testLibraryFragment>::@setter::isNotConst
          element: <testLibraryFragment>::@setter::isNotConst#element
          formalParameters
            _isNotConst
              element: <testLibraryFragment>::@setter::isNotConst::@parameter::_isNotConst#element
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::foo
        expression: expression_0
      getter: <testLibraryFragment>::@getter::foo#element
    hasInitializer isNotConst
      reference: <testLibrary>::@topLevelVariable::isNotConst
      firstFragment: <testLibraryFragment>::@topLevelVariable::isNotConst
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      type: int
      getter: <testLibraryFragment>::@getter::isNotConst#element
      setter: <testLibraryFragment>::@setter::isNotConst#element
    const hasInitializer isConst
      reference: <testLibrary>::@topLevelVariable::isConst
      firstFragment: <testLibraryFragment>::@topLevelVariable::isConst
      metadata
        Annotation
          atSign: @ @42
          name: SimpleIdentifier
            token: foo @43
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element2: <testLibraryFragment>::@getter::foo#element
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::isConst
        expression: expression_1
      getter: <testLibraryFragment>::@getter::isConst#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
    synthetic static get isNotConst
      firstFragment: <testLibraryFragment>::@getter::isNotConst
      returnType: int
    synthetic static get isConst
      firstFragment: <testLibraryFragment>::@getter::isConst
      returnType: int
  setters
    synthetic static set isNotConst
      firstFragment: <testLibraryFragment>::@setter::isNotConst
      formalParameters
        requiredPositional _isNotConst
          type: int
      returnType: void
''');
  }

  test_metadata_partDirective() async {
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/foo.dart
      topLevelVariables
        hasInitializer a @37
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @41
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
    <testLibrary>::@fragment::package:test/foo.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_partDirective2() async {
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
    expect(library.definingCompilationUnit.parts[0].metadata, isEmpty);
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
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new#element
              typeName: A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
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
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element2: dart:core::<fragment>::@getter::deprecated#element
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
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_metadata_prefixed_variable() async {
    newFile('$testPackageLibPath/a.dart', 'const b = null;');
    var library = await buildLibrary('import "a.dart" as a; @a.b class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a @19
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @19
      classes
        class C @33
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_metadata_simpleFormalParameter() async {
    var library = await buildLibrary('const a = null; f(@a x) {}');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            x @21
              element: <testLibraryFragment>::@function::f::@parameter::x#element
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional hasImplicitType x
          type: dynamic
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            m @29
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              formalParameters
                x @34
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @31
                      name: SimpleIdentifier
                        token: a @32
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          formalParameters
            requiredPositional hasImplicitType x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: a @32
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
          returnType: dynamic
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        set foo @21
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            x @32
              element: <testLibraryFragment>::@setter::foo::@parameter::x#element
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional x
          type: int
          metadata
            Annotation
              atSign: @ @25
              name: SimpleIdentifier
                token: a @26
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      returnType: void
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await buildLibrary('const a = null; f([@a x = null]) {}');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default x @22
              element: <testLibraryFragment>::@function::f::@parameter::x#element
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
              initializer: expression_1
                NullLiteral
                  literal: null @26
                  staticType: Null
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalPositional hasImplicitType x
          type: dynamic
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          constantInitializer
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @23
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 29
              formalParameters
                x @35
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::x#element
        class B @48
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 64
              formalParameters
                super.x @75
                  element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @66
                      name: SimpleIdentifier
                        token: a @67
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
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
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional x
              type: int
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType x
              type: int
              metadata
                Annotation
                  atSign: @ @66
                  name: SimpleIdentifier
                    token: a @67
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await buildLibrary('const a = null; @a int v;');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
        v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
      returnType: void
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await buildLibrary('const a = null; class C<@a T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @27
              element: T@27
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @27
              element: T@27
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class D @48
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
        class E @59
          reference: <testLibraryFragment>::@class::E
          element: <testLibrary>::@class::E
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::E::@constructor::new
              element: <testLibraryFragment>::@class::E::@constructor::new#element
              typeName: E
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      supertype: D
      mixins
        E
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibraryFragment>::@class::D::@constructor::new#element
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
    class E
      reference: <testLibrary>::@class::E
      firstFragment: <testLibraryFragment>::@class::E
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::E::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await buildLibrary('const a = null; f<@a T>() {}');
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
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @21
              element: T@21
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await buildLibrary('const a = null; typedef F<@a T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @24
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @29
              element: T@29
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      aliasedType: dynamic Function()
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
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
    expect(x.metadata2.annotations, hasLength(1));
    // Check details.
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
        hasInitializer x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          metadata
            Annotation
              atSign: @ @13
              name: SimpleIdentifier
                token: a @14
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      metadata
        Annotation
          atSign: @ @13
          name: SimpleIdentifier
            token: a @14
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element2: <testLibraryFragment>::@getter::a#element
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
      returnType: void
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <testLibraryFragment>::@class::A::@field::x#element
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @29
                  staticType: int
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static const hasInitializer x
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@class::A::@field::x
            expression: expression_0
          getter: <testLibraryFragment>::@class::A::@getter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get x
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
          returnType: int
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @28
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            hasInitializer b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            hasInitializer c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibraryFragment>::@enum::E::@field::c#element
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
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
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
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
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @56
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          element: <testLibrary>::@extension::E
          fields
            hasInitializer x @36
              reference: <testLibraryFragment>::@extension::E::@field::x
              element: <testLibraryFragment>::@extension::E::@field::x#element
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @40
                  staticType: int
              getter2: <testLibraryFragment>::@extension::E::@getter::x
          getters
            synthetic get x
              reference: <testLibraryFragment>::@extension::E::@getter::x
              element: <testLibraryFragment>::@extension::E::@getter::x#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      fields
        static const hasInitializer x
          firstFragment: <testLibraryFragment>::@extension::E::@field::x
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@extension::E::@field::x
            expression: expression_0
          getter: <testLibraryFragment>::@extension::E::@getter::x#element
      getters
        synthetic static get x
          firstFragment: <testLibraryFragment>::@extension::E::@getter::x
          returnType: int
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      classes
        class C @41
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 18
              formalParameters
                _ @20
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @43
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional hasImplicitType _
              type: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 18
              formalParameters
                _ @20
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional hasImplicitType _
              type: dynamic
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    var library = await buildLibrary('@foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    var library = await buildLibrary('@String.foo() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    var library = await buildLibrary('@foo.bar class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @15
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo @23
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    var library = await buildLibrary('@foo.bar.baz() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo @23
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        class C @49
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo @23
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    var library = await buildLibrary('@foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo @23
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @23
      classes
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_simpleIdentifier() async {
    var library = await buildLibrary('@foo class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @11
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    var library = await buildLibrary('@foo() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @13
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
