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
      enclosingElement3: <null>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: A @1
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
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
                            element: <null>
                            staticType: null
                          colon: : @8
                        expression: IntegerLiteral
                          literal: 3 @10
                          staticType: int
                    rightParenthesis: ) @11
                    staticType: (int, {int a})
                rightParenthesis: ) @12
              element: <testLibraryFragment>::@class::A::@constructor::new
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @43
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
        class A @31
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @43
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                o @45
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::o#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional o
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: A @1
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
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
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @45
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @45
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                o @47
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::o#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional o
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
  libraryImports
    package:test/a.dart as a @19
      enclosingElement3: <testLibraryFragment>
  prefixes
    a @19
      reference: <testLibraryFragment>::@prefix::a
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as a @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @19
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement3: <testLibraryFragment>
      classes
        class C @39
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @22
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: a @23
                  staticElement: <testLibraryFragment>::@prefix::a
                  element: <testLibraryFragment>::@prefix2::a
                  staticType: null
                period: . @24
                identifier: SimpleIdentifier
                  token: A @25
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  element: package:test/a.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                element: package:test/a.dart::<fragment>::@class::A#element
                staticType: null
              period: . @26
              constructorName: SimpleIdentifier
                token: named @27
                staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
                element: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
                staticType: null
              element: package:test/a.dart::<fragment>::@class::A::@constructor::named
              element2: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @18
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  element: package:test/a.dart::<fragment>::@class::A#element
                  staticType: null
                period: . @19
                identifier: SimpleIdentifier
                  token: named @20
                  staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
                  element: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
                element: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
                staticType: null
              element: package:test/a.dart::<fragment>::@class::A::@constructor::named
              element2: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
      enclosingElement3: <null>
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            x @34
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              type: int
              shouldUseTypeForInitializerInference: true
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: int
              returnType: void
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
      classes
        class C @19
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            x @34
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x @-1
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
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
      setters
        synthetic set x=
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: int
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
      enclosingElement3: <null>
      classes
        class C @27
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          fields
            static const foo @54
              reference: <testLibraryFragment>::@class::C::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@class::C::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
          methods
            bar @77
              reference: <testLibraryFragment>::@class::C::@method::bar
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    staticElement: <testLibraryFragment>::@class::C::@getter::foo
                    element: <testLibraryFragment>::@class::C::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@class::C::@getter::foo
                  element2: <testLibraryFragment>::@class::C::@getter::foo#element
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @34
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          fields
            foo @54
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <testLibraryFragment>::@class::C::@field::foo#element
              getter2: <testLibraryFragment>::@class::C::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get foo @-1
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
                    staticElement: <testLibraryFragment>::@class::C::@getter::foo
                    element: <testLibraryFragment>::@class::C::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@class::C::@getter::foo
                  element2: <testLibraryFragment>::@class::C::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      fields
        static const foo
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
      methods
        bar
          firstFragment: <testLibraryFragment>::@class::C::@method::bar
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                staticElement: <testLibraryFragment>::@class::C::@getter::foo
                element: <testLibraryFragment>::@class::C::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@class::C::@getter::foo
              element2: <testLibraryFragment>::@class::C::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@getter::b
              element2: <testLibraryFragment>::@getter::b#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @22
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
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
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
      enclosingElement3: <null>
      classes
        class alias C @25
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          supertype: D
          mixins
            E
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
                  element: <testLibraryFragment>::@class::D::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @45
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
        class E @56
          reference: <testLibraryFragment>::@class::E
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::E
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
                  element: <testLibraryFragment>::@class::D::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @45
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
        class E @56
          reference: <testLibraryFragment>::@class::E
          element: <testLibraryFragment>::@class::E#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              element: <testLibraryFragment>::@class::E::@constructor::new#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class alias C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
    class D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
    class E
      firstFragment: <testLibraryFragment>::@class::E
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::E::@constructor::new
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 19
              nameEnd: 25
              parameters
                requiredPositional _ @30
                  type: int
        class C @54
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @36
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @37
                  staticElement: <testLibraryFragment>::@class::A
                  element: <testLibraryFragment>::@class::A#element
                  staticType: null
                period: . @38
                identifier: SimpleIdentifier
                  token: named @39
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
                  element: <testLibraryFragment>::@class::A::@constructor::named#element
                  staticType: null
                staticElement: <testLibraryFragment>::@class::A::@constructor::named
                element: <testLibraryFragment>::@class::A::@constructor::named#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @44
                arguments
                  IntegerLiteral
                    literal: 0 @45
                    staticType: int
                rightParenthesis: ) @46
              element: <testLibraryFragment>::@class::A::@constructor::named
              element2: <testLibraryFragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 19
              nameEnd: 25
              formalParameters
                _ @30
                  element: <testLibraryFragment>::@class::A::@constructor::named::@parameter::_#element
        class C @54
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
          formalParameters
            requiredPositional _
              type: int
    class C
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 22
              nameEnd: 28
              parameters
                requiredPositional _ @31
                  type: T
        class C @56
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @38
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @39
                  staticElement: <testLibraryFragment>::@class::A
                  element: <testLibraryFragment>::@class::A#element
                  staticType: null
                period: . @40
                identifier: SimpleIdentifier
                  token: named @41
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::A::@constructor::named
                    substitution: {T: int}
                  element: <testLibraryFragment>::@class::A::@constructor::named#element
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::named
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::A::@constructor::named#element
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
              element2: <testLibraryFragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 22
              nameEnd: 28
              formalParameters
                _ @31
                  element: <testLibraryFragment>::@class::A::@constructor::named::@parameter::_#element
        class C @56
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: A @36
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @37
                arguments
                  NamedType
                    name: int @38
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @41
              period: . @42
              constructorName: SimpleIdentifier
                token: named @43
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::named
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::A::@constructor::named#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::named
                substitution: {T: int}
              element2: <testLibraryFragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: A @36
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @37
                arguments
                  NamedType
                    name: int @38
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @41
              period: . @42
              constructorName: SimpleIdentifier
                token: named @43
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::named
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::A::@constructor::named#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::named
                substitution: {T: int}
              element2: <testLibraryFragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          constructors
            const named @23
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 22
              nameEnd: 28
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class C
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  element: package:test/foo.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                element: package:test/foo.dart::<fragment>::@class::A#element
                staticType: null
              period: . @32
              constructorName: SimpleIdentifier
                token: named @33
                staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @38
                arguments
                  IntegerLiteral
                    literal: 0 @39
                    staticType: int
                rightParenthesis: ) @40
              element: package:test/foo.dart::<fragment>::@class::A::@constructor::named
              element2: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @48
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  element: package:test/foo.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                element: package:test/foo.dart::<fragment>::@class::A#element
                staticType: null
              period: . @32
              constructorName: SimpleIdentifier
                token: named @33
                staticElement: ConstructorMember
                  base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                  substitution: {T: int}
                element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
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
              element2: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  element: package:test/foo.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                element: package:test/foo.dart::<fragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @32
                arguments
                  NamedType
                    name: int @33
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @36
              period: . @37
              constructorName: SimpleIdentifier
                token: named @38
                staticElement: ConstructorMember
                  base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                  substitution: {T: int}
                element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @43
                rightParenthesis: ) @44
              element: ConstructorMember
                base: package:test/foo.dart::<fragment>::@class::A::@constructor::named
                substitution: {T: int}
              element2: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 19
              nameEnd: 25
        class alias C @50
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @52
              defaultType: dynamic
          supertype: A
          mixins
            B
          constructors
            synthetic const named @-1
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  period: . @0
                  constructorName: SimpleIdentifier
                    token: named @-1
                    staticElement: <testLibraryFragment>::@class::A::@constructor::named
                    element: <testLibraryFragment>::@class::A::@constructor::named#element
                    staticType: null
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
                  element: <testLibraryFragment>::@class::A::@constructor::named#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::named
        class D @85
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @68
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @69
                  staticElement: <testLibraryFragment>::@class::C
                  element: <testLibraryFragment>::@class::C#element
                  staticType: null
                period: . @70
                identifier: SimpleIdentifier
                  token: named @71
                  staticElement: ConstructorMember
                    base: <testLibraryFragment>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                  element: <testLibraryFragment>::@class::C::@constructor::named#element
                  staticType: null
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::named
                  substitution: {T: dynamic}
                element: <testLibraryFragment>::@class::C::@constructor::named#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @76
                rightParenthesis: ) @77
              element: ConstructorMember
                base: <testLibraryFragment>::@class::C::@constructor::named
                substitution: {T: dynamic}
              element2: <testLibraryFragment>::@class::C::@constructor::named#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
      mixins
        mixin B @38
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            const named @20
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              periodOffset: 19
              nameEnd: 25
        class C @50
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @52
              element: <not-implemented>
          constructors
            synthetic const named @-1
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  period: . @0
                  constructorName: SimpleIdentifier
                    token: named @-1
                    staticElement: <testLibraryFragment>::@class::A::@constructor::named
                    element: <testLibraryFragment>::@class::A::@constructor::named#element
                    staticType: null
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::named
                  element: <testLibraryFragment>::@class::A::@constructor::named#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::named
        class D @85
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
      mixins
        mixin B @38
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
    class alias C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      supertype: A
      constructors
        synthetic const named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          superConstructor: <testLibraryFragment>::@class::A::@constructor::named#element
    class D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin B
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
                requiredPositional _ @24
                  type: int
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: A @31
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @32
                arguments
                  IntegerLiteral
                    literal: 0 @33
                    staticType: int
                rightParenthesis: ) @34
              element: <testLibraryFragment>::@class::A::@constructor::new
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
                _ @24
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional _
              type: int
    class C
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
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _ @25
                  type: T
        class C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: A @33
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
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
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                _ @25
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
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
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  NamedType
                    name: int @32
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @35
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  element: package:test/foo.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                element: package:test/foo.dart::<fragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @32
                arguments
                  IntegerLiteral
                    literal: 0 @33
                    staticType: int
                rightParenthesis: ) @34
              element: package:test/foo.dart::<fragment>::@class::A::@constructor::new
              element2: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  element: package:test/foo.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                element: package:test/foo.dart::<fragment>::@class::A#element
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
              element2: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @46
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: A @31
                  staticElement: package:test/foo.dart::<fragment>::@class::A
                  element: package:test/foo.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@class::A
                element: package:test/foo.dart::<fragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @32
                arguments
                  NamedType
                    name: int @33
                    element: dart:core::<fragment>::@class::int
                    element2: dart:core::<fragment>::@class::int#element
                    type: int
                rightBracket: > @36
              arguments: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              element: ConstructorMember
                base: package:test/foo.dart::<fragment>::@class::A::@constructor::new
                substitution: {T: int}
              element2: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
        class alias C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @46
              defaultType: dynamic
          supertype: A
          mixins
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class D @73
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @62
              name: SimpleIdentifier
                token: C @63
                staticElement: <testLibraryFragment>::@class::C
                element: <testLibraryFragment>::@class::C#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              element: ConstructorMember
                base: <testLibraryFragment>::@class::C::@constructor::new
                substitution: {T: dynamic}
              element2: <testLibraryFragment>::@class::C::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            const new @18
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class C @44
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @46
              element: <not-implemented>
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class D @73
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      supertype: A
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
    class D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin B
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
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            const @16
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional x @18
                  type: dynamic
        class C @39
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: A @25
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @26
                arguments
                  NullLiteral
                    literal: null @27
                    staticType: Null
                rightParenthesis: ) @31
              element: <testLibraryFragment>::@class::A::@constructor::new
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
            const new @16
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                x @18
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::x#element
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional x
              type: dynamic
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            named @31
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              periodOffset: 30
              nameEnd: 36
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            named @31
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              periodOffset: 30
              nameEnd: 36
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element: <testLibraryFragment>::@getter::a
      element2: <testLibraryFragment>::@getter::a#element
  libraryExports
    package:test/foo.dart
      enclosingElement3: <testLibraryFragment>
      metadata
        Annotation
          atSign: @ @0
          name: SimpleIdentifier
            token: a @1
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryExports
        package:test/foo.dart
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        static const a @28
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @32
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element: <testLibraryFragment>::@getter::a
      element2: <testLibraryFragment>::@getter::a#element
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @28
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
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            x @33
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: int
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          fields
            x @33
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x @-1
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
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
      setters
        synthetic set x=
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: int
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            x @32
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            @37
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional final this.x @47
                  type: dynamic
                  metadata
                    Annotation
                      atSign: @ @39
                      name: SimpleIdentifier
                        token: a @40
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          fields
            x @32
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            new @37
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                this.x @47
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @39
                      name: SimpleIdentifier
                        token: a @40
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x @-1
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
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
            requiredPositional final x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @39
                  name: SimpleIdentifier
                    token: a @40
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: dynamic
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            x @30
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            @33
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default final this.x @44
                  type: dynamic
                  metadata
                    Annotation
                      atSign: @ @36
                      name: SimpleIdentifier
                        token: a @37
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
                  constantInitializer
                    NullLiteral
                      literal: null @48
                      staticType: Null
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          fields
            x @30
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            new @33
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                default this.x @44
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @36
                      name: SimpleIdentifier
                        token: a @37
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x @-1
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
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
            optionalPositional final x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: a @37
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: dynamic
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        synthetic static f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        static get f @23
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        synthetic f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibraryFragment>::@topLevelVariable::f#element
          getter2: <testLibraryFragment>::@getter::f
      getters
        get a @-1
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
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    synthetic f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic
      getter: <testLibraryFragment>::@getter::f#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    static get f
      firstFragment: <testLibraryFragment>::@getter::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        synthetic static f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        static set f= @23
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        synthetic f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibraryFragment>::@topLevelVariable::f#element
          setter2: <testLibraryFragment>::@setter::f
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        set f= @23
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          formalParameters
            value @25
              element: <testLibraryFragment>::@setter::f::@parameter::value#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    synthetic f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    static set f=
      firstFragment: <testLibraryFragment>::@setter::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
      formalParameters
        requiredPositional value
          type: dynamic
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
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @27
          reference: <testLibraryFragment>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@typeAlias::F#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
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
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
      aliasedType: dynamic Function()
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional g @21
              type: dynamic Function()
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            g @21
              element: <testLibraryFragment>::@function::f::@parameter::g#element
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional g
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default g @22
              type: dynamic Function()
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            default g @22
              element: <testLibraryFragment>::@function::f::@parameter::g#element
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalPositional g
          type: dynamic Function()
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
      typeAliases
        F @46
          reference: <testLibraryFragment>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@getter::b
              element2: <testLibraryFragment>::@getter::b#element
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@typeAlias::F#element
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@getter::b
              element2: <testLibraryFragment>::@getter::b#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @22
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
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      metadata
        Annotation
          atSign: @ @32
          name: SimpleIdentifier
            token: a @33
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
        Annotation
          atSign: @ @35
          name: SimpleIdentifier
            token: b @36
            staticElement: <testLibraryFragment>::@getter::b
            element: <testLibraryFragment>::@getter::b#element
            staticType: null
          element: <testLibraryFragment>::@getter::b
          element2: <testLibraryFragment>::@getter::b#element
      aliasedType: void Function()
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
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
      enclosingElement3: <null>
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
                      element: <testLibraryFragment>::@getter::a#element
                      staticType: null
                    element: <testLibraryFragment>::@getter::a
                    element2: <testLibraryFragment>::@getter::a#element
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
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
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function(int)
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
      enclosingElement3: <null>
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
                          element: <testLibraryFragment>::@getter::a#element
                          staticType: null
                        element: <testLibraryFragment>::@getter::a
                        element2: <testLibraryFragment>::@getter::a#element
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
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
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function(int Function(int))
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
      enclosingElement3: <null>
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
                      element: <testLibraryFragment>::@getter::a#element
                      staticType: null
                    element: <testLibraryFragment>::@getter::a
                    element2: <testLibraryFragment>::@getter::a#element
            parameters
              requiredPositional first @50
                type: int
            returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
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
      typeAliases
        F @22
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function<T>(int)
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

  test_metadata_invalid_classDeclaration() async {
    var library = await buildLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @8
              name: SimpleIdentifier
                token: f @9
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @10
                arguments
                  IntegerLiteral
                    literal: 42 @11
                    staticType: int
                rightParenthesis: ) @13
              element: <testLibraryFragment>::@function::f
              element2: <testLibraryFragment>::@function::f#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            _ @2
              element: <testLibraryFragment>::@function::f::@parameter::_#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional _
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
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: deprecated @1
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
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
      enclosingElement3: <null>
      parts
        part_0
          uri: source 'dart:math'
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: deprecated @1
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
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
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element: <testLibraryFragment>::@getter::a
      element2: <testLibraryFragment>::@getter::a#element
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @20
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @24
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element: <testLibraryFragment>::@getter::a
      element2: <testLibraryFragment>::@getter::a#element
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const a @20
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
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            get m @33
              reference: <testLibraryFragment>::@class::C::@getter::m
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          fields
            m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              element: <testLibraryFragment>::@class::C::@field::m#element
              getter2: <testLibraryFragment>::@class::C::@getter::m
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get m @33
              reference: <testLibraryFragment>::@class::C::@getter::m
              element: <testLibraryFragment>::@class::C::@getter::m#element
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
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
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            m @54
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    element: <testLibraryFragment>::@getter::b#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
                  element2: <testLibraryFragment>::@getter::b#element
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            m @54
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    element: <testLibraryFragment>::@getter::b#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
                  element2: <testLibraryFragment>::@getter::b#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @22
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
  classes
    class C
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
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@getter::b
              element2: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
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
      enclosingElement3: <null>
      mixins
        mixin M @38
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          methods
            m @54
              reference: <testLibraryFragment>::@mixin::M::@method::m
              enclosingElement3: <testLibraryFragment>::@mixin::M
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    element: <testLibraryFragment>::@getter::b#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
                  element2: <testLibraryFragment>::@getter::b#element
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@mixin::M#element
          methods
            m @54
              reference: <testLibraryFragment>::@mixin::M::@method::m
              element: <testLibraryFragment>::@mixin::M::@method::m#element
              metadata
                Annotation
                  atSign: @ @44
                  name: SimpleIdentifier
                    token: a @45
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: b @50
                    staticElement: <testLibraryFragment>::@getter::b
                    element: <testLibraryFragment>::@getter::b#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::b
                  element2: <testLibraryFragment>::@getter::b#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @22
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
  mixins
    mixin M
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
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @49
              name: SimpleIdentifier
                token: b @50
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@getter::b
              element2: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            set m= @37
              reference: <testLibraryFragment>::@class::C::@setter::m
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: a @29
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              parameters
                requiredPositional value @39
                  type: dynamic
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          fields
            m @-1
              reference: <testLibraryFragment>::@class::C::@field::m
              element: <testLibraryFragment>::@class::C::@field::m#element
              setter2: <testLibraryFragment>::@class::C::@setter::m
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          setters
            set m= @37
              reference: <testLibraryFragment>::@class::C::@setter::m
              element: <testLibraryFragment>::@class::C::@setter::m#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: a @29
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              formalParameters
                value @39
                  element: <testLibraryFragment>::@class::C::@setter::m::@parameter::value#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
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
        set m=
          firstFragment: <testLibraryFragment>::@class::C::@setter::m
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: a @29
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          formalParameters
            requiredPositional value
              type: dynamic
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      mixins
        mixin M @27
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          superclassConstraints
            Object
          fields
            static const foo @54
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
          methods
            bar @77
              reference: <testLibraryFragment>::@mixin::M::@method::bar
              enclosingElement3: <testLibraryFragment>::@mixin::M
              metadata
                Annotation
                  atSign: @ @65
                  name: SimpleIdentifier
                    token: foo @66
                    staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
                    element: <testLibraryFragment>::@mixin::M::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@mixin::M::@getter::foo
                  element2: <testLibraryFragment>::@mixin::M::@getter::foo#element
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @34
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          fields
            foo @54
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @-1
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
                    staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
                    element: <testLibraryFragment>::@mixin::M::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@mixin::M::@getter::foo
                  element2: <testLibraryFragment>::@mixin::M::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      superclassConstraints
        Object
      fields
        static const foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
      getters
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
      methods
        bar
          firstFragment: <testLibraryFragment>::@mixin::M::@method::bar
          metadata
            Annotation
              atSign: @ @65
              name: SimpleIdentifier
                token: foo @66
                staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
                element: <testLibraryFragment>::@mixin::M::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@mixin::M::@getter::foo
              element2: <testLibraryFragment>::@mixin::M::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      mixins
        mixin M @44
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: b @36
                staticElement: <testLibraryFragment>::@getter::b
                element: <testLibraryFragment>::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@getter::b
              element2: <testLibraryFragment>::@getter::b#element
          superclassConstraints
            Object
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static const b @22
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @26
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@mixin::M#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        const b @22
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
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    const b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
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
      enclosingElement3: <null>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @34
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @35
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              parameters
                requiredPositional a @46
                  type: int
                  metadata
                    Annotation
                      atSign: @ @37
                      name: SimpleIdentifier
                        token: foo @38
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            new @35
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              formalParameters
                a @46
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                  metadata
                    Annotation
                      atSign: @ @37
                      name: SimpleIdentifier
                        token: foo @38
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            requiredPositional a
              type: int
              metadata
                Annotation
                  atSign: @ @37
                  name: SimpleIdentifier
                    token: foo @38
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic getter @-1
              reference: <testLibraryFragment>::@class::A::@field::getter
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            get getter @43
              reference: <testLibraryFragment>::@class::A::@getter::getter
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              returnType: int
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          fields
            getter @-1
              reference: <testLibraryFragment>::@class::A::@field::getter
              element: <testLibraryFragment>::@class::A::@field::getter#element
              getter2: <testLibraryFragment>::@class::A::@getter::getter
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          getters
            get getter @43
              reference: <testLibraryFragment>::@class::A::@getter::getter
              element: <testLibraryFragment>::@class::A::@getter::getter#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
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
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            method @40
              reference: <testLibraryFragment>::@class::A::@method::method
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              typeParameters
                covariant T @52
                  defaultType: dynamic
                  metadata
                    Annotation
                      atSign: @ @47
                      name: SimpleIdentifier
                        token: foo @48
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
              parameters
                requiredPositional a @64
                  type: int
                  metadata
                    Annotation
                      atSign: @ @55
                      name: SimpleIdentifier
                        token: foo @56
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            method @40
              reference: <testLibraryFragment>::@class::A::@method::method
              element: <testLibraryFragment>::@class::A::@method::method#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              typeParameters
                T @52
                  element: <not-implemented>
                  metadata
                    Annotation
                      atSign: @ @47
                      name: SimpleIdentifier
                        token: foo @48
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
              formalParameters
                a @64
                  element: <testLibraryFragment>::@class::A::@method::method::@parameter::a#element
                  metadata
                    Annotation
                      atSign: @ @55
                      name: SimpleIdentifier
                        token: foo @56
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
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
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T
              metadata
                Annotation
                  atSign: @ @47
                  name: SimpleIdentifier
                    token: foo @48
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            requiredPositional a
              type: int
              metadata
                Annotation
                  atSign: @ @55
                  name: SimpleIdentifier
                    token: foo @56
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic setter @-1
              reference: <testLibraryFragment>::@class::A::@field::setter
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            set setter= @39
              reference: <testLibraryFragment>::@class::A::@setter::setter
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              parameters
                requiredPositional a @55
                  type: int
                  metadata
                    Annotation
                      atSign: @ @46
                      name: SimpleIdentifier
                        token: foo @47
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          fields
            setter @-1
              reference: <testLibraryFragment>::@class::A::@field::setter
              element: <testLibraryFragment>::@class::A::@field::setter#element
              setter2: <testLibraryFragment>::@class::A::@setter::setter
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          setters
            set setter= @39
              reference: <testLibraryFragment>::@class::A::@setter::setter
              element: <testLibraryFragment>::@class::A::@setter::setter#element
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              formalParameters
                a @55
                  element: <testLibraryFragment>::@class::A::@setter::setter::@parameter::a#element
                  metadata
                    Annotation
                      atSign: @ @46
                      name: SimpleIdentifier
                        token: foo @47
                        staticElement: <testLibraryFragment>::@getter::foo
                        element: <testLibraryFragment>::@getter::foo#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::foo
                      element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
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
        set setter=
          firstFragment: <testLibraryFragment>::@class::A::@setter::setter
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            requiredPositional a
              type: int
              metadata
                Annotation
                  atSign: @ @46
                  name: SimpleIdentifier
                    token: foo @47
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class alias B @50
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @39
              name: SimpleIdentifier
                token: foo @40
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @57
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @52
                  name: SimpleIdentifier
                    token: foo @53
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          supertype: A
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      mixins
        mixin M @33
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class B @50
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @57
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @52
                  name: SimpleIdentifier
                    token: foo @53
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      mixins
        mixin M @33
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @52
              name: SimpleIdentifier
                token: foo @53
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          supertype: Enum
          fields
            static const enumConstant e1 @37
              reference: <testLibraryFragment>::@enum::E::@field::e1
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
            static const enumConstant e2 @43
              reference: <testLibraryFragment>::@enum::E::@field::e2
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
            static const enumConstant e3 @54
              reference: <testLibraryFragment>::@enum::E::@field::e3
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @49
                  name: SimpleIdentifier
                    token: foo @50
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
                      token: e1 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::e1
                      element: <testLibraryFragment>::@enum::E::@getter::e1#element
                      staticType: E
                    SimpleIdentifier
                      token: e2 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::e2
                      element: <testLibraryFragment>::@enum::E::@getter::e2#element
                      staticType: E
                    SimpleIdentifier
                      token: e3 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::e3
                      element: <testLibraryFragment>::@enum::E::@getter::e3#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get e1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e1
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get e2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e2
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get e3 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e3
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant e1 @37
              reference: <testLibraryFragment>::@enum::E::@field::e1
              element: <testLibraryFragment>::@enum::E::@field::e1#element
              getter2: <testLibraryFragment>::@enum::E::@getter::e1
            enumConstant e2 @43
              reference: <testLibraryFragment>::@enum::E::@field::e2
              element: <testLibraryFragment>::@enum::E::@field::e2#element
              getter2: <testLibraryFragment>::@enum::E::@getter::e2
            enumConstant e3 @54
              reference: <testLibraryFragment>::@enum::E::@field::e3
              element: <testLibraryFragment>::@enum::E::@field::e3#element
              getter2: <testLibraryFragment>::@enum::E::@getter::e3
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get e1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e1
              element: <testLibraryFragment>::@enum::E::@getter::e1#element
            get e2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e2
              element: <testLibraryFragment>::@enum::E::@getter::e2#element
            get e3 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::e3
              element: <testLibraryFragment>::@enum::E::@getter::e3#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const e1
          firstFragment: <testLibraryFragment>::@enum::E::@field::e1
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::e1#element
        static const e2
          firstFragment: <testLibraryFragment>::@enum::E::@field::e2
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::e2#element
        static const e3
          firstFragment: <testLibraryFragment>::@enum::E::@field::e3
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::e3#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get e1
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e1
        synthetic static get e2
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e2
        synthetic static get e3
          firstFragment: <testLibraryFragment>::@enum::E::@getter::e3
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      extensions
        E @31
          reference: <testLibraryFragment>::@extension::E
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @38
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          extendedType: List<T>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@extension::E#element
          typeParameters
            T @38
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  extensions
    extension E
      firstFragment: <testLibraryFragment>::@extension::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: foo @34
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            static isStatic @42
              reference: <testLibraryFragment>::@class::A::@field::isStatic
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              type: int
              shouldUseTypeForInitializerInference: false
            static const isStaticConst @79
              reference: <testLibraryFragment>::@class::A::@field::isStaticConst
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @59
                  name: SimpleIdentifier
                    token: foo @60
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 2 @95
                  staticType: int
            isInstance @112
              reference: <testLibraryFragment>::@class::A::@field::isInstance
              enclosingElement3: <testLibraryFragment>::@class::A
              metadata
                Annotation
                  atSign: @ @101
                  name: SimpleIdentifier
                    token: foo @102
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
              type: int
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic static get isStatic @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStatic
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic static set isStatic= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isStatic
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _isStatic @-1
                  type: int
              returnType: void
            synthetic static get isStaticConst @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStaticConst
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic get isInstance @-1
              reference: <testLibraryFragment>::@class::A::@getter::isInstance
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic set isInstance= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isInstance
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _isInstance @-1
                  type: int
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          fields
            isStatic @42
              reference: <testLibraryFragment>::@class::A::@field::isStatic
              element: <testLibraryFragment>::@class::A::@field::isStatic#element
              getter2: <testLibraryFragment>::@class::A::@getter::isStatic
              setter2: <testLibraryFragment>::@class::A::@setter::isStatic
            isStaticConst @79
              reference: <testLibraryFragment>::@class::A::@field::isStaticConst
              element: <testLibraryFragment>::@class::A::@field::isStaticConst#element
              getter2: <testLibraryFragment>::@class::A::@getter::isStaticConst
            isInstance @112
              reference: <testLibraryFragment>::@class::A::@field::isInstance
              element: <testLibraryFragment>::@class::A::@field::isInstance#element
              getter2: <testLibraryFragment>::@class::A::@getter::isInstance
              setter2: <testLibraryFragment>::@class::A::@setter::isInstance
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          getters
            get isStatic @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStatic
              element: <testLibraryFragment>::@class::A::@getter::isStatic#element
            get isStaticConst @-1
              reference: <testLibraryFragment>::@class::A::@getter::isStaticConst
              element: <testLibraryFragment>::@class::A::@getter::isStaticConst#element
            get isInstance @-1
              reference: <testLibraryFragment>::@class::A::@getter::isInstance
              element: <testLibraryFragment>::@class::A::@getter::isInstance#element
          setters
            set isStatic= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isStatic
              element: <testLibraryFragment>::@class::A::@setter::isStatic#element
              formalParameters
                _isStatic @-1
                  element: <testLibraryFragment>::@class::A::@setter::isStatic::@parameter::_isStatic#element
            set isInstance= @-1
              reference: <testLibraryFragment>::@class::A::@setter::isInstance
              element: <testLibraryFragment>::@class::A::@setter::isInstance#element
              formalParameters
                _isInstance @-1
                  element: <testLibraryFragment>::@class::A::@setter::isInstance::@parameter::_isInstance#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static isStatic
          firstFragment: <testLibraryFragment>::@class::A::@field::isStatic
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::isStatic#element
          setter: <testLibraryFragment>::@class::A::@setter::isStatic#element
        static const isStaticConst
          firstFragment: <testLibraryFragment>::@class::A::@field::isStaticConst
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::isStaticConst#element
        isInstance
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
        synthetic static get isStaticConst
          firstFragment: <testLibraryFragment>::@class::A::@getter::isStaticConst
        synthetic get isInstance
          firstFragment: <testLibraryFragment>::@class::A::@getter::isInstance
      setters
        synthetic static set isStatic=
          firstFragment: <testLibraryFragment>::@class::A::@setter::isStatic
          formalParameters
            requiredPositional _isStatic
              type: int
        synthetic set isInstance=
          firstFragment: <testLibraryFragment>::@class::A::@setter::isInstance
          formalParameters
            requiredPositional _isInstance
              type: int
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
        element: <testLibraryFragment>::@getter::foo#element
        staticType: null
      element: <testLibraryFragment>::@getter::foo
      element2: <testLibraryFragment>::@getter::foo#element
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const foo @52
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @58
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
        element: <testLibraryFragment>::@getter::foo#element
        staticType: null
      element: <testLibraryFragment>::@getter::foo
      element2: <testLibraryFragment>::@getter::foo#element
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const foo @52
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      mixins
        mixin A @27
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @34
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          superclassConstraints
            Object
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@mixin::A#element
          typeParameters
            T @34
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: foo @30
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: foo @30
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      superclassConstraints
        Object
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @34
          reference: <testLibraryFragment>::@typeAlias::F
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            unrelated T @41
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: foo @37
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
                      element: <testLibraryFragment>::@getter::foo#element
                      staticType: null
                    element: <testLibraryFragment>::@getter::foo
                    element2: <testLibraryFragment>::@getter::foo#element
            returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@typeAlias::F#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T @41
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @36
                  name: SimpleIdentifier
                    token: foo @37
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
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
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @36
              name: SimpleIdentifier
                token: foo @37
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      aliasedType: void Function(int)
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      typeAliases
        A @29
          reference: <testLibraryFragment>::@typeAlias::A
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            unrelated T @36
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
                      element: <testLibraryFragment>::@getter::foo#element
                      staticType: null
                    element: <testLibraryFragment>::@getter::foo
                    element2: <testLibraryFragment>::@getter::foo#element
            parameters
              requiredPositional a @72
                type: int
                metadata
                  Annotation
                    atSign: @ @63
                    name: SimpleIdentifier
                      token: foo @64
                      staticElement: <testLibraryFragment>::@getter::foo
                      element: <testLibraryFragment>::@getter::foo#element
                      staticType: null
                    element: <testLibraryFragment>::@getter::foo
                    element2: <testLibraryFragment>::@getter::foo#element
            returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@typeAlias::A#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T @36
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
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
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @31
              name: SimpleIdentifier
                token: foo @32
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      aliasedType: void Function<U>(int)
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: foo @18
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @38
              name: SimpleIdentifier
                token: foo @39
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          unit: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static const foo @65
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @71
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
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
      enclosingElement3: <null>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @33
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            T @33
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
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
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
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
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
        synthetic static getter @-1
          reference: <testLibraryFragment>::@topLevelVariable::getter
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
        static get getter @29
          reference: <testLibraryFragment>::@getter::getter
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
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
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
        synthetic getter @-1
          reference: <testLibraryFragment>::@topLevelVariable::getter
          element: <testLibraryFragment>::@topLevelVariable::getter#element
          getter2: <testLibraryFragment>::@getter::getter
      getters
        get foo @-1
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
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
    synthetic getter
      firstFragment: <testLibraryFragment>::@topLevelVariable::getter
      type: int
      getter: <testLibraryFragment>::@getter::getter#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
    static get getter
      firstFragment: <testLibraryFragment>::@getter::getter
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
        synthetic static setter @-1
          reference: <testLibraryFragment>::@topLevelVariable::setter
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
        static set setter= @25
          reference: <testLibraryFragment>::@setter::setter
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          parameters
            requiredPositional a @41
              type: int
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
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
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
        synthetic setter @-1
          reference: <testLibraryFragment>::@topLevelVariable::setter
          element: <testLibraryFragment>::@topLevelVariable::setter#element
          setter2: <testLibraryFragment>::@setter::setter
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set setter= @25
          reference: <testLibraryFragment>::@setter::setter
          element: <testLibraryFragment>::@setter::setter#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          formalParameters
            a @41
              element: <testLibraryFragment>::@setter::setter::@parameter::a#element
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
    synthetic setter
      firstFragment: <testLibraryFragment>::@topLevelVariable::setter
      type: int
      setter: <testLibraryFragment>::@setter::setter#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set setter=
      firstFragment: <testLibraryFragment>::@setter::setter
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
      formalParameters
        requiredPositional a
          type: int
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: foo @33
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
        static isNotConst @25
          reference: <testLibraryFragment>::@topLevelVariable::isNotConst
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          type: int
          shouldUseTypeForInitializerInference: false
        static const isConst @53
          reference: <testLibraryFragment>::@topLevelVariable::isConst
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 2 @63
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get isNotConst @-1
          reference: <testLibraryFragment>::@getter::isNotConst
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set isNotConst= @-1
          reference: <testLibraryFragment>::@setter::isNotConst
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _isNotConst @-1
              type: int
          returnType: void
        synthetic static get isConst @-1
          reference: <testLibraryFragment>::@getter::isConst
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
        isNotConst @25
          reference: <testLibraryFragment>::@topLevelVariable::isNotConst
          element: <testLibraryFragment>::@topLevelVariable::isNotConst#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          getter2: <testLibraryFragment>::@getter::isNotConst
          setter2: <testLibraryFragment>::@setter::isNotConst
        const isConst @53
          reference: <testLibraryFragment>::@topLevelVariable::isConst
          element: <testLibraryFragment>::@topLevelVariable::isConst#element
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          getter2: <testLibraryFragment>::@getter::isConst
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
        get isNotConst @-1
          reference: <testLibraryFragment>::@getter::isNotConst
          element: <testLibraryFragment>::@getter::isNotConst#element
        get isConst @-1
          reference: <testLibraryFragment>::@getter::isConst
          element: <testLibraryFragment>::@getter::isConst#element
      setters
        set isNotConst= @-1
          reference: <testLibraryFragment>::@setter::isNotConst
          element: <testLibraryFragment>::@setter::isNotConst#element
          formalParameters
            _isNotConst @-1
              element: <testLibraryFragment>::@setter::isNotConst::@parameter::_isNotConst#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
    isNotConst
      firstFragment: <testLibraryFragment>::@topLevelVariable::isNotConst
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: foo @17
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
      type: int
      getter: <testLibraryFragment>::@getter::isNotConst#element
      setter: <testLibraryFragment>::@setter::isNotConst#element
    const isConst
      firstFragment: <testLibraryFragment>::@topLevelVariable::isConst
      metadata
        Annotation
          atSign: @ @42
          name: SimpleIdentifier
            token: foo @43
            staticElement: <testLibraryFragment>::@getter::foo
            element: <testLibraryFragment>::@getter::foo#element
            staticType: null
          element: <testLibraryFragment>::@getter::foo
          element2: <testLibraryFragment>::@getter::foo#element
      type: int
      getter: <testLibraryFragment>::@getter::isConst#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get isNotConst
      firstFragment: <testLibraryFragment>::@getter::isNotConst
    synthetic static get isConst
      firstFragment: <testLibraryFragment>::@getter::isConst
  setters
    synthetic static set isNotConst=
      firstFragment: <testLibraryFragment>::@setter::isNotConst
      formalParameters
        requiredPositional _isNotConst
          type: int
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
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/foo.dart
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @11
              name: SimpleIdentifier
                token: a @12
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          unit: <testLibrary>::@fragment::package:test/foo.dart
      topLevelVariables
        static const a @37
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @41
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
    <testLibrary>::@fragment::package:test/foo.dart
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
    <testLibrary>::@fragment::package:test/foo.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::A
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
          element: <testLibrary>::@fragment::package:test/a.dart::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new#element
  classes
    class A
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:math
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
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
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        dart:math
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
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
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
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
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/a.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    a @19
      reference: <testLibraryFragment>::@prefix::a
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart as a @19
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @19
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement3: <testLibraryFragment>
      classes
        class C @33
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @22
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: a @23
                  staticElement: <testLibraryFragment>::@prefix::a
                  element: <testLibraryFragment>::@prefix2::a
                  staticType: null
                period: . @24
                identifier: SimpleIdentifier
                  token: b @25
                  staticElement: package:test/a.dart::<fragment>::@getter::b
                  element: package:test/a.dart::<fragment>::@getter::b#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@getter::b
                element: package:test/a.dart::<fragment>::@getter::b#element
                staticType: null
              element: package:test/a.dart::<fragment>::@getter::b
              element2: package:test/a.dart::<fragment>::@getter::b#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional x @21
              type: dynamic
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            x @21
              element: <testLibraryFragment>::@function::f::@parameter::x#element
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional x
          type: dynamic
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            m @29
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @34
                  type: dynamic
                  metadata
                    Annotation
                      atSign: @ @31
                      name: SimpleIdentifier
                        token: a @32
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
              returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
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
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          formalParameters
            requiredPositional x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: a @32
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        static set foo= @21
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional x @32
              type: int
              metadata
                Annotation
                  atSign: @ @25
                  name: SimpleIdentifier
                    token: a @26
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        set foo= @21
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
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional x
          type: int
          metadata
            Annotation
              atSign: @ @25
              name: SimpleIdentifier
                token: a @26
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default x @22
              type: dynamic
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            default x @22
              element: <testLibraryFragment>::@function::f::@parameter::x#element
              metadata
                Annotation
                  atSign: @ @19
                  name: SimpleIdentifier
                    token: a @20
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalPositional x
          type: dynamic
          metadata
            Annotation
              atSign: @ @19
              name: SimpleIdentifier
                token: a @20
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
      classes
        class A @23
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @29
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional x @35
                  type: int
        class B @48
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A
          constructors
            @64
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional final super.x @75
                  type: int
                  metadata
                    Annotation
                      atSign: @ @66
                      name: SimpleIdentifier
                        token: a @67
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
                  superConstructorParameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::x
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            new @29
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                x @35
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::x#element
        class B @48
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            new @64
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              formalParameters
                super.x @75
                  element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::x#element
                  metadata
                    Annotation
                      atSign: @ @66
                      name: SimpleIdentifier
                        token: a @67
                        staticElement: <testLibraryFragment>::@getter::a
                        element: <testLibraryFragment>::@getter::a#element
                        staticType: null
                      element: <testLibraryFragment>::@getter::a
                      element2: <testLibraryFragment>::@getter::a#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
      topLevelVariables
        const a @6
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
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional x
              type: int
    class B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          formalParameters
            requiredPositional final x
              type: int
              metadata
                Annotation
                  atSign: @ @66
                  name: SimpleIdentifier
                    token: a @67
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
        static v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          type: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        v @23
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: a @17
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v @-1
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      metadata
        Annotation
          atSign: @ @16
          name: SimpleIdentifier
            token: a @17
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
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
      enclosingElement3: <null>
      classes
        class C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @27
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @27
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      classes
        class alias C @22
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @27
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          supertype: D
          mixins
            E
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
                  element: <testLibraryFragment>::@class::D::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @48
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
        class E @59
          reference: <testLibraryFragment>::@class::E
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::E
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @27
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @24
                  name: SimpleIdentifier
                    token: a @25
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::D::@constructor::new
                  element: <testLibraryFragment>::@class::D::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
        class D @48
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
        class E @59
          reference: <testLibraryFragment>::@class::E
          element: <testLibraryFragment>::@class::E#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::E::@constructor::new
              element: <testLibraryFragment>::@class::E::@constructor::new#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class alias C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @24
              name: SimpleIdentifier
                token: a @25
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      supertype: D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
    class D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
    class E
      firstFragment: <testLibraryFragment>::@class::E
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::E::@constructor::new
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
      enclosingElement3: <null>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @21
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      functions
        f @16
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          typeParameters
            T @21
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @18
                  name: SimpleIdentifier
                    token: a @19
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: a @19
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
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
      enclosingElement3: <null>
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
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
          constantInitializer
            NullLiteral
              literal: null @10
              staticType: Null
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@typeAlias::F#element
          typeParameters
            T @29
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
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
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      aliasedType: dynamic Function()
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
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
        static x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @13
              name: SimpleIdentifier
                token: a @14
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
        x @20
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          metadata
            Annotation
              atSign: @ @13
              name: SimpleIdentifier
                token: a @14
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      metadata
        Annotation
          atSign: @ @13
          name: SimpleIdentifier
            token: a @14
            staticElement: <testLibraryFragment>::@getter::a
            element: <testLibraryFragment>::@getter::a#element
            staticType: null
          element: <testLibraryFragment>::@getter::a
          element2: <testLibraryFragment>::@getter::a#element
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
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
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            static const x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @29
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @34
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @35
                  staticElement: <testLibraryFragment>::@class::A
                  element: <testLibraryFragment>::@class::A#element
                  staticType: null
                period: . @36
                identifier: SimpleIdentifier
                  token: x @37
                  staticElement: <testLibraryFragment>::@class::A::@getter::x
                  element: <testLibraryFragment>::@class::A::@getter::x#element
                  staticType: null
                staticElement: <testLibraryFragment>::@class::A::@getter::x
                element: <testLibraryFragment>::@class::A::@getter::x#element
                staticType: null
              element: <testLibraryFragment>::@class::A::@getter::x
              element2: <testLibraryFragment>::@class::A::@getter::x#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
            x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <testLibraryFragment>::@class::A::@field::x#element
              getter2: <testLibraryFragment>::@class::A::@getter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              element: <testLibraryFragment>::@class::A::@getter::x#element
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static const x
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get x
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: E @18
                  staticElement: <testLibraryFragment>::@enum::E
                  element: <testLibraryFragment>::@enum::E#element
                  staticType: null
                period: . @19
                identifier: SimpleIdentifier
                  token: b @20
                  staticElement: <testLibraryFragment>::@enum::E::@getter::b
                  element: <testLibraryFragment>::@enum::E::@getter::b#element
                  staticType: null
                staticElement: <testLibraryFragment>::@enum::E::@getter::b
                element: <testLibraryFragment>::@enum::E::@getter::b#element
                staticType: null
              element: <testLibraryFragment>::@enum::E::@getter::b
              element2: <testLibraryFragment>::@enum::E::@getter::b#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @28
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
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
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
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
      enclosingElement3: <null>
      classes
        class C @56
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @45
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: E @46
                  staticElement: <testLibraryFragment>::@extension::E
                  element: <testLibraryFragment>::@extension::E#element
                  staticType: null
                period: . @47
                identifier: SimpleIdentifier
                  token: x @48
                  staticElement: <testLibraryFragment>::@extension::E::@getter::x
                  element: <testLibraryFragment>::@extension::E::@getter::x#element
                  staticType: null
                staticElement: <testLibraryFragment>::@extension::E::@getter::x
                element: <testLibraryFragment>::@extension::E::@getter::x#element
                staticType: null
              element: <testLibraryFragment>::@extension::E::@getter::x
              element2: <testLibraryFragment>::@extension::E::@getter::x#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement3: <testLibraryFragment>
          extendedType: int
          fields
            static const x @36
              reference: <testLibraryFragment>::@extension::E::@field::x
              enclosingElement3: <testLibraryFragment>::@extension::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @40
                  staticType: int
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@extension::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@extension::E
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          element: <testLibraryFragment>::@extension::E#element
          fields
            x @36
              reference: <testLibraryFragment>::@extension::E::@field::x
              element: <testLibraryFragment>::@extension::E::@field::x#element
              getter2: <testLibraryFragment>::@extension::E::@getter::x
          getters
            get x @-1
              reference: <testLibraryFragment>::@extension::E::@getter::x
              element: <testLibraryFragment>::@extension::E::@getter::x#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  extensions
    extension E
      firstFragment: <testLibraryFragment>::@extension::E
      fields
        static const x
          firstFragment: <testLibraryFragment>::@extension::E::@field::x
          type: int
          getter: <testLibraryFragment>::@extension::E::@getter::x#element
      getters
        synthetic static get x
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @41
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @26
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @27
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @30
                identifier: SimpleIdentifier
                  token: E @31
                  staticElement: package:test/foo.dart::<fragment>::@extension::E
                  element: package:test/foo.dart::<fragment>::@extension::E#element
                  staticType: null
                staticElement: package:test/foo.dart::<fragment>::@extension::E
                element: package:test/foo.dart::<fragment>::@extension::E#element
                staticType: null
              period: . @32
              constructorName: SimpleIdentifier
                token: x @33
                staticElement: package:test/foo.dart::<fragment>::@extension::E::@getter::x
                element: package:test/foo.dart::<fragment>::@extension::E::@getter::x#element
                staticType: null
              element: package:test/foo.dart::<fragment>::@extension::E::@getter::x
              element2: package:test/foo.dart::<fragment>::@extension::E::@getter::x#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
                requiredPositional _ @20
                  type: dynamic
        class C @43
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @27
              name: SimpleIdentifier
                token: A @28
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  SuperExpression
                    superKeyword: super @30
                    staticType: InvalidType
                rightParenthesis: ) @35
              element: <testLibraryFragment>::@class::A::@constructor::new
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
                _ @20
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @43
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional _
              type: dynamic
    class C
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
                requiredPositional _ @20
                  type: dynamic
        class C @42
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @27
              name: SimpleIdentifier
                token: A @28
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  ThisExpression
                    thisKeyword: this @30
                    staticType: dynamic
                rightParenthesis: ) @34
              element: <testLibraryFragment>::@class::A::@constructor::new
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
                _ @20
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
        class C @42
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional _
              type: dynamic
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @8
                rightParenthesis: ) @9
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: String @1
                  staticElement: dart:core::<fragment>::@class::String
                  element: dart:core::<fragment>::@class::String#element
                  staticType: null
                period: . @7
                identifier: SimpleIdentifier
                  token: foo @8
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @11
                rightParenthesis: ) @12
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @20
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @15
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @15
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async as foo @23
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: bar @33
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              period: . @8
              constructorName: SimpleIdentifier
                token: baz @9
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @12
                rightParenthesis: ) @13
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async as foo @23
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @49
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: bar @33
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              period: . @36
              constructorName: SimpleIdentifier
                token: baz @37
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @40
                rightParenthesis: ) @41
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async as foo @23
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @52
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: Future @33
                  staticElement: dart:async::<fragment>::@class::Future
                  element: dart:async::<fragment>::@class::Future#element
                  staticType: null
                staticElement: dart:async::<fragment>::@class::Future
                element: dart:async::<fragment>::@class::Future#element
                staticType: null
              period: . @39
              constructorName: SimpleIdentifier
                token: bar @40
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @43
                rightParenthesis: ) @44
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  staticElement: <null>
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @8
                rightParenthesis: ) @9
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @17
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @23
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async as foo @23
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @23
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      classes
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @28
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @29
                  staticElement: <testLibraryFragment>::@prefix::foo
                  element: <testLibraryFragment>::@prefix2::foo
                  staticType: null
                period: . @32
                identifier: SimpleIdentifier
                  token: bar @33
                  staticElement: <null>
                  element: <null>
                  staticType: null
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @11
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                staticElement: <null>
                element: <null>
                staticType: null
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @11
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class C @44
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: v @36
                staticElement: <null>
                element: <null>
                staticType: null
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @13
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                staticElement: <null>
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @4
                rightParenthesis: ) @5
              element: <null>
              element2: <null>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @13
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
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
