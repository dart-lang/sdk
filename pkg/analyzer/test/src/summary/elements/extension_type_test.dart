// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../element_text.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeElementTest_keepLinking);
    defineReflectiveTests(ExtensionTypeElementTest_fromBytes);
    defineReflectiveTests(ExtensionTypeElementTest_augmentation_keepLinking);
    defineReflectiveTests(ExtensionTypeElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

mixin ExtensionTypeElementMixin on ElementsBaseTest {
  test_constructor_const() async {
    var library = await buildLibrary(r'''
extension type const A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @21
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @27
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            const @21
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @27
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @21
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @27
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            const new @21
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @27
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_constructor_named() async {
    var library = await buildLibrary(r'''
extension type A.named(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 33
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::named
          typeErasure: int
          fields
            final it @27
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 23
              codeLength: 6
              type: int
          constructors
            named @17
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 16
              codeLength: 14
              periodOffset: 16
              nameEnd: 22
              parameters
                requiredPositional final this.it @27
                  type: int
                  codeOffset: 23
                  codeLength: 6
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @27
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            named @17
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              element: <none>
              codeOffset: 16
              codeLength: 14
              periodOffset: 16
              nameEnd: 22
              parameters
                this.it @27
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      codeOffset: 0
      codeLength: 33
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        named
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::named
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_constructor_secondary_fieldFormalParameter() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  A.named(this.it);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @21
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
            named @31
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 30
              nameEnd: 36
              parameters
                requiredPositional final this.it @42
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @21
                  element: <none>
            named @31
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              element: <none>
              periodOffset: 30
              nameEnd: 36
              parameters
                this.it @42
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: num
      fields
        final it
          reference: <none>
          type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
        named
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::named
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_constructor_secondary_fieldFormalParameter_typed() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  A.named(int this.it);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @21
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
            named @31
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 30
              nameEnd: 36
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @21
                  element: <none>
            named @31
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              element: <none>
              periodOffset: 30
              nameEnd: 36
              parameters
                this.it @46
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: num
      fields
        final it
          reference: <none>
          type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
        named
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::named
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_constructor_secondary_fieldInitializer() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @21
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
            const named @37
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 36
              nameEnd: 42
              parameters
                requiredPositional a @47
                  type: int
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: it @52
                    staticElement: <testLibraryFragment>::@extensionType::A::@field::it
                    staticType: null
                  equals: = @55
                  expression: SimpleIdentifier
                    token: a @57
                    staticElement: <testLibraryFragment>::@extensionType::A::@constructor::named::@parameter::a
                    staticType: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @21
                  element: <none>
            const named @37
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              element: <none>
              periodOffset: 36
              nameEnd: 42
              parameters
                a @47
                  element: <none>
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: it @52
                    staticElement: <testLibraryFragment>::@extensionType::A::@field::it
                    staticType: null
                  equals: = @55
                  expression: SimpleIdentifier
                    token: a @57
                    staticElement: <testLibraryFragment>::@extensionType::A::@constructor::named::@parameter::a
                    staticType: int
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: num
      fields
        final it
          reference: <none>
          type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
        const named
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::named
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_constructor_unnamed() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 27
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 17
              codeLength: 6
              type: int
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 16
              codeLength: 8
              parameters
                requiredPositional final this.it @21
                  type: int
                  codeOffset: 17
                  codeLength: 6
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              codeOffset: 16
              codeLength: 8
              parameters
                this.it @21
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      codeOffset: 0
      codeLength: 27
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_documentation() async {
    var library = await buildLibrary(r'''
/// Docs
extension type A(int it) {
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @24
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          documentationComment: /// Docs
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @30
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @24
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @30
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @24
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @30
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @24
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @30
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      documentationComment: /// Docs
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_field_const_typed() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static const int foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            static const foo @46
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 0 @52
                  staticType: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @46
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static const foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
''');
  }

  test_field_const_untyped() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static const foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            static const foo @42
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @48
                  staticType: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @42
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static const foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
''');
  }

  test_field_instance_untyped() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  final foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            final foo @35
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            synthetic get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @35
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
''');
  }

  test_field_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    var library = await buildLibrary(r'''
import 'a.dart';
extension type A(@foo int it) {}
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
      extensionTypes
        A @32
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @43
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              metadata
                Annotation
                  atSign: @ @34
                  name: SimpleIdentifier
                    token: foo @35
                    staticElement: package:test/a.dart::<fragment>::@getter::foo
                    staticType: null
                  element: package:test/a.dart::<fragment>::@getter::foo
              type: int
          constructors
            @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @43
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      extensionTypes
        extension type A @32
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @43
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @43
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_getter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            get foo @37
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @37
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
''');
  }

  test_interfaces_class() async {
    var library = await buildLibrary(r'''
class A {}
class B {}
class C implements A, B {}
extension type X(C it) implements A, B {}
''');

    configuration.withConstructors = false;
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
        class B @17
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          interfaces
            A
            B
      extensionTypes
        X @64
          reference: <testLibraryFragment>::@extensionType::X
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::X::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::X::@constructor::new
          typeErasure: C
          interfaces
            A
            B
          fields
            final it @68
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              type: C
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              returnType: C
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
        class B @17
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
        class C @28
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
      extensionTypes
        extension type X @64
          reference: <testLibraryFragment>::@extensionType::X
          element: <testLibraryFragment>::@extensionType::X
          fields
            it @68
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::X::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
  extensionTypes
    extension type X
      reference: <testLibraryFragment>::@extensionType::X
      firstFragment: <testLibraryFragment>::@extensionType::X
      typeErasure: C
      fields
        final it
          reference: <none>
          type: C
          firstFragment: <testLibraryFragment>::@extensionType::X::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::X::@getter::it
''');
  }

  test_interfaces_cycle2() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements B {}
extension type B(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasImplementsSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            Object
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
        hasImplementsSelfReference B @56
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          interfaces
            Object
          fields
            final it @62
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @56
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @62
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_interfaces_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasImplementsSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            Object
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_interfaces_extensionType() async {
    var library = await buildLibrary(r'''
extension type A(num it) {}
extension type B(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
        B @43
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          interfaces
            A
          fields
            final it @49
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @43
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @49
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: num
      fields
        final it
          reference: <none>
          type: num
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_interfaces_futureOr() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements num, FutureOr<int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_interfaces_implicitObjectQuestion() async {
    var library = await buildLibrary(r'''
extension type X(int? it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        X @15
          reference: <testLibraryFragment>::@extensionType::X
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::X::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::X::@constructor::new
          typeErasure: int?
          fields
            final it @22
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              type: int?
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              returnType: int?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type X @15
          reference: <testLibraryFragment>::@extensionType::X
          element: <testLibraryFragment>::@extensionType::X
          fields
            it @22
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::X::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              element: <none>
  extensionTypes
    extension type X
      reference: <testLibraryFragment>::@extensionType::X
      firstFragment: <testLibraryFragment>::@extensionType::X
      typeErasure: int?
      fields
        final it
          reference: <none>
          type: int?
          firstFragment: <testLibraryFragment>::@extensionType::X::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::X::@getter::it
''');
  }

  test_interfaces_implicitObjectQuestion_fromTypeParameter() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: T
          fields
            final it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: T
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          typeParameters
            T @17
              element: <none>
          fields
            it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: T
      fields
        final it
          reference: <none>
          type: T
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_interfaces_void() async {
    var library = await buildLibrary(r'''
typedef A = void;
extension type X(int it) implements A, num {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        X @33
          reference: <testLibraryFragment>::@extensionType::X
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::X::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::X::@constructor::new
          typeErasure: int
          interfaces
            num
          fields
            final it @39
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              returnType: int
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type X @33
          reference: <testLibraryFragment>::@extensionType::X
          element: <testLibraryFragment>::@extensionType::X
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::X::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              element: <none>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
  extensionTypes
    extension type X
      reference: <testLibraryFragment>::@extensionType::X
      firstFragment: <testLibraryFragment>::@extensionType::X
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::X::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::X::@getter::it
  typeAliases
    A
      reference: <none>
      aliasedType: void
''');
  }

  test_isPromotable_representationField_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {}

class B {
  int _it = 0;
}

class C {
  int get _it => 0;
}
''');

    configuration
      ..forPromotableFields(extensionTypeNames: {'A'})
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::_it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int?
          fields
            final promotable _it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::_it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int?
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibraryFragment>::@class::B::@field::_it
      conflictingGetters
        <testLibraryFragment>::@class::C::@getter::_it
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            promotable _it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::_it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::_it
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        _it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::B::@field::_it
          getter: <none>
          setter: <none>
      getters
        synthetic get _it
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@getter::_it
      setters
        synthetic set _it=
          reference: <none>
          parameters
            requiredPositional __it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::B::@setter::_it
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic _it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::_it
          getter: <none>
      getters
        get _it
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::_it
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int?
      fields
        final _it
          reference: <none>
          type: int?
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::_it
          getter: <none>
      getters
        synthetic get _it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::_it
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibraryFragment>::@class::B::@field::_it
      conflictingGetters
        <testLibraryFragment>::@class::C::@getter::_it
''');
  }

  test_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    var library = await buildLibrary(r'''
import 'a.dart';
@foo
extension type A(int it) {}
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
      extensionTypes
        A @37
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: foo @18
                staticElement: package:test/a.dart::<fragment>::@getter::foo
                staticType: null
              element: package:test/a.dart::<fragment>::@getter::foo
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @43
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @37
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @43
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      extensionTypes
        extension type A @37
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @43
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @37
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @43
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_method() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo(int a) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @34
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional a @42
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @34
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
              parameters
                a @42
                  element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
''');
  }

  test_method_defaultFormalParameter_defaultValue() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo({int a = 0}) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @34
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                optionalNamed default a @43
                  reference: <testLibraryFragment>::@extensionType::A::@method::foo::@parameter::a
                  type: int
                  constantInitializer
                    IntegerLiteral
                      literal: 0 @47
                      staticType: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @34
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
              parameters
                default a @43
                  reference: <testLibraryFragment>::@extensionType::A::@method::foo::@parameter::a
                  element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <none>
          parameters
            optionalNamed a
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
''');
  }

  test_noField() async {
    var library = await buildLibrary(r'''
extension type A() {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 21
          representation: <testLibraryFragment>::@extensionType::A::@field::<empty>
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final <empty> @17
              reference: <testLibraryFragment>::@extensionType::A::@field::<empty>
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 17
              codeLength: 0
              type: InvalidType
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 16
              codeLength: 2
              parameters
                requiredPositional final this.<empty> @17
                  type: InvalidType
                  codeOffset: 17
                  codeLength: 0
                  field: <testLibraryFragment>::@extensionType::A::@field::<empty>
          accessors
            synthetic get <empty> @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::<empty>
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            <empty> @17
              reference: <testLibraryFragment>::@extensionType::A::@field::<empty>
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::<empty>
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              codeOffset: 16
              codeLength: 2
              parameters
                this.<empty> @17
                  element: <none>
          getters
            get <empty> @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::<empty>
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      codeOffset: 0
      codeLength: 21
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: InvalidType
      fields
        final <empty>
          reference: <none>
          type: InvalidType
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::<empty>
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final <empty>
              reference: <none>
              type: InvalidType
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get <empty>
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::<empty>
''');
  }

  test_notSimplyBounded_self() async {
    var library = await buildLibrary(r'''
extension type A<T extends A>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        notSimplyBounded A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              bound: A<dynamic>
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @34
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          typeParameters
            T @17
              element: <none>
          fields
            it @34
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
          bound: A<dynamic>
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_setter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo(double _) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: double
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            set foo= @33
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @44
                  type: double
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          setters
            set foo= @33
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _ @44
                  element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo
          reference: <none>
          type: double
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          setter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: double
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_typeErasure_hasExtension_cycle2_direct() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(A it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasRepresentationSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: InvalidType
        hasRepresentationSelfReference B @42
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: InvalidType
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @42
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @46
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: InvalidType
      fields
        final it
          reference: <none>
          type: InvalidType
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: InvalidType
      fields
        final it
          reference: <none>
          type: InvalidType
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_typeErasure_hasExtension_cycle2_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(List<B> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: B
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: B
        hasRepresentationSelfReference B @42
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: InvalidType
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @42
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: InvalidType
      fields
        final it
          reference: <none>
          type: B
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: InvalidType
      fields
        final it
          reference: <none>
          type: InvalidType
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_typeErasure_hasExtension_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(A it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasRepresentationSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: InvalidType
      fields
        final it
          reference: <none>
          type: InvalidType
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_typeErasure_hasExtension_functionType() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

extension type B(A Function(A a) it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
        B @44
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int Function(int)
          fields
            final it @62
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: A Function(A)
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: A Function(A)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @44
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @62
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int Function(int)
      fields
        final it
          reference: <none>
          type: A Function(A)
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_typeErasure_hasExtension_interfaceType() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {}

extension type B(A<double> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: T
          fields
            final it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: T
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
        B @45
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: double
          fields
            final it @57
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: A<double>
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: A<double>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          typeParameters
            T @17
              element: <none>
          fields
            it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @45
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @57
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: T
      fields
        final it
          reference: <none>
          type: T
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: double
      fields
        final it
          reference: <none>
          type: A<double>
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_typeErasure_hasExtension_interfaceType_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

extension type B(List<A> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
        B @44
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: List<int>
          fields
            final it @54
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: List<A>
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: List<A>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type B @44
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @54
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: List<int>
      fields
        final it
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
''');
  }

  test_typeErasure_notExtension() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_typeParameters() async {
    var library = await buildLibrary(r'''
extension type A<T extends num, U>(Map<T, U> it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              bound: num
              defaultType: num
            covariant U @32
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: Map<T, U>
          fields
            final it @45
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: Map<T, U>
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @45
                  type: Map<T, U>
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: Map<T, U>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          typeParameters
            T @17
              element: <none>
            U @32
              element: <none>
          fields
            it @45
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @45
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
          bound: num
        U
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: Map<T, U>
      fields
        final it
          reference: <none>
          type: Map<T, U>
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: Map<T, U>
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }
}

abstract class ExtensionTypeElementTest_augmentation extends ElementsBaseTest {
  test_augmentationTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension type A(int it) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension type A(int it) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {}
''');

    configuration.withExportScope = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@extensionType::A
  exportNamespace
    A: <testLibraryFragment>::@extensionType::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
  exportedReferences
    declared <testLibraryFragment>::@extensionType::A
  exportNamespace
    A: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension type A(int it) {
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension type A(int it) {
  void foo2() {}
}
''');

    var library = await buildLibrary(r'''
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
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
          typeErasure: int
          fields
            final it @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
          constructors
            augment @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional final this.it @65
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
          methods
            foo1 @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            foo2 @60
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: void
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
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            it @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
          constructors
            augment new @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
              element: <none>
              parameters
                this.it @65
                  element: <none>
          getters
            get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
              element: <none>
          methods
            foo1 @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            foo2 @60
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
      methods
        foo1
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
        foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
''');
  }

  test_augmented_constructors_add_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  A.named();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            named @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              periodOffset: 59
              nameEnd: 65
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          constructors
            named @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 59
              nameEnd: 65
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
        named
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_augmented_constructors_add_named_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T2>(int it) {
  A.named(T2 a);
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T1>(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @40
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @40
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
              ConstructorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
                augmentationSubstitution: {T2: T1}
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            named @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              periodOffset: 63
              nameEnd: 69
              parameters
                requiredPositional a @73
                  type: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T1 @32
              element: <none>
          fields
            it @40
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @40
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <none>
          constructors
            named @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 63
              nameEnd: 69
              parameters
                a @73
                  element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T1
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
        named
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: T2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  A();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A.named(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::named
          typeErasure: int
          fields
            final it @42
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            named @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 31
              nameEnd: 37
              parameters
                requiredPositional final this.it @42
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              <testLibraryFragment>::@extensionType::A::@constructor::named
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            @58
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @42
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            named @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              element: <none>
              periodOffset: 31
              nameEnd: 37
              parameters
                this.it @42
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          constructors
            new @58
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        named
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::named
        new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @51
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @51
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static set foo= @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @85
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @51
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          setters
            augment set foo= @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              element: <none>
              parameters
                _ @85
                  element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            foo @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  static int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic static foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            static get foo @59
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @59
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  static int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  static int foo1 = 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo1= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo1 @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              <testLibraryFragment>::@extensionType::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            static foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              setter: setter_1
          accessors
            synthetic static get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_2
            synthetic static set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _foo2 @-1
                  type: int
              returnType: void
              id: setter_1
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo1
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <none>
          setters
            set foo1= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              element: <none>
              parameters
                _foo1 @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              setter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              element: <none>
          setters
            set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              element: <none>
              parameters
                _foo2 @-1
                  element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          getter: <none>
          setter: <none>
        static foo2
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
        synthetic static get foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
      setters
        synthetic static set foo1=
          reference: <none>
          parameters
            requiredPositional _foo1
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
        synthetic static set foo2=
          reference: <none>
          parameters
            requiredPositional _foo2
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  int get foo1 => 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              id: field_2
              getter: getter_2
          accessors
            get foo2 @66
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
          getters
            get foo2 @66
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          getter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
        get foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T2>(int it) {
  T2 get foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T1>(int it) {
  T1 get foo1;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @40
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: T1
              id: field_1
              getter: getter_1
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @40
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            abstract get foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T1
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: T2
              id: field_2
              getter: getter_2
          accessors
            abstract get foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T2
              id: getter_2
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T1 @32
              element: <none>
          fields
            it @40
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @40
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <none>
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
          getters
            get foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T1
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo1
          reference: <none>
          type: T1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          getter: <none>
        synthetic foo2
          reference: <none>
          type: T2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        abstract get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
        abstract get foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: field_1
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @51
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  int get foo1 => 0;
  int get foo2 => 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
            get foo2 @73
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibraryFragment>::@extensionType::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              <testLibraryFragment>::@extensionType::A::@getter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment get foo1 @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo2
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
            get foo2 @73
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo2
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          getters
            augment get foo1 @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          getter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo2
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo2
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo2
        get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
''');
  }

  test_augmented_getters_augment_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension type A(int it) {
  int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo @67
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          accessors
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: field_1
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          constructors
            new @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @51
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @67
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
''');
  }

  test_augmented_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) implements I2 {}
extension type I2(int it) {}
''');

    configuration.withConstructors = false;
    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) implements I1 {}
extension type I1(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
              I2
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @72
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2
        I2 @86
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @93
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type I1 @72
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibraryFragment>::@extensionType::I1
          fields
            it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
        extension type I2 @86
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          fields
            it @93
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          getters
            get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibraryFragment>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
''');
  }

  test_augmented_interfaces_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension type A(int it) implements I2 {}
extension type I2(int it) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension type A(int it) implements I3 {}
extension type I3(int it) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) implements I1 {}
extension type I1(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
              I2
              I3
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @72
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @72
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final this.it @79
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          interfaces
            I2
        I2 @101
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @101
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final this.it @108
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          interfaces
            I3
        I3 @83
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          representation: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
          typeErasure: int
          fields
            final it @90
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              type: int
          constructors
            @83
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              parameters
                requiredPositional final this.it @90
                  type: int
                  field: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type I1 @72
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibraryFragment>::@extensionType::I1
          fields
            it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          constructors
            new @72
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              element: <none>
              parameters
                this.it @79
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
        extension type I2 @101
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          fields
            it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          constructors
            new @101
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              element: <none>
              parameters
                this.it @108
                  element: <none>
          getters
            get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I3 @83
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
          element: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
          fields
            it @90
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
          constructors
            new @83
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
              element: <none>
              parameters
                this.it @90
                  element: <none>
          getters
            get it @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibraryFragment>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
    extension type I3
      reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
''');
  }

  test_augmented_interfaces_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T2>(int it) implements I2<T2> {}
extension type I2<E>(int it) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
              I2<T>
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @75
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @75
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final this.it @82
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2<T2>
        I2 @94
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @97
              defaultType: dynamic
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @104
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @94
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final this.it @104
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <none>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @39
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type I1 @75
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibraryFragment>::@extensionType::I1
          fields
            it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          constructors
            new @75
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              element: <none>
              parameters
                this.it @82
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <none>
        extension type I2 @94
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          typeParameters
            E @97
              element: <none>
          fields
            it @104
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          constructors
            new @94
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              element: <none>
              parameters
                this.it @104
                  element: <none>
          getters
            get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibraryFragment>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeParameters
        E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T2, T3>(int it) implements I2<T2> {}
extension type I2<E>(int it) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @75
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @75
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final this.it @82
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
            covariant T3 @50
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2<T2>
        I2 @98
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @101
              defaultType: dynamic
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final this.it @108
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <none>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @39
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
        extension type I1 @75
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibraryFragment>::@extensionType::I1
          fields
            it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          constructors
            new @75
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              element: <none>
              parameters
                this.it @82
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <none>
            T3 @50
              element: <none>
        extension type I2 @98
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          typeParameters
            E @101
              element: <none>
          fields
            it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          constructors
            new @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              element: <none>
              parameters
                this.it @108
                  element: <none>
          getters
            get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibraryFragment>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::I1::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeParameters
        E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  void foo() {}
}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              <testLibraryFragment>::@extensionType::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            bar @63
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          methods
            bar @63
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
        bar
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  void foo1() {}
  void foo2() {}
}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo1 @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
            foo2 @66
              reference: <testLibraryFragment>::@extensionType::A::@method::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              <testLibraryFragment>::@extensionType::A::@method::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo1 @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo1 @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo1
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
            foo2 @66
              reference: <testLibraryFragment>::@extensionType::A::@method::foo2
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          methods
            augment foo1 @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo1
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo2
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo2
        foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo1
''');
  }

  test_augmented_methods_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension type A(int it) {
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension type A(int it) {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  void foo() {}
}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          methods
            augment foo @86
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            augment foo @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          methods
            augment foo @86
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            augment foo @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T2>(int it) {
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T>(int it) {
  T foo() => throw 0;
}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
                augmentationSubstitution: {T2: T}
              <testLibraryFragment>::@extensionType::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            bar @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <none>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @39
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <none>
          methods
            bar @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
        bar
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T2>(int it) {
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T>(int it) {
  T foo() => throw 0;
}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T2: T}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <none>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @39
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <none>
          methods
            augment foo @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T>(int it) {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  void foo() {}
  void bar() {}
}
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
            bar @65
              reference: <testLibraryFragment>::@extensionType::A::@method::bar
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibraryFragment>::@extensionType::A::@method::bar
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T: InvalidType}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
            bar @65
              reference: <testLibraryFragment>::@extensionType::A::@method::bar
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T @46
              element: <none>
          methods
            augment foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        bar
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::bar
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  set foo1(int _) {}
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            set foo1= @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @57
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              id: field_2
              setter: setter_1
          accessors
            set foo2= @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @71
                  type: int
              returnType: void
              id: setter_1
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <none>
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo1
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          setters
            set foo1= @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              element: <none>
              parameters
                _ @57
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <none>
              setter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
          setters
            set foo2= @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              element: <none>
              parameters
                _ @71
                  element: <none>
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          setter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      setters
        set foo1=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
        set foo2=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment static set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment static set foo= @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @85
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          setters
            augment set foo= @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              element: <none>
              parameters
                _ @85
                  element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        static foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A(int it) {
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A(int it) {
  set foo1(int _) {}
  set foo2(int _) {}
}
''');

    configuration.withPropertyLinking = true;
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
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_2
              setter: setter_1
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            set foo1= @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @57
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
            set foo2= @69
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @78
                  type: int
              returnType: void
              id: setter_1
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibraryFragment>::@extensionType::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              <testLibraryFragment>::@extensionType::A::@setter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment set foo1= @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @79
                  type: int
              returnType: void
              id: setter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @30
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <none>
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              element: <none>
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo2
          constructors
            new @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <none>
              parameters
                this.it @36
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
          setters
            set foo1= @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              element: <none>
              parameters
                _ @57
                  element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
            set foo2= @69
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo2
              element: <none>
              parameters
                _ @78
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          setters
            augment set foo1= @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              element: <none>
              parameters
                _ @79
                  element: <none>
              previousFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          setter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo2
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final it
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      setters
        set foo2=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo2
        set foo1=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
''');
  }

  test_augmentedBy_class2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';

extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @46
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @46
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }

  test_augmentedBy_class_extensionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment extension type A(int it) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';

extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
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
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @46
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @45
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @46
          reference: <testLibraryFragment>::@extensionType::A
          element: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibraryFragment>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  extensionTypes
    extension type A
      reference: <testLibraryFragment>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
''');
  }
}

@reflectiveTest
class ExtensionTypeElementTest_augmentation_fromBytes
    extends ExtensionTypeElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionTypeElementTest_augmentation_keepLinking
    extends ExtensionTypeElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class ExtensionTypeElementTest_fromBytes extends ElementsBaseTest
    with ExtensionTypeElementMixin {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionTypeElementTest_keepLinking extends ElementsBaseTest
    with ExtensionTypeElementMixin {
  @override
  bool get keepLinkingLibraries => true;
}

// TODO(scheglov): This is duplicate.
extension on ElementTextConfiguration {
  void forPromotableFields({
    Set<String> classNames = const {},
    Set<String> enumNames = const {},
    Set<String> extensionTypeNames = const {},
    Set<String> mixinNames = const {},
    Set<String> fieldNames = const {},
  }) {
    filter = (e) {
      if (e is ClassElement) {
        return classNames.contains(e.name);
      } else if (e is ConstructorElement) {
        return false;
      } else if (e is EnumElement) {
        return enumNames.contains(e.name);
      } else if (e is ExtensionTypeElement) {
        return extensionTypeNames.contains(e.name);
      } else if (e is FieldElement) {
        return fieldNames.isEmpty || fieldNames.contains(e.name);
      } else if (e is MixinElement) {
        return mixinNames.contains(e.name);
      } else if (e is PartElement) {
        return false;
      } else if (e is PropertyAccessorElement) {
        return false;
      }
      return true;
    };
  }
}
