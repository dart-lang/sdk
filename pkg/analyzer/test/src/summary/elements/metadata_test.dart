// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: A @1
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @2
                arguments
                  RecordLiteral
                    leftParenthesis: ( @3
                    fields
                      IntegerLiteral
                        literal: 2 @4
                        staticType: int
                      NamedExpression
                        name: Label
                          label: SimpleIdentifier
                            token: a @7
                            staticElement: <null>
                            staticType: null
                          colon: : @8
                        expression: IntegerLiteral
                          literal: 3 @10
                          staticType: int
                    rightParenthesis: ) @11
                    staticType: (int, {int a})
                rightParenthesis: ) @12
              element: <testLibraryFragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const @43
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional o @45
                  type: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class A @31
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @43
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                o @45
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional o
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: A @1
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @2
                arguments
                  RecordLiteral
                    constKeyword: const @3
                    leftParenthesis: ( @9
                    fields
                      SimpleStringLiteral
                        literal: '' @10
                    rightParenthesis: ) @13
                    staticType: (String,)
                rightParenthesis: ) @14
              element: <testLibraryFragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const @45
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional o @47
                  type: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @45
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                o @47
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional o
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
  libraryImports
    package:test/a.dart as a @19
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    a @19
      reference: <testLibraryFragment>::@prefix::a
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as a @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @19
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @39
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @22
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: a @23
                  staticElement: <testLibraryFragment>::@prefix::a
                  staticType: null
                period: . @24
                identifier: SimpleIdentifier
                  token: A @25
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                staticType: null
              period: . @26
              constructorName: SimpleIdentifier
                token: named @27
                staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
                staticType: null
              element: package:test/a.dart::<fragment>::@class::A::@constructor::named
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      prefixes
        a
          reference: <testLibraryFragment>::@prefix::a
      classes
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @18
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  staticType: null
                period: . @19
                identifier: SimpleIdentifier
                  token: named @20
                  staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
                staticType: null
              element: package:test/a.dart::<fragment>::@class::A::@constructor::named
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
    var x = _elementOfDefiningUnit(library, ['@class', 'C', '@field', 'x'])
        as FieldElement;
    expect(x.metadata, hasLength(1));
    // Check details.
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
            x @34
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              type: int
              shouldUseTypeForInitializerInference: true
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: int
              returnType: void
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
      element: <testLibrary>
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            x @34
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <none>
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <none>
              parameters
                _x @-1
                  element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          reference: <none>
          parameters
            requiredPositional _x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @27
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          fields
            static const foo @54
              reference: <testLibraryFragment>::@class::C::@field::foo
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@class::C::@getter::foo
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
          methods
            bar @77
              reference: <testLibraryFragment>::@class::C::@method::bar
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    staticElement: <testLibraryFragment>::@class::C::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@class::C::@getter::foo
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @27
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @34
              element: <none>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          fields
            foo @54
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::C::@getter::foo
              element: <none>
          methods
            bar @77
              reference: <testLibraryFragment>::@class::C::@method::bar
              element: <none>
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    staticElement: <testLibraryFragment>::@class::C::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@class::C::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@class::C
      fields
        static const foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
      methods
        bar
          reference: <none>
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                staticElement: <testLibraryFragment>::@class::C::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@class::C::@getter::foo
          firstFragment: <testLibraryFragment>::@class::C::@method::bar
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                staticType: null
              element: <testLibraryFragment>::@getter::b
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    const b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
''');
  }

  test_metadata_classTypeAlias() async {
    var library = await buildLibrary(
        'const a = null; @a class C = D with E; class D {} class E {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class alias C @25
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          supertype: D
          mixins
            E
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @45
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
        class E @56
          reference: <testLibraryFragment>::@class::E
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::E
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @25
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @45
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
        class E @56
          reference: <testLibraryFragment>::@class::E
          element: <testLibraryFragment>::@class::E
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class alias C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
    class E
      reference: <testLibraryFragment>::@class::E
      firstFragment: <testLibraryFragment>::@class::E
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::E::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 19
              nameEnd: 25
              parameters
                requiredPositional _ @30
                  type: int
        class C @54
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @36
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @37
                  staticElement: <testLibraryFragment>::@class::A
                  staticType: null
                period: . @38
                identifier: SimpleIdentifier
                  token: named @39
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
                  staticType: null
                staticElement: <testLibraryFragment>::@class::A::@constructor::named
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @44
                arguments
                  IntegerLiteral
                    literal: 0 @45
                    staticType: int
                rightParenthesis: ) @46
              element: <testLibraryFragment>::@class::A::@constructor::named
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 19
              nameEnd: 25
              parameters
                _ @30
                  element: <none>
        class C @54
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 22
              nameEnd: 28
              parameters
                requiredPositional _ @31
                  type: T
        class C @56
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @38
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @39
                  staticElement: <testLibraryFragment>::@class::A
                  staticType: null
                period: . @40
                identifier: SimpleIdentifier
                  token: named @41
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::A::@constructor::named
                    substitution: {T: int}
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @46
                arguments
                  IntegerLiteral
                    literal: 0 @47
                    staticType: int
                rightParenthesis: ) @48
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 22
              nameEnd: 28
              parameters
                _ @31
                  element: <none>
        class C @56
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: A @36
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @37
                arguments
                  NamedType
                    name: int @38
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @41
              period: . @42
              constructorName: SimpleIdentifier
                token: named @43
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: A @36
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @37
                arguments
                  NamedType
                    name: int @38
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @41
              period: . @42
              constructorName: SimpleIdentifier
                token: named @43
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                staticType: null
              period: . @32
              constructorName: SimpleIdentifier
                token: named @33
                staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @38
                arguments
                  IntegerLiteral
                    literal: 0 @39
                    staticType: int
                rightParenthesis: ) @40
              element: package:test/foo.dart::<fragment>::@class::A::@constructor::named
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                staticType: null
              period: . @32
              constructorName: SimpleIdentifier
                token: named @33
                staticElement: ConstructorMember
                  base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @38
                arguments
                  IntegerLiteral
                    literal: 0 @39
                    staticType: int
                rightParenthesis: ) @40
              element: ConstructorMember
                base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @32
                arguments
                  NamedType
                    name: int @33
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @36
              period: . @37
              constructorName: SimpleIdentifier
                token: named @38
                staticElement: ConstructorMember
                  base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @43
                rightParenthesis: ) @44
              element: ConstructorMember
                base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 19
              nameEnd: 25
        class alias C @50
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @52
              defaultType: dynamic
          supertype: A
          mixins
            B
          constructors
            synthetic const named @-1
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  period: . @0
                  constructorName: SimpleIdentifier
                    token: named @-1
                    staticElement: <testLibraryFragment>::@class::A::@constructor::named
                    staticType: null
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
              superConstructor: <testLibraryFragment>::@class::A::@constructor::named
        class D @85
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @68
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @69
                  staticElement: <testLibraryFragment>::@class::C
                  staticType: null
                period: . @70
                identifier: SimpleIdentifier
                  token: named @71
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::named
                  substitution: {T: dynamic}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @76
                rightParenthesis: ) @77
              element: ConstructorMember
                base: <testLibraryFragment>::@class::C::@constructor::named
                substitution: {T: dynamic}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      mixins
        mixin B @38
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 19
              nameEnd: 25
        class C @50
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @52
              element: <none>
          constructors
            synthetic const named @-1
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  period: . @0
                  constructorName: SimpleIdentifier
                    token: named @-1
                    staticElement: <testLibraryFragment>::@class::A::@constructor::named
                    staticType: null
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
              superConstructor: <testLibraryFragment>::@class::A::@constructor::named
        class D @85
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      mixins
        mixin B @38
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class alias C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A
      constructors
        synthetic const named
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
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
                requiredPositional _ @24
                  type: int
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: A @31
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @32
                arguments
                  IntegerLiteral
                    literal: 0 @33
                    staticType: int
                rightParenthesis: ) @34
              element: <testLibraryFragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                _ @24
                  element: <none>
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _ @25
                  type: T
        class C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: A @33
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @34
                arguments
                  IntegerLiteral
                    literal: 0 @35
                    staticType: int
                rightParenthesis: ) @36
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                _ @25
                  element: <none>
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  NamedType
                    name: int @32
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @35
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_metadata_constructor_call_unnamed_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', 'class A { const A(_); }');
    var library =
        await buildLibrary('import "foo.dart" as foo; @foo.A(0) class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @32
                arguments
                  IntegerLiteral
                    literal: 0 @33
                    staticType: int
                rightParenthesis: ) @34
              element: package:test/foo.dart::<fragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @32
                arguments
                  IntegerLiteral
                    literal: 0 @33
                    staticType: int
                rightParenthesis: ) @34
              element: ConstructorMember
                base: package:test/foo.dart::<fragment>::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @46
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @32
                arguments
                  NamedType
                    name: int @33
                    element: dart:core::<fragment>::@class::int
                    type: int
                rightBracket: > @36
              arguments: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              element: ConstructorMember
                base: package:test/foo.dart::<fragment>::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @46
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
        class alias C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @46
              defaultType: dynamic
          supertype: A
          mixins
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class D @73
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @62
              name: SimpleIdentifier
                token: C @63
                staticElement: <testLibraryFragment>::@class::C
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              element: ConstructorMember
                base: <testLibraryFragment>::@class::C::@constructor::new
                substitution: {T: dynamic}
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @46
              element: <none>
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class D @73
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A
      constructors
        synthetic const new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
''');
  }

  test_metadata_constructor_call_with_args() async {
    var library =
        await buildLibrary('class A { const A(x); } @A(null) class C {}');
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
            const @16
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional x @18
                  type: dynamic
        class C @39
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: A @25
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @26
                arguments
                  NullLiteral
                    literal: null @27
                    staticType: Null
                rightParenthesis: ) @31
              element: <testLibraryFragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @16
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                x @18
                  element: <none>
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_metadata_constructorDeclaration_named() async {
    var library =
        await buildLibrary('const a = null; class C { @a C.named(); }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            named @31
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              periodOffset: 30
              nameEnd: 36
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            named @31
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <none>
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              periodOffset: 30
              nameEnd: 36
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        named
          reference: <none>
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await buildLibrary('const a = null; class C { @a C(); }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        new
          reference: <none>
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  libraryExports
    package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      metadata
        Annotation
          atSign: @ @0
          name: SimpleIdentifier
            token: a @1
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      topLevelVariables
        static const a @28
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @32
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @28
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await buildLibrary('const a = null; class C { @a int x; }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            x @33
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: int
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            x @33
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <none>
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <none>
              parameters
                _x @-1
                  element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          reference: <none>
          parameters
            requiredPositional _x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            x @32
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            @37
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional final this.x @47
                  type: dynamic
                  metadata
                    Annotation
                      atSign: @ @39
                      name: SimpleIdentifier
                        token: a @40
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            x @32
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            new @37
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              parameters
                this.x @47
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @39
                      name: SimpleIdentifier
                        token: a @40
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <none>
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <none>
              parameters
                _x @-1
                  element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: dynamic
              metadata
                Annotation
                  atSign: @ @39
                  name: SimpleIdentifier
                    token: a @40
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          reference: <none>
          parameters
            requiredPositional _x
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    var library = await buildLibrary(
        'const a = null; class C { var x; C([@a this.x = null]); }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            x @30
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            @33
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default final this.x @44
                  type: dynamic
                  metadata
                    Annotation
                      atSign: @ @36
                      name: SimpleIdentifier
                        token: a @37
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                  constantInitializer
                    NullLiteral
                      literal: null @48
                      staticType: Null
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            x @30
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            new @33
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              parameters
                default this.x @44
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @36
                      name: SimpleIdentifier
                        token: a @37
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <none>
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <none>
              parameters
                _x @-1
                  element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            optionalPositional final x
              reference: <none>
              type: dynamic
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: a @37
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          reference: <none>
          parameters
            requiredPositional _x
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await buildLibrary('const a = null; @a get f => null;');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        synthetic static f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        static get f @23
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        synthetic f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get f @23
          reference: <testLibraryFragment>::@getter::f
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    synthetic f
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    static get f
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
      firstFragment: <testLibraryFragment>::@getter::f
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await buildLibrary('const a = null; @a set f(value) {}');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        synthetic static f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        static set f= @23
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          parameters
            requiredPositional value @25
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        synthetic f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          setter2: <testLibraryFragment>::@setter::f
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      setters
        set f= @23
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          parameters
            value @25
              element: <none>
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    synthetic f
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    static set f=
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
      parameters
        requiredPositional value
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::f
''');
  }

  test_metadata_functionTypeAlias() async {
    var library = await buildLibrary('const a = null; @a typedef F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @27
          reference: <testLibraryFragment>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @27
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  typeAliases
    F
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
      aliasedType: dynamic Function()
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await buildLibrary('const a = null; f(@a g()) {}');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional g @21
              type: dynamic Function()
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            g @21
              element: <none>
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      reference: <none>
      parameters
        requiredPositional g
          reference: <none>
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await buildLibrary('const a = null; f([@a g() = null]) {}');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            optionalPositional default g @22
              type: dynamic Function()
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              constantInitializer
                NullLiteral
                  literal: null @28
                  staticType: null
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default g @22
              element: <none>
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      reference: <none>
      parameters
        optionalPositional g
          reference: <none>
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @46
          reference: <testLibraryFragment>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                staticType: null
              element: <testLibraryFragment>::@getter::b
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @46
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                staticType: null
              element: <testLibraryFragment>::@getter::b
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
  typeAliases
    F
      reference: <none>
      metadata
        Annotation
          atSign: @ @32
          name: SimpleIdentifier
            token: a @33
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
        Annotation
          atSign: @ @35
          name: SimpleIdentifier
            token: b @36
            staticElement: <testLibraryFragment>::@getter::b
            staticType: null
          element: <testLibraryFragment>::@getter::b
      aliasedType: void Function()
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    const b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional first @47
                type: int
                metadata
                  Annotation
                    atSign: @ @40
                    name: SimpleIdentifier
                      token: a @41
                      staticElement: <testLibraryFragment>::@getter::a
                      staticType: null
                    element: <testLibraryFragment>::@getter::a
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
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
      element: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function(int)
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(int Function(int))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional foo @44
                type: int Function(int)
                parameters
                  requiredPositional bar @55
                    type: int
                    metadata
                      Annotation
                        atSign: @ @48
                        name: SimpleIdentifier
                          token: a @49
                          staticElement: <testLibraryFragment>::@getter::a
                          staticType: null
                        element: <testLibraryFragment>::@getter::a
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
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
      element: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function(int Function(int))
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function<T>(int)
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant T @43
                metadata
                  Annotation
                    atSign: @ @40
                    name: SimpleIdentifier
                      token: a @41
                      staticElement: <testLibraryFragment>::@getter::a
                      staticType: null
                    element: <testLibraryFragment>::@getter::a
            parameters
              requiredPositional first @50
                type: int
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
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
      element: <testLibrary>
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function<T>(int)
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_invalid_classDeclaration() async {
    var library = await buildLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @8
              name: SimpleIdentifier
                token: f @9
                staticElement: <testLibraryFragment>::@function::f
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @10
                arguments
                  IntegerLiteral
                    literal: 42 @11
                    staticType: int
                rightParenthesis: ) @13
              element: <testLibraryFragment>::@function::f
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @2
              type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            _ @2
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  functions
    f
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: deprecated @1
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: source 'dart:math'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: deprecated @1
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
----------------------------------------
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
  name: L
  nameOffset: 11
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @20
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @24
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  name: L
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @20
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_methodDeclaration_getter() async {
    var library =
        await buildLibrary('const a = null; class C { @a get m => null; }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            synthetic m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            get m @33
              reference: <testLibraryFragment>::@class::C::@getter::m
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::m
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get m @33
              reference: <testLibraryFragment>::@class::C::@getter::m
              element: <none>
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic m
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::m
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get m
          reference: <none>
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@class::C::@getter::m
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            m @54
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            m @54
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <none>
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          reference: <none>
          metadata
            Annotation
              atSign: @ @44
              name: SimpleIdentifier
                token: a @45
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                staticElement: <testLibraryFragment>::@getter::b
                staticType: null
              element: <testLibraryFragment>::@getter::b
          firstFragment: <testLibraryFragment>::@class::C::@method::m
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    const b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin M @38
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          methods
            m @54
              reference: <testLibraryFragment>::@mixin::M::@method::m
              enclosingElement: <testLibraryFragment>::@mixin::M
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @38
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
          methods
            m @54
              reference: <testLibraryFragment>::@mixin::M::@method::m
              element: <none>
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      methods
        m
          reference: <none>
          metadata
            Annotation
              atSign: @ @44
              name: SimpleIdentifier
                token: a @45
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                staticElement: <testLibraryFragment>::@getter::b
                staticType: null
              element: <testLibraryFragment>::@getter::b
          firstFragment: <testLibraryFragment>::@mixin::M::@method::m
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    const b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            synthetic m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            set m= @37
              reference: <testLibraryFragment>::@class::C::@setter::m
              enclosingElement: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: a @29
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              parameters
                requiredPositional value @39
                  type: dynamic
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              element: <none>
              setter2: <testLibraryFragment>::@class::C::@setter::m
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          setters
            set m= @37
              reference: <testLibraryFragment>::@class::C::@setter::m
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: a @29
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              parameters
                value @39
                  element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic m
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::m
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set m=
          reference: <none>
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: a @29
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          parameters
            requiredPositional value
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@setter::m
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin M @27
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          superclassConstraints
            Object
          fields
            static const foo @54
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: int
          methods
            bar @77
              reference: <testLibraryFragment>::@mixin::M::@method::bar
              enclosingElement: <testLibraryFragment>::@mixin::M
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@mixin::M::@getter::foo
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @27
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
          typeParameters
            T @34
              element: <none>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          fields
            foo @54
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <none>
          methods
            bar @77
              reference: <testLibraryFragment>::@mixin::M::@method::bar
              element: <none>
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@mixin::M::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        static const foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          getter: <none>
      getters
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
      methods
        bar
          reference: <none>
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@mixin::M::@getter::foo
          firstFragment: <testLibraryFragment>::@mixin::M::@method::bar
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin M @44
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                staticType: null
              element: <testLibraryFragment>::@getter::b
          superclassConstraints
            Object
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @44
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    const b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @34
              element: <none>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            @35
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              parameters
                requiredPositional a @46
                  type: int
                  metadata
                    Annotation
                      atSign: @ @37
                      name: SimpleIdentifier
                        token: foo @38
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            new @35
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              parameters
                a @46
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @37
                      name: SimpleIdentifier
                        token: foo @38
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          reference: <none>
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          parameters
            requiredPositional a
              reference: <none>
              type: int
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            synthetic getter @-1
              reference: <testLibraryFragment>::@class::A::@field::getter
              enclosingElement: <testLibraryFragment>::@class::A
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            get getter @43
              reference: <testLibraryFragment>::@class::A::@getter::getter
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              returnType: int
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          fields
            getter @-1
              reference: <testLibraryFragment>::@class::A::@field::getter
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::getter
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get getter @43
              reference: <testLibraryFragment>::@class::A::@getter::getter
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic getter
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::getter
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        get getter
          reference: <none>
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::getter
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            method @40
              reference: <testLibraryFragment>::@class::A::@method::method
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              typeParameters
                covariant T @52
                  defaultType: dynamic
                  metadata
                    Annotation
                      atSign: @ @47
                      name: SimpleIdentifier
                        token: foo @48
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
              parameters
                requiredPositional a @64
                  type: int
                  metadata
                    Annotation
                      atSign: @ @55
                      name: SimpleIdentifier
                        token: foo @56
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          methods
            method @40
              reference: <testLibraryFragment>::@class::A::@method::method
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              typeParameters
                T @52
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @47
                      name: SimpleIdentifier
                        token: foo @48
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
              parameters
                a @64
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @55
                      name: SimpleIdentifier
                        token: foo @56
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        method
          reference: <none>
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            T
              metadata
                Annotation
                  atSign: @ @47
                  name: SimpleIdentifier
                    token: foo @48
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          parameters
            requiredPositional a
              reference: <none>
              type: int
              metadata
                Annotation
                  atSign: @ @55
                  name: SimpleIdentifier
                    token: foo @56
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          firstFragment: <testLibraryFragment>::@class::A::@method::method
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            synthetic setter @-1
              reference: <testLibraryFragment>::@class::A::@field::setter
              enclosingElement: <testLibraryFragment>::@class::A
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            set setter= @39
              reference: <testLibraryFragment>::@class::A::@setter::setter
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              parameters
                requiredPositional a @55
                  type: int
                  metadata
                    Annotation
                      atSign: @ @46
                      name: SimpleIdentifier
                        token: foo @47
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          fields
            setter @-1
              reference: <testLibraryFragment>::@class::A::@field::setter
              element: <none>
              setter2: <testLibraryFragment>::@class::A::@setter::setter
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          setters
            set setter= @39
              reference: <testLibraryFragment>::@class::A::@setter::setter
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              parameters
                a @55
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @46
                      name: SimpleIdentifier
                        token: foo @47
                        staticElement: <testLibraryFragment>::@getter::foo
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic setter
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::setter
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      setters
        set setter=
          reference: <none>
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          parameters
            requiredPositional a
              reference: <none>
              type: int
              metadata
                Annotation
                  atSign: @ @46
                  name: SimpleIdentifier
                    token: foo @47
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          firstFragment: <testLibraryFragment>::@class::A::@setter::setter
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class alias B @50
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @39
              name: SimpleIdentifier
                token: foo @40
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @57
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @52
                  name: SimpleIdentifier
                    token: foo @53
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          supertype: A
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      mixins
        mixin M @33
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @50
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          typeParameters
            T @57
              element: <none>
              metadata
                Annotation
                  atSign: @ @52
                  name: SimpleIdentifier
                    token: foo @53
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      mixins
        mixin M @33
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      reference: <testLibraryFragment>::@class::B
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @52
              name: SimpleIdentifier
                token: foo @53
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          supertype: Enum
          fields
            static const enumConstant e1 @37
              reference: <testLibraryFragment>::@enum::E::@field::e1
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
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
            static const enumConstant e2 @43
              reference: <testLibraryFragment>::@enum::E::@field::e2
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
            static const enumConstant e3 @54
              reference: <testLibraryFragment>::@enum::E::@field::e3
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: foo @50
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
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
                      token: e1 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::e1
                      staticType: E
                    SimpleIdentifier
                      token: e2 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::e2
                      staticType: E
                    SimpleIdentifier
                      token: e3 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::e3
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get e1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e1
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get e2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e2
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get e3 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e3
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant e1 @37
              reference: <testLibraryFragment>::@enum::E::@field::e1
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::e1
            enumConstant e2 @43
              reference: <testLibraryFragment>::@enum::E::@field::e2
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::e2
            enumConstant e3 @54
              reference: <testLibraryFragment>::@enum::E::@field::e3
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::e3
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get e1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e1
              element: <none>
            get e2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e2
              element: <none>
            get e3 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e3
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const e1
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::e1
          getter: <none>
        static const e2
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::e2
          getter: <none>
        static const e3
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::e3
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get e1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e1
        synthetic static get e2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e2
        synthetic static get e3
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e3
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        E @31
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @38
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          extendedType: List<T>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension E @31
          reference: <testLibraryFragment>::@extension::E
          element: <testLibraryFragment>::@extension::E
          typeParameters
            T @38
              element: <none>
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  extensions
    extension E
      reference: <testLibraryFragment>::@extension::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: foo @34
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@extension::E
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            static isStatic @42
              reference: <testLibraryFragment>::@class::A::@field::isStatic
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              type: int
              shouldUseTypeForInitializerInference: false
            static const isStaticConst @79
              reference: <testLibraryFragment>::@class::A::@field::isStaticConst
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @59
                  name: SimpleIdentifier
                    token: foo @60
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 2 @95
                  staticType: int
            isInstance @112
              reference: <testLibraryFragment>::@class::A::@field::isInstance
              enclosingElement: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @101
                  name: SimpleIdentifier
                    token: foo @102
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              type: int
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic static get isStatic @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStatic
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
            synthetic static set isStatic= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isStatic
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _isStatic @-1
                  type: int
              returnType: void
            synthetic static get isStaticConst @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStaticConst
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
            synthetic get isInstance @-1
              reference: <testLibraryFragment>::@class::A::@getter::isInstance
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
            synthetic set isInstance= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isInstance
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _isInstance @-1
                  type: int
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          fields
            isStatic @42
              reference: <testLibraryFragment>::@class::A::@field::isStatic
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::isStatic
              setter2: <testLibraryFragment>::@class::A::@setter::isStatic
            isStaticConst @79
              reference: <testLibraryFragment>::@class::A::@field::isStaticConst
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::isStaticConst
            isInstance @112
              reference: <testLibraryFragment>::@class::A::@field::isInstance
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::isInstance
              setter2: <testLibraryFragment>::@class::A::@setter::isInstance
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get isStatic @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStatic
              element: <none>
            get isStaticConst @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStaticConst
              element: <none>
            get isInstance @-1
              reference: <testLibraryFragment>::@class::A::@getter::isInstance
              element: <none>
          setters
            set isStatic= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isStatic
              element: <none>
              parameters
                _isStatic @-1
                  element: <none>
            set isInstance= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isInstance
              element: <none>
              parameters
                _isInstance @-1
                  element: <none>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static isStatic
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::isStatic
          getter: <none>
          setter: <none>
        static const isStaticConst
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::isStaticConst
          getter: <none>
        isInstance
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::isInstance
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get isStatic
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::isStatic
        synthetic static get isStaticConst
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::isStaticConst
        synthetic get isInstance
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::isInstance
      setters
        synthetic static set isStatic=
          reference: <none>
          parameters
            requiredPositional _isStatic
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@setter::isStatic
        synthetic set isInstance=
          reference: <none>
          parameters
            requiredPositional _isInstance
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@setter::isInstance
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  name: my.lib
  nameOffset: 37
  reference: <testLibrary>
  documentationComment: /// Some documentation.
  metadata
    Annotation
      atSign: @ @24
      name: SimpleIdentifier
        token: foo @25
        staticElement: <testLibraryFragment>::@getter::foo
        staticType: null
      element: <testLibraryFragment>::@getter::foo
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const foo @52
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @58
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  documentationComment: /// Some documentation.
  metadata
    Annotation
      atSign: @ @24
      name: SimpleIdentifier
        token: foo @25
        staticElement: <testLibraryFragment>::@getter::foo
        staticType: null
      element: <testLibraryFragment>::@getter::foo
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const foo @52
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @27
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          superclassConstraints
            Object
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin A @27
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A
          typeParameters
            T @34
              element: <none>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @34
          reference: <testLibraryFragment>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            unrelated T @41
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: foo @37
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          aliasedType: void Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @53
                type: int
                metadata
                  Annotation
                    atSign: @ @44
                    name: SimpleIdentifier
                      token: foo @45
                      staticElement: <testLibraryFragment>::@getter::foo
                      staticType: null
                    element: <testLibraryFragment>::@getter::foo
            returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @34
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            T @41
              element: <none>
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: foo @37
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  typeAliases
    F
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            staticType: null
          element: <testLibraryFragment>::@getter::foo
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @36
              name: SimpleIdentifier
                token: foo @37
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      aliasedType: void Function(int)
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @29
          reference: <testLibraryFragment>::@typeAlias::A
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            unrelated T @36
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          aliasedType: void Function<U>(int)
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant U @60
                metadata
                  Annotation
                    atSign: @ @55
                    name: SimpleIdentifier
                      token: foo @56
                      staticElement: <testLibraryFragment>::@getter::foo
                      staticType: null
                    element: <testLibraryFragment>::@getter::foo
            parameters
              requiredPositional a @72
                type: int
                metadata
                  Annotation
                    atSign: @ @63
                    name: SimpleIdentifier
                      token: foo @64
                      staticElement: <testLibraryFragment>::@getter::foo
                      staticType: null
                    element: <testLibraryFragment>::@getter::foo
            returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @29
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            T @36
              element: <none>
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  typeAliases
    A
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            staticType: null
          element: <testLibraryFragment>::@getter::foo
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @31
              name: SimpleIdentifier
                token: foo @32
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      aliasedType: void Function<U>(int)
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: foo @18
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @38
              name: SimpleIdentifier
                token: foo @39
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          unit: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static const foo @65
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @71
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        const foo @65
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @33
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          parameters
            optionalNamed default a @47
              reference: <testLibraryFragment>::@function::f::@parameter::a
              type: int?
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
              constantInitializer
                IntegerLiteral
                  literal: 42 @51
                  staticType: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            T @33
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          parameters
            default a @47
              reference: <testLibraryFragment>::@function::f::@parameter::a
              element: <none>
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  functions
    f
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            staticType: null
          element: <testLibraryFragment>::@getter::foo
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      parameters
        optionalNamed a
          reference: <none>
          type: int?
          metadata
            Annotation
              atSign: @ @37
              name: SimpleIdentifier
                token: foo @38
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
        synthetic static getter @-1
          reference: <testLibraryFragment>::@topLevelVariable::getter
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
        static get getter @29
          reference: <testLibraryFragment>::@getter::getter
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
        synthetic getter @-1
          reference: <testLibraryFragment>::@topLevelVariable::getter
          element: <none>
          getter2: <testLibraryFragment>::@getter::getter
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
        get getter @29
          reference: <testLibraryFragment>::@getter::getter
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
    synthetic getter
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::getter
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
    static get getter
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            staticType: null
          element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@getter::getter
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
        synthetic static setter @-1
          reference: <testLibraryFragment>::@topLevelVariable::setter
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
        static set setter= @25
          reference: <testLibraryFragment>::@setter::setter
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          parameters
            requiredPositional a @41
              type: int
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
        synthetic setter @-1
          reference: <testLibraryFragment>::@topLevelVariable::setter
          element: <none>
          setter2: <testLibraryFragment>::@setter::setter
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
      setters
        set setter= @25
          reference: <testLibraryFragment>::@setter::setter
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          parameters
            a @41
              element: <none>
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
    synthetic setter
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::setter
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set setter=
      reference: <none>
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            staticType: null
          element: <testLibraryFragment>::@getter::foo
      parameters
        requiredPositional a
          reference: <none>
          type: int
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: foo @33
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@setter::setter
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
        static isNotConst @25
          reference: <testLibraryFragment>::@topLevelVariable::isNotConst
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          type: int
          shouldUseTypeForInitializerInference: false
        static const isConst @53
          reference: <testLibraryFragment>::@topLevelVariable::isConst
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 2 @63
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get isNotConst @-1
          reference: <testLibraryFragment>::@getter::isNotConst
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set isNotConst= @-1
          reference: <testLibraryFragment>::@setter::isNotConst
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _isNotConst @-1
              type: int
          returnType: void
        synthetic static get isConst @-1
          reference: <testLibraryFragment>::@getter::isConst
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
        isNotConst @25
          reference: <testLibraryFragment>::@topLevelVariable::isNotConst
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          getter2: <testLibraryFragment>::@getter::isNotConst
          setter2: <testLibraryFragment>::@setter::isNotConst
        const isConst @53
          reference: <testLibraryFragment>::@topLevelVariable::isConst
          element: <none>
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          getter2: <testLibraryFragment>::@getter::isConst
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
        get isNotConst @-1
          reference: <testLibraryFragment>::@getter::isNotConst
          element: <none>
        get isConst @-1
          reference: <testLibraryFragment>::@getter::isConst
          element: <none>
      setters
        set isNotConst= @-1
          reference: <testLibraryFragment>::@setter::isNotConst
          element: <none>
          parameters
            _isNotConst @-1
              element: <none>
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
    isNotConst
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::isNotConst
      getter: <none>
      setter: <none>
    const isConst
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::isConst
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get isNotConst
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::isNotConst
    synthetic static get isConst
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::isConst
  setters
    synthetic static set isNotConst=
      reference: <none>
      parameters
        requiredPositional _isNotConst
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::isNotConst
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
  name: L
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @11
              name: SimpleIdentifier
                token: a @12
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          unit: <testLibrary>::@fragment::package:test/foo.dart
      topLevelVariables
        static const a @37
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @41
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
    <testLibrary>::@fragment::package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  name: L
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/foo.dart
      topLevelVariables
        const a @37
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
    <testLibrary>::@fragment::package:test/foo.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
    expect(library.parts[0].metadata, isEmpty);
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          element: <testLibrary>::@fragment::package:test/a.dart::@class::A
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
      constructors
        synthetic new
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      libraryImports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_metadata_prefixed_variable() async {
    newFile('$testPackageLibPath/a.dart', 'const b = null;');
    var library = await buildLibrary('import "a.dart" as a; @a.b class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart as a @19
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    a @19
      reference: <testLibraryFragment>::@prefix::a
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as a @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @19
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @33
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @22
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: a @23
                  staticElement: <testLibraryFragment>::@prefix::a
                  staticType: null
                period: . @24
                identifier: SimpleIdentifier
                  token: b @25
                  staticElement: package:test/a.dart::<fragment>::@getter::b
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@getter::b
                staticType: null
              element: package:test/a.dart::<fragment>::@getter::b
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      prefixes
        a
          reference: <testLibraryFragment>::@prefix::a
      classes
        class C @33
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_metadata_simpleFormalParameter() async {
    var library = await buildLibrary('const a = null; f(@a x) {}');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional x @21
              type: dynamic
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            x @21
              element: <none>
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: dynamic
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            m @29
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @34
                  type: dynamic
                  metadata
                    Annotation
                      atSign: @ @31
                      name: SimpleIdentifier
                        token: a @32
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            m @29
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <none>
              parameters
                x @34
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @31
                      name: SimpleIdentifier
                        token: a @32
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: dynamic
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: a @32
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@class::C::@method::m
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        static set foo= @21
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional x @32
              type: int
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      setters
        set foo= @21
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            x @32
              element: <none>
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: int
          metadata
            Annotation
              atSign: @ @25
              name: SimpleIdentifier
                token: a @26
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      firstFragment: <testLibraryFragment>::@setter::foo
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await buildLibrary('const a = null; f([@a x = null]) {}');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            optionalPositional default x @22
              type: dynamic
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              constantInitializer
                NullLiteral
                  literal: null @26
                  staticType: Null
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default x @22
              element: <none>
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      reference: <none>
      parameters
        optionalPositional x
          reference: <none>
          type: dynamic
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @23
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            @29
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional x @35
                  type: int
        class B @48
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            @64
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              parameters
                requiredPositional final super.x @75
                  type: int
                  metadata
                    Annotation
                      atSign: @ @66
                      name: SimpleIdentifier
                        token: a @67
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                  superConstructorParameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::x
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @23
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            new @29
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                x @35
                  element: <none>
        class B @48
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            new @64
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              parameters
                super.x @75
                  element: <none>
                  metadata
                    Annotation
                      atSign: @ @66
                      name: SimpleIdentifier
                        token: a @67
                        staticElement: <testLibraryFragment>::@getter::a
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: int
              metadata
                Annotation
                  atSign: @ @66
                  name: SimpleIdentifier
                    token: a @67
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await buildLibrary('const a = null; @a int v;');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          type: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    v
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::v
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await buildLibrary('const a = null; class C<@a T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @27
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @27
              element: <none>
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class alias C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @27
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          supertype: D
          mixins
            E
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @48
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
        class E @59
          reference: <testLibraryFragment>::@class::E
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::E
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @27
              element: <none>
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @48
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
        class E @59
          reference: <testLibraryFragment>::@class::E
          element: <testLibraryFragment>::@class::E
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  classes
    class alias C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
    class E
      reference: <testLibraryFragment>::@class::E
      firstFragment: <testLibraryFragment>::@class::E
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::E::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await buildLibrary('const a = null; f<@a T>() {}');
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
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @21
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @21
              element: <none>
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      reference: <none>
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await buildLibrary('const a = null; typedef F<@a T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @24
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @29
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @24
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @29
              element: <none>
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      aliasedType: dynamic Function()
  topLevelVariables
    const a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_metadata_unit_topLevelVariable_first() async {
    var library = await buildLibrary(r'''
const a = 0;
@a
int x = 0;
''');
    // Check metadata without asking any other properties.
    var x = _elementOfDefiningUnit(library, ['@topLevelVariable', 'x'])
        as TopLevelVariableElement;
    expect(x.metadata, hasLength(1));
    // Check details.
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
        static x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @13
              name: SimpleIdentifier
                token: a @14
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          metadata
            Annotation
              atSign: @ @13
              name: SimpleIdentifier
                token: a @14
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            static const x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              enclosingElement: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @29
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @34
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @35
                  staticElement: <testLibraryFragment>::@class::A
                  staticType: null
                period: . @36
                identifier: SimpleIdentifier
                  token: x @37
                  staticElement: <testLibraryFragment>::@class::A::@getter::x
                  staticType: null
                staticElement: <testLibraryFragment>::@class::A::@getter::x
                staticType: null
              element: <testLibraryFragment>::@class::A::@getter::x
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          fields
            x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              element: <none>
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static const x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: E @18
                  staticElement: <testLibraryFragment>::@enum::E
                  staticType: null
                period: . @19
                identifier: SimpleIdentifier
                  token: b @20
                  staticElement: <testLibraryFragment>::@enum::E::@getter::b
                  staticType: null
                staticElement: <testLibraryFragment>::@enum::E::@getter::b
                staticType: null
              element: <testLibraryFragment>::@enum::E::@getter::b
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @28
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <none>
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          getter: <none>
        static const b
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          getter: <none>
        static const c
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @56
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @45
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: E @46
                  staticElement: <testLibraryFragment>::@extension::E
                  staticType: null
                period: . @47
                identifier: SimpleIdentifier
                  token: x @48
                  staticElement: <testLibraryFragment>::@extension::E::@getter::x
                  staticType: null
                staticElement: <testLibraryFragment>::@extension::E::@getter::x
                staticType: null
              element: <testLibraryFragment>::@extension::E::@getter::x
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          extendedType: int
          fields
            static const x @36
              reference: <testLibraryFragment>::@extension::E::@field::x
              enclosingElement: <testLibraryFragment>::@extension::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @40
                  staticType: int
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@extension::E::@getter::x
              enclosingElement: <testLibraryFragment>::@extension::E
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @56
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          element: <testLibraryFragment>::@extension::E
          fields
            x @36
              reference: <testLibraryFragment>::@extension::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@extension::E::@getter::x
          getters
            get x @-1
              reference: <testLibraryFragment>::@extension::E::@getter::x
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  extensions
    extension E
      reference: <testLibraryFragment>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      fields
        static const x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extension::E::@field::x
          getter: <none>
      getters
        synthetic static get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@extension::E::@getter::x
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @41
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: E @31
                  staticElement: package:test/foo.dart::<fragment>::@extension::E
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@extension::E
                staticType: null
              period: . @32
              constructorName: SimpleIdentifier
                token: x @33
                staticElement: package:test/foo.dart::<fragment>::@extension::E::@getter::x
                staticType: null
              element: package:test/foo.dart::<fragment>::@extension::E::@getter::x
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @41
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
                requiredPositional _ @20
                  type: dynamic
        class C @43
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @27
              name: SimpleIdentifier
                token: A @28
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  SuperExpression
                    superKeyword: super @30
                    staticType: InvalidType
                rightParenthesis: ) @35
              element: <testLibraryFragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                _ @20
                  element: <none>
        class C @43
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
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
                requiredPositional _ @20
                  type: dynamic
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @27
              name: SimpleIdentifier
                token: A @28
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  ThisExpression
                    thisKeyword: this @30
                    staticType: dynamic
                rightParenthesis: ) @34
              element: <testLibraryFragment>::@class::A::@constructor::new
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                _ @20
                  element: <none>
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    var library = await buildLibrary('@foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @8
                rightParenthesis: ) @9
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    var library = await buildLibrary('@String.foo() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: String @1
                  staticElement: dart:core::<fragment>::@class::String
                  staticType: null
                period: . @7
                identifier: SimpleIdentifier
                  token: foo @8
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @11
                rightParenthesis: ) @12
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    var library = await buildLibrary('@foo.bar class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @15
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @15
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    var library =
        await buildLibrary('import "dart:async" as foo; @foo.bar class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async as foo @23
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async as foo @23
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: bar @33
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    var library = await buildLibrary('@foo.bar.baz() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              period: . @8
              constructorName: SimpleIdentifier
                token: baz @9
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @12
                rightParenthesis: ) @13
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    var library = await buildLibrary(
        'import "dart:async" as foo; @foo.bar.baz() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async as foo @23
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async as foo @23
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @49
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: bar @33
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              period: . @36
              constructorName: SimpleIdentifier
                token: baz @37
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @40
                rightParenthesis: ) @41
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @49
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    var library = await buildLibrary(
        'import "dart:async" as foo; @foo.Future.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async as foo @23
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async as foo @23
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: Future @33
                  staticElement: dart:async::<fragment>::@class::Future
                  staticType: null
                staticElement: dart:async::<fragment>::@class::Future
                staticType: null
              period: . @39
              constructorName: SimpleIdentifier
                token: bar @40
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @43
                rightParenthesis: ) @44
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    var library = await buildLibrary('@foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @8
                rightParenthesis: ) @9
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    var library =
        await buildLibrary('import "dart:async" as foo; @foo.bar() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async as foo @23
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async as foo @23
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: bar @33
                  staticElement: <null>
                  staticType: null
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      classes
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_simpleIdentifier() async {
    var library = await buildLibrary('@foo class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @11
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                staticElement: <null>
                staticType: null
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @11
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_simpleIdentifier_multiplyDefined() async {
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
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
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: v @36
                staticElement: <null>
                staticType: null
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    var library = await buildLibrary('@foo() class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @13
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                staticElement: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @4
                rightParenthesis: ) @5
              element: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @13
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
''');
  }

  // TODO(scheglov): This is duplicate.
  Element _elementOfDefiningUnit(
      LibraryElementImpl library, List<String> names) {
    var reference = library.definingCompilationUnit.reference!;
    for (var name in names) {
      reference = reference.getChild(name);
    }

    var element = reference.element;
    if (element != null) {
      return element;
    }

    var elementFactory = library.linkedData!.elementFactory;
    return elementFactory.elementOfReference(reference)!;
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
